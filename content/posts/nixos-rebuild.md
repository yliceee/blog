+++
title = """
  An addendum to a "new" deployment tool
  """
date = 2023-11-20T17:39:00-06:00
draft = false
+++

There's this [awesome blog-post](https://www.haskellforall.com/2023/01/announcing-nixos-rebuild-new-deployment.html) about using `nixos-rebuild` as a tool to deploy to remote NixOS machines. If you're new to the world of deploying NixOS machines, you might not know that there are [many](https://nix-community.github.io/awesome-nix/#deployment-tools).

Some have varying support for flakes, parallel deployments, etc. `nixos-rebuild` is not necessarily a solution to all of these problems, but it is a natural (at least on NixOS), [multi-platform](https://search.nixos.org/packages?channel=23.05&show=nixos-rebuild&from=0&size=50&sort=relevance&type=packages&query=nixos-rebuild) solution.

However, there is a minor issue. It is recommended to use `nixos-rebuild` with `sudo` in many cases. If you're using ssh to connect to your remote machine, you need to then pass `--use-remote-sudo`, like the blog recommends.

It seems, unfortunately, that this flag is [broken](https://github.com/NixOS/nixpkgs/issues/118655):

```bash
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

The solution, then, is to [exchange SSH keys]({{< relref "ssh-keys" >}}) with the root user of your client machines.

Just a minor edit to a good post!
