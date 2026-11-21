# command-finder/sources/command.zsh

# Catalog comment lines (a command, then an aligned comment with its description), for example:
#   # git log --oneline -20           # Show the last 20 commits
# Use them for subcommands and common invocations that are not aliases or functions
# Output: command \x1f command \x1f description \x1f \x1f file \x1f line
cf::source_command() {
  local -a files=( ${(f)"$(cf::files)"} )
  (( $#files )) || return 0

  $CF_AWK -v sep=$CF_SEP '
  /^#[ \t]+[^#═─ \t][^#]*[^# \t][ \t][ \t]+#[ \t]+[^ \t]/ {
    match($0, /[ \t][ \t]+#[ \t]+/)
    cmd = substr($0, 2, RSTART - 2)
    sub(/^[ \t]+/, "", cmd); sub(/[ \t]+$/, "", cmd)
    desc = substr($0, RSTART + RLENGTH)
    sub(/[ \t]+$/, "", desc)
    printf "command%s%s%s%s%s%s%s%s%d\n", sep, cmd, sep, desc, sep, sep, FILENAME, sep, FNR
  }
  ' "${files[@]}"
}
