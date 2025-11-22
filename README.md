# BM Font Module

This module provides a way to load and parse BM Font files.  Instead of writing to the PixelDisplay, this module returns a list of Sprites that can be used to render the text.

## Usage

```miniscript
font = Font.load("/usr/fonts/font.fnt")
sprites = font.getSprites("Hello World", 100, 100)
display(4).sprites += sprites
```

## Fonts

### Berry Rotunda

https://www.dafont.com/berry-rotunda.font