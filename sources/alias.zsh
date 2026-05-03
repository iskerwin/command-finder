# command-finder/sources/alias.zsh

cf::source_alias() {
  local -A alias_desc
  # 收集你自己文件里定义的 alias 名（白名单）
  local -A my_alias_names

  local alias_dir="$HOME/.config/shell"
  if [[ -d "$alias_dir" ]]; then
    for f in "$alias_dir"/**/*.zsh(N) "$alias_dir"/*.zsh(N); do
      [[ -f "$f" ]] || continue
      awk '
      /^alias[[:space:]]+[a-zA-Z0-9_=.:-]+=/ {
        name = $0
        sub(/^alias[[:space:]]+/, "", name)
        sub(/=.*/, "", name)

        line = $0
        desc = ""
        in_single = 0; in_double = 0
        n = split(line, chars, "")
        for (i = 1; i <= n; i++) {
          c = chars[i]
          if (c == "\x27" && !in_double) in_single = !in_single
          else if (c == "\"" && !in_single) in_double = !in_double
          else if (c == "#" && !in_single && !in_double) {
            desc = substr(line, i + 1)
            sub(/^[[:space:]]+/, "", desc)
            sub(/[[:space:]]+$/, "", desc)
            break
          }
        }
        printf "%s\t%s\n", name, desc
      }
      ' "$f"
    done | while IFS=$'\t' read -r name desc; do
      alias_desc[$name]="$desc"
      my_alias_names[$name]=1   # ← 记录白名单
    done
  fi

  local name value
  for name value in ${(kv)aliases}; do
    [[ -n "${my_alias_names[$name]}" ]] || continue   # ← 不在白名单就跳过
    value=${value//$'\n'/ }
    local adesc="${alias_desc[$name]:-}"
    cf::format_row 2000 "$name" "$value" "alias" "$adesc"
  done
}