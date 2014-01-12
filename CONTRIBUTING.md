# How to contribute

Pull requests are much appreciated. Here's a quick guide:

1. Fork the repo.

2. Follow the [Build Instructions](https://github.com/neoneye/newton-commander/blob/master/BUILD_INSTRUCTIONS.md) and [let me know](https://twitter.com/neoneye) if you managed to compile it or not.

3. Make your changes.

4. Push to your fork and submit a pull request.

At this point you're waiting on me. I like to at least comment on, if not accept, pull requests within three business days (and, typically, one business day). I may suggest some changes or improvements or alternatives.


# Starting points

Here are possible starting points thats that doesn't require that you know every corner of NC.


# Double click to change directory

- *Difficulty level: Easy programming skills*
- I think it's in the `NCLister.m` in the `newton-commander-ui` repository.

In Finder you can double click on a folder to change directory.
In NC you can only change directory using the Enter key.


# Drag and drop on the NC icon

- *Difficulty level: Easy programming skills*
- I think it's in the `AppDelegate` in the `newton-commander` repository.

There is currently no way to quickly go to the same folder as the Finder.
Drag a file from Finder and drop it on the NC icon in the dock,
that would cause NC to change directory so it's at the same path as the Finder.
Perhaps change path of the active tab.


# Software update

- *Difficulty level: Medium programming skills*

Integrate with [Sparkle](https://github.com/andymatuschak/Sparkle).
The main branch of Sparkle doesn't work with Xcode 5.
You may have to try out different forks and find one that works.


# F1 key = Inspect file properties

- *Difficulty level: Medium programming skills*
- It's located in the class `NCHelpView` in the `newton-commander-ui` cocoapod.

Currently when you press F1 it shows a webview with "test.html".
It's completely static and doesn't show anything.
Ideally F1 should show details about a file/folder, such as:

- Show unix permissions (stat64)
- Does it have a hidden suffix
- Invoke the `file` command
- Show Access Control Lists (ACL)
- Show extended attributes (xattr)
- Show preview image
- movies: Perhaps pull details from IMDB
- folders: Perhaps show a treemap ala GrandPerspective

I don't expect you to implement it all.
You can start showing the file size and absolute path.


# Clean up PSMTabBarControl

- *Difficulty level: Easy programming skills*
- Located in the [PSMTabBarControl repository](https://github.com/neoneye/PSMTabBarControl).

Migrate it to use bundle_resources in the `PSMTabBarControl.podspec`



