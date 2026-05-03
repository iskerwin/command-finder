## Command Finder

Stop memorizing commands. Just search.
An interactive command palette for your shell — powered by fzf.
Search through:

* your command history
* your aliases
* your functions

…and insert or copy them instantly.

## ✨ Features

* 🔍 Fuzzy search everything
* ⚡ Instant insert into shell (Ctrl+F)
* 🧠 Smart ranking (based on usage frequency)
* 🧾 Alias expansion (Ctrl+E)
* 📋 Copy command (Ctrl+Y)
* 🎨 Beautiful UI (fzf + icons + preview)

## ⚙️ Installation

```bash
git clone https://github.com/iskerwin/command-finder ~/.command-finder
```
Add to your .zshrc:

```bash
source ~/.command-finder/command-finder.plugin.zsh
```

## ⌨️ Usage

```bash
af
```

Then:

* `ENTER` → insert command
* `Ctrl + E` → expand alias
* `Ctrl + Y` → copy command

## 🧩 How it works

* Collects commands from:
    * history file
    * your aliases (whitelisted)
    * your functions (with annotations)
* Scores them:
    * history → frequency-based
    * alias → static weight
    * function → static weight
* Pipes into fzf with preview + UI rendering

## 🧠 Function Annotations

You can document your functions like this:

```bash
# @desc: deploy to production
# @usage: deploy <env>
deploy() {
  ...
}
```

## 📂 Project Structure

```bash
command-finder/
├── core.zsh
├── lib/
├── sources/
│   ├── history.zsh
│   ├── alias.zsh
│   └── function.zsh
└── ui/
```

## 🚧 Roadmap

* Fish shell support
* Bash support
* Plugin system
* Remote command sync

## ⭐ Why this exists

Because nobody remembers commands.