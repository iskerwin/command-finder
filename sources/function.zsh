# command-finder/sources/function.zsh

# Describe a function with "# @desc: ..." and "# @usage: ..." comments right above it
# Only functions with @desc are listed, except in files whose path matches the awk regex
# CF_FUNCTION_ALL (empty by default), where every public function is listed.
# Internal functions (starting with _ or containing ::) are always skipped
# Output: function \x1f name \x1f description \x1f usage \x1f file \x1f line
cf::source_function() {
  local -a files=( ${(f)"$(cf::files)"} )
  (( $#files )) || return 0

  $CF_AWK -v sep=$CF_SEP -v all="${CF_FUNCTION_ALL-}" '
  function emit(name) {
    if (name !~ /^_/ && name !~ /::/ && (desc != "" || (all != "" && FILENAME ~ all)))
      printf "function%s%s%s%s%s%s%s%s%s%d\n", sep, name, sep, desc, sep, usage, sep, FILENAME, sep, FNR
    desc = ""; usage = ""
  }

  FNR == 1 { desc = ""; usage = "" }

  /^[[:space:]]*#[[:space:]]*@desc:/ {
    sub(/^[[:space:]]*#[[:space:]]*@desc:[[:space:]]*/, "")
    desc = $0
    next
  }

  /^[[:space:]]*#[[:space:]]*@usage:/ {
    sub(/^[[:space:]]*#[[:space:]]*@usage:[[:space:]]*/, "")
    usage = $0
    next
  }

  /^[[:space:]]*#/ { next }

  /^[a-zA-Z0-9_:-]+[[:space:]]*\(\)/ {
    name = $0
    sub(/[[:space:]]*\(.*/, "", name)
    emit(name)
    next
  }

  /^function[[:space:]]+[a-zA-Z0-9_:-]+/ {
    name = $0
    sub(/^function[[:space:]]+/, "", name)
    sub(/[[:space:]]*[({].*/, "", name)
    sub(/[[:space:]].*/, "", name)
    emit(name)
    next
  }

  /^[^#]/ { desc = ""; usage = "" }
  ' "${files[@]}"
}
