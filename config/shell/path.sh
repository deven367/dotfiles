# Shared POSIX PATH setup for Omarchy shells and the desktop session.
# Local launchers win; other entries retain their order. Empty entries would
# search the working directory, so omit them along with duplicate entries.
[ ! -r /usr/share/omarchy/default/bash/env-bootstrap ] || . /usr/share/omarchy/default/bash/env-bootstrap

_user_path_rest=${PATH-}
if [ -d "$HOME/bin" ]; then
    _user_path_rest="${_user_path_rest:+$_user_path_rest:}$HOME/bin"
fi
_user_path="$HOME/.local/bin"
while [ -n "$_user_path_rest" ]; do
    case "$_user_path_rest" in
        *:*)
            _user_path_entry=${_user_path_rest%%:*}
            _user_path_rest=${_user_path_rest#*:}
            ;;
        *)
            _user_path_entry=$_user_path_rest
            _user_path_rest=
            ;;
    esac
    case "$_user_path_entry" in
        ''|"$HOME/.local/share/../bin") continue ;;
    esac
    case ":$_user_path:" in
        *:"$_user_path_entry":*) ;;
        *) _user_path="$_user_path:$_user_path_entry" ;;
    esac
done
PATH=$_user_path
export PATH
unset _user_path _user_path_rest _user_path_entry
