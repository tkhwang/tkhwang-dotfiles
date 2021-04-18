# tkhwang-dotfiles

## Homebrew

## VIM

#### vim-plug

```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
 https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

My own personal configurations...

## Basic setting

- 기본 설정 아래 글 참조 : [본격 macOS 에 개발 환경 구축하기](https://subicura.com/2017/11/22/mac-os-development-environment-setup.html)
  - zsh : oh-my-zsh
  - iTerm configuration
  - Color theme : Snazzy
    [mbadolato/iTerm2-Color-Schemes: Over 175 terminal color schemes/themes for iTerm/iTerm2)](https://github.com/mbadolato/iTerm2-Color-Schemes)

## Font

- [ryanoasis/nerd-fonts: Iconic font aggregator, collection, and patcher.](https://github.com/ryanoasis/nerd-fonts)
- [artofrawr/powerline-fonts: Nerd fonts that I use for my shell & editor.](https://github.com/artofrawr/powerline-fonts)

## prompt

[denysdovhan/spaceship-prompt: A Zsh prompt for Astronauts](https://github.com/denysdovhan/spaceship-prompt)

## vim

[liuchengxu/space-vim: Lean & mean spacemacs-ish Vim distribution](https://github.com/liuchengxu/space-vim)

## tmux

Install TPM

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Copy `.tmux.conf` to `~`

```bash
cp .tmux.conf ~
```

## Utility

- autojump : [wting/autojump: A cd command that learns - easily navigate directories from the command line](https://github.com/wting/autojump)

## MacOS

### Application

- [Alfred - Productivity App for Mac OS X](https://www.alfredapp.com/)
- [‎Mac App Store 에서 제공하는 PopClip](https://itunes.apple.com/kr/app/popclip/id445189367?mt=12)
- [‎Amphetamine](https://itunes.apple.com/us/app/amphetamine/id937984704?mt=12)
- VPN : [Windscribe](https://kor.windscribe.com/)
- [Karabiner - Software for macOS](https://pqrs.org/osx/karabiner/) : Keyboard remap
  - `delete_forward` => `grave_accent_and_tilde`
  - `grave_accent_and_tilde` => `escape`

#### Window arrangement

- [Spectacle](https://www.spectacleapp.com/)
- [Magnet – Window manager for Mac](http://magnet.crowdcafe.com/)

#### Coding

- [Dashboard · WakaTime](https://wakatime.com/dashboard)
- [jontelang/WakaLet: Wakatime.com OSX menulet (menubar application)](https://github.com/jontelang/WakaLet)

#### WIFI

- [스타웍스 - 스타벅스 WiFi 연결러](http://xn--9t4ba803ac1m.com/)
- [Network traffic analyzer & SSL/TLS decryption for iPhone, iPad, Android, PC on macOS](https://debookee.com/)

#### Wallpaper

- [‎Irvue](https://itunes.apple.com/kr/app/irvue/id1039633667?mt=12)
- [‎Unsplash Wallpapers](https://itunes.apple.com/kr/app/unsplash-wallpapers/id1284863847?mt=12)

## Windows

#### Caps lock 키를 Windows key 로 remap

[Windows: Map CAPS LOCK to Windows Key | mattshaw.org](http://mattshaw.org/news/window-map-caps-lock-to-windows-key/)

Save as caps.reg, then double click to import into Registry.

```
Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout]
"Scancode Map"=hex:00,00,00,00,00,00,00,00,02,00,00,00,5c,e0,3a,00,00,00,00,00
```

## Editor

### VSCode

### Sublime text
