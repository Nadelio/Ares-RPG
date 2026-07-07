#!/usr/bin/env nu

def main [
    --love-path: string = ""
    --output-dir: string = "./dist"
    --game-name: string = "AresRPG"
] {
    let os = $nu.os-info.name

    let resolved_love_path = if $love_path != "" {
        $love_path
    } else {
        match $os {
            "windows" => "C:/Program Files/LOVE",
            "macos"   => "/Applications/love.app",
            "linux"   => (try { ^which love | str trim } catch { "/usr/bin/love" }),
            _         => { error make { msg: $"Unsupported OS: ($os)" } }
        }
    }

    let love_ok = match $os {
        "windows" => ($"($resolved_love_path)/love.exe" | path exists),
        _         => ($resolved_love_path | path exists)
    }
    if not $love_ok {
        error make { msg: $"Love2D not found at '($resolved_love_path)'. Pass --love-path to override." }
    }

    if ($output_dir | path exists) { rm -rf $output_dir }
    mkdir $output_dir

    let love_file = $"($output_dir)/game.love"

    print "Compressing game files..."
    ^zip -r $love_file main.lua core assets

    match $os {
        "windows" => {
            print "Building Windows executable..."
            let out_exe = $"($output_dir)/($game_name).exe"
            (open --raw $"($resolved_love_path)/love.exe") ++ (open --raw $love_file) | save --raw $out_exe
            ls $resolved_love_path | where name =~ '\.dll$' | get name | each {|dll| cp $dll $output_dir }
            print $"  ($out_exe)"
        },
        "macos" => {
            print "Building macOS app bundle..."
            let out_app = $"($output_dir)/($game_name).app"
            cp -r $resolved_love_path $out_app
            cp $love_file $"($out_app)/Contents/Resources/"
            print $"  ($out_app)"
        },
        "linux" => {
            print "Building Linux executable..."
            let out_bin = $"($output_dir)/($game_name)"
            (open --raw $resolved_love_path) ++ (open --raw $love_file) | save --raw $out_bin
            ^chmod +x $out_bin
            print $"  ($out_bin)  (requires Love2D shared libs on target)"
        }
    }

    rm $love_file

    mkdir $"($output_dir)/mods"
    "Drop mod folders here. Each mod is a subfolder with a mod.lua manifest.
Example layout:
  mods/
    my_mod/
      mod.lua
      systems/
      components/
      prefabs/
" | save $"($output_dir)/mods/README.txt"

    print ""
    print $"Build complete -> ($output_dir)/"
    print "  mods/  <-- modders drop their folders here"
}
