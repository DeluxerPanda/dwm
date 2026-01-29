#!/usr/bin/env bash

if [ -f /usr/bin/fastfetch ]; then
	fastfetch
fi
      alias cat='bat'

eval "$(starship init bash)"

