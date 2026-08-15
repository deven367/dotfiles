#!/usr/bin/env python3
"""Shared chat plumbing for bin/chat-* scripts.

One REPL, three transports (openai-compatible, anthropic, gemini).
Each chat-* script is a thin wrapper that picks provider/model/label/system.
API keys come from the environment (~/.secrets via env.zsh), never from files.

Usage (see the chat-* wrappers):
    from chatlib import run, ask
    run(provider="openai", model="gpt-4o", label="GPT4o : ", system="...")
    ask(provider="gemini", model="gemini-pro", prompt="...")
"""

import os

from rich.console import Console
from rich.markdown import Markdown
from rich.prompt import Prompt


def _openai_factory(env_var, base_url):
    from openai import OpenAI

    def make(model, system):
        client = OpenAI(api_key=os.environ[env_var], base_url=base_url)
        log = [{"role": "system", "content": system}] if system else []

        def send(text):
            log.append({"role": "user", "content": text})
            resp = client.chat.completions.create(
                model=model,
                messages=log,
                max_tokens=3800,
                stop=None,
                temperature=0.7,
            )
            reply = resp.choices[0].message.content or ""
            log.append({"role": "assistant", "content": reply})
            return reply

        return send

    return make


def _anthropic_factory(env_var, base_url):
    import anthropic

    def make(model, system):
        client = anthropic.Client(api_key=os.environ[env_var])
        log = []
        kwargs = {"system": system} if system else {}

        def send(text):
            log.append({"role": "user", "content": [{"type": "text", "text": text}]})
            resp = client.messages.create(
                model=model, max_tokens=3800, messages=log, **kwargs
            )
            reply = "".join(
                b.text for b in resp.content if getattr(b, "type", "") == "text"
            )
            log.append({"role": "assistant", "content": [{"type": "text", "text": reply}]})
            return reply

        return send

    return make


def _gemini_factory(env_var, base_url):
    import google.generativeai as genai

    def make(model, system):
        genai.configure(api_key=os.environ[env_var])
        kwargs = {"system_instruction": system} if system else {}
        chat = genai.GenerativeModel(model, **kwargs).start_chat(history=[])

        def send(text):
            return chat.send_message(text).text

        return send

    return make


FACTORIES = {
    "openai": (_openai_factory, "OPENAI_API_KEY"),
    "anthropic": (_anthropic_factory, "ANTHROPIC_API_KEY"),
    "gemini": (_gemini_factory, "GEMINI_API_KEY"),
}


def _session(provider, model, system, base_url, env_var=None):
    factory, default_env = FACTORIES[provider]
    return factory(env_var or default_env, base_url)(model, system)


def run(provider, model, label, color="cyan", rule=False, system=None, base_url=None, env_var=None):
    """Interactive REPL: prompt, send, render the reply as markdown."""
    console = Console()
    send = _session(provider, model, system, base_url, env_var)
    console.print("[dim](type 'quit' or 'bye' to exit)[/dim]")
    while True:
        try:
            user_input = Prompt.ask(f"[bold {color}]You[/bold {color}]").strip()
        except (EOFError, KeyboardInterrupt):
            console.print("Goodbye!")
            return
        if not user_input:
            continue
        if user_input.lower() in ("quit", "bye"):
            console.print("Goodbye!")
            return
        try:
            reply = send(user_input)
        except Exception as exc:
            console.print(f"[red]error: {exc}[/red]")
            continue
        console.print(f"[bold {color}]{label}[/bold {color}]")
        console.print(Markdown(reply))
        if rule:
            console.rule(style="dim")


def ask(provider, model, prompt, system=None, base_url=None, env_var=None):
    """One-shot: print a single reply as markdown (pipe-friendly)."""
    console = Console()
    reply = _session(provider, model, system, base_url, env_var)(prompt)
    console.print(Markdown(reply))
