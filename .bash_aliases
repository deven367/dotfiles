commit () { git commit -am "${1}" && git push; }
fixes () { git commit -am "fixes #${1}" && git push; }
pypi () { pip install "${1}"; }
ps () { pip show ${1}; }
count () { find "${1}" -type f | rev | cut -d. -f1 | rev  | tr '[:upper:]' '[:lower:]' | sort | uniq --count | sort -rn; }
# interactive job on carbonate
intc () { srun --nodes=1 --ntasks-per-node=1 --time=0${1}:00:00 -p gpu -A r00308 --gpus-per-node=v100:1 --pty bash -i; }

# interactive job on bigred200
intb () { salloc -p gpu -A r00286 --nodes=1 --tasks-per-node=1 --gpus-per-node=1 --mem=16GB --time=0${1}:00:00; }

intbd () { salloc -p gpu-debug -A r00286 --nodes=1 --tasks-per-node=1 --gpus-per-node=1 --mem=16GB --time=0${1}:00:00; }

# view txt and err files from the sqlite database
view_txt () { sqlite3 job_results.db "select txt_content from job_results where job_id = '${1}';" > ${1}.txt; }
view_err () { sqlite3 job_results.db "select err_content from job_results where job_id = '${1}';" > ${1}.err; }


# download youtube mp3
get_mp3 () { yt-dlp -x --audio-format mp3 "${1}"; }

# handy for cleaning nbs
nbclean () { nbdev_clean --fname "${1}"; }

# simple commands to loop certain commands
loop1 () { watch -n 1 "${1}"; }
loop () { watch -n ${1} "${2}"; }

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
a jp="jupyter notebook --no-browser"
a jl="jupyter lab --no-browser"
a ca="conda activate ''"
a cdd="conda deactivate"
a mktorch="conda create -yn torch python=3.10"
a cals="conda env list"
a gs='git status'
a connect_bigred='ssh bigred200'
a connect_carbonate='ssh carbonate'
a ping_bigred='ping -c5 bigred200.uits.iu.edu'
a ll='ls -laF'
a t="todo.sh"
a push="git push"
a pull="git pull"

a pending_gpu="squeue -p gpu -t PD --sort=+i"
a running_gpu="squeue -p gpu -t R --sort=+i"

a pending="squeue -t PD --sort=+i"
a running="squeue -t R --sort=+i"

a pgd="pending -p gpu-debug"
a rgd="running -p gpu-debug"

a jobs="squeue --me"


export PATH=$PATH:~/bin
export MODULAR_HOME=~/.modular