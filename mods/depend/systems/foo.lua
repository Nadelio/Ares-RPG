local Registry = require("core.registry")

local FooSystem = {}

function FooSystem.init(Events, world, map, logger)
    print("Hello, world!")
end

Registry.register("systems", "foo", FooSystem)

return FooSystem