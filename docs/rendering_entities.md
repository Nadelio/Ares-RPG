# Rendering Entities

> [!NOTE]
> This guide assumes you have read [Your First Prefab](./first_prefab.md) and understand how components and prefabs work. If you haven't, head there first.

---

## `core.components.renderable`

Any entity or object that has both a `position` and a `renderable` component will be drawn by the renderer, the `Renderable` component houses all the information needed to draw the entity, including the character (glyph), colors (fg/bg), and style (italics/bold/underline).

Require it from `core.components.renderable`:

```lua
local Renderable = require("core.components.renderable")
```

Create an instance with `Renderable.new(data)`:

```lua
renderable = Renderable.new({
    glyph     = "@",
    fg        = Colors.green,
    bg        = Colors.black,
    italics   = false,
    bold      = false,
    underline = false,
    sprite = {
        x = 0, y = 0,
        resolution = 16,
        atlas_path = "assets/atlas_16px.png",
        rotation = 0
    }
})
```

Quick reference:

Field | Type | Default | Description
---|---|---|---
`glyph` | string | `"?"` | The character drawn on screen, any single printable character or UTF symbol works
`fg` | `{r,g,b}` | `Colors.reset` | Foreground (text) color
`bg` | `{r,g,b}` or `nil` | `Colors.black` | Background color, set to `nil` to draw no background rectangle at all
`italics` | boolean | `false` | Renders the glyph in italics
`bold` | boolean | `false` | Renders the glyph bold
`underline` | boolean | `false` | Renders the glyph underlined
`sprite.x` | int | `0` | The x-coordinate for the sprite in the atlas image
`sprite.y` | int | `0` | The y-coordinate for the sprite in the atlas image
`resolution` | int | `16` | The size of the sprite
`atlas_path` | string | `assets/atlas_16px.png` | The path to the image used for the sprite's source atlas
`rotation` | int | `0` | Clockwise rotation of the sprite in degrees, snapped to 90 degree steps (`0`, `90`, `180`, `270`)

---

## Renderable sprites

Sprite fields are optional and default individually:

```lua
local Renderable = Registry.resolve("components", "renderable")
local player = Renderable.new({
    glyph = "@",
    sprite = { x = 1, y = 0 }
})
```

`sprite.x` and `sprite.y` are zero-based atlas cell indices, not pixel offsets.
Omitted fields default to `x = 0`, `y = 0`, `resolution = 16`, `rotation = 0`, and
`atlas_path = "assets/textures/atlas_16px.png"`. The resolution describes the
source cell size, `G_settings.sprite_resolution` controls its displayed size.
For example, a 16px sprite is scaled to 32x32 when the display resolution is 32.
The same sprite fields may also be supplied at the top level when `sprite` is
omitted.

`rotation` turns the sprite clockwise around its center. Only quarter turns are
supported: any other value is snapped to the nearest 90 degree step and wrapped
into the `0`-`270` range (so `-90` becomes `270` and `360` becomes `0`). This lets
one atlas cell serve several orientations, e.g. a single wall sprite covers both
vertical and horizontal walls.

---

## Tile sprites

The functions in `core/render/tile_styles.lua` now return renderable definitions
instead of just glyph strings. `TileStyles.W` selects an entry from `wall_styles`
using the existing neighboring-wall logic. Each wall shape, including hidden
walls (`" "`), has its own editable definition:

```lua
["│"] = Renderable.new({
    glyph = "│",
    sprite = {
        x = 0, y = 0,
        resolution = 16,
        atlas_path = "assets/textures/atlas_16px.png"
    }
}),
```

Edit `floor_style` for floor tiles (`X`) and `corridor_style` for corridors (`C`).
Wall shapes reuse one base wall sprite rotated in 90 degree steps: `─` is `│`
turned once, corners turn clockwise from `╭`, and intersections from `├`. Point
the base cells at your artwork (or give any shape its own cell) and the rotations
follow automatically. Sprite defaults and scaling work exactly as
they do for entities. Text mode still draws the selected glyph.

Custom tile-style functions may return `Renderable.new({...})` to supply a glyph,
colors, text styling, and a sprite. Existing functions returning only a glyph
string remain supported and use the default sprite in sprite mode.

---

## Colors

The built-in named colors live in `core.render.colors`:

```lua
local Colors = require("core.render.colors")
```

Name | Hex code | RGB float values 
---|---|---
`Colors.red` | `#FF4D4D` | `{1.0,0.3,0.3}`
`Colors.orange` | `#FFB14D` | `{1.0,0.7,0.3}`
`Colors.yellow` | `#FFFF4D` | `{1.0,1.0,0.3}`
`Colors.green` | `#4DFF4D` | `{0.3,1.0,0.3}`
`Colors.blue` | `#6699FF` | `{0.4,0.6,1.0}`
`Colors.gray` | `#4D4D4D` | `{0.7,0.7,0.7}`
`Colors.black` | `#000000` | `{0.0,0.0,0.0}`
`Colors.reset` | `#FFFFFF` | `{1.0,1.0,1.0}`
`Colors.cursor` | `#59A6FF` | `{0.35,0.65,1.0}`

Colors are plain Lua tables with three values in the `{r, g, b}` format where each channel is a number between `0` and `1`. You can define your own anywhere in your mod, no registration needed:

```lua
local my_colors = {
    toxic  = { 0.4, 1.0, 0.2 },
    ash    = { 0.5, 0.5, 0.45 },
    void   = { 0.15, 0.0, 0.3 },
}
```

Pass them directly to `Renderable.new` the same way you would a named color from `core.render.colors`.

> [!NOTE]
> You can also override the default colors by simply using this init function template in your `mod.lua`:
> ```lua
> init = function()
>   local Colors = require("core.render.colors")
>   Colors.red = {1.0, 0.0, 0.0} -- simply access each built-in color field and override their values
>   Colors.peach = {1.0, 0.67, 0.46} -- you can even add new colors this way
> end
> ```

---

## Draw Order

Each frame the renderer visits every tile and picks exactly one thing to draw per tile according to this priority:

1. Entities - anything in the world (`world:add(...)`) that has both `position` and `renderable` components.
2. Objects - anything on the map (`map:add_object(...)`) that has both `position` and `renderable` components.
3. Tiles - the base map grid, drawn using the tile's `TileStyle` function.

If two entities share a tile, the last one inserted into the world wins, if two objects share a tile, the one on top of the stack wins.

> [!NOTE]
> Entities always draw on top of objects, if you want an object to be visible, make sure no entity occupies the same tile by setting the `collides` field to `true` in the object.

### Sprite mode layering

In sprite rendering mode (`G_settings.sprite_rendering = true`) the map tile is
always drawn first, then the entity, object, or movement-preview ghost sprite is
drawn on top of it. Transparent pixels in an entity or object sprite therefore
show the map underneath. Because of this, the `bg` color of an entity or object
is ignored in sprite mode, the tile's own `bg` is drawn instead. Text mode is
unaffected and still draws exactly one glyph per tile.

### UI panels in sprite mode

The UI renderer also has a sprite mode, drawn in two layers:

1. **Background layer** - every widget whose lines contain box-drawing border
   characters (`─ │ ╭ ╮ ╰ ╯ ├ ┤ ┬ ┴ ┼ ╶ ╴`) gets a sprite panel: a grid of
   corner, edge, and (optionally) fill sprites covering the widget's area. A
   separate title strip covers the top border behind the title text. The
   widget's `background` color, if any, is drawn underneath the panel.
2. **Foreground layer** - the widget text is drawn on top. Border characters
   are skipped (the panel replaced them), titles, labels, and values stay text.

Panel cells are drawn at the **game cell size** (`G_settings.sprite_resolution`),
not at the font's glyph size, so UI artwork and map artwork always share the same
pixel scale. The panel grid is anchored at the widget's top-left corner and
rounded up to whole cells, so it covers at least the widget's text area.

`UIRenderer.build(context, settings)` uses the same sprite-panel geometry as
drawing, including title caps, content padding, and cell rounding. Column
alignment, stacking, and centered dialogs therefore use the rendered bounds.
Widget definitions with `column = "right"` reserve their measured width in
the right-hand column before positioning runs. Pass the same settings to
`build` and `draw`. Omitted build settings use `context.settings` or `G_settings`.

The panel pieces live in `UIRenderer.panel_sprites` (`core.render.ui_renderer`):

Key | Default | Description
---|---|---
`corner` | UI atlas cell `(1, 1)` | The top-left corner, the other three corners reuse it rotated clockwise in 90 degree steps
`edge` | UI atlas cell `(0, 1)` | The left edge, the other edges reuse it rotated clockwise. Single-row or single-column panels are drawn entirely from edges
`fill` | UI atlas cell `(1, 0)` | Tiles the panel interior, leave `nil` to let the widget's `background` color show through instead
`title_edge` | UI atlas cell `(2, 0)` | The left title cap; the right cap reuses it rotated 180 degrees. Caps occupy the cells immediately outside the title fill
`title_fill` | UI atlas cell `(2, 1)` | Tiles behind the title text and its surrounding spaces, replacing the ordinary top edge beneath the lettering

The defaults use `assets/textures/atlas_ui_16px.png`. Titles are detected as
nonblank text between border glyphs in the first line, including single-row
panels. In sprite mode, the title text and its fill shift right as needed to
reserve a full cell inside the panel for the left cap. The panel width grows
if needed to also fit the right cap. Content rows keep their original positions.
Every panel cell overlapping the measured title text (including its
padding) uses the title fill instead of the ordinary border, so transparent
title artwork cannot expose an edge sprite beneath the lettering. The strip
extends down to cover the font height if it exceeds one game cell.
Setting either title piece to `nil` leaves the widget's background showing
through that part of the strip. Text rendering mode is unchanged.

Mods can retarget or replace any piece:

```lua
local UIRenderer = require("core.render.ui_renderer")

UIRenderer.panel_sprites.corner = {
    x = 2, y = 0,
    atlas_path = "assets/textures/my_atlas.png",
    resolution = 16,
    rotation = 0
}
```

The set of characters treated as borders is `UIRenderer.border_glyphs`, which
mods may extend.

#### UI icon sprites

In sprite mode, any UI line segment that carries a `sprite` field draws that
sprite at the game cell size instead of printing its text:

```lua
{ text = "⚔ ", sprite = { x = 1, y = 0 }, color = Colors.red }
```

The segment's `text` is not printed, it only reserves horizontal layout space,
so pad it to roughly the icon's width. In text mode the text is printed as
usual, keeping both modes aligned.

### Item color override

Objects that have both an `interactable` and an `item` component automatically have their `fg` color replaced with the item's rarity color at draw time. You do not need to set the color yourself, just give the item a valid `rarity` string (`"common"`, `"uncommon"`, `"rare"`, `"epic"`, `"legendary"`, or `"cursed"`). (See also: [Adding Custom Rarities](./custom_rarities.md))

### Selection highlight

When an interactable object has `interactable.selected = true`, the renderer inverts its colors: the foreground becomes `Colors.cursor` (a soft blue) and the background becomes the original `fg` color. This is the same highlight used for the player's cursor. You do not need to handle this yourself.

---

## Custom NPC Entity

This example creates a `Merchant` prefab, a non-hostile NPC shown as a yellow `$` character. It has a `position` and a `renderable`, so it will appear on screen automatically once added to the world.

```lua
local Registry   = require("core.registry")
local Position   = require("core.components.position")
local Renderable = require("core.components.renderable")
local Colors     = require("core.render.colors")

local Merchant = {}

function Merchant.new(data)
    return {
        name       = data.name or "Merchant",
        position   = Position.new({ x = data.x or 0, y = data.y or 0 }),
        renderable = Renderable.new({
            glyph = "$",
            fg    = Colors.yellow,
        }),
    }
end

Registry.register("prefabs", "merchant", Merchant)

return Merchant
```

A few things to note:
- `bg` is omitted, so it defaults to `Colors.black`, pass `nil` if you want the tile background to show through instead..
- Once you call `world:add(Merchant.new({ x = 3, y = 2 }))`, the merchant will appear on the map without any extra setup.

---

For further reading, navigate to [Registering New Content](./registering_content.md) or [Extending Existing Content](./extending_content.md).
