# Overview

Source Code:
- Uses ARC.
- Uses CocoaPods.


# Build Instructions

Prerequisites
- Xcode 5.0.2 (5A3005)
- OS X 10.9.x
- ruby 2.0.0p247 or better (type `ruby -v` to see version)
- rubygems 2.0.3 or better (type `gem -v` to see version)
- cocoapods 0.29.0 or better (type `pod --version` to see version)


### Step 1 - Newton Commander cocoapods

Add the Newton Commander cocoapods repo to your cocoapods installation.

Run this in a terminal:

    pod repo add all-newton-commander-cocoapods https://github.com/neoneye/all-newton-commander-cocoapods.git

This should create the folder `~/.cocoapods/repos/all-newton-commander-cocoapods`


### Step 2 - Get the source code of the app

Run this in a terminal:

	cd ~/Downloads
	git clone https://github.com/neoneye/newton-commander.git


### Step 3 - Get the cocoapods that NC depends on

Run this in a terminal:

	cd newton-commander
	pod install

This should create: `NewtonCommander.xcworkspace`, `Pods`.


### Step 4 - Build and run

- Open the `NewtonCommander.xcworkspace`.
- Compile and run.
- Enter your admin password, so that worker process can run.


# Uninstall

Run this in a terminal:

    pod repo remove all-newton-commander-cocoapods


# Contact

Simon Strandgaard

- http://github.com/neoneye
- http://twitter.com/neoneye
- neoneye@gmail.com


# License

Newton Commander is available under the MIT License. See the LICENSE file for more info.
