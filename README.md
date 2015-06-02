# Adafruit-PiTFT-Helper

A script for configuring Adafruit's PiTFT displays on a Raspberry Pi.

**This is in a beta state and may contain bugs.**

## PiTFT Documentation

- [PiTFT - Assembled 320x240 2.8" TFT+Touchscreen for Raspberry Pi](https://www.adafruit.com/product/1601)
- [PiTFT - Assembled 480x320 3.5" TFT+Touchscreen for Raspberry Pi](https://www.adafruit.com/product/2097)

## Getting Started: Kernel & Helper Script Installation

First, add [Adafruit's Occidentalis package repository][o] to your system.
Occidentalis is a growing collection of useful packages and configuration
defaults for installation on Raspbian systems.

If you want to bootstrap the full version of Occidentalis on a fresh, unused Pi
from another computer, we offer an easy graphical tool called the [Pi Finder][p].
Once bootstrapped, you can open a terminal on your Pi and run:

```sh
sudo apt-get install raspberrypi-bootloader-adafruit-pitft
sudo apt-get install adafruit-pitft-helper
```

...which first installs a custom kernel with PiTFT support, and then the helper
script itself.  If you _just_ want to install the kernel and helper without
pulling down any other extra packages, you can run the following from the
command line of a working Pi:

```sh
curl -SLs https://apt.adafruit.com/add | sudo bash
sudo apt-get install raspberrypi-bootloader-adafruit-pitft
sudo apt-get install adafruit-pitft-helper
```

This can take a surprisingly long time to finish, especially if you're using a
slower SD card, so be patient.

**Please be careful!** Installing a new kernel always has the potential to
leave your Raspberry Pi unbootable.  You should make a backup copy of your SD
card before trying this, or (even better!) start with a fresh card.

## Using adafruit-pitft-helper

`adafruit-pitft-helper` must be run with root privileges, and takes a parameter
specifying the type of PiTFT to configure.  Invoke it like so:

```sh
sudo adafruit-pitft-helper -t 28r
```

For a full list of available options, check the help:

```sh
adafruit-pitft-helper -h
```

## Installing PiTFT support in a Raspbian image file (experimental!)

This repository includes a [small wrapper script][c] for installing the custom
kernel and PiTFT configuration in a Rasbpian image file.  In order to use it,
you can download and unzip a recent Raspbian image on a Raspberry Pi, then do
something like the following in a terminal:

```sh
curl -SLs https://apt.adafruit.com/add | sudo bash
sudo apt-get install adafruit-pitft-helper
sudo adafruit-pitft-chroot-install -t 28r -i ~/2015-02-16-raspbian-wheezy.img
```

...where `-t` specifies the type of PiTFT just like the same option to
`adafruit-pitft-helper`, and `-i` specifies the path to an image file.

[o]: https://github.com/adafruit/Adafruit-Occidentalis
[p]: https://github.com/adafruit/Adafruit-Pi-Finder
[c]: https://github.com/adafruit/Adafruit-PiTFT-Helper/blob/master/adafruit-pitft-chroot-install
