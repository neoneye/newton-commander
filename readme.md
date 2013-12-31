# Newton Commander

A dual-pane file manager with tabs for Mac OS X.


# Download

[Newton Commander.zip](https://github.com/neoneye/newton-commander/releases/download/0.1.1/Newton.Commander.zip)

[Release notes](https://github.com/neoneye/newton-commander/releases/tag/0.1.1)


1. Unzip it.
2. Try open it. (It should fail because Mavericks blocks unsigned apps)
3. Open your Mac System Preferences
4. Go to the "Security & Privacy" panel.
5. It should say "Newton Commander.app" was blocked from opening because it is not from an identified developer.
6. Choose "Open Anyway".


# Overview

Features:
- Each tab runs in its own child process. 
- Closing a tab kills the child process.
- A tab can be started as a different user, allowing you to see otherwise restricted files.

Source Code:
- Uses ARC.
- Uses CocoaPods.

![Screenshot of copy sheet](https://raw.github.com/neoneye/newton-commander/master/source/docs/screenshot001.jpg)
![Screenshot of child-process running as root](https://raw.github.com/neoneye/newton-commander/master/source/docs/screenshot002.jpg)
![Screenshot showing that resource-fork is still used on Mavericks](https://raw.github.com/neoneye/newton-commander/master/source/docs/screenshot003.jpg)


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
