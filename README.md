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
```

## .oh-my-zsh

```shell
#!/bin/bash

cd $ZSH_CUSTOM/plugins

git clone https://github.com/zsh-users/zsh-autosuggestions.git
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

cd $ZSH_CUSTOM/themes

# Theme from https://github.com/agnoster/agnoster-zsh-theme
ln -s ~/dev/dotfiles/.oh-my-zsh/custom/agnoster.zsh-theme agnoster.zsh-theme
```

