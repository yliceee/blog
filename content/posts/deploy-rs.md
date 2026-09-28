+++
title = "Using deploy-rs with a conventional Nix flake configuration system"
date = 2023-11-19T20:05:00-06:00
tags = ["nixos", "howto"]
draft = false
+++

1.  [Exchange SSH keys]({{< relref "ssh-keys" >}}) between the appropriate users (root on the client machine, if you intend to use `nixpkgs.lib.nixosSystem`-created configurations).
2.  Add a `deploy` output like:
    ```nix
       {
         ...
               deploy.nodes = {
               host_name = {
                   hostname = "${builtins.readFile /run/secrets/host_name_ip}";
                   profiles.system = {
                   user = "root";
                   path = deploy-rs.lib.x86_64-linux.activate.nixos
                       self.nixosConfigurations.host_name;
                   };
               };
               # ... more nodes ...
               };
         ...
       }
    ```

    -   The `builtins...` interpolation isn't needed if you don't manage your secrets appropriately with `sops-nix`.
3.  Add [deploy-rs](https://github.com/serokell/deploy-rs) as a flake input the usual way
4.  Add the deploy-rs binary **from the flake input** to the list of installed packages, like you would with other flake-installed binaries (thorium, etc.)
    -   If you just use the deploy-rs that comes with `nixpkgs` or a random `nix-shell`, you will have a ton of weird issues
5.  Use `sudo deploy . -- --impure` to deploy to your machines
    -   `sudo` is only necessary if you need to deploy secrets kept in /run, like with `sops-nix` (since /run needs root access to read from)
    -   `-- --impure` is only necessary if you have flake impurities (like sops secrets)
        -   The extra `--` is to tell deploy-rs that you are trying to pass the argument `--impure` to the underlying `nixos-rebuild` call. See `deploy --help`.
