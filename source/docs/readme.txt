Newton Commander todos

== Primary TODOes

Replace AuthorizationExecuteWithPrivileges() with SMJobBless
I must rework my code in a completely different way.. but how?
http://developer.apple.com/library/mac/#samplecode/SMJobBless/Introduction/Intro.html
http://stackoverflow.com/questions/6841937/authorizationexecutewithprivileges-is-deprecated
http://developer.apple.com/library/prerelease/mac/#documentation/General/Reference/ServiceManagementFwRef/ServiceManagement_h/
http://qc-dev.blogspot.com/2010/07/installing-helper-tool.html
https://devforums.apple.com/thread/112174


copy+move sheets must work.. by using the Worker component and satisfy the copymove tests



== Secondary TODOes

duplicate folder
I use this a lot at my job, instead I use the Finder for this. CMD-D


CMD Arrow-Left to open the folder that cursor is hovering over.. in the opposite panel.
CMD Arrow-Right to do the same.


delete a single file/folder, should preserver the Y position of the cursor


F1 inspector


Change permissions sheet


Rework NSConnection code between parent process and child process to use NSXPCConnection.
Not sure if this allows us to run as a different user. 
Create a proof of concept, where the child process runs as a different user.


faster navigation.. navigating to parent dir is incredibly slow, compared to navigating into a subdir.
What is causing this slowdown?
Navigate out to parent dir is too damn slow. This can be optimized by caching everything in the parent dir. Breadcrumbs must restore NCListerItems, so that when you later hit backspace, then you get
the cached data.


Finegrained progressbars in copy sheet.


AirDrop integration.


iCloud integration.


https://github.com/peterb180369/iMedia/tree/experimental-SandboxedVersion
has read-access to the entire file system. 
But what if you have read-access and there is a directory that your user don't have access to browse.. can you then browse it? 


Why have I never tried out the SFAuthorizationView ?
http://developer.apple.com/library/mac/#documentation/Security/Reference/SecurityInterfaceFramework/Classes/SFAuthorizationView_Class/Reference/Reference.html
http://www.bdunagan.com/2009/12/13/system-preferences-pane-lock/


PSMTabBarControl uses a non NSString instance that it passes around, instead
of the expected NSString. I gotta rework the code so it doesn't generate warnings.
Really difficult to solve because "identifier" is supposed to be a string, but PSMTabBar is using it for other types of classes. And it uses bindings too, which makes it harder to determine wether the code side bad side effects.
Perhaps I should write to PSM himself and ask how to approach it. Maybe he has a few great idea.. he is a genius. 


Don't use .xib files nor .storyboard files.
It's difficult to see what has been changed in a commit.


NSFileVersion support. Introduce a column that shows how many version exists of a file.


magic trackpad integration.. three finger swipe down to show context menu.. maybe
[NSResponder swipeWithEvent:(NSEvent *)event]
or two finger pinch to show context menu.. maybe
[NSResponder magnifyWithEvent:(NSEvent *)event]


replace the NCPathControl with GCJumpBar instead. Much more powerful and nice too.


too damn unreliable when browsing SSH via MacFUSE. Hangs, crashes, cannot close tabs.
I guess this is due to the poor NCWorker component. The new Worker component will hopefully be more robust to 
when the child dies/crashes.


Kill the helper process when the lister is hanging.
2010_09_21 - It is sometimes hanging when using MacFusion connected with SFTP to a remote site. So a kill is still much needed.
This will probably be solved when switching from NCWorker to the new Worker


bug: on my work when browsing the Samba share "S01", it sometimes hangs forever and the Finder asks me if I want to
disconnect. But NewtonCommander just hangs forever. Here it would be necessary to kill the worker process.

NCWorkerThread callbackResponseData, must discard data if NCLister can't catch up with the
data it's getting from the helper process. I guess this happens a lot.

bug: arrow_down is sometimes hanging when using quicklook

bug: quicklook sometimes leads to a crash when closing the quicklook window.
it freezes at the point where the quicklook window has collapsed to a max 200x100 pixel box
and for some reason it brings down the entire program. Not sure why.

protect Rename against reload in the lister. Currenly when you are busy renaming a file and if the
lister is updated, then the file gets renamed to some random name. This is not good.
we must freeze all updates while a rename operation is going on.

when copying to a non-HFS filesystem, then my copy code generates these files.. how to avoid that?
-rw-r--r--  1 simon    simon       4096 Oct 15 09:59 ._.htaccess_virus
-rw-r--r--  1 simon    simon         74 Oct 15 10:00 .htaccess_virus

make the filename column (dir-size) field somewhat prettier, it's rather ugly.

Merge folders when copying, without overwriting anything.

eject, must indicate that the currently active path has becomed unavailable.

Date columns. Somewhere in the helperprocess I think I temporarily disabled the code
for obtaining the fieldvalues for one of the date columns. Double check that all columns
have the right timestamps.. which I'm pretty sure the don't have at the moment.
"Created" is wrong I think.
possible another column is wrong as well.

brain confusion in the MakeLink sheet.. I think it should work more like a copy operation, 
where you use the source panel and the destination panel. Not the other way around. 
It feels so wrong when do it multiple times.

Use a C struct for the listeritems. It's too damn slow to use objective c for sorting them
and assigning icons. assignIconToItems can probably be optimized if I could eliminate some
of the many retain/autorelease invokations

RsrcSize is obtained on some dirs when browsing ftp.scene.org. This property only works 
with files. Figure out why I am trying to obtain it on the dirs on ftp.scene.org and 
disable this bad behavior.

The Date columns cannot show dates before or after epoch. The HFS filesystem supports dates 
beyond the epoch range, so we should show it correct.

NCFileManager attributesOfItemAtPath:error:.. we should have 2 variants of this.
one that uses stat. Another that uses lstat. Is this really a problem?

Switch user button to remember its value. When you activate another tab then it doesn't
recall what user that was switched to for that tab.

Authenticate a single time and use this authentication with the workers. So that you don't have to
type in your password all the time. Currently you don't have to type in your password at all, but
this is incredible dangerous since anyone can take control over your computer.
Is this possible at all?

navigateInto behaves somewhat annoying with symlinks/aliases. When you hit enter on
an alias-dir then the worker needs to resolve the path, before it can obtain any entries.
The time spend on resolving the path is just enough to redisplay the non-resolved path
and then the newly resolved path arrives back from the worker process, only to redisplay
the screen. It gives an impression of some weird glitch going on. Plus there is the
possibility to remove the entire resolvepath phase in the worker.
The listRequest can have a isAlreadyResolved option, so that step 1 can be eliminated.

Backspace.. sometimes it doesn't go back/go to parent dir.. instead it jumps to an entire different dir.
I think it's when I first have jumped to a bookmark. Later when hitting backspace then
I think what happened was that I was taken to the dir before we jumped to the bookmark.
Here the right dir would be parent dir.

Get rid of NSFileManager entirely within NCLister.m
Currently used by RENAME and by COUNT_FILES. Rarely used.. however still needs to be fixed.

Make integration between worker process and core framework more robust. So when something goes
wrong it's dealt with in a way so that I can figure out what's wrong. Recently "switch user"
code is sometimes not switching user correct. I want to know when it happens and why it happens.

Can the same AuthorizationRef be used with AuthorizationExecuteWithPrivileges() 
to start the worker processes with higher priority? If so then no need for sudo.
The first time the user needs to do a privileged operation, it would be a good time
to AEWP, so the setuid bit can be set. Apple calls this repair the setuid bit.
http://developer.apple.com/mac/library/documentation/Security/Conceptual/authorization_concepts/02authconcepts/authconcepts.html#//apple_ref/doc/uid/TP30000995-CH205-TPXREF16

I see that Apple's FSCopyObject code has the function CopyForksToDropBox().
It seems that a folder with ACL permissions set so that you can only copy files into this 
dir, but cannot access anything within it.. in this case we cannot use the copy code,
since it refers to the files via their filename. In the future we must refer to the files
using FSRef or file descriptors. The real test is with dropbox folders.

Various copy modes: abort if already exist, skip if already exist, overwrite if already exist,
ask if already exist.

Leak - when closing a tab then the worker process continues to live on. I would expect it
to die when it's no longer needed.

ftp.dina.kvl.dk is a very unreliable FTP server and it triggers some nasty errors.
Another reason why the NCWorker is a good idea, so that we can recover.
It actually triggers a full crash of the GUI program. We need to make it much more robust
against crashes in the worker.

PSMTabBarControl doesn't show any tabs in debug mode. It does show tabs in release mode. go figure.
It also generates this error message:
2010-07-17 02:07:02.199 Newton Commander[53601:80f] An instance 0x236da0 of class NSTabViewItem was deallocated while key value observers were still registered with it. Observation info was leaked, and may even become mistakenly attached to some other object. Set a breakpoint on NSKVODeallocateBreak to stop here in the debugger. Here's the current observation info:
<NSKeyValueObservationInfo 0x150c00> (
<NSKeyValueObservance 0x135f10: Observer: 0x229d60, Key path: identifier, Options: <New: NO, Old: NO, Prior: NO> Context: 0x0, Property: 0x15ee40>
<NSKeyValueObservance 0x135f10: Observer: 0x229d60, Key path: identifier, Options: <New: NO, Old: NO, Prior: NO> Context: 0x0, Property: 0x15ee40>
<NSKeyValueObservance 0x135f10: Observer: 0x229d60, Key path: identifier, Options: <New: NO, Old: NO, Prior: NO> Context: 0x0, Property: 0x15ee40>
<NSKeyValueObservance 0x135f10: Observer: 0x229d60, Key path: identifier, Options: <New: NO, Old: NO, Prior: NO> Context: 0x0, Property: 0x15ee40>

unittests in SharedCode static library.. before I made it a static library the tests worked fine.
But I haven't had time to make a test target for the static library.

F1 = "(help) me interpret what I'm seeing", this is what I want it to do. When hitting F1 the opposite
panel should display info about the file type. e.g. This is a symlink pointing to another symlink
pointing to a file. The permissions is set to 777 which is dangerous. The SETUID bit is set and this is
dangerous. The invisible flag is set. It has loads of xattr metadata. Overall 80% looks suspecious.
A cross between ranks.nl and w3c validator.
If I hit F1 on a broken link, then I want to know what path the link is pointing to and wether there
is a file or not at the destination. The permissions the target file has and if there is permission mismatch.

When there is only 1 tab in a panel, then CTRL-TAB behaves wrong. It is supposed cycle through
the tabs within the panel, but for some reason it navigates to the opposite tab.
When there is only 1 tab then there of cause is nothing to cycle through, but then the behavior
should be to do nothing (which is the same as cycling to itself).

footer bar must show size of resource fork

Preferences: "Shortcuts" panel as in ForkLift

 


== Feedback from Rasmus Abrahamsen

Copying a big folder results in "Counting items…" which may last several minutes. I do not want to wait for this. Especially not later on when an operation won't be blocking. Allow me to start copying immediately but count if you need to, I don't need to know, just start.

Make operations non-blocking.

Multiple copy/move operations from the same source should run one at a time.

When the spinner in a tab is visible, the path is moving back and forth.

The "Size" column numbers are not pretty, make them normal text with no special font and graphics.

preferences, File sizes should be intelligent and with units.

When focus is on one tab, the opposite tab gets dark. This is not very pretty. Perhaps just highlight the current selection in the active tab while the current selection in the inactive is gray.

When opening a big folder, which takes time to load, I can still move around and open other folders at the same time. This results in the "breadcrumbs" getting messed up.

There is a [ back ] button in the root /

Don't require sudo at start of program, do it when it's needed. Some people feel uneasy about that.

Allow me to hide hidden files.

Why is some "Mode" cells red? It does not look very pretty. Consider something less bright than #ff0000.

Perhaps hide many columns by default. I don't think most users will need those visible.

The "switch user" menu should be part of the top menu instead of the app window for less clutter.

The size used graphic down right needs work. Perhaps use the iTunes-like design?

Resizing columns and windows is very laggy.

What is "RsrcSize" ? In general, make more user friendly column names.

The "Type" column is very rough.

Make a "default" starting folder, set it to the "Home" folder by default.

Make a bookmarks menu for home folder, desktop, documents, etc.

Make breadcrumbs clickable.

Make "close" button on tabs, like Safari.

Option to hide bottom bar.

"Mkdir" in toolbar should be "New".

Font in columns is a little bit too big. iTunes looks a bit better here, steal?

Rename loses focus as soon as folder refreshes.

Rename has no border, so it looks weird.

Perhaps bind cmd+down and cmd+up like enter and backspace.

"Counting items…" seems to stall a lot. Or is just really slow.

Cancelling "Copy" should maybe delete destination files.

"Delete" should be called "Trash" or "Move to Trash".

Selections should not be that bright red. What about blue like finder?

Make a setting to hide most user accounts (Those beginning with "_"). It's nice to be able to use them, but 99% won't ever.

Rounded edges in the bottom.


== GOAL #0 - unit tests for copy/move

- how can I test it?
- overwrite if older
- overwrite all
- rename
- permission denied, do you want to continue



== GOAL #1 - move sheet

man rename
rename() is the function the we should use to move stuff around within the same volume
it can deadlock if there is a cycle in the graph caused by hardlinked dirs (yes.. the man page says this)

OK  make a nib file with the controls needed 
OK  make controller class that can perform a fake move operation
 -  extend the worker with move code
OK  establish communication between worker app and main app 

 
== GOAL #2 - copy sheet

copy-code: replace all "perror"s with statuscode+LOG_ERROR, so that the user is shown an alert when there is trouble.

copy-code: close file descriptors whenever there is a problem

Copy sheet
 ?. figure out if we should protect ourself against infinite recursion loops
 ?. scan phase that checks if you need elevated permissions to perform the copy
 ?. skip if already exist                                        4H |  8H | ?
 ?. abort scan when hitting ESC                                  4H |  8H | ?
 ?. abort copy when hitting ESC.. are you sure                   4H |  8H | 4H
 ?. fine grained progress for big files                          8H | 16H | ?

Copy: Spinning beachball during the Scan phase with folders that contains many items.
/usr/share/man/man3 is triggering this problem.

Copy: Spinning beachball during the Copy phase with folders that contains many items.
Triggering a Reload whenever a selected file has been copied.. if there are lots of items
then there will be lots of reloads. And if a reload is expensive then BOOM.
/usr/share/man/man3 is triggering this problem.
This was especially a problem when the lister-drawing code was painfully slow,
it took 400 milliseconds to repaint the table.. if the file system is notifying us
that it needs to repaint faster that it can repaint, then we are in trouble.
This is exactly what's happening. I need to only repaint when the lister is otherwise
not busy repainting.

Abort the copy operation by killing the worker process, a very hardcore way
of stopping the on-going operation. If it's a large file that is being copied
or if the file system for some reason is hanging, then it can be necessary to
kill it. Maybe kill it if it takes longer than 5 seconds.

Test precision of timestamps when copying.. I can see that stat returns in nanoseconds.
So we should try with some nanoseconds to see if it's copied correct.

I should consider using mmap() for reading small files (less than 8 MB), because both the FreeBSD and
the Darwin code for cp() says so.

Maybe use FSOpenIterator, since it's very expensive to do a path 2 fsref lookup.

The FSGetCatalogInfo() with kFSCatInfoContentMod hangs when the path is "/Volumes".. why?

I should create a separate test suite for copy() and another one for move(), similar to GNU coreutils

decision: No pipe to begin with. This will keep things simple.
Piping requires a significant amount of research.   

copy to a volume that doesn't support resource fork, should not try to write to the resource fork, since Apple creates odd looking resource files.. __MAC_OS_X resource folder



== GOAL #4 - inspector

Inspector, quick n dirty, to debug the copy operation
 3. Figure out how to pass lots of strings to the webview        2H | 4H | ?
 4. Gather all the info via the datasource and display it        4H | 8H | ?

Total estimate for goal#4:                                       9H | 18H | ? 

Time spend on unforeseen tasks
 ?. reload WebView when arrow up/down is pressed                  ? |   ? | ?


Integration with OpenMeta tags



== GOAL #5 - improve text rendering speed

My feedback cycle has slowed down to being painful.. not good.
The program has become increasingly annoying to use because updating the table takes 200 miliseconds
and sometimes even more. This must go way faster. If you hit TAB then focus must be moved immediately
to the opposite tab. Waiting for 0.2 second feels like an eternity. 

NCFileItem copyWithZone seems to have a retain/release problem with NSDate.. it seems that it's leaking
instances like mad when using Instruments.

use CoreText to draw the permissioncell


_recursiveDisplayRectIfNeededIgnoringOpacity takes around 0.17 seconds each time the lister
is repainted. This happens when selecting/deselecting files, when reloading, when pageup/pagedowning,
when tabbing between panels. E.g. LOTS of times.
nclistertableview drawrect   0.000827s and 0.146419s to render.
permissioncell               0.000222s and 0.006676s to render.
imageandtextcell             0.000110s and 0.000460s to render.
listertabletextcell          0.000068s and 0.000403s to render.
A full redraw when hitting pagedown takes 0.24 seconds. If I disable the permissioncell and the datecell,
then it only takes 0.05 seconds.




== JuxtaFile features that I still need to code

Inspect file properties.

Filter files as in JuxtaFile with partial match

Increase/Decrease font size using CMD + and CMD -

Gray out filename suffix

Lister process is killable

Timeline column.

Show/hide hidden files.

create "ncmd" commandline tool.. similar to TextMate's "mate" command.

create preferences pane for installing / uninstalling the "ncmd" command.

Open path in terminal

Open files in diff tool

About window with donate button.



== NICE TO HAVE

BUG: rename a symbolic link.. doesn't work

SHIFT arrowup/arrowdown is too damn slow.

SHIFT pageup/down doesn't work.

Select/deselect files by glob.. as muCommander's "+" key on the nummeric keyboard

Delete must have a progressbar

Copy a single file is impossible if the source file is named "rakefile" and the
destination dir contains a file also named "rakefile". But I don't want to overwrite
the existing "rakefile".. instead I want the new "rakefile" to have a new name.
I should show a window the prompts the user what name the new file should have.

Have multiple icons for a file that indicates various issues with the file:
 1. Quarantene icon
 2. 

I think that the progressbars in the available diskspace box are wrong.
Currently they show the amount of disk usage.
It could be better if they showed amount of free disk space.. as in muCommander

MakeFile to offer a popupbutton with templates, e.g. txt, rtf, html, xml, php.
so that you quickly can create files.

Delete sheet to have a "delete immediate" mode. Currently it can only do "move to trash".
muCommander has a nice checkbox for it.

How do I show comments?  MDItemCreate() returns NULL for all files 
not residing on the SnowLeopard volume. So I cannot see any metadata 
for files on other volumes! sigh Finder can do it, so can Path Finder. 
But how do they do it?

display column: Color

display column: Dimensions

display column: Summary.
 1. Image files:  WIDTHxHEIGHT
 2. Audio files:  Duration Bitrate
 3. Movie files:  Duration

music:
display column: Music category (rock, samba, polka)

music:
display column: Music rating

movies:
display column: Movie rating on IMDB/Rotten tomatoes

movies:
display column: Movie category (scifi, cartoon) from IMDB

movies:
F1=info about movie files
 1. pull IMDB details
 2. show movie category, rating, plot summary, year, etc.
 3. show movie poster

Copy path to clipboard
.. POSIX path
.. Server afp URL
.. Abbreviated (Tilde) POSIX path
.. POSIX path for Terminal.app
.. HFS path
.. Full name
.. Display name
.. Extension
.. Windows style path

Moving the data fork of a file into the resource fork, then deleting the data fork.

Deleting a file's data fork.

Deleting a file's resource fork.

Listing all resources in a resource fork by ID, type and name.

Making files and folders invisible or visible. 

"flattens" a folder, i.e. moves all files which are descendants of it so that they are directly inside it.

managing file comments in batch. You can use the program for batch setting, erasing, appending and listing file comments.

utility for aggregating a set of files into subfolders based on their extension. Each such subfolder is named using the common extension of the files it contains

utility for reordering files in a given folder by prefixing their filenames with appropriately formatted indices.

HFSDebug integration somehow, sadly requires root access a lot
http://osxbook.com/software/hfsdebug/

"ls -la" displays a "+" when there are ACL rules. We just display 1 or 0 wether the 
file has ACL rules or not. Displaying more info would be nice. A start could be to show the 
number of ACL rules.

"ls -la" displays a "@" when there are xattr's for a item. Show different icons depending on
what keys are set, e.g. apple.quarantene could show a warning sign.
macromates could be shown as a textmate icon.

The Date column looks like crap when using the Helvetica font. The date parts needs to be aligned,
the same way the components are aligned in the permissions column.

The Date column could need a variable width spacing between the "YYYY-MM-DD" and the "HH:MM:SS" parts.

Help - Apple Help Programming Guide
Use the new help-book format introduced with Snow Leopard... the old one sucked
http://developer.apple.com/library/mac/#documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/user_help_concepts/apple_help_concepts.html#//apple_ref/doc/uid/TP30000903-CH205-BABJIAIE

When we encounter a symlink, then we want to see the size of the file that is linked to.
Currently we are showing the size of the symlink it self. And it's usually 50 bytes.
We want to see the real file size.

When we encounter a symlink, then we want to do as "ls" does.  symlink -> dir1/dir2/name

randomize files.. as a sort option.

folders first.. as a sort option.

warn if files are locked with either chflags uchg or schg, which requires that you boot up in
single user mode to remove the lock!

Damn, I just realize that ListerDataSource is a bad name, it makes no sense what so ever to use this
together with the CopyController. I need to decide wether to let all lister actions go through
one class or go through multiple classes... or perhaps one class with multiple interfaces.
So what names could work?
bridge, facade, interface, provider, endpoint, connection, controller, context
Maybe having having a class/interface for each task (list, copy, delete) would be a good idea or
perhaps it will unnecessarily bloat the interface. It must be simple to debug/maintain.
As a start I need to hook up NCCopyController with something that can copy.. but how?
I already have made a NCSystemCopy and NCSystemCopyDelegate. 
And now I have started making a NCTransferSimple and NCTransferProtocol.

looknfeel: find prettier icons for the toolbar.. this will make the program look more finished

make sure all icons in mainwindow toolbar are legit

make sure all icons in preferences toolbar are legit

font system is mega hardcoded to a few fonts. Need better way for user to select fonts
and adjust paddings.

Rework the bookmark system. / Directory Hotlist 
muCommander - CTRL-B to add to bookmarks, shows a modal dialog where you can
enter Name: and Location:.  Very useful.. even more useful than my current bookmark system.
CTRL-D = Directory Hotlist as in TotalCommander / DoubleCommander. 
CMD-ArrowLeft = Left hotlist
CMD-ArrowRight = Right hotlist

copy-sheet with a textfield (Custom target name), so that you can specify another name. 
Very handy when duplicating folders. I realize that I duplicate folders a lot for backup purposes.

The [back] item, must show hardlink count again as in the good old time.

The F keys are usually assigned to Expose / Dashboard / Spaces. The Terminal.app can somehow
intercept the keys anyhow. We should do the same.

NCListerAdvancedDataSource must use the TimeProfiling code, so that I can look for bottlenecks.
Update TimeProfiling code to work with the new advanced datasource. Where the TimeProfile
measures time between calls, this will not work. It's necessary to do the measurements
in the worker code and send the results to the main process which stores them.

F2     = Rename as in DOpus.
CMD+F  = Find
CMD+R  = Reload / Reveal in Finder
CMD+D  = Duplicate file
CMD F = Reveal selected items in Apple's Finder   <--  psonice: TODO: cmd-shift-r for reveal in finder
DELETE = stefan: and have delete on SHIFT+something

CMD+SHIFT+G = symlink - Go to dir that contains the original file.
Actually when hitting enter on a file-symlink/file-alias then go to the original file. Much easier
than remembering some keycombo.
However what if it's a dir-symlink then we have no way to get to the original dir. Yes we end up inside
the dir when we go into it, but we don't have a way to reveal the target file.

ALT F1 + F2.

Currently the copycontroller is controlled directly via the mainwindowcontroller. However it
will become a mess when I introduce a class for carrying out the copy operation that
only can be one of per lister. Moving the copycontroller out to the tabpanelcontroller 
seems to be a better plan. Nah, it seems to be better the way it is now. so no need to change it.

SETUID bit on executable the first time you try to switch to another user.

Display All Info must show:
 FSGetCatalogInfo
 stat64
 xattr
 rsrcfork
 datafork
 comment
 etc.. maybe look at FSMegaInfo for inspiration

Run external scripts and show html output as in TextMate. Uses for this:
 - open a external diff tool with left pane and right pane.
 - create zip file
 - bzr update
 - bzr commit
 - git update
 - git commit
 - find command
 - grep command

Create zip file without __MAC_OS_X folder in it.
Without .svn and without .DS_Store.
 
With MacFUSE SSH mounted volumes. Sometimes dirs aren't showing the hardlink count,
probably because I don't invoke stat on the item. It just says "0" for all dirs on planck.
Nope. If I via a console type "ls -la" or "stat" I can see that the hardlink count always
is set to 1. MacFUSE probably doesn't support hardlink count.

Search box in toolbar for partial matching

F8 = delete sheeet. muCommander has a really nice Delete sheet.
A checkbox for "Move to trash".
A expand/unexpand button that shows you a list of elements to be deleted.

UI rework - Merge all F7 operations in a single window sheet.
Subsequent F7 cycles through the tabs: mkdir, mkfile, mklink.
Escape cancels the operation.
Merge all the F7 sheets into a single sheet, so that you both can create DIRs, FILEs and LINKs
using the F7 sheet. Having a NSTabView for each of the things. Subsequent keypresses of F7 cycles
through the tabs. The last selected tab is shown next time the sheet is invoked.
ESC closes the sheet. This way we can extend the sheet with a sheet for creating Aliases and hardlinks
and creating files from a template (e.g loremipsum.pdf, lena.png)

separate out all the lister code in NCWorkerPluginAdvanced.m to a separate class, so that
things aren't that cluttered.

Make a commandline exectable that only contains the SimpleCopy code, so that I can script it.
And so that I can bundle it together with Newton Commander, so that people can use it as
a replacement for "cp".

psonice: it definitely needs an option to remove all the .* files and system stuff from the view

clicking the of the toolbar item "Edit" doesn't cause anything to happen. But hitting F4 does
cause something to happen. The problem is that NCMainWindowController doesn't have any code
for switching to edit mode.

clicking the of the toolbar item "View" doesn't cause anything to happen. But hitting F3 does
cause something to happen. The problem is that NCMainWindowController doesn't have any code
for switching to view mode.

Way too often the cursor row is blank, making me confused so that I believe that the opposite panel is active. I must ensure that there ALWAYS is a cursor row that is active. The opposite cursor should NOT be blue, since I think this is a contributing factor to the confusion, gray is a better color, so that there is a clear color distintion between left and right pane.

PSMTabBarControl seems somewhat crashprone. Stress test it and see if it reveals 
some of the problems and try fix it.

the sheets (goto folder, mkdir, mkfile, mklink) currently pops up horizontally centered in the window.
These should be horizontally centered in the panel.

quicklook when browsing dirs as another user, that you don't have permission to
access with your regular user. I guess I will have to transfer the data to a tmp dir
and then quicklook it from there.

when there is more text to fit in on the screen then NSPathControl only displays 
parts of the dirnames. The truncated part is faded out.
Do a similar fade in our NCPathControl.

Make NCPathControl clickable.
when clicked they must show a popup menu with it self and its sibling dirs

Clean up mess in NCPathControl code.

deletecontroller must preserve the cursor at the same position as before
the delete operation. So that you don't loose your position.

move the NCCore framework's resources/nib/xib's to the main bundle

[ parent ] to be shown only when the previous dir == parent dir.
[ back ] to be shown only when the previous dir != parent dir.
If CMD is held down [ parent ] is shown.

Perhaps use NSOperationQueue within the NCWorker for all the lister functions.

tabs must save: switch user, so that when the program starts it logs in as the same user.

the tab popup window was soo cool. make it work again.

Jacob from Umloud says that the only useful thing from Adobe Bridge is the "ISO" value that is displayed
in the file inspector.

-(IBAction)selectAllOrNone:(id)sender;
this code is ugly. I must have done something wrong with the responder chain.

Export to CSV file. All details about the files goes into this file. The rows are in the same
order as in the lister.
selected;inode;type;name;owner;group
1;412412;file;     readme.txt;root;   wheel
0; 92929;file;     index.html;neoneye;staff
0; 82913;dir;      source;    neoneye;staff
0; 51525;dir-alias;Library;   root;   wheel
Add these fields to the CSV file:
time_spend_in_drawrect;local_or_remote;total_size_of_names_in_bytes


Kan vi ikke få den gode gamle CTRL-Pil op keyboard shortcut til at lave en ny tab også! Det ville være great.

psonice: if you can make a simple + cheap 'finder replacement' version for mass market, it might sell well

File Sharing: how deep should "dscl" be integrated in a file manager? e.g Share this folder via Samba.

Show wether the volume is Read-only or Read-Write.

Show mediatype such as: DVD/CD/BlueRay/FTP/SFTP/USB/SDD/HDD,AFS. etc.

gather statistics.. mb transfered daily/weekly/monthly.
number of changedirs..  number of switch user.

when opening ListPanel.xib or InfoPanel.xib then Interface Builder cannot find NCCore.ibplugin.
When I tell Interface Builder manually that the plugin is located at /very/long/path
then Interface Builder understands. However I want it to happen automatically,
so that things can compile out of the box at some point later, when I cannot remember that
this thing needs to be done manually. 
what should I set this to for Interface Builder to open with the plugins I have made?
Overriding Plug-In and Framework Directory  ; IBC_OVERRIDING_PLUGINS_AND_FRAMEWORKS_DIR
Plug-In Search Paths                        ; IBC_PLUGIN_SEARCH_PATHS
Plug-Ins                                    ; IBC_PLUGINS
I currently set "IBC_PLUGINS" to
$(BUILD_DIR)/$(CONFIGURATION)/NCCore.ibplugin
$(PSMTABBARCONTROL_DIR)/build/$(CONFIGURATION)/PSMTabBarControl.ibplugin
But it doesn't seem to impact anything. I still have to manually locate the ibplugin
if I want to edit one of the .xib files.


MB KB GB TB in Size column.

bindings in NCLister that doesn't require overriding LOTs of functions.

click in lister-tabbar must activate the entire panel. how?
click in lister-background must activate the entire panel. how?

rename, 1..3 lines field editor, to wordwrap long lines so that the field editor spans
up to max 3 rows, the same way as Finder does it.

rename, for some font-faces the field editor is having trouble vertically centering
the text inside it. It's being clipped at the bottom edge.

use doxygen on the code
http://developer.apple.com/tools/creatingdocsetswithdoxygen.html


Integrate with the mount command
mount_smbfs, mount_ftp, mount_afp, mount_nfs, mount_webdav

Figure out how to share certain folders via samba or ftp.

Clear quarantene xattr for files recursively

Move resourcefork to a separate file.

Copy desired attributes from a file to another file. E.g. copy xattr's from one file to another.
Copy ACL to multiple files. etc.

create file/folder.. with empty content or by fetching content from URL
Retrieve from URL...
based on template


== Dual pane tools

Programs that involves both left and right panel, eg. Difftools, CompareDirs, SyncDirs.
Make a panel in preferences where you can setup these tools.


== DEAD CODE

none at the moment


== REDUCE SIZE OF DEPLOYED PACKAGE

ListPanel.nib contains lots of crap from PSMTabBarControl. Among other things it contains
the full path to several of the resources it's using. On another machine these full-paths
will be invalid. Further more these paths reveals private stuff about my setup.. details
that I don't want to share. How can I get rid of all this overhead from PSMTabBarControl?



== REDUCE SIZE OF EXECUTABLES

NCMainWindowController windowDidLoad
really big function

NCListerCounter drawRect: 
really big function

NCScroller darkTheme
really big function

NCLister reloadTableSetup
big function

NCLister reload
big function

NCScroller grayBlueTheme
big function

NCLister tableView:objectValueForTableColumn:row:
big function


Use "pamtotiff" to generate a multi-image TIFF file containing all the icons
http://netpbm.sourceforge.net/doc/pamtotiff.html



== APPLICATION ICON

Does the icon (icns file) have to be 300 Kbytes large?

Application icons are stored in apple's icns file format, that unfortunately have
no compression options at the moment, so the files are huge.
Mail.app have a 400 Kbytes icon!
iTunes.app have a 370 Kbytes icon!
Apparently the icns format supports jpeg2000
http://en.wikipedia.org/wiki/Apple_Icon_Image_format 
I have managed to compress Apple's Mail icon from 400 Kbytes to just 33 Kbytes.

I have crafted a tiny 512x512 image as possible that still looks somewhat crappy,
but it's file size is only 3.791 bytes, which is better than my old icon 308 Kbytes!



== CRASH REPORTER FRAMEWORK

Summary of frameworks
http://www.red-sweater.com/blog/860/crash-reporter-roundup

google breakpad
http://code.google.com/p/google-breakpad/

PLCrashReporter
http://code.google.com/p/plcrashreporter/

UKCrashReporter
http://www.zathras.de/angelweb/sourcecode.htm#UKCrashReporter

CMCrashReporter
http://cmcrashreporter.codingmammoth.com/

unsanity: Smart Crash Reports
http://smartcrashreports.com/



== PAYMENT FRAMEWORK

AquaticPrime


== SOFTWARE UPDATE FRAMEWORK

Sparkle


== OUTLINE VIEW FRAMEWORK

espresso served here have made a pretty one


== NOTIFICATION FRAMEWORK

use GROWL for this kind of messages
 1. Growl - restarting worker process as ROOT
 1. Growl - delete is not possible, since there are no selected items
 2. Growl - lister is hanging, because waiting for file system to return stat info
 2. NSAlert - cannot start NCWorker, executable is missing
 3. NSAlert - cannot establish connection with NCWorker, IPC is broken
 4. NSAlert - cannot show copy-sheet, the nib file is missing.


== FTP sites to test with

UNSTABLE:  ftp://ftp.hp.com
UNSTABLE:  ftp://ftp.dina.kvl.dk/
ftp://ftp.apple.com
ftp://ftp.mozilla.org/
ftp://ftp.cuhk.hk/
ftp://ftp.microsoft.com
ftp://ftp.oracle.com
ftp://ftp.novell.com
ftp://ftp.sony.com
ftp://ftp.hq.nasa.gov


== Time Profiling

The program can generate CSV files with profiling info.

Apple Numbers is a great a tool for processing the trace-data from setWorkingDir. 
A bar chart in the background displaying the total time.
A stacked bar chart in the foreground displaying the elapsed time for the various phases.

By showing these charts on the website, we may attract people that have interest
in great performance.



== Rejected todos

Can the worker be rewritten so that it doesn't use threads at all (NSTread nor pthreads), so
it instead runs in the main-thread. Nothing heavy is going on the the thread currently, so
I see no need for using a separate thread for this. Making things unnecessary complicated.
Probably a bad idea, since it may cause the UI to hang in some cases. So I don't want to
investigate this.

FSCreateFork() can create new forks.. so beyond data and resource fork.. it appears to be possible
to create myownfork. I need to write code for creating forks and for adding data to these forks.
HFS+ named forks were never implemented beyond the data and resource forks required for HFS 
compatibility. FSCreateFork() returns errFSBadForkName for all other names.



== Naming conventions

Looking around in Finder.app's nib files I see that they prefix all action methods with cmd, e.g.
cmdViewAsList:
cmdMoveToTrash:


== Vision 

Navigation is primary goal, so it must be smooth, no beachballs. The whole way the program is
put together is with this goal in mind. The mac file system API can cause processeses to hang
for very long periods of time (10 second timeout, sometimes longer). It happens all the time
making it very frustrating to use other file managers. To avoid hangups I have moved out all
file system code to a separate process that can be killed when it hangs. When things are slow
then the user interface isn't affected. Another benefit of this separate design is that the 
process can run as another user, allowing you to browse around as the root user.

Provide as few commands to the user as possible:
 - copy / move
 - delete
 - mkdir/mkfile/mklink
 - view info


== progress bars

/tmp/com.bee3_htdocs_2010_10_15.tar.gz             95% 1096MB   1.3MB/s   00:39 ETA


== AnalyzeCopy TODO

none




== Fix permissions on NewtonCommanderHelper

#
# This is the script for use inside Xcode to fix the SETUID bit on NCWorker
#

echo "Repairing SETUID bit"
#echo "BEFORE <---------------"

#env
#echo "BUILT_PRODUCTS_DIR = ${BUILT_PRODUCTS_DIR}"
#echo "PRODUCT_NAME = ${PRODUCT_NAME}"
#echo "FULL_PRODUCT_NAME = ${FULL_PRODUCT_NAME}"
#echo "EXECUTABLE_FOLDER_PATH = ${EXECUTABLE_FOLDER_PATH}"

NCWORKER_PATH=${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/NewtonCommanderHelper

#echo "NCWORKER_PATH = ${NCWORKER_PATH}"
sudo /usr/bin/fixperm_on_newtoncommanders_worker.sh "${NCWORKER_PATH}" > /dev/null


#echo "AFTER <---------------"



== Misc ideas

MacFUSE filesystem that is bridged with a PHP interface, so that you can browse
files on a website, without SSH or FTP.

Site backup script that streams everything as one big tar file, so that it never
hits the memory limit of the server (often 128 Mb).


== Copy/Move Alerts

Overwrite: /Users/neoneye/download/superkit/readme.txt
       500 bytes, 12 aug 2009
With file: /usr/include/superkit/readme.txt
       800 bytes, 7 sep 2010
Overwrite | Overwrite all | Skip | Cancel | Overwrite all older | Skip all | Rename | Resume


Copy Error
Cannot read file readme.txt
Skip | Skip All | Retry | Cancel


Error Copying File or Folder
Cannot copy readme.txt
There is not enough free space.
Delete one or more files to free disk space, and then try again
OK


Download Error
There is not enough room on the disk to save readme.txt
Remove unnecessary files from the disk and try again, or try saving in a different location
OK


Confirm File Replace
This folder already contains a file named 'readme.txt'
Would you like to replace the existing file
5.12 Mb, 7 sep 2010
With this one?
5.8 Mb, 10 sep 2010
Yes | Yes to all | No | Cancel


Copy File
There is already a file with the same name in this location
click the file you want to keep
-------------------------------
    Copy and Replace
    Replace the file in the destination folder with the file you are copying:
    readme.txt (/usr/include/superkit)
    size: 800 bytes
    Data modified: 7 sep 2010
-------------------------------
    Don't Copy
    No files will be changed. Leave this file in the destination folder:
    readme.txt (/Users/neoneye/download/superkit)
    size: 500 bytes
    Data modified: 12 aug 2009
-------------------------------
Cancel


Confirm File Replace
The destination already contains a file named 'readme.txt'
Existing file | Name: readme.txt
preview       | Size: 500 bytes
              | Date: 12 aug 2009
              | Desc: 30 lines
--------------------------------------
New file      | Name: readme.txt
preview       | Size: 800 bytes
              | Date: 7 sep 2010
              | Desc: 50 lines
Replace | Skip | Abort


Confirm
Local file 'readme.txt' already exist. Overwrite?
New:      800 bytes, 7 sep 2010
Existing: 500 bytes, 12 aug 2009
Yes | No | Abort | Apppend | No to All | Yes to All
[ ] Never ask me again


File collision
---------------------------
      Source: readme.txt
    Location: /usr/include/superkit
        Size: 500 bytes
        Date: 12 aug 2009
 Permissions: -rw-
---------------------------
 Destination: readme.txt
    Location: /Users/neoneye/download/superkit
        Size: 800 bytes
        Date: 7 sep 2010
 Permissions: -rw-
---------------------------
Cancel | Skip | Overwrite | Overwrite if older | Rename
[ ] Apply to all


Confirm
Overwrite '/Users/neoneye/download/superkit/readme.txt' ?
Yes | No | Yes to All | No to All | Cancel


Target file already exists!
Suggested action: Resume
Remote: readme.txt in /Users/neoneye/download/superkit
Local:  readme.txt in /usr/include/superkit
Source: 500 bytes, 12 aug 2009
Target: 800 bytes, 7 sep 2010
Overwrite | Resume | Skip | Cancel


+- Overwrite: --------------------------------------------------+
| /Users/neoneye/download/superkit/readme.txt        PREVIEWBOX |
|       500 bytes, 12 aug 2009                                  |
+- With file: --------------------------------------------------+
| /usr/include/superkit/readme.txt                   PREVIEWBOX |
|       800 bytes, 7 sep 2010                                   |
+---------------------------------------------------------------+
[ ] thumbnails     [ ] Custom fields   [+]
Overwrite | Overwrite all | Skip | Cancel | Overwrite all older | Skip all | Rename | Append | More options>>


Copy
An item named 'readme.txt' already exist in this location. Do you want
to replace it with the one you're moving?
Stop | Replace


An item with the name 'readme.txt' already exist in this location. What
would you like to do?
New                                   | Old
/usr/include/superkit/readme.txt      | /Users/neoneye/download/superkit/readme.txt
500 bytes                             | 800 bytes
12 aug 2009                           | 7 sep 2010
Stop | [ ] Apply to all | Skip | Merge | Replace



Copy File
There is already a file with the same name in this location
Click the file you want to keep
-------------------------------
    Copy and Replace
    Replace the file in the destination folder with the file you are copying:
    readme.txt (/usr/include/superkit)
    size: 800 bytes
    Data modified: 7 sep 2010
-------------------------------
    Don't Copy
    No files will be changed. Leave this file in the destination folder:
    readme.txt (/Users/neoneye/download/superkit)
    size: 500 bytes
    Data modified: 12 aug 2009
-------------------------------
    Copy, but keep both files
    The file you are copying will be renamed "readme (2).txt"
-------------------------------
[ ] Do this for the next 2 conflicts | Skip | Cancel



Overwrite Files
/Users/neoneye/download/superkit/readme.txt
Would you like to replace the existing file
500 bytes, 12 aug 2009
With this one?
800 bytes, 7 sep 2010
( ) Skip
(*) Overwrite [ Always | Update if Newer | Restore if Older  ]
[ ] Apply to all files 
OK | Cancel


File Exists
File already exists:
readme.txt
Overwrite | Rename | Cancel
(*) Always Ask
( ) Always Overwrite
( ) Always Rename


Target file already exists
The target file already exists.
Please choose an action.                Action:
--------------------------------------| (*) Overwrite
Source file:                          | ( ) Overwrite if source newer
readme.txt                            | ( ) Overwrite if different size
500 bytes                             | ( ) Overwrite if different size or source newer
12 aug 2009                           | ( ) Resume
--------------------------------------| ( ) Rename
Target file:                          | ( ) Skip
readme.txt                            | 
800 bytes                             | [ ] Always use this action
7 sep 2010                            |     [ ] Apply to current queue only
--------------------------------------|     [ ] Apply only to uploads
OK | Cancel




Replace file
 File exists: [ /Users/neoneye/download/superkit/readme.txt ]
        size: 500 bytes       12 aug 2009   
Replace with: [ /usr/include/superkit/readme.txt            ]
        size: 800 bytes        7 sep 2010   
Yes | Yes to All | No | No to All | Cancel


Confirm File Replace
Source: [ /Users/neoneye/download/superkit/readme.txt ]
Target: [ /usr/include/superkit/readme.txt            ]
The target file exists and is newer than the source.
Overwrite the newer file?
Yes | No | No to All


Confirm Overwrite
You are about to overwrite the "readme.txt" file.
This file may contain user code that will be lost
if you do not back it up onto another file.
Please verify that you are ready to proceed.
Back | Continue | Exit


Confirm
Local file 'readme.txt' already exists.
Overwrite?
New:       500 bytes, 12 aug 2009
Existing:  800 bytes, 7 sep 2010
Yes | No | Cancel | Newer Only | No to All | Yes to All
[ ] Never ask me again



Confirm file replace
The following file already exist
/usr/include/superkit/readme.txt
Would you like to replace the existing file
500 bytes
12 aug 2009
with this one?
800 bytes
7 sep 2010
Yes | Yes to All | Rename | No | No to All | Cancel


Confirm File Replace
Would you like to replace the existing file
"/usr/include/superkit/readme.txt"
modified on 7 sep 2010
with this one?
modified on 12 aug 2009
Yes | No | Yes to All | No to All




== Unit testing Copy/Move

we want the Alerts to be correct and to provide the user with max flexibility to do what they want,
so that they enjoy using this program. 


data_source/
    file1
    file2
    file3
data_target/
    file2

move from source to target

expect "do you want file2 or file2 ?"






== Publicity

I ought to write a huge comparison of file managers for OS X.. the latest is from 2006
http://www.simplehelp.net/2006/10/08/10-os-x-finder-alternatives-compared-and-reviewed/

http://ezinearticles.com/?The-Best-OS-X-File-Management-Software&id=2412263

http://codertools.wordpress.com/2009/06/03/file-managers-part-2-osx/

http://superuser.com/questions/138527/dual-pane-file-manager-for-mac-os-x





== Naming

The newton (symbol: N) is the SI derived unit of force, named after Isaac Newton in recognition of his work on classical mechanics.

