<div align="center">

# ✦ dotfiles

**CachyOS · Hyprland · Caelestia · fish**

Конфиги, разложенные по пакетам [GNU Stow](https://www.gnu.org/software/stow/)

</div>

---

## 📦 Пакеты

| | Пакет | Что внутри |
|---|---|---|
| 🪟 | `hypr` | Hyprland (Lua-конфиг) |
| 🌙 | `caelestia` | Caelestia shell + CLI |
| 🧩 | `quickshell` | Quickshell |
| 🔍 | `fuzzel` | лаунчер |
| 💻 | `foot` · `kitty` · `alacritty` | терминалы |
| 🐟 | `fish` | основной шелл |
| 🚀 | `starship` | промпт |
| 🐚 | `zsh` · `bash` | запасные шеллы |
| 🌿 | `git` | `.gitconfig`, глобальный ignore |
| 📊 | `btop` · `fastfetch` · `cava` | мониторинг и красота |
| ✏️ | `micro` | редактор |

## ⚡ Установка

```sh
sudo pacman -S stow git
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
stow */            # все пакеты
stow fish git zsh  # или только нужные
```

> [!TIP]
> Сначала запусти `stow -nv <пакет>`. Это dry-run: он покажет, что будет слинковано и где есть конфликты.

## 🛠 Как это работает

Каждая папка — отдельный пакет, внутри которого повторяется структура `$HOME`:

```
dotfiles/fish/.config/fish  →  ~/.config/fish
dotfiles/zsh/.zshrc         →  ~/.zshrc
```

## ➕ Добавить новый конфиг

```sh
mkdir -p ~/dotfiles/<имя>/.config
mv ~/.config/<имя> ~/dotfiles/<имя>/.config/
cd ~/dotfiles && stow <имя>
```

## ➖ Убрать пакет

```sh
stow -D <имя>      # удалит только симлинки, файлы останутся в репо
```

## 🙈 Не попадает в git

- `fish_variables` — состояние конкретной машины
- `*.bak*` — бэкапы
- `micro/backups`, `micro/buffers` — кэш редактора
