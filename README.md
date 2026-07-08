# Ares RPG

A simple turn-based cyberpunk/fantasy RPG that uses ascii-style graphics and has heavy modding support.

---

Navigate the floors, traveling deeper and deeper until you either die or meet the man at the bottom of all this.\
You are the robot AZ-1.\
You want your freedom.\

---

<p float="left" align="center">
    <!-- <img src="./repo_assets/beta_screenshot.png" width="300"> -->
    <img src="./repo_assets/beta_screenshot.png" width="300">
    <!-- <img src="./repo_assets/beta_screenshot.png" width="300"> -->
</p>

<p align="center">
    Go to Downloads
</p>
<p align="center">
    <a href="https://github.com/Nadelio/Ares-RPG/releases">
        <img src="./repo_assets/download_icon.png" alt="Download Here!" width="100">
    </a>
</p>

--- 

# Building From Scratch
```bash
# using bash
LOVE_PATH="custom_love_path" # use this if you have a non-standard Love2D path
bash build.sh
# output directory is the first arg, the game name is the second arg
```

## Dependencies
- Love2D, the library used for multiplatform input and audio (as well as the window and some other minor things)
- `zip`, used for creating the `.love` archive
    - MacOS has `zip` built in, but Windows and Linux will need to download it via your desired package manager (if you don't already have it)

---

<p align="center">
    <a href="./docs/README.md">
        <img src="./repo_assets/GettingStarted.svg" alt="Getting Started" width="500">
    </a>
</p>
<p align="center">
    <a href="./docs/">
        <img src="./repo_assets/ModdingDocs.svg" alt="Modding Documentation" width="500">
    </a>
</p>