# Positioning and Anchoring

In SNKRX, the main menu displays three left-aligned buttons: *arena run*, *options*, and *quit*.

## Lua + LOVE2D

In the original implementation, each button is constructed with an explicit x-coordinate [(mainmenu.lua)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/mainmenu.lua#L85):

```lua
self.arena_run_button = Button{x = 55, y = gh/2 - 10, button_text = 'arena run', ...}
self.options_button   = Button{x = 47, y = gh/2 + 12, button_text = 'options', ...}
self.quit_button      = Button{x = 37, y = gh/2 + 34, button_text = 'quit', ...}
```

The x-coordinates (55, 47, 37) decrease as the button text gets shorter. The programmer manually tuned each value to preserve left-alignment across buttons of different widths. The underlying Button class centers its text by setting it's alignment parameter to 'center' [(Button)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L596), but exposes no alignment option for the button's own position, leaving the caller responsible for compensating.

## Atmos + Pico

In Atmos, all three buttons share the same x-coordinate, using the anchor='W' (west) parameter to declare left-alignment explicitly [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/34abfe76fd6b3afbded3d1e8a4830bcdc2550265/atmos-port/menu.atm#L10):

```lua
pico.output.draw.rect(@{ '%', x=0.01, y=0.5, w=0.18, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.6, w=0.15, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.7, w=0.13, h=0.08, anchor='W' })
```

The anchor point eliminates the need for manual x-offset tuning. Changing a button's width does not require updating its position.

## Analysis
The original Lua code uses the x-coordinate as an implicit alignment variable, encoding the button's visual intent as a "magic number". It also means tweaking the button's internal layout (like centering text) doesn't cascade into position fixes.


---

# Button Encapsulation and Sizing

In SNKRX, each button sizes itself to fit its text content and is drawn to the screen each frame.

## Lua + LOVE2D

In the original implementation, button sizing is computed in `Button:init` [(buy_screen.lua)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L594):

```lua
self.shape = Rectangle(self.x, self.y,
    args.w or (pixul_font:get_text_width(self.button_text) + 8),
    pixul_font.h + 4)
```

The width is derived from the text width plus a fixed pixel padding (`+8`), and the height from the font height plus padding (`+4`). The button is then drawn directly to the screen each frame in `Button:draw` [(buy_screen.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L635):

```lua
function Button:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, ...)
    self.text:draw(self.x, self.y + 1, 0, 1, 1)
    graphics.pop()
end
```

The button background and text are drawn separately every frame. Positioning the text relative to the button requires manual offset calculations (`self.y + 1`). The button is a class with separate `init`, `update`, and `draw` methods — the programmer must navigate across all of them to understand the full behavior.

## Atmos + Pico

In Atmos, the button is a self-contained task. Sizing, drawing, and hover detection all live in one place [(menu.atm)](https://github.com/a327ex/SNKRX/blob/d1f1354f34ea0b944e9712989dbbb04dbf70f66c/atmos-port/menu.atm#L14):

```lua
func Button(x, y, h, anc, text) {
    val rect = @{"%", x=x, y=y, h=h, anchor=anc}
    pico.get.text(rect, text)
    pico.layer.empty(:world, text, false, rect)
    
    pico.zet.layer(text)
    pico.zet.effect @{ color=@{"%", r=0.2, g=0.2, b=0.2} }
    pico.output.clear()
    
    pico.zet.pencil @{ color='white' }
    pico.output.draw.text(text, @{ "%", x=0.5, y=0.5, h=1-PAD })
    pico.zet.layer(:world)
    ...
}
```

`pico.get.text` fills the rect's width based on the text content directly, removing the need for manual width calculation. The button is then rendered once into its own layer — inside the layer, the text is simply centered at `(0.5, 0.5)`, no manual offsets needed. The same `rect` is then drawn onto the world each frame:

```lua
every :draw { pico.output.draw.layer(text, rect) }
```

## Analysis

In the original Lua code, sizing and rendering are spread across `init` and `draw`, each only tells part of the story. In Atmos, the button is a single task: `pico.get.text` derives the size from text content, the button layer confines rendering to its own coordinate space where centering is simplified, and the same `rect` serves sizing, drawing, and collision detection for hovering.
