# dotfiles

## Usage

```shell
#!/bin/bash

git clone https://github.com/rlj1202/dotfiles
cd dotfiles
git --work-tree=$HOME add .whatever-i-want
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
