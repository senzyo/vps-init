# 以下是自定义内容

PS1='\n'
PS1+='\[\e[1;37m\]'
PS1+='\t '
PS1+='\[\e[1;31m\]'
PS1+='\u'
PS1+='\[\e[1;37m\]'
PS1+='@'
PS1+='\[\e[1;31m\]'
PS1+='\h '
PS1+='\[\e[1;36m\]'
PS1+='$PWD'
PS1+='\n'
PS1+='\[\e[1;31m\]'
PS1+='\$ '
PS1+='\[\e[0m\]'
export PS1

alias ls="ls -F --color=auto"
alias la="ls -aF --color=auto"
alias ll="ls -alF --color=auto"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias tree="tree -pughDC"

ch() {
	: >"$HOME/.bash_history"
	history -c
	clear
}

export TIME_STYLE="+%Y-%m-%d %H:%M:%S"
