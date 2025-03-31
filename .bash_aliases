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
intll4 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:L40S:4 --mem=64GB --time=0${1}:00:00; }
intll8 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:L40S:8 --mem=0 --time=0${1}:00:00; }

intlh2 ()  { salloc -p general -A cogneuroai --nodes=1 --tasks-per-node=10 --gres=gpu:H100:2 --mem=150GB --time=0${1}:00:00; }


# view txt and err files from the sqlite database
view_txt () { sqlite3 ~/job_results.db "select txt_content from job_results where job_id = '${1}';" > ${1}.txt; }
view_err () { sqlite3 ~/job_results.db "select err_content from job_results where job_id = '${1}';" > ${1}.err; }


# download youtube mp3
get-mp3 () { yt-dlp -x --audio-format mp3 -o '%(id)s.%(ext)s' "${1}"; }

# handy for cleaning nbs
nbclean () { nbdev_clean --fname "${1}"; }

# simple commands to loop certain commands
loop1 () { watch -n 1 "${1}"; }
loop () { watch -n ${1} "${2}"; }

cvt-whisper () { ffmpeg -i "${1}" -ar 16000 -ac 1 -c:a pcm_s16le "${1:0:-4}.wav";}

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

a pending_gpu="squeue -p gpu -t PD --sort=+i"
a running_gpu="squeue -p gpu -t R --sort=+i"

a pending="squeue -t PD --sort=+i"
a running="squeue -t R --sort=+i"

a pgd="pending -p gpu-debug"
a rgd="running -p gpu-debug"

a jobs="squeue --me --sort=+i"


if [ -d ~/.local ]; then
    export PATH=$PATH:~/bin:~/.local/bin/:~/gh/bin
    export PATH=$PATH:"/Applications/Racket v8.14/bin"
fi

if [ -d ~/.modular ]; then
    export MODULAR_HOME="~/.modular"
    export PATH="/Users/deven367/.modular/pkg/packages.modular.com_mojo/bin:$PATH"
fi
