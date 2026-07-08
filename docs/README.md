# Getting Started

First thing: Download and install [Love2D](https://love2d.org/)

Love2D is required for the game to run, by default it is bundled with the executable, but you might want to read the source code without having a browser open to Github.

Once you have Love2D installed, locate the `mods/` folder, if you are modding the executable and haven't downloaded the raw source code, it should be in these directories:
OS | Directory
---|---
Windows | `%AppData%/Roaming/AresRPG/mods/`
Linux | `~/.local/share/AresRPG/mods/`
MacOS | `~/Library/Application Support/AresRPG/mods/`

If you downloaded the raw source code, the `mods/` folder will be in the root folder of the source code.

--- 

Now that you have located the mods folder, create a new folder in it, name it anything, it doesn't matter on a technical level.

Next create a `mod.lua` file and copy this mod manifest template into it:
```lua
return {
    id = "",
    name = "",
    description = "",
    version = "",
    dependencies = {},
    init = function() end
}
```

The `id` is how your mod will be referenced within the game, it is also how the mod loader identifies your mod as a dependency to another mod.

The name is what will be shown in the Mod List menu, same with the description and version.

I'd suggest following the [Semantic Versioning Guidelines](https://semver.org/) for the version string.

The `dependencies` table is an array of mod IDs (as strings).

The `init` function is a function that takes no parameters, and returns nothing. It is purely used as a post-load setup function, please don't use it to inject malware, thanks \<3

> [!NOTE]
> Systems that are registered with the Registry will automatically have their `init` function called, so you do not need to call them manually in the `mod.lua` `init` function.

---

After you have created your mods manifest, you need to 3 folders, `components/`, `prefabs/`, and `systems/`. These folders will be where all your mod code lives.

> [!NOTE]
> A quick overview of how Ares is structured: Events trigger Systems, Systems work off of Components, Components is data, Prefabs are collections of Components and (sometimes) Systems.\
> The `init(Events, world, map, logger)` function in Systems is used to create reciever functions for events.\
> The `new(data)` function in Components and Prefabs is for creating instances of Components and Prefabs

Now your modding environment should be completely setup, so you are good to get to modding!

For further reading, navigate to the [Ares ECS Framework](./ecs_framework.md) or [Your First Mod](./first_mod.md)

# Table of Contents
[Ares ECS Framework](./ecs_framework.md)\
[Your First Mod](./first_mod.md)\
[Core Events List](./events.md)