#!/usr/bin/env bash
case $- in
*i*) ;;
*) return ;;
esac
[[ -z ${debian_chroot:-} && -r /etc/debian_chroot ]] && debian_chroot=$(cat /etc/debian_chroot)
case "${TERM}" in
xterm-color | *-256color) color_prompt=yes ;;
*) ;;
esac
if [[ -n ${force_color_prompt:-} ]]; then
	if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
		color_prompt=yes
	else
		color_prompt=
	fi
fi
if [[ ${color_prompt} == yes ]]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt
case "${TERM}" in
xterm* | rxvt*) PS1="\[\e]0;${debian_chroot:+(${debian_chroot})}\u@\h: \w\a\]${PS1}" ;;
*) ;;
esac
if [[ -x "/usr/bin/dircolors" ]]; then
	# shellcheck disable=SC2015
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# shellcheck disable=SC1090
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
if ! shopt -oq posix; then
	if [ -f "/usr/share/bash-completion/bash_completion" ]; then
		. "/usr/share/bash-completion/bash_completion"
	elif [ -f "/etc/bash_completion" ]; then
		. "/etc/bash_completion"
	fi
fi
[[ -r "/opt/iris/src/init.sh" ]] && . "/opt/iris/src/init.sh"
