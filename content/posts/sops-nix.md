+++
title = "How to use sops-nix to manage secrets on NixOS"
date = 2023-11-19T20:05:00-06:00
tags = ["nixos", "security", "ATTACH", "howto"]
draft = false
+++

-   Make .sops.yaml file with your hosts public key of choice (you can use age, or ssh-age)
-   Make a `secrets/` dir and add any `secret.yaml` to it
    -   To make a secret.yaml, set your `$EDITOR` and then run `sops /path/to/secret.yaml`.
-   Add any client (machine to be deployed to) machine's ssh-to-age public key to `keys:`
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
