Opcoders File Manager version 0

This version 0 is parked indefinitely. I badly needed support for multiple tabs
and thus had to rewrite most of the interface in version 1. 
Version 0 represents the best I could do without tabs.


        Newton Commander - File Manager for Mac OS X
        --------------------------------------------
                        Version 0.9.0

    This was intended to become free software available under 
    the BSD license. However I have now changed my mind.
    It's still hasn't reached release quality, so there is no point 
    in releasing it as it is now, this would spoil the interest 
    from early adaptors.


    Introduction
    ------------

    Newton Commander is a dual-tab file manager. Features currently 
    are as follows:

        o  Browse all dirs even dirs that requires asking 
           for password, because it runs as root,
           except on FUSE volumes mounted per user.
        o  Resistent against file system time-outs, when it 
           happens the process is restarted and the user
           will not notice that it happened. Certain dirs
           on the Mac can yield +10 second time-outs if you
           access with Apple Finder.
        o  Obtains file listings via the GetDirectoryEntries,
           and can thus also reveal the cloaked files that
           Apple don't want you to see.
        o  Fast, because of its asynchronous nature.
        o  Extremely verbose info for files.
        o  Customizable menu for application launching.
        o  Customizable menu for bookmarks.
        o  Customize hidden files.
        o  Quicklook



    Planned Features
    ----------------

        o  Copy/Move that is verbose about what it's doing.
        o  Chose what user to browse as: John Doe, Root, Neoneye, etc.


    Credits
    -------

    This project was made by opcoders.com to help raise awareness
    of its main product: 
    GraphicDesignerToolbox - http://gdtoolbox.com/


GOAL FOR FIRST PUBLIC ANNOUNCEMENT
==================================
 1. browse all dirs even dirs that requires asking for password.
 2. extremely verbose info for files
 3. no hickups/timeouts in the UI
 4. fast



ISSUES TO FIX BEFORE ANY ANNOUNCEMENT CAN BE MADE WHAT SO EVER
==============================================================
 1. changedir needs to be more reliable
    when you hit enter on a big dir and quickly switches to another dir,
    then the request from the big dir is still being processed,
    for some reason the response from the big dir interferes with the
    current listing of the files.. annoying. 

 2. can we improve KCList/Discover performance further, so that
    the gap between you hit enter to you see something on the screen
    is as short as possible. It still varies a great deal, sometimes
    I guess it takes up to ~300 msec or maybe more to take any action.
    This must be more consistent, also if that means we will have to
    show a blank file listing.

 3. multi selections

 4. preserve multi selection when searching.

 5. reset search when hitting ESC.

 6. there are link types that we for some reason cannot follow.
    it's really strange the /Users/neoneye/hl link is like that.
    kMDItemContentType = com.apple.alias-file

    http://developer.apple.com/technotes/fl/fl_30.html

	http://developer.apple.com/documentation/Carbon/Reference/Alias_Manager/Reference/reference.html#//apple_ref/c/func/FSCopyAliasInfo

 7. KCHelper takes a path to the KCList program, which is an open
    invitation for a hijacker to insert his own path and gain
    priviledged access to the computer. Because of this the 
    KCList program must be installed.

 8. context menu arrow_left must be populated with apps that
    are capable of opening that filetype.

 9. deploy as a DMG file

10. homepage

11. copy/move multiple files 






CURRENT STATUS
==============

Issues:
 1. There is no mouse support.
 2. Copy/Move/Delete has no progressbars.


It's a Norton Commander clone with my own tweaks, so it's neither 
very mac'ish nor true to the Commander idea. Primary goal is SPEED.
All the file managers I have tried on OS X freezes, crashes or 
has obscure keybindings. My program has neither of these issues!


Has a commandline program bundled with it, so it's easy to
open the File Manager from a terminal.

Has a Finder plugin bundled with it, so it's easy to
open the File Manager from the Finder.



NAVIGATION KEYS (the primary keybindings)
=========================================

The primary usage is for navigating files using the keyboard, 
so navigation needs to be fast.
Here the original keybindings in Norton Commander is the best.

Arrow up/down: for moving the cursor by a single row.

Page up/down: for moving the cursor by a page while preserving the cursor position.

Home/End: for moving the cursor to the top/bottom.

Enter: for entering directories.

Backspace: for going to parent dir.



OTHER KEYS (the secondary keybindings)
======================================

Arrow left/right: to open the popup menu with actions.
This is perhaps my biggest innovation, a feature not yet seen in any
other file managers.

F3 one time: to see QuickLook preview.

F3 two times: to see detailed file info.

CMD T: open current path in Terminal.app
CMD ALT T: open current path in Terminal.app (in a new tab)
CMD SHIFT T: open current path in Terminal.app (in a new window)

CMD C: copies the current path to the clipboard, so it's easy to
insert into documents.

CMD R: reload info the current directory.

CMD 0-9: jump to a bookmark.









RSRC
====

We want to access the resource fork

prompt> la rakefile/rsrc
-rw-r--r--  1 neoneye  admin  0 19 Jul 02:41 rakefile/rsrc
prompt> la rakefile 
-rw-r--r--@ 1 neoneye  admin  2749 19 Jul 02:41 rakefile
prompt>



SORTING
=======

Action Menu
1. Sort
1.0  Misc Actions
   - Unsorted
   - Randomized order   
   - Reverse all columns
1.1  First Sort By (radio button)
   - Name  <--------- hit enter two times to reverse the sorting
   - Type
   - Size
1.2  Then Sort By (radio button)
   - Name
   - Type
   - Size
1.3. Name Column
   - Yes
   - Reverse this column
1.4. Type Column
   - Yes, treat link files as dirs
   - Yes
   - Reverse this column
1.5. Size Column
   - Yes, ignore size of dir nodes
   - Yes
   - Reverse this column


HIDDEN FILES
============

footer info:  5 hidden

Action Menu
1. Hidden
 - Show all
 - Hide dotfiles
 - Hide invisible files
 - Hide system files
 - Hide currentdir and parentdir inodes























