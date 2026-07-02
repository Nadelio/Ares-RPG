return {
    id = "test",
    name = "Test Mod",
    description = "A test mod.",
    version = "1.0.0",
    dependencies = {
        "foo"
    },
    init = function() print("Hello from Test Mod!") end
}