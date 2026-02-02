# xdns bash completion
# Install: sudo cp completions/xdns.bash /etc/bash_completion.d/xdns
# Or: cp completions/xdns.bash ~/.local/share/bash-completion/completions/xdns

_xdns() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main options
    opts="-h --help -v --version -l --list -s --set -c --custom -r --restore -t --test --lock"
    
    case "${prev}" in
        -s|--set)
            # DNS provider numbers 1-12
            COMPREPLY=($(compgen -W "1 2 3 4 5 6 7 8 9 10 11 12" -- "${cur}"))
            return 0
            ;;
        *)
            ;;
    esac
    
    # Complete options
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        return 0
    fi
}

complete -F _xdns xdns
complete -F _xdns sudo
