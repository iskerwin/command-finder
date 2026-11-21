#!/bin/zsh
# Metadata, sorting, insertion and concurrent history tests. Never touches the real history or runs a selection.
emulate -L zsh
setopt err_return pipe_fail
unsetopt bgnice
local here=${${(%):-%x}:A:h}
local tmp=$(mktemp -d)
trap 'command rm -rf -- "$tmp"' EXIT
local -i passed=0
assert() {
    [[ $2 == $3 ]] || { print -ru2 -- "$1: expected ${(qqq)2}, got ${(qqq)3}"; exit 1; }
    (( ++passed ))
}
source $here/lib/utils.zsh
source $here/lib/ui.zsh
source $here/sources/history.zsh
source $here/sources/function.zsh
source $here/core.zsh
XDG_STATE_HOME=$tmp/state
CF_HISTORY_MAX=200
# Concurrent appends under one lock lose no records.
local -a workers
local i
for i in {1..20}; do
    ( cf::history_add "command-$i" ) &
    workers+=( $! )
done
for i in $workers; do wait $i; done
local file=$(cf::history_file)
assert 'concurrent append' 20 "$(wc -l < "$file" | tr -d ' ')"
assert 'unique records' 20 "$(cut -f2- "$file" | sort -u | wc -l | tr -d ' ')"
CF_HISTORY_MAX=5
cf::history_add last
assert 'trim retains latest record' last "$(tail -n1 "$file" | cut -f2-)"
assert 'trim length' 5 "$(wc -l < "$file" | tr -d ' ')"
assert 'private history' 600 "$(zmodload -F zsh/stat b:zstat; m=$(zstat -o +mode -- "$file"); print -r -- ${m[-3,-1]})"
cf::history_add $'  tab\tline\nvalue  '
assert 'sanitize history record' 'tab line value' "$(tail -n1 "$file" | cut -f2-)"

mkdir -p $tmp/config
cat > $tmp/config/example.zsh <<'EOF'
# @desc: Sample description
# @usage: sample [arg]
sample() { :; }
_hidden() { :; }
EOF
local -a CF_PATHS=( $tmp/config )
local row=$(cf::source_function)
assert 'metadata name' sample "${${(ps:\x1f:)row}[2]}"
assert 'metadata usage' 'sample [arg]' "${${(ps:\x1f:)row}[4]}"

# Undocumented functions are listed only in files matching CF_FUNCTION_ALL; CF_PATHS may name files.
print -r -- 'plain() { :; }' > $tmp/plain.zsh
CF_PATHS=( $tmp/plain.zsh )
assert 'undocumented skipped' '' "$(cf::source_function)"
local CF_FUNCTION_ALL='/plain\.zsh$'
assert 'CF_FUNCTION_ALL lists all' plain "${${(ps:\x1f:)$(cf::source_function)}[2]}"
unset CF_FUNCTION_ALL
CF_PATHS=( $tmp/config )

# Without host _ui_* helpers the built-in fzf look is used.
local -a reply
cf::fzf_opts
assert 'fallback fzf options' 1 "$(( ${reply[(I)--bind=*change:first*]} > 0 ))"

# all view: alias → function → command, then name; history view: frecency, ties by type.
row() { print -r -- "${(pj:\x1f:)@}"; }
cf::history_scores() { row zcmd 1 1 0; row bfn 5 2 0; row yal 1 1 0; }
cf::source_alias() { row alias yal '' x '' 1; row alias Bal '' x '' 2; }
cf::source_function() { row function bfn '' bfn '' 3; row function afn '' afn '' 4; }
cf::source_command() { row command Ctrl-a '' '' '' 5; row command zcmd '' '' '' 6; row command acmd '' '' '' 7; }
cf::render() { cat; }
cf::fzf() { cut -f2 > "$tmp/all"; cut -f2 "$1/history" > "$tmp/history"; }
command_finder
assert 'all view order' 'Bal yal afn bfn acmd zcmd Ctrl-a' "${(j: :)${(f)$(<$tmp/all)}}"
assert 'history view order' 'bfn yal zcmd' "${(j: :)${(f)$(<$tmp/history)}}"

# With a fixed selection, Enter only fills the buffer and copying neither runs nor records it.
cf::collect() { :; }
cf::render() { cat; }
cf::fzf() { print -r -- "$selection"; }
print() {
    if [[ $1 == -z ]]; then inserted=$3; else builtin print "$@"; fi
}
cf::copy() { builtin print -r -- "$1" > "$tmp/copied"; }
local selection=$'\nfunction\tsample\tdesc\tsample [arg]\t\t\t\tsample '
local inserted=''
command_finder
assert 'enter inserts without execution' 'sample ' "$inserted"
selection=$'ctrl-y\nalias\tsample\tdesc\texpanded value\t\t\t\tsample'
command_finder
assert 'copy uses alias expansion' 'expanded value' "$(command cat -- "$tmp/copied")"
builtin print -r -- "$passed passed"
