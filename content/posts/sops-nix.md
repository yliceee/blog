+++
title = "How to use sops-nix to manage secrets on NixOS"
date = 2023-11-19T20:05:00-06:00
tags = ["nixos", "security", "ATTACH", "howto"]
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

-   Make .sops.yaml file with your hosts public key of choice (you can use age, or ssh-age)
-   Make a `secrets/` dir and add any `secret.yaml` to it
    -   To make a secret.yaml, set your `$EDITOR` and then run `sops /path/to/secret.yaml`.
-   Add any client (_machine to be deployed to_) machine's ssh-to-age public key to `keys:`
    -   If using `ssh-to-age`, make sure to use the `/etc/ssh/ssh_host_ed25519_key.pub` file as the public key. Neither the authorized_keys.d file nor any other public key will be dedicated automatically by sops without more configuration (as of <span class="timestamp-wrapper"><span class="timestamp">[2023-10-03 Tue 17:38]</span></span>)
-   Add the clients name to `key_groups: -age:`
-   [?] If you are adding new keys, make sure to run `sops updatekeys filename` to update the recipients of each secret
    -   Not sure if this is necessary tbh. I did have to do it at one point, but who knows if you need to do this on new files created.
-   Add `sops.defaultSopsFile = /path/to/secret.yaml;` to configuration.nix
-   Add `sops.age.keyFile = /path/to/age/keys.txt;` to configuration.nix
    -   Frequently, this will be `/home/username/.config/sops/age/keys.txt;`
-   **For each secret "key_name" in secret.yaml** add `sops.secrets.key_name = { };` to configuration.nix
-   At runtime, secrets are placed in plaintext files in `/run/secrets`
-   Refer to secrets by using `"${builtins.readFile /run/secrets/secretname}"`
    This is using _string interpolation_ and a builtin "read form file" function to get the contents of the plaintext secrets
-   As of time of writing (<span class="timestamp-wrapper"><span class="timestamp">[2023-10-03 Tue 17:41]</span></span>) I still don't understand services.

[^fn:1]: Also see the useful [nix-pill](https://nixos.org/guides/nix-pills/basics-of-language#id1364) about it