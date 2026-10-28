#!/usr/bin/env python3
"""Generates the hotkeys card (dark + light) from hypr/variables.lua. hero is hand-made, not touched."""
import re
from pathlib import Path
from xml.sax.saxutils import escape

ASSETS = Path(__file__).parent / "assets"
VARIABLES = ASSETS.parents[1] / "hypr/.config/hypr/variables.lua"
W, H = 840, 576
SANS = "'Google Sans Flex','Google Sans','Segoe UI',Roboto,sans-serif"
MONO = "'JetBrains Mono','Fira Code',monospace"

THEMES = {
    "dark": dict(bg="#2d2832", card="#38323d", text="#eadfed", muted="#cec2d4", chip="#563e5d", chip_text="#f8d8fe"),
    "light": dict(bg="#efe5f3", card="#eadfed", text="#1f1924", muted="#4c4452", chip="#f8d8fe", chip_text="#563e5d"),
}

STYLE = f"""<style>text{{font-family:{SANS}}}
.m{{font-family:{MONO}}}
.up{{animation:up .8s cubic-bezier(.05,.7,.1,1) both}}
@keyframes up{{from{{opacity:0;transform:translateY(14px)}}to{{opacity:1;transform:none}}}}
@media (prefers-reduced-motion:reduce){{*{{animation:none!important}}}}</style>"""

# label -> variable in hypr/variables.lua (+ key appended to modifier-only binds)
HOTKEYS = [
    ("Терминал", "kbTerminal"), ("Закрыть окно", "kbCloseWindow"),
    ("Лаунчер", "kbLauncher"), ("Полный экран", "kbWindowFullscreen"),
    ("Браузер", "kbBrowser"), ("Плавающее окно", "kbToggleWindowFloating"),
    ("Редактор", "kbEditor"), ("Рабочий стол", "kbGoToWs", "1-9"),
    ("Файлы", "kbFileExplorer"), ("Окно на стол", "kbMoveWinToWs", "1-9"),
    ("Блокировка", "kbLock"), ("Спец. стол", "kbSpecialWs"),
    ("Меню сессии", "kbSession"), ("Музыка", "kbMusicWs"),
    ("Пипетка", "kbColorPicker"), ("Переключить окно", "kbWindowCycleNext"),
    ("Скриншот", "kbScreenshotFreeze"), ("Запись экрана", "kbRecord"),
]
KEY_NAMES = {"DELETE": "DEL", "ESCAPE": "ESC", "BACKSLASH": "\\", "COMMA": ",", "MINUS": "-", "EQUAL": "="}


def combo(bind):
    out = []
    for k in bind.upper().split("+"):
        k = KEY_NAMES.get(k.strip(), k.strip())
        if k.startswith("SUPER"):  # "SUPER + SUPER_L" is the bare-SUPER launcher
            k = "SUPER"
        if k not in out:
            out.append(k)
    return " ".join(out)


def hotkey_rows():
    # first string of `kbName = "..."` or `kbName = { "...", ... }`
    binds = dict(re.findall(r'^\s*(kb\w+)\s*=\s*\{?\s*"([^"]+)"', VARIABLES.read_text(), re.M))
    rows = []
    for label, var, *suffix in HOTKEYS:
        if var not in binds:
            raise SystemExit(f"{var} not found in {VARIABLES}")
        rows.append((label, combo(binds[var] + "".join(" + " + s for s in suffix))))
    return rows


assert combo("SUPER + SUPER_L") == "SUPER" and combo("CTRL + ALT + Delete") == "CTRL ALT DEL"


def text(x, y, s, fill, size, weight=None, cls="", anchor=None):
    style = f"font-size:{size}px" + (f";font-weight:{weight}" if weight else "")
    attrs = (f' class="{cls}"' if cls else "") + (f' text-anchor="{anchor}"' if anchor else "")
    return f'<text x="{x}" y="{y}" fill="{fill}"{attrs} style="{style}">{escape(s)}</text>'


def keys(right, y, pressed, c):
    out, x = "", right
    for i, k in enumerate(reversed(pressed.split())):
        w = len(k) * 7.4 + 18
        x -= w
        out = f'<rect x="{x:.1f}" y="{y}" width="{w:.1f}" height="26" rx="8" fill="{c["chip"]}"/>' \
              + text(round(x + w / 2, 1), y + 17.5, k, c["chip_text"], 12, 600, "m", "middle") + out
        if i < len(pressed.split()) - 1:
            x -= 16
            out = text(round(x + 8, 1), y + 18, "+", c["muted"], 14, 600, anchor="middle") + out
    return out


def hotkeys(c):
    grid = ""
    for i, (label, pressed) in enumerate(hotkey_rows()):
        x, y = 44 + i % 2 * 382, 84 + i // 2 * 52
        grid += f'<rect x="{x}" y="{y}" width="370" height="44" rx="16" fill="{c["card"]}"/>' \
                + text(x + 20, y + 27, label, c["text"], 15, 600) + keys(x + 370 - 9, y + 9, pressed, c)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" ' \
           f'role="img" aria-label="Хоткеи"><title>Хоткеи</title>{STYLE}' \
           f'<rect width="{W}" height="{H}" rx="28" fill="{c["bg"]}"/>' \
           + text(44, 56, "Хоткеи", c["text"], 26, 700) \
           + text(796, 56, "hypr/variables.lua", c["muted"], 15, cls="m", anchor="end") \
           + f'<g class="up">{grid}</g></svg>'


if __name__ == "__main__":
    for theme, c in THEMES.items():
        (ASSETS / f"hotkeys-{theme}.svg").write_text(hotkeys(c))
        print(f"hotkeys-{theme}.svg")
