# dotfiles

## Usage

```shell
#!/bin/bash

git clone --recursive https://github.com/rlj1202/dotfiles
```

### Using symlinks

```shell
#!/bin/bash

cd ~

rm .vimrc
ln -s ~/dev/dotfiles/.vimrc .vimrc

rm .zshrc
ln -s ~/dev/dotfiles/.zshrc .zshrc

rm .zshenv
ln -s ~/dev/dotfiles/.zshenv .zshenv
```

### Setup iCloud as remote

```shell
#!/usr/bin/env bash

ICLOUD_DIR='~/Library/Mobile Documents/com~apple~CloudDocs'

cd "$ICLOUD_DIR"
mkdir git
cd git
git init --bare dotfiles.git

git remote add icloud "$ICLOUD_DIR/git/dotfiles.git"
git push -u icloud main

# Wait for all items to be uploaded
# Execute this command before or/and after pushing to check the status
brctl monitor -w com.apple.CloudDocs > /dev/null
```

## What should/shouldn't go in `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin` and `.zlogout` [^1]

[^1]: https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout

1. `.zshenv`
  - Always sourced
  - Often contains exported variables that should be available to other programs
    - For example: `$PATH`, `$EDITOR`, `$PAGER`, `$ZDOTDIR`, etc
  - Suggestions:
    - Things which are needed by a command non-interactively
    - Things which should be updated on each new shell
2. `.zprofile`
  - For login shells
  - Basically the same as `.zlogin` except the order of execution
  - Suggestions:
    - Things which take some time to run a command
3. `.zshrc`
  - For interactive shells
  - Use `setopt` and `unsetopt` commands to set options for the interactive
    shells
  - Do whatever you need for interactive usage
    - Load shell modules
    - Set history options
    - Set prompt
    - Set command completion
    - Set command correction
    - Set command suggestion
    - Set command highlighting
    - Set command alias
    - Set key bindings
    - Set variables only available in the interactive shells (`$LS_COLORS`)
    - Some misc tools (auto cd or something similar)
    - etc
  - Suggestions:
    - Things which are related to interactive usage
4. `.zlogin`
  - For login shells
  - Often used to start X using `startx`
  - Some systems start X on boot so this file is not always very useful
  - Suggestions:
    - Things which are need to run when shell is fully setup
5. `.zlogout`
  - Sometimes used to clear and reset the terminal
  - Suggestions:
    - Things which are some resources acquired at login and need to be released
