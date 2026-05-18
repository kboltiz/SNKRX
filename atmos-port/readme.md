# Positioning and Anchoring

In SNKRX, the main menu displays three left-aligned buttons: *arena run*, *options*, and *quit*.

## Lua + LOVE2D

In the original implementation, each button is constructed with an explicit x-coordinate [(mainmenu.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/mainmenu.lua#L85):

```lua
self.arena_run_button = Button{x = 55, y = gh/2 - 10, button_text = 'arena run', ...}
self.options_button   = Button{x = 47, y = gh/2 + 12, button_text = 'options', ...}
self.quit_button      = Button{x = 37, y = gh/2 + 34, button_text = 'quit', ...}
```

The x-coordinates (55, 47, 37) decrease as the button text gets shorter. The programmer manually tuned each value to preserve left-alignment across buttons of different widths. The underlying Button class centers its text by setting it's alignment parameter to 'center' [(Button)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L596), but exposes no alignment option for the button's own position, leaving the caller responsible for compensating.

## Atmos + Pico

In Atmos, all three buttons share the same x-coordinate, using the anchor='W' (west) parameter to declare left-alignment explicitly [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/menu/atmos-port/menu.atm):

```lua
pico.output.draw.rect(@{ '%', x=0.01, y=0.5, w=0.18, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.6, w=0.15, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.7, w=0.13, h=0.08, anchor='W' })
```

The anchor point eliminates the need for manual x-offset tuning. Changing a button's width does not require updating its position.

## Analysis
The original Lua code uses the x-coordinate as an implicit alignment variable, encoding the button's visual intent as a "magic number". It also means tweaking the button's internal layout (like centering text) doesn't cascade into position fixes.
