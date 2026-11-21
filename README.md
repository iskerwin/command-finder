# command-finder

A zsh plugin that turns your own aliases, functions and documented commands into a searchable fzf picker. Press `Ctrl-G`, type a few letters, and insert, run or copy the command.

- **Aliases** defined in your config files, with their trailing comment as the description
- **Functions** with a `# @desc:` / `# @usage:` comment above them
- **Catalog lines**: comment lines such as `# git log --oneline -20   # Show the last 20 commits`, for subcommands and common invocations
- **History**: what you pick is remembered and ranked by frecency

## Requirements

- zsh 5.8+
- [fzf](https://github.com/junegunn/fzf) 0.61+
- Optional: [bat](https://github.com/sharkdp/bat) for highlighted previews, a [Nerd Font](https://www.nerdfonts.com/) for the type icons

## Install

**Homebrew**

```sh
brew install iskerwin/tap/command-finder
echo 'source "$(brew --prefix)/share/command-finder/command-finder.plugin.zsh"' >> ~/.zshrc
```

**[zap](https://github.com/zap-zsh/zap)**

```zsh
plug "iskerwin/command-finder"
```

**Manual**

```sh
git clone https://github.com/iskerwin/command-finder ~/.local/share/command-finder
echo 'source ~/.local/share/command-finder/command-finder.plugin.zsh' >> ~/.zshrc
```

Any plugin manager that sources `*.plugin.zsh` (antidote, zinit, sheldon, Oh My Zsh custom plugins) works the same way.

## Usage

| Key | Action |
|---|---|
| `Ctrl-G` | Open the picker (also `command_finder`; many people add `alias af=command_finder`) |
| `Enter` | Insert into the command line |
| `Ctrl-X` | Run it |
| `Ctrl-E` | Insert an alias's expansion instead of its name |
| `Ctrl-Y` | Copy (an alias copies its expansion) |
| `Ctrl-S` | Cycle the views: All → Aliases → Functions → Commands |
| `Ctrl-R` | Toggle the History view |
| `Ctrl-O` | Open the definition in `$VISUAL` / `$EDITOR` |
| `Ctrl-/` | Toggle the preview |

The All view is grouped alias → function → command and sorted by name within each group. The History view is sorted by frecency.

`cf::group <prefix> [keywords...]` opens the picker with only the `<prefix>-*` commands, which makes an easy entry point for a family of functions:

```zsh
# @desc: Network tools
# @usage: net [keywords...]
net() { cf::group net "$@"; }
```

## Writing entries

```zsh
alias gl='git log --oneline -20'          # Show the last 20 commits

# @desc: Create a directory and cd into it
# @usage: mkcd <dir>
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# docker compose logs -f <service>         # Follow a service's logs
```

Functions starting with `_` or containing `::` are treated as internal and never listed. Catalog lines need at least two spaces before the second `#`; the inserted text stops at the first ` <` or ` [` placeholder.

## Configuration

Set these before sourcing the plugin.

| Variable | Default | Meaning |
|---|---|---|
| `CF_PATHS` | `~/.zshrc` `~/.config/zsh` | Files and directories to scan (directories: every `*.zsh` below them) |
| `CF_FUNCTION_ALL` | empty | awk regex of file paths whose public functions are listed even without `@desc` |
| `CF_BINDKEY` | `^G` | Key that opens the picker; empty binds nothing |
| `CF_HISTORY_MAX` | `1000` | Selections kept in `${XDG_STATE_HOME:-~/.local/state}/command-finder/history` |
| `CF_HISTORY_ONLY_MAX` | `50` | History entries shown that match no alias, function or catalog line |
| `CF_FZF_OPTS` | built in | fzf look and keys |

If your shell defines `_ui_err`, `_ui_warn`, `_ui_fzf_opts`, `_ui_fzf_label`, `_ui_fzf_tabs` or `_ui_fzf_keys`, command-finder uses them instead of its built-in versions, so it can match your other pickers. Copying uses `clip-copy` when available, then `pbcopy`, `wl-copy`, `xclip`, `xsel`, and finally OSC 52.

## Development

```sh
zsh -f tests.zsh
```

## License

[MIT](LICENSE)
