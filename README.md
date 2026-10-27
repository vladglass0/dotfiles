<div align="center">

<picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/hero-dark.svg"><img src=".github/assets/hero-light.svg" width="100%" alt="dotfiles — CachyOS · Hyprland · Caelestia · fish"></picture>

<picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/packages-dark.svg"><img src=".github/assets/packages-light.svg" width="100%" alt="Packages"></picture>

<picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/wave-dark.svg"><img src=".github/assets/wave-light.svg" width="100%" alt=""></picture>

</div>

## ⚡ Установка

```sh
sudo pacman -S stow git
git clone https://github.com/vladglass0/dotfiles ~/dotfiles
cd ~/dotfiles
stow */            # все пакеты
stow fish git zsh  # или только нужные
```

> [!TIP]
> `stow -nv <пакет>` делает dry-run: показывает, что будет слинковано и где есть конфликты.

## 🛠 Как это работает

Каждая папка — отдельный пакет, внутри которого повторяется структура `$HOME`:

```
dotfiles/fish/.config/fish  →  ~/.config/fish
dotfiles/zsh/.zshrc         →  ~/.zshrc
```

## ➕ Добавить / ➖ убрать

```sh
mkdir -p ~/dotfiles/<имя>/.config
mv ~/.config/<имя> ~/dotfiles/<имя>/.config/
cd ~/dotfiles && stow <имя>

stow -D <имя>      # удалит только симлинки, файлы останутся в репо
```

## 🙈 Не попадает в git

`fish_variables` · `*.bak*` · `micro/backups` · `micro/buffers`

<div align="center">

<picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/wave-dark.svg"><img src=".github/assets/wave-light.svg" width="100%" alt=""></picture>

</div>
