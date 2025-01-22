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

# PCB

The PCB was developed using KiCAD 7.0.11 under Ubuntu.

Prototype versions of the PCB were manufactured by
[OSHPARK](https://oshpark.com/). The KiCAD PCB file was uploaded directly, as
opposed to exporting Gerber files, etc.

# Software (code)

## Development environment

Software development has been tested on native Ubuntu 24.04. It likely works on
most Linux distributions, and under Windows using WSL2.

The software is developed using the ESP-IDF SDK. Espressif publishes Docker
images containing IDF, so there is no need to install IDF locally. Easy
instructions to build the software are provided below.

Integration for [vscode (Visual Studio Code)](https://code.visualstudio.com/)
is provided.

## Docker setup

```shell
sudo apt update
sudo apt -y install docker.io
sudo usermod --groups docker --append $(id -u -n)
```

Now log out and in again to ensure you're a member of the `docker` group.

## vscode integration

Point vscode at the `code/` sub-directory of this git repository. This will
automatically configure the vscode integration, such as build tasks. From the
GUI, File > Open Folder. From the command-line:

```shell
cd /path/to/fcch-rfid-v2/code
code .
```

To build/flash/..., simply press Ctrl-Shift-B and select the appropriate task.
You may wish to apply a local edit to `.vscode/tasks.json` to change the serial
dongle's device name.

## Building from the command-line

`build.sh` will download the relevant Docker image, and run `idf.py` within it
as required.

Note that `build.sh` bind-mounts your home directory and the source code from
your host into the (ephemeral) Docker container. Files will be saved in
`~/.cache/Espressif`, `~/.ccache` and perhaps other directories.

### Build

```shell
./build.sh
```

### Clean

```shell
./build.sh idf.py fullclean
```

### Enter Docker Container for Experimentation

```shell
./build.sh bash
```

## Flashing

In the following commands, replace `/dev/ttyUSB0` with the relevant port on
your host.

One-time setup; not necessary if your udev rules do this automatically:

```shell
sudo chmod 666 /dev/ttyUSB0
```

To flash, each time:

```shell
./build.sh idf.py -p /dev/ttyUSB0 flash
```

# Debugging

Monitor all MQTT messages in a broker:

```shell
mosquitto_sub -h broker_hostname_or_ip -t '#' -v
```
