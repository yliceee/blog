+++
title = "How to actually exchange SSH keys (passwordless SSH)"
date = 2023-11-19T20:05:00-06:00
tags = ["linux", "howto"]
draft = false
+++

SSH should be 1-to-1 for device-to-key

1.  Run `ssh-keygen -t ed25519 -N ''` to generate _one unique key_ per machine, do not overwrite!
    -   You should probably use the type of key in this command, see [the archwiki](https://wiki.archlinux.org/title/SSH_keys#Ed25519) and surrounding discussion for more details
2.  `ssh-copy-id user@host` for the user and host you want to log into
3.  Do the same thing from the other machine

You should now be able to login to either machine from the other without requiring a password.
