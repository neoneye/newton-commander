
Today I was busy backing up Lasses files from his computer.
He accidentially unplugged the remote disk.
Finder could not resume the copy operation, so it had to be
done from scratch again!
A copy mode for resuming would be a life saver!

Prompt-mode:
 1. Ask before overwrite
 2. Always overwrite
 3. Skip always if there exist a file already
 4. Overwrite if there exist a file a different size. 
    Skip if size and signature is identical (but don't do comparison)



-----------------------------------

Argh crap. Just discovered that Apple has a function
for copying files with LOTs of callbacks describing progress.
I have been looking for something similar but without luck
until now (when I almost have my own copy code).
http://developer.apple.com/mac/library/documentation/Carbon/Reference/File_Manager/Reference/reference.html#//apple_ref/doc/uid/TP30000107-CH4g-TPXREF156


FSPathCopyObjectAsync
FSPathMoveObjectAsync
PBRenameUnicodeAsync

FSFileOperationCopyStatus
 - can provide us with the name of the current item


kFSOperationObjectsRemainingKey
kFSOperationThroughputKey


FSFileOperationCopyStatus
Gets a copy of the current status information for an asynchronous file operation.

Drawbacks:
 - no future way to copy to a virtual file system!
 - no way to copy from user account A to user account B directly.
 - no way to change overwrite/ask mode on the fly.
 - no way to skip files.
 - no verbose error handling.
 - no pause.
 - no throughput cap.
 - no ignore certain kinds of data:  .DS_Store, rsrc
 - no way to copy a particular type of files: *.png
 - no way to see if read() is hanging.. (aio_read much better)
 - not possible to write every operation to a log file.
 - has throughput. But no read-throughput, write-throughput.
 - no append mode.

Benefits:
 - reliable.
 - less code to maintain.
 - will also work in the next version of Mac OS X.
 - can resolve aliases.

Unknowns:
 - I have no idea how to code the move operation.
   When is the right time to delete a file.
   Can it be moved within the volume, fast or slow, etc.


Since I'm making a file manager I will have to code most of these
operations anyways: create links, deal with resource fork, acl,
permissions. So it may not be a total waste of time.



-------------------------------------------------------------
Resource fork and the finder info pops up in the xattr list.
How am I supposed to copy the xattr list ?
 A. should I skip these entries.
 B. copy the regular attr list instead.
 C. other?





