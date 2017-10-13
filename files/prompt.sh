#!/bin/bash

# Test to make sure the shell is interactive.
if [[ $- != *i* ]] ; then
	return
fi

# Configure basic shell settings.
shopt -s checkwinsize
shopt -s no_empty_cmd_completion
shopt -s histappend

# Change the window title of X terminals
case ${TERM} in
  [aEkx]term*|rxvt*|gnome*|konsole*|interix)
    PS1='\[\033]0;\u@\h:\w\007\]'
    ;;
  screen*)
    PS1='\[\033k\u@\h:\w\033\\\]'
    ;;
  *)
    unset PS1
    ;;
esac

# Source the 256 color pallet for directories.
eval "$(dircolors -b /etc/DIR_COLORS.256color)"

# Set the bash prompt to have proper colors.
if [[ ${EUID} == 0 ]] ; then
  PS1+='\[\033[01;31m\]\u\[\033[01;34m\] \W \$\[\033[00m\] '
else
  PS1+='\[\033[01;32m\]\u\[\033[01;34m\] \w \$\[\033[00m\] '
fi

alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
