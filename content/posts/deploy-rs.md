+++
title = "Using deploy-rs with a conventional Nix flake configuration system"
date = 2023-11-19T20:05:00-06:00
tags = ["nixos", "howto"]
draft = false
+++

## Motivation &amp; Concepts {#motivation-and-concepts}

The concept of "secrets" in a software project are pretty straightforward- it can be anything from SSH keys, API keys, passwords, anything that your project takes as a parameter and you don't want published.

NixOS configurations are confusing, and are some of the deepest and most important software projects you will use on your NixOS machine. They're also likely to be rife with secrets- in my own configuration, I set even the password for my user account using `configuration.nix`.

As such, it's useful to have a way to host your configuration publicly without needing to keep a separate copy secret-free. [sops-nix](https://github.com/Mic92/sops-nix) is one such solution.


### Concepts {#concepts}

The manual is very comprehensive, but the basic idea is the following:

> 1.  Create a config yaml file to select which users/machines have access to certain private keys
> 2.  Create a secrets yaml detailing your secrets in plain-text
> 3.  sops-nix encrypts this file using the keys specified in the config
> 4.  Then, declare the secrets in `configuration.nix`. sops-nix will decrypt the secrets at evaluation time, and store them in a directory in `/run/secrets`
> 5.  Refer to secrets in subsequent generations using [string interpolation](https://nixos.org/manual/nix/stable/language/string-interpolation)[^fn:1]


## Setup {#setup}

1.  [Exchange SSH keys]({{< relref "ssh-keys" >}}) between the appropriate users (root on the target machine, if you intend to use `nixpkgs.lib.nixosSystem`-created configurations).
2.  Add a `deploy` output like:
    ```nix
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
    ```

    -   The `builtins...` interpolation isn't needed if you don't manage your secrets appropriately with `sops-nix`.
3.  Add `deploy-rs` as a flake input the usual way
4.  Add the `deploy-rs` binary **from the flake input** like you would with other flake-installed binaries (thorium, etc.)
    -   If you just use the `deploy-rs` that comes with `nixpkgs` or a random `nix-shell`, you will have a ton of weird issues
5.  Use `sudo deploy . -- --impure` to deploy to your machines
    -   `sudo` is only necessary if you need to deploy secrets kept in /run, like with `sops-nix` (since /run needs root access to read from)
    -   `-- --impure` is only necessary if you have flake impurities (like sops secrets)
        -   The extra `--` is to tell `deploy-rs` that you are trying to pass the argument `--impure` to the underlying `nixos-rebuild` call. See `deploy --help`.

[^fn:1]: Also see the useful [nix-pill](https://nixos.org/guides/nix-pills/basics-of-language#id1364) about it