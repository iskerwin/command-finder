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
source $here/lib/ui-fallback.zsh
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

# The plugin works without zsh-ui (fallback), and zsh-ui wins whether it loads before or after it.
assert 'fallback without zsh-ui' 'ui-fallback.zsh' "$(zsh -f -c 'source $1/command-finder.plugin.zsh; print -r -- ${functions_source[_ui_err]:t}' _ $here)"
assert 'zsh-ui loaded first wins' zsh-ui "$(zsh -f -c '_ui_err() { print zsh-ui; }; source $1/command-finder.plugin.zsh; _ui_err' _ $here)"
assert 'zsh-ui loaded later wins' zsh-ui "$(zsh -f -c 'source $1/command-finder.plugin.zsh; _ui_err() { print zsh-ui; }; _ui_err' _ $here)"

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
# fzf older than 0.58: say so and bind nothing
oldfzf=$(mktemp -d)
print -r -- '#!/bin/sh
echo "0.44.1 (debian)"' > $oldfzf/fzf; chmod +x $oldfzf/fzf
assert 'old fzf: message, no widget' 'command-finder: needs fzf 0.58 or newer, found 0.44.1 0' \
    "$(env -u ZSH_UI_DIR PATH=$oldfzf:$PATH zsh -fi -c 'source $1/command-finder.plugin.zsh 2>&1 | cut -d" " -f1-8; source $1/command-finder.plugin.zsh 2>/dev/null; print -r -- ${+widgets[command_finder]}' _ ${here:-$PWD} 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
# cf-doctor: loaded and failing without fzf, passing with a new enough one
nofzf=$(mktemp -d); command ln -s $commands[zsh] $nofzf/zsh
out=$(env -u ZSH_UI_DIR PATH=$nofzf HOME=$tmp $commands[zsh] -f -c 'CF_PATHS=( $2 ); source $1/command-finder.plugin.zsh; cf-doctor; print -r -- "rc=$?"' _ ${here:-$PWD} $here/core.zsh 2>&1 </dev/null || true)
assert 'cf-doctor without fzf: exits 1' 1 "$(print -r -- $out | grep -c '^rc=1')"
assert 'cf-doctor without fzf: names fzf' 1 "$(print -r -- $out | grep -c '^! fzf  the picker')"
newfzf=$(mktemp -d)
print -r -- '#!/bin/sh
echo "0.66.0 (brew)"' > $newfzf/fzf; chmod +x $newfzf/fzf
out=$(env -u ZSH_UI_DIR PATH=$newfzf:$PATH HOME=$tmp XDG_STATE_HOME=$tmp/st $commands[zsh] -f -c 'CF_PATHS=( $2 $3/missing ); source $1/command-finder.plugin.zsh; cf-doctor; print -r -- "rc=$?"' _ ${here:-$PWD} $here/core.zsh $tmp 2>&1 </dev/null || true)
assert 'cf-doctor with fzf 0.66: exits 0' 1 "$(print -r -- $out | grep -c '^rc=0')"
out2=$(env -u ZSH_UI_DIR PATH=$newfzf:$PATH HOME=$tmp XDG_STATE_HOME=$tmp/st $commands[zsh] -f -c 'CF_PATHS=( $2 ); source $1/command-finder.plugin.zsh; cf-doctor' _ ${here:-$PWD} $here/sources 2>&1 </dev/null || true)
assert 'cf-doctor: counts the *.zsh files in a directory' 1 "$(print -r -- $out2 | grep -c 'sources/  4 \*.zsh')"
assert 'cf-doctor: missing CF_PATHS entry is flagged' 1 "$(print -r -- $out | grep -c 'missing  does not exist')"
builtin print -r -- "$passed passed"
