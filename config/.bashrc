#!/usr/bin/env bash
iatest=$(expr index "$-" i)

#######################################################
# SOURCED ALIAS'S AND SCRIPTS BY zachbrowne.me and ChrisTitusTech
#######################################################
if [ -f /usr/bin/fastfetch ]; then
	fastfetch
fi
      alias cat='bat'

eval "$(starship init bash)"

