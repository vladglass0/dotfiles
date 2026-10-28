# AGENTS.md

Dotfiles для CachyOS · Hyprland · Caelestia · fish, раскладываются через GNU Stow.

## Структура

- Каждая папка верхнего уровня — stow-пакет, внутри повторяется структура `$HOME`:
  `fish/.config/fish` → `~/.config/fish`, `zsh/.zshrc` → `~/.zshrc`.
- Файлы в корне (`README.md`, `AGENTS.md`, `CLAUDE.md`, `.github/`) не stow-пакеты — `stow */` берёт только папки.
- `.github/assets/` — SVG для README (светлая и тёмная версии каждой картинки). `hero` сделан вручную,
  карточку хоткеев генерирует `.github/gen-svg.py` (хоткеи читает из `hypr/.config/hypr/variables.lua`).
  Руками SVG не правь: меняй скрипт. Action `readme-cards.yml` перегенерирует их при пуше и коммитит сам.

## Правила

- Редактируй файлы в репо, а не в `~/.config`: там симлинки на этот репо.
- Новый пакет: `<имя>/.config/<имя>/...`, затем `stow <имя>`. Проверка конфликтов: `stow -nv <имя>`.
- Hyprland настраивается на Lua (`hypr/.config/hypr/hyprland.lua` + модули в `hyprland/`), не на `hyprland.conf`.
- Caelestia перегенерирует цветовые файлы при смене обоев/схемы: `hypr/.config/hypr/scheme/current.lua`,
  `btop/.config/btop/themes/caelestia.theme`, цвета в `fuzzel.ini`, `cava/config` и т.п. Их изменения в `git status` — обычно шум, не правь их руками.
- Не коммить секреты, `fish_variables`, `*.bak*`, бэкапы micro и папку `git/` (в `.gitignore`).
- README пишется на русском, коммиты — коротко, на английском (`edit README.md`).
