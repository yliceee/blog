+++
title = "Installing Gnome 45"
date = 2023-11-22T11:57:00-06:00
tags = ["blog", "nixos", "tricks", "gnome", "linux"]
draft = false
+++

I recently spent some time trying to install gnome 45 on my NixOS laptop (which is finally [merged](https://github.com/NixOS/nixpkgs/pull/247766) 🥳 thank you NixOS contributors!)

Unfortunately doing so was kind of a pain in my setup. My laptop is an under-powered machine with only 8GB of RAM, and although my desktop has quite a bit more RAM (and a better processor) its NixOS partition is currently a measly 100GB.

So, building it from source was kind of out of the question on my desktop, and it would take forever on my laptop.

After a while, a Hydra job was started for it, so now I could just download from [cache.nixos.org](https://cache.nixos.org). But on the branch it was built for, some of my packages were totally broken.

I learned that you can not only specify different versions of Nixpkgs in the same configuration, but you can also derive your system configuration (like, in particular, the gnome 45 module and settings) from one version, and _your packages from another!_

When doing this, it may be necessary to pass in extra configuration arguments to the version of Nixpkgs you use for packages. In my case, I use a few unfree packages (like Spotify). Here's how I did that:

```nix
pkgs = (import inp.nixpkgsForPackages {config.allowUnfree = true;});
```

> There were a few other interesting leads/tricks I discovered throughout the ordeal, which I've included below.


## Tricks {#tricks}

-   Foregoing switching to a configuration until boot (instead of activating while the machine is running) saves memory, time, and is less stressful when trying to conserve disk space
-   You can just fully `(import inp.nixpkgsForPackages {args_go_here})` in configuration.nix, and pass any `config.STUFF` arguments in at `args_go_here`. This is useful for example when trying to allow unfree configs:
    ```nix
        pkgsOld = (import inp.nixpkgsOld { config.allowUnfree = true; });
    ```
-   Experiment with `--store` and `--eval-store` to speed up builds!
    -   URL syntax for these flags is: `--store 'ssh://HOST'`, etc.
-   Hydra stuff
    -   When Hydra evaluates branches of Nixpkgs, any evaluations that succeed are immediately deposited in the [cache.nixos.org]({{< relref "#d41d8c" >}})
-   Gnome 45 works now, and is in master!
