# command-finder/lib/format.zsh

# score \t name \t desc \t type \t usage
cf::format_row() {
  printf "%s\t%s\t%s\t%s\t%s\n" "$1" "$2" "$3" "$4" "$5"
}