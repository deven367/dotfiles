#!/usr/bin/env bash
#
# trim-texlive.sh — reclaim several GB from a full MacTeX / TeX Live install by
# removing documentation, package sources, and the engine packages that nothing
# on this machine uses.
#
#   ./trim-texlive.sh                     # dry run: pre-flight + plan, changes nothing
#   sudo ./trim-texlive.sh --apply        # execute
#   sudo ./trim-texlive.sh --apply --gui  # also drop BibDesk / LaTeXiT / hintview
#   TEXLIVE_ROOT=/usr/local/texlive/2026 ./trim-texlive.sh    # target another tree
#
# What is kept, and why: `latexmk --shell-escape -pdf %DOC%` (the LaTeX Workshop
# recipe) runs pdflatex, bibtex, biber and synctex. Those stay, along with the
# fonts, texmf-var font maps, and everything minted / pstricks documents need.
#
# What is dropped: xetex, lualatex, ConTeXt, Asymptote, bibtexu, upmendex and the
# multistream biber — verified zero occurrences of all of them across
# ~/projects and ~/Documents (plain biber is deliberately kept for biblatex).
#
# Safety model: tlmgr copies removed packages to tlpkg/backups before removing
# them, and this script only deletes that directory after the post-removal
# compile test passes. Until then: sudo tlmgr restore --all.
#
set -euo pipefail

APPLY=0
GUI=0

usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; }

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --gui)   GUI=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# Newest /usr/local/texlive/20xx unless overridden.
if [[ -n "${TEXLIVE_ROOT:-}" ]]; then
  TEXROOT=$TEXLIVE_ROOT
else
  TEXROOT=''
  for d in /usr/local/texlive/20*; do [[ -d $d ]] && TEXROOT=$d; done   # glob sorts, last wins
  [[ -n $TEXROOT ]] || { echo "error: no TeX Live under /usr/local/texlive" >&2; exit 1; }
fi
TLPDB="$TEXROOT/tlpkg/texlive.tlpdb"
DOCDIR="$TEXROOT/texmf-dist/doc"
SRCDIR="$TEXROOT/texmf-dist/source"
BACKUPDIR="$TEXROOT/tlpkg/backups"

# Each binary lives in a separate <pkg>.universal-darwin container package, and
# tlmgr never removes a package's dependencies on its own, so both names must be
# listed. --force is required: tlmgr otherwise refuses because ctex /
# collection-xetex / latex-bin nominally depend on xetex and luatex.
DROP_PKGS=(
  xetex xetex.universal-darwin
  luatex luatex.universal-darwin
  luahbtex luahbtex.universal-darwin
  luajittex luajittex.universal-darwin
  context context.universal-darwin        # also carries luametatex + mtxrun
  asymptote asymptote.universal-darwin
  bibtexu bibtexu.universal-darwin
  upmendex upmendex.universal-darwin
  biber-ms biber-ms.universal-darwin      # multistream biber; plain biber is kept
)

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

run() {   # every mutating call goes through here
  if ((APPLY)); then
    "$@"
  else
    printf '  would run: %s\n' "$*"
  fi
}

dirsize() { [[ -d $1 ]] && du -sh "$1" | cut -f1 || echo 'absent'; }

# The build-critical binaries must exist and run. pygments / ghostscript are
# reported but not enforced: we remove neither python nor ghostscript, they are
# listed so a broken minted / pstricks setup is visible rather than mysterious.
check_capabilities() {
  local phase=$1
  say "capability check ($phase):"
  local probe
  for probe in pdflatex bibtex latexmk; do
    if "$probe" --version >/dev/null 2>&1 || "$probe" -v >/dev/null 2>&1; then
      say "  ok    $probe"
    else
      say "  FAIL  $probe"
      return 1
    fi
  done
  if synctex 2>&1 | grep -q version; then say "  ok    synctex"; else say "  FAIL  synctex"; return 1; fi
  if python3 -c 'import pygments' 2>/dev/null; then
    say "  ok    pygments (minted)"
  else
    say "  warn  pygments missing — minted documents will not build"
  fi
  if command -v gs >/dev/null 2>&1; then
    say "  ok    ghostscript $(gs --version) (pstricks/eps)"
  else
    say "  warn  ghostscript missing — pstricks/eps documents will not build"
  fi
}

# Compile a beamer document that needs two passes and a bibtex run. This is the
# regression test for the whole script: it uses the same flags as the editor
# recipe (minus -outdir=%OUTDIR%, which is a VS Code placeholder, not a path).
SMOKEDIR=$(mktemp -d)
trap 'rm -rf "$SMOKEDIR"' EXIT

smoke_build() {
  cat > "$SMOKEDIR/probe.tex" <<'TEX'
\documentclass[8pt]{beamer}
\begin{document}
\section{Probe}
\begin{frame}{Toc}\tableofcontents\end{frame}
\begin{frame}{Cite}\cite{knuth1984}\end{frame}
\bibliographystyle{plain}
\bibliography{refs}
\end{document}
TEX
  cat > "$SMOKEDIR/refs.bib" <<'BIB'
@book{knuth1984, author={Donald E. Knuth}, title={The {\TeX}book}, year={1984}, publisher={Addison-Wesley}}
BIB
  if ! ( cd "$SMOKEDIR" && latexmk --shell-escape -synctex=1 -interaction=nonstopmode \
          -file-line-error -pdf probe.tex ) >"$SMOKEDIR/build.log" 2>&1; then
    say "  FAIL  latexmk exited non-zero:"
    tail -15 "$SMOKEDIR/build.log" | sed 's/^/        /'
    return 1
  fi
  [[ -s $SMOKEDIR/probe.pdf ]] || { say "  FAIL  no PDF produced"; return 1; }
  grep -q 'bibcite{knuth1984}' "$SMOKEDIR/probe.aux" \
    || { say "  FAIL  bibliography did not resolve"; return 1; }
  rm -rf "$SMOKEDIR"/probe.* "$SMOKEDIR"/refs.*    # keep the dir for the next run
  say "  ok    beamer + toc + bibtex compiled end to end"
}

# kpse must still resolve the core formats after the doc/source deletion.
kpse_sanity() {
  local f
  for f in beamer.cls pdftex.map cmr10.tfm; do
    if kpsewhich "$f" >/dev/null; then
      say "  ok    kpsewhich $f"
    else
      say "  FAIL  kpsewhich $f"
      return 1
    fi
  done
}

# ---------------------------------------------------------------- pre-flight
if ((APPLY)); then
  [[ $EUID -eq 0 ]] || die "--apply needs root: sudo $0 --apply${GUI:+ --gui}"
fi

[[ -d $TEXROOT ]] || die "no TeX Live at $TEXROOT (set TEXLIVE_ROOT=...)"
[[ -f $TLPDB ]]   || die "no $TLPDB — not a TeX Live install?"
command -v kpsewhich >/dev/null 2>&1 || die "kpsewhich not on PATH — fix the TeX PATH (/etc/paths.d/TeX) first"

say "TeX Live root : $TEXROOT  ($(dirsize "$TEXROOT"))"
say "mode          : $( ((APPLY)) && echo APPLY || echo 'DRY RUN (pass --apply to execute)' )"
say
say "1. pre-flight — the toolchain must build before we touch it"
check_capabilities before || die "toolchain already broken; nothing removed"
smoke_build || die "baseline compile failed; nothing removed"

# ------------------------------------------------------------- plan
present=()
for p in "${DROP_PKGS[@]}"; do
  grep -qx "name $p" "$TLPDB" && present+=("$p")
done

say
say "2. plan"
say "   engines to remove : ${#present[@]} package(s)$( (( ${#present[@]} )) && printf '\n     %s' "${present[@]}" )"
(( ${#present[@]} )) && say
say "   documentation     : $DOCDIR  ($(dirsize "$DOCDIR"))"
say "   package sources   : $SRCDIR  ($(dirsize "$SRCDIR"))"
say "   tlmgr backups     : $BACKUPDIR  ($(dirsize "$BACKUPDIR"))"
((GUI)) && say "   GUI apps          : /Applications/TeX/{BibDesk,LaTeXiT,hintview}.app"
say

if ! ((APPLY)); then
  say "dry run complete — nothing was changed. Re-run with: sudo $0 --apply"
  exit 0
fi

# ------------------------------------------------------------- execute
say "3. removing unused engines"
command -v tlmgr >/dev/null 2>&1 || die "tlmgr not on PATH"
run tlmgr option docfiles 0          # stop future installs pulling documentation
if (( ${#present[@]} )); then
  run tlmgr remove --force --no-depends "${present[@]}"
else
  say "  nothing to remove (already trimmed?)"
fi

say
say "4. post-removal verification"
ok=1
check_capabilities after || ok=0
smoke_build || ok=0
if ((ok == 0)); then
  say
  say "VERIFICATION FAILED. Docs/sources were not touched and tlmgr's backups are intact:"
  say "    sudo tlmgr restore --all"
  exit 1
fi

say
say "5. documentation + sources (no compile step reads these; texdoc stops working)"
for d in "$DOCDIR" "$SRCDIR"; do
  if [[ -d $d ]]; then run rm -rf "$d"; else say "  already absent: $d"; fi
done
run mktexlsr
kpse_sanity || die "kpse lookups broke after removing docs/sources"

say
say "6. dropping tlmgr's removal backups — undo window closes here"
if [[ -d $BACKUPDIR ]]; then run rm -rf "$BACKUPDIR"; else say "  no backups dir"; fi

if ((GUI)); then
  say
  say "7. GUI apps"
  for app in BibDesk LaTeXiT hintview; do
    p="/Applications/TeX/$app.app"
    if [[ -d $p ]]; then run rm -rf "$p"; else say "  absent: $p"; fi
  done
fi

say
say "done. $TEXROOT is now $(du -sh "$TEXROOT" | cut -f1)"
say "rollback (only if you kept the backups): sudo tlmgr restore --all"
say "note: MacTeX pkg receipts remain registered; clear them with:"
say "  sudo pkgutil --forget org.tug.mactex.texlive2023   # and org.tug.mactex.gui2023"
