# shellcheck disable=SC2034,SC2153,SC2086,SC2155

# Above line is because shellcheck doesn't support zsh, per
# https://github.com/koalaman/shellcheck/wiki/SC1071, and the ignore: param in
# ludeeus/action-shellcheck only supports _directories_, not _files_. So
# instead, we manually add any error the shellcheck step finds in the file to
# the above line ...

# Source this in your ~/.zshrc
autoload -U add-zsh-hook

export ATUIN_SESSION=$(atuin uuid)
export ATUIN_HISTORY="atuin history list"

_atuin_preexec(){
	local id; id=$(atuin history start "$1")
	export ATUIN_HISTORY_ID="$id"
}

_atuin_precmd(){
	local EXIT="$?"

	[[ -z "${ATUIN_HISTORY_ID}" ]] && return


	(RUST_LOG=error atuin history end $ATUIN_HISTORY_ID --exit $EXIT &) > /dev/null 2>&1
}

_atuin_search(){
	emulate -L zsh
	zle -I

	# Switch to cursor mode, then back to application
	echoti rmkx
	# swap stderr and stdout, so that the tui stuff works
	# TODO: not this
	output=$(RUST_LOG=error atuin search -i $BUFFER 3>&1 1>&2 2>&3)
	echoti smkx

	if [[ -n $output ]] ; then
		LBUFFER=$output
	fi

	zle reset-prompt
}

_atuin_search_filterSession(){
	emulate -L zsh
	zle -I

	# Switch to cursor mode, then back to application
	echoti rmkx
	# swap stderr and stdout, so that the tui stuff works
	# TODO: not this
	output=$(RUST_LOG=error atuin search -i -f session $BUFFER 3>&1 1>&2 2>&3)
	echoti smkx

	if [[ -n $output ]] ; then
		LBUFFER=$output
	fi

	zle reset-prompt
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd

zle -N _atuin_search_widget _atuin_search
zle -N _atuin_search_widget_filterSession _atuin_search_filterSession

if [[ -z $ATUIN_NOBIND ]]; then
	bindkey '^r' _atuin_search_widget_filterSession

	# depends on terminal mode
	bindkey '^[[A' _atuin_search_widget
	bindkey '^[OA' _atuin_search_widget
fi
