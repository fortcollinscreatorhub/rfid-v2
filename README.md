# What is this repository?

An RFID reader solution for Fort Collins Creator Hub. The Hub uses RFID readers
on external doors to allow people into the building, and to control
access-to/use-of equipment.

This version of the RFID reader:
* Was developed by Stephen Warren; v1 was by Steve Undy.
* The PCB relies on COTS (Commercial Off-The-Shelf) components where possible,
  to reduce circuit complexity.
* The PCB uses through-hole construction, to make it easier for arbitary people
  to construct.
* Management of the reader is intended to be easier:
  * The PCB has an LCD for status display.
  * WiFi AP mode is enabled when STA mode cannot connect.
  * A web interface is always available for management.
    This may be password protected.
* The software configuration code ("connection manager") is intended to be
  modular and re-usable by other projects. It may be moved into a shared git
  submodule one day.

# How to clone this repository

This project uses git submodules, unfortunately. To clone the repository, run:

```shell
git clone --recurse-submodules https://github.com/fortcollinscreatorhub/rfid-v2
```

If you wish to push back to the github repo, you probably want to clone with
`ssh`, or edit `.git/config` to use ssh URLs after cloning, e.g.:

```shell
git clone --recurse-submodules git@github.com:fortcollinscreatorhub/rfid-v2
```

Or after cloning:

```shell
vi .git/config
```

Even if you clone using the ssh URL, you'll still need to edit the remote
definition for each submodule after the initial clone operation.

# PCB (circuit board)

See the [PCB README](pcb/README.md).

# Software (code)

See the [code README](code/README.md).

# Mounting Boxes

See the [mounting boxes README](mounting-boxes/README.md).
