# Open Fallout Tactics

This repository contains source code for [LÖVE](https://love2d.org/) to display sprites from [Fallout Tactics](https://en.wikipedia.org/wiki/Fallout_Tactics:_Brotherhood_of_Steel).

The goal of this project is mainly to entertain my reverse engineering curiosities.

## Technical details

Since parsing binary files with lua is not feasable with a 60 fps target, I leveraged the LuaJIT [FFI](http://luajit.org/ext_ffi.html) library for faster parsing.

## Media

![](https://dl.dropboxusercontent.com/s/chq2sdmqdb5j86y/OpenFT_2015-07-03_16-14-34.png "Vehicles")

![](https://dl.dropboxusercontent.com/s/0s4r6x7phenm50l/2015-06-09_14-21-13.gif "Character animations")

![](https://dl.dropboxusercontent.com/s/bdbfddptvh3hl9i/2015-06-09_14-24-04.gif "Vehicle animations")
