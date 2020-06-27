
# mac brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# vscode
brew cask install visual-studio-code

# hyper
brew cask install hyper

# iTerm2
brew cask install iterm2


# Create a `.zsh` directory to store our plugins in one place
mkdir ~/.zsh

# Clone repo to `~/.zsh/` directory
cd ~/.zsh && git clone git@github.com:zdharma/fast-syntax-highlighting.git

# Enable 'fast-syntax-highlighting' plugin in ZSH
source $HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Download completion config
cd ~/.zsh && wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/lib/completion.zsh

# Enable 'completion' plugin in ZSH
source $HOME/.zsh/completion.zsh

# Initialize the completion system
autoload -Uz compinit

# Cache completion if nothing changed - faster startup time
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi

# Enhanced form of menu completion called `menu selection'
zmodload -i zsh/complist

# Download 'zsh-autosuggestions' plugin
cd ~/.zsh && git clone git@github.com:zsh-users/zsh-autosuggestions.git

# Enable 'zsh-autosuggestions' plugin in ZSH
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Download history config
cd ~/.zsh && wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/lib/history.zsh

# Enable 'history' config in ZSH
source $HOME/.zsh/history.zsh

