gadd () { git add "${1}"; }
commit () { git commit -m "${1}" && git push; }
fixes () { git commit -am "fixes #${1}" && git push; }
pypi () { pip install "${1}"; }
count () { find "${1}" -type f | rev | cut -d. -f1 | rev  | tr '[:upper:]' '[:lower:]' | sort | uniq --count | sort -rn; }
# interactive job on quartz
intq ()   { salloc --nodes=1 --ntasks-per-node=10 --time=0${1}:00:00 -p gpu -A r00286 --gpus-per-node=v100:1 --mem=64GB; }
intqd ()  { salloc --nodes=1 --ntasks-per-node=10 --time=01:00:00 -p gpu-debug -A r00286 --gpus-per-node=v100:1 --mem=64GB; }
intqd2 ()  { salloc --nodes=1 --ntasks-per-node=10 --time=01:00:00 -p gpu-debug -A r00286 --gpus-per-node=v100:2 --mem=64GB; }
intqd4 () { salloc --nodes=1 --ntasks-per-node=10 --time=01:00:00 -p gpu-debug -A r00286 --gpus-per-node=v100:4 --mem=0; }

# interactive job on bigred200
intb ()    { salloc -p gpu -A r00286 --nodes=1 --tasks-per-node=1 --gpus-per-node=1 --mem=16GB --time=0${1}:00:00; }
intbc ()   { salloc -p general -A r00286 --nodes=1 --tasks-per-node=1 --mem=64GB --time=0${1}:00:00; }
intbd ()   { salloc -p gpu-debug -A r00286 --nodes=1 --tasks-per-node=1 --gpus-per-node=1 --mem=64G --time=01:00:00; }
intbd4 ()  { salloc -p gpu-debug -A r00286 --nodes=1 --tasks-per-node=1 --gpus-per-node=4 --mem=0 --time=01:00:00; }
intbd42 () { salloc -p gpu-debug -A r00286 --nodes=2 --tasks-per-node=1 --gpus-per-node=4 --mem=0 --time=01:00:00; }

# interactive job on lair
intll ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:L40S:${1} --mem=400GB --time=0${2}:00:00; }
intll4 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:L40S:4 --mem=64GB --time=0${1}:00:00; }
intll8 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:L40S:8 --mem=0 --time=0${1}:00:00; }

intlh ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:H100:${1} --mem=150GB --time=0${2}:00:00; }
intlh2 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:H100:2 --mem=150GB --time=0${1}:00:00; }

function download-playlist() {
    if [[ -n "$1" ]]; then
        touch ./files.txt;
        counter=1;
        while read line; do
            if [[ "$line" == "http"* ]]; then
                curl --silent -o ${counter}.mp4 "$line";
                echo "file ${counter}.mp4" >> ./files.txt;
                ((counter++));
            fi;
        done < "$1";
        ffmpeg -f concat -safe 0 -i ./files.txt -codec copy output.mp4;
    else
        echo 'Usage: download-playlist <file.m3u8>';
    fi
}

# view txt and err files from the sqlite database
view_txt () { sqlite3 ~/job_results.db "select txt_content from job_results where job_id = '${1}';" > ${1}.txt; }
view_err () { sqlite3 ~/job_results.db "select err_content from job_results where job_id = '${1}';" > ${1}.err; }


# download youtube mp3; prints the downloaded path on stdout so it can feed a pipe
#   get-mp3 URL | cvt-whisper | otxt
# (yt-dlp progress goes to stderr: its --print/--progress both write to stdout, which would
#  corrupt the pipe, so the path is captured via --print-to-file instead)
get-mp3 () {
  local url="$1" t out
  t=$(mktemp)
  yt-dlp -x --audio-format mp3 -o '%(id)s.%(ext)s' --print-to-file after_move:filepath "$t" "$url" >&2
  out=$(cat "$t"); rm -f "$t"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}

# handy for cleaning nbs
nbclean () { nbdev_clean --fname "${1}"; }

# simple commands to loop certain commands
loop1 () { watch -n 1 "${1}"; }
loop () { watch -n ${1} "${2}"; }

# media -> 16 kHz mono WAV for whisper. Path from $1 or stdin; prints the WAV path
cvt-whisper () {
  local in="$1"
  [ -n "$in" ] || IFS= read -r in
  in="${in%$'\r'}"                              # tolerate CR from a piped producer
  [ -n "$in" ] || { echo "usage: cvt-whisper <media>  (or pipe a path in)" >&2; return 2; }
  local out="${in%.*}.wav"
  [ "$out" = "$in" ] && out="${in}.16k.wav"   # input is already .wav: don't clobber it
  ffmpeg -nostdin -y -loglevel error -i "$in" -vn -ar 16000 -ac 1 -c:a pcm_s16le "$out" || return 1
  printf '%s\n' "$out"
}

# pandoc
word_to_md () { pandoc -t markdown_strict --extract-media="./attachments/${1}" "${1}" -o "${1:0:-5}.md"; }

alias a=alias

a issues="gh issue list"
a issue="gh issue create"
a enhancement="gh issue create -l enhancement -b '' -t"
a bug="gh issue create -l bug -b '' -t"
a breaking="gh issue create -l breaking -b '' -t"
a note="gh issue -R deven367/notes create"
a notes="gh issue list -R deven367/notes"

alias gitssh="perl -pi -e 's#https://github\.com/#git\@github.com:# if /\[remote \"origin/../fetch =/' .git/config"

a minst="mamba install -c defaults"
a cls="clear"
a multipull="ls | parallel git -C {} pull"
a jp="jupyter nbclassic --no-browser"
a jl="jupyter lab --no-browser"
a ca="conda activate ''"
a cdd="conda deactivate"
a mktorch="conda create -yn torch python=3.10"
a cals="conda env list"
a gs='git status'
a ll='ls -laF'
a t="todo.sh"
a push="git push"
a pull="git pull"
a grv="git remote -v"
a mpull="find . -name ".git" -type d | sed 's/\/.git//' |  xargs -P10 -I{} git -C {} pull"
a sizes="du -sh * | sort -rh"

a pending-gpu="squeue -p gpu -t PD --sort=+i"
a running-gpu="squeue -p gpu -t R --sort=+i"

a pending="squeue -t PD --sort=+i"
a running="squeue -t R --sort=+i"

a pgd="pending -p gpu-debug"
a rgd="running -p gpu-debug"

a jobs="squeue --me --sort=+i"

# forward a local port through ssh (default host: lair)
sshforward () { [ -n "$1" ] || { echo "Error: Please provide a port number." >&2; echo "Usage: sshforward <port> [host]" >&2; return 1; }; ssh -N -L "${1}:localhost:${1}" "${2:-lair}"; }

# Remote-SSH into an internal compute node.
# User/key/ProxyJump come from the wildcard blocks in ~/.ssh/config (Host lair-*, g*, x*);
# Remote-SSH just runs `ssh <node>`, so nothing per-node to hand-edit.
#   vsnode lair              -> resolves your running job via squeue (e.g. lair-g6)
#   vsnode lair-g6 ~/proj    -> explicit node + remote folder (default /tmp)
vsnode () {
  [ -n "$1" ] || { echo "usage: vsnode <cluster|node> [remote-path]" >&2; return 1; }
  local target=$1 node; shift
  case $target in
    lair|quartz|bigred200)
      # ponytail: first node only; iterate %N if you ever need a multi-node job
      node=$(ssh -o BatchMode=yes "$target" 'squeue -h -u $USER -t RUNNING -o %N' | tr ',' '\n' | head -1) ;;
    *) node=$target ;;
  esac
  [ -n "$node" ] || { echo "vsnode: no running job on $target" >&2; return 1; }
  code --remote "ssh-remote+$node" "${1:-/tmp}"
}

# llama.cpp server tunnel: localhost:9932 <-> <host>:9932 (background, pidfile-managed)
#   llamatunnel [host]   start (default host: node-lair; no-op if already up)
#   llamatunnel stop     stop (pidfile first, lsof fallback)
llamatunnel () {
  local host="${1:-node-lair}"
  if [ "${1:-}" = "stop" ]; then
    if [ -f /tmp/llamatunnel.pid ] && kill -0 "$(cat /tmp/llamatunnel.pid)" 2>/dev/null; then
      kill "$(cat /tmp/llamatunnel.pid)" && echo "tunnel stopped (pid $(cat /tmp/llamatunnel.pid))"
    elif lsof -tiTCP:9932 -sTCP:LISTEN >/dev/null 2>&1; then
      lsof -tiTCP:9932 -sTCP:LISTEN 2>/dev/null | while read p; do kill "$p"; done
      echo "tunnel stopped (lsof fallback)"
    else
      echo "no tunnel running"
    fi
    rm -f /tmp/llamatunnel.pid
    return 0
  fi
  if lsof -tiTCP:9932 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "tunnel already up on localhost:9932"
    return 1
  fi
  nohup ssh -N -o ExitOnForwardFailure=yes -L 9932:127.0.0.1:9932 "$host" >/tmp/llamatunnel.log 2>&1 &
  echo $! > /tmp/llamatunnel.pid
  sleep 1
  if lsof -tiTCP:9932 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "tunnel up to $host (pid $(cat /tmp/llamatunnel.pid))"
  else
    echo "tunnel failed - log:"; cat /tmp/llamatunnel.log; rm -f /tmp/llamatunnel.pid
  fi
}
