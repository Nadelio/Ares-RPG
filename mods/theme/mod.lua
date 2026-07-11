return {
    id = "theme",
    name = "Custom Color Theme",
    description = "A mod that changes the built-in render colors for red, green, and blue",
    version = "1.0.0",
    dependencies = {},
    init = function()
        local Colors = require("core.render.colors")
        Colors.red = {1.0, 0.0, 0.0}
        Colors.green = {0.0, 1.0, 0.0}
        Colors.blue = {0.0, 0.0, 1.0}
    end
}