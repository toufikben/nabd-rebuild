#!/usr/bin/env python3
"""Fetches the OFL variable fonts used for the reading styles and cuts the
static weights the app bundles (Flutter does not drive the wght axis from
FontWeight). Re-run only to refresh the fonts.

    python3 scripts/make_fonts.py
"""
import io
import os
import urllib.request

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

BASE = 'https://raw.githubusercontent.com/google/fonts/main/ofl'
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts')
FONTS = {
    'Nunito': ('nunito/Nunito%5Bwght%5D.ttf', 'nunito/OFL.txt'),
    'Lora': ('lora/Lora%5Bwght%5D.ttf', 'lora/OFL.txt'),
}
WEIGHTS = {400: 'Regular', 600: 'SemiBold', 700: 'Bold'}


def fetch(path):
    with urllib.request.urlopen(f'{BASE}/{path}') as response:
        return response.read()


for family, (font_path, licence_path) in FONTS.items():
    data = fetch(font_path)
    for weight, style in WEIGHTS.items():
        font = TTFont(io.BytesIO(data))
        static = instantiateVariableFont(font, {'wght': weight}, updateFontNames=True)
        static.save(os.path.join(OUT, f'{family}-{style}.ttf'))
    with open(os.path.join(OUT, f'OFL-{family}.txt'), 'wb') as f:
        f.write(fetch(licence_path))
    print(family, 'done')
