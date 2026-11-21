# command-finder/sources/alias.zsh

# Only aliases defined in CF_PATHS and still active; the description is the trailing comment, the value comes from $aliases
# Output: alias \x1f name \x1f description \x1f expansion \x1f file \x1f line
cf::source_alias() {
  local -a files=( ${(f)"$(cf::files)"} )
  (( $#files )) || return 0

  local name desc file line raw value
  local -A seen fallback entry
  $CF_AWK -v sep=$CF_SEP '
    /^[[:space:]]*alias[[:space:]]+[a-zA-Z0-9_.:-]+=/ {
      name = $0
      sub(/^[[:space:]]*alias[[:space:]]+/, "", name)
      sub(/=.*/, "", name)

      # The description follows the first # outside quotes that is preceded by whitespace; the value is between = and it
      line = $0; desc = ""; end = length(line) + 1
      in_single = 0; in_double = 0
      n = split(line, chars, "")
      for (i = 1; i <= n; i++) {
        c = chars[i]
        if (c == "\x27" && !in_double) in_single = !in_single
        else if (c == "\"" && !in_single) in_double = !in_double
        else if (c == "#" && !in_single && !in_double && i > 1 && chars[i-1] ~ /[[:space:]]/) {
          desc = substr(line, i + 1)
          sub(/^[[:space:]]+/, "", desc)
          sub(/[[:space:]]+$/, "", desc)
          end = i
          break
        }
      }
      raw = substr(line, index(line, "=") + 1, end - index(line, "=") - 1)
      sub(/[[:space:]]+$/, "", raw)
      printf "%s%s%s%s%s%s%d%s%s\n", name, sep, desc, sep, FILENAME, sep, FNR, sep, raw
    }
  ' "${files[@]}" |
  while IFS=$CF_SEP read -r name desc file line raw; do
    (( $+aliases[$name] )) || continue
    # An alias defined in several places (e.g. with and without eza): keep the one whose value matches the active value;
    # if none matches (unusual quoting), keep the first
    if [[ ${(Q)raw} == "$aliases[$name]" ]]; then
      (( $+seen[$name] )) && (( ! $+fallback[$name] )) && continue
      unset "fallback[$name]"
    else
      (( $+seen[$name] )) && continue
      fallback[$name]=1
    fi
    seen[$name]=1
    value=${aliases[$name]//[$'\t\n'$CF_SEP]/ }
    entry[$name]="alias$CF_SEP$name$CF_SEP$desc$CF_SEP$value$CF_SEP$file$CF_SEP$line"
  done
  (( $#entry )) && print -rl -- "${(@v)entry}"
}
