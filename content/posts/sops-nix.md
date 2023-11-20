+++
title = "How to use sops-nix to manage secrets on NixOS"
date = 2023-11-19T20:05:00-06:00
tags = ["nixos", "security", "ATTACH", "howto"]
draft = false
+++

## Motivation &amp; Concepts {#motivation-and-concepts}

The concept of "secrets" in a software project is pretty straightforward- it can be anything from SSH keys, API keys, passwords, anything that your project takes as a parameter and you don't want published.

NixOS configurations are confusing, and are some of the deepest and most important software projects you will use on your NixOS machine. They're also likely to be rife with secrets- in my own configuration, I set even the password for my user account using `configuration.nix`.

As such, it's useful to have a way to host your configuration publicly without needing to keep a separate copy secret-free. [sops-nix](https://github.com/Mic92/sops-nix) is one such solution.


### Concepts {#concepts}

The manual is very comprehensive, but the basic idea is the following:

> 1.  Create a config yaml file to select which users/machines have access to certain private keys
> 2.  Create a secrets yaml detailing your secrets in plain-text
> 3.  [sops](https://github.com/getsops/sops) encrypts this file using the keys specified in the config
> 4.  Then, declare the secrets in `configuration.nix`. sops-nix will decrypt the secrets at evaluation time, and store them in a directory in `/run/secrets`
> 5.  Refer to secrets in subsequent generations using [string interpolation](https://nixos.org/manual/nix/stable/language/string-interpolation)[^fn:1]


## Setup {#setup}

1.  Make .sops.yaml file with your host('s) public key of choice (you can use age, or the tool `ssh-age`)
2.  Make a `secrets/` dir and add any `secret.yaml` to it
    -   To make a secret.yaml, set your `$EDITOR` and then run `sops /path/to/secret.yaml`.
3.  Add any client (_machine to be deployed to_) machine's public key to `keys:`
    -   If using `ssh-to-age`, make sure to use the `/etc/ssh/ssh_host_ed25519_key.pub` file as the input public key. Neither the authorized_keys.d file nor any other public key will be dedicated automatically by sops without more configuration (as of <span class="timestamp-wrapper"><span class="timestamp">[2023-10-03 Tue 17:38]</span></span>)
4.  Add the clients name to `key_groups: -age:`
5.  [?] If you are adding new keys, make sure to run `sops updatekeys filename` to update the recipients of each secret
    -   Not sure if this is necessary tbh. I did have to do it at one point, but who knows if you need to do this on new files created.
6.  Add `sops.defaultSopsFile = /path/to/secret.yaml;` to configuration.nix
7.  Add `sops.age.keyFile = /path/to/age/keys.txt;` to configuration.nix
    -   Frequently, this will be `/home/username/.config/sops/age/keys.txt;`
8.  **For each secret "key_name" in secret.yaml** add `sops.secrets.key_name = { };` to configuration.nix
9.  At runtime, secrets are placed in plaintext files in `/run/secrets`
10. Refer to secrets by using `"${builtins.readFile /run/secrets/secretname}"`
    This is using _string interpolation_ and a builtin "read form file" function to get the contents of the plaintext secrets
11. As of time of writing (<span class="timestamp-wrapper"><span class="timestamp">[2023-10-03 Tue 17:41]</span></span>) I still don't understand services.


## Special cases &amp; further reading {#special-cases-and-further-reading}

This post isn't meant to be comprehensive. The (frankly exhaustive) sops-nix documentation should be the first and final source on its configuration.

However, there are a few special cases to mention to save a few web searches.


### Deploying twice? {#deploying-twice}

Something you may notice is that if you attempt to switch to a configuration that both declares new secrets and uses said secrets at the same time, it will fail.

This is because the method used in this post to refer to secrets (`builtins.readFile /run/secrets/...`) depends on the secrets already being there- which doesn't happen until nix has fully evaluated a valid configuration that declares them.

What this means practically is that you need to first switch to a configuration which declares the secrets ([step four](#concepts)) and _then_ switch to a configuration that uses them. There's some more nuance and tricks relating to this, however.


#### Use a deployment tool {#use-a-deployment-tool}

There are a _lot_ of [deployment tools](https://nix-community.github.io/awesome-nix/#deployment-tools) for NixOS. A deployment tool basically controls the building of configurations and transferring of those configurations (sometimes as a thin wrapper around [nixos-rebuild](https://www.haskellforall.com/2023/01/announcing-nixos-rebuild-new-deployment.html)) to various machines, which may or not be remote.

I personally [use deploy-rs]({{< relref "deploy-rs" >}}).

A deployment tool can make it trivial to deploy new secrets to remote machines.

Because secret substitution (interpolation) happens at evaluation time, if you build a configuration remotely on a machine which already has the new secrets installed, you can skip the separate declaration step.

> [...] _if you build a configuration remotely on a machine which already has the new secrets installed, you can skip the separate declaration step._


#### Housekeeping {#housekeeping}

It's always a good idea to store your secrets in one [module](https://nixos.wiki/wiki/NixOS_modules)[^fn:2].

This way, you can be sure you've actually included all of your secrets, and don't have to go hunting through your configuration.

Though, of course, NixOS will give you an error if one is missing, and the message is actually helpful:

```bash
error: opening file '/run/secrets/missing_secret': No such file or directory
```


### `neededForUsers` {#neededforusers}

The sops-nix documentation [mentions](https://github.com/Mic92/sops-nix#setting-a-users-password) that some extra settings for secrets needed before users are created, like, especially, a user's password.

> _The settings for a secret are specified in the (usually empty) attribute set when you declare it:_
>
> ```nix
> sops.secrets.key_name = {
>   #... settings go here ...
> };
> ```

[^fn:1]: Also see the useful [nix-pill](https://nixos.org/guides/nix-pills/basics-of-language#id1364) about it
[^fn:2]: _Yes_, I'm linking to the frequently out-of-date, never-use, no-good-very-bad NixOS wiki. But in this case, its basic description of modules is straight to the point.