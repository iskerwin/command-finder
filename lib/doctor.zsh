# command-finder/lib/doctor.zsh — cf-doctor: what command-finder needs, what it found, and how to fix the rest.
# Loaded before the fzf check, so it also works when fzf is missing or too old.

# cf::install_hint <package>: install command for this system → $REPLY
cf::install_hint() {
  if (( $+commands[brew] )); then REPLY="brew install $1"
  elif (( $+commands[apt-get] )); then REPLY="sudo apt install $1"
  elif (( $+commands[dnf] )); then REPLY="sudo dnf install $1"
  else REPLY="install $1 with your package manager"
  fi
}

# cf::bat: the bat command (Debian and Ubuntu name it batcat) → $REPLY, false without one
cf::bat() {
  if (( $+commands[bat] )); then REPLY=bat
  elif (( $+commands[batcat] )); then REPLY=batcat
  else REPLY=''; return 1
  fi
}

# @desc: Check what command-finder needs and what it found, and how to fix the rest
# @usage: cf-doctor
cf-doctor() {
  emulate -L zsh
  if [[ ${1-} == (-h|--help) ]]; then
    _ui_usage cf-doctor
    print -r -- '  Check fzf, the optional tools, CF_PATHS, the key binding and the history file.'
    return 0
  fi
  local -i bad=0 n
  local g=${_ui[gry]} r=${_ui[r]} v ed p
  local -a zfiles
  _ui_head cf-doctor 'command-finder'

  _ui_sect required
  if is-at-least 5.8 2>/dev/null || { autoload -Uz is-at-least && is-at-least 5.8; }; then
    _ui_ok "zsh $ZSH_VERSION"
  else
    _ui_warn "zsh $ZSH_VERSION  ${g}needs 5.8+${r}"; (( ++bad ))
  fi
  if (( ! $+commands[fzf] )); then
    cf::install_hint fzf
    _ui_warn "fzf  ${g}the picker${r}  → $REPLY"; (( ++bad ))
  elif ! _ui_fzf_since 0.58; then
    _ui_fzf_ver; v=$(( REPLY / 1000000 )).$(( REPLY / 1000 % 1000 )).$(( REPLY % 1000 ))
    _ui_warn "fzf $v  ${g}needs 0.58+${r}  → ${${commands[brew]:+brew upgrade fzf}:-github.com/junegunn/fzf/releases}"; (( ++bad ))
  else
    _ui_fzf_ver
    _ui_ok "fzf $(( REPLY / 1000000 )).$(( REPLY / 1000 % 1000 )).$(( REPLY % 1000 ))"
  fi

  _ui_sect optional 'the picker works without them'
  if cf::bat; then
    _ui_ok "$REPLY  ${g}highlighted previews${r}"
  else
    cf::install_hint bat
    _ui_warn "bat  ${g}highlighted previews (plain text without it)${r}  → $REPLY"
  fi
  for p in clip-copy pbcopy wl-copy xclip xsel; do
    (( $+commands[$p] )) || continue
    [[ $p == wl-copy && -z ${WAYLAND_DISPLAY-} ]] && continue
    [[ $p == (xclip|xsel) && -z ${DISPLAY-} ]] && continue
    v=$p; break
  done
  if [[ -n $v ]]; then _ui_ok "$v  ${g}^Y copy${r}"
  else _ui_ok "OSC 52  ${g}^Y copy through the terminal (some terminals need it enabled)${r}"; fi
  ed=${VISUAL:-${EDITOR-}}
  if [[ -z $ed ]]; then
    for p in zed code cursor vi; do (( $+commands[$p] )) && { ed=$p; break; }; done
  fi
  if [[ -n $ed ]] && (( $+commands[${ed%% *}] )); then
    _ui_ok "${ed%% *}  ${g}^O open the definition${r}"
  else
    _ui_warn "editor  ${g}^O open the definition${r}  → set VISUAL or EDITOR${ed:+ (${ed%% *} not found)}"
  fi

  _ui_sect sources 'CF_PATHS'
  for p in $CF_PATHS; do
    if [[ -f $p ]]; then
      _ui_ok "${p/#$HOME/~}"
    elif [[ -d $p ]]; then
      zfiles=( $p/**/*.zsh(N.) ); n=${#zfiles}
      if (( n )); then _ui_ok "${p/#$HOME/~}/  ${g}$n *.zsh${r}"
      else _ui_warn "${p/#$HOME/~}/  ${g}no *.zsh files${r}"; fi
    else
      _ui_warn "${p/#$HOME/~}  ${g}does not exist${r}"
    fi
  done
  (( ${#CF_PATHS} )) || { _ui_warn "CF_PATHS is empty: nothing to list"; (( ++bad )); }
  if (( $+functions[cf::collect] )); then
    local -A count
    local t
    for t in ${(f)"$(cf::collect 2>/dev/null | cut -f4)"}; do (( ++count[$t] )); done
    _ui_hint "found ${count[alias]:-0} aliases, ${count[function]:-0} functions, ${count[command]:-0} catalog lines, ${count[history]:-0} history-only entries"
  fi

  _ui_sect key
  if [[ -z ${CF_BINDKEY-^G} ]]; then
    _ui_hint "no key bound (CF_BINDKEY=''); run command_finder"
  elif (( ! $+widgets[command_finder] )); then
    _ui_warn "${CF_BINDKEY-^G}  ${g}not bound: the plugin stopped before binding (see required)${r}"
  else
    v=${${(z)"$(bindkey -- "${CF_BINDKEY-^G}" 2>/dev/null)"}[2]}
    if [[ $v == command_finder ]]; then
      _ui_ok "${CF_BINDKEY-^G}  ${g}opens the picker${r}"
    else
      _ui_warn "${CF_BINDKEY-^G}  ${g}is bound to ${v:-nothing}${r}  → load command-finder after what rebinds it, or after bindkey -v / -e"
    fi
  fi

  _ui_sect history
  p=$(cf::history_file)
  if [[ -f $p ]]; then
    _ui_ok "${p/#$HOME/~}  ${g}${#${(f)"$(<$p)"}} selections${r}"
  elif [[ -w ${p:h} || ( ! -e ${p:h} && -w ${p:h:h} ) || ! -e ${p:h:h} ]]; then
    _ui_hint "${p/#$HOME/~}  created on the first selection"
  else
    _ui_warn "${p/#$HOME/~}  ${g}directory not writable: selections are not remembered${r}"
  fi

  _ui_sect look
  if (( $+functions[_ui_palette] )) && [[ ${functions_source[_ui_palette]:t} != ui-fallback.zsh ]]; then
    _ui_ok "zsh-ui  ${g}shared look with your other tools${r}"
  else
    _ui_hint "zsh-ui not loaded — plain built-in look; github.com/iskerwin/zsh-ui for the shared one"
  fi
  (( bad == 0 ))
}
(( $+functions[compdef] )) && compdef "_arguments '(- *)'{-h,--help}'[show help]'" cf-doctor
