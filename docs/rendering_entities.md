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
