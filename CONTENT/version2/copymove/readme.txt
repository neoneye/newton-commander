== THE PURPOSE

this project is about building a commandline tool in C that can copy/move files

Q: what is wrong with NSFileManager's copy code?
A: it cannot merge file hierarchies. Operations cannot be cancelled.
There is no useful progressbar. It doesn't copy all meta data in the AnalyzeCopy tests.
It is not interactive.

Q: what is wrong with 'cp' ?
A: it cannot merge file hierarchies. Limited number of filenames in the argument-list. 
It doesn't copy all meta data in the AnalyzeCopy tests. It is not interactive.

Q: why one tool for both cp and mv, wouldn't it be better to make two separate tools?
A: the unittests are almost the same for both operations, so it's better
to have it as a single tool. Less code. Less bugs.

Q: what protocol should it use?  
A: use stdin/stdout. In the past I have tried using sockets 
where I had established a bidirectional NSProxy connection.
It is impossible to test wether it works or not.

Q: a commandline tool.. why not make a static library that easily can be embedded?
A: it needs to be killable, when the user decides to cancel an ongoing operation,
then it should stop instantly. Way too often I have experienced
file managers that gets stuck in the middle of a file operation.
A benefit of this is that the copy/move code will not leak memory in
the main application.

Q: should the copy code be open source?
A: I'm considering open sourcing just the copy/move tool along with the unittests,
so that other people can benefit from it. Could be fun to make a freebsd version of it.
the domain "copymove.com" is available

Q: what is the main challenge in project?
A: Exercise advanced merge operation when copying/moving content into a folder 
with has content with the same names. Should it be overwritten or renamed 
or should the operation be cancelled. Also file permission problems, e.g. You don't have
permissions to read the file "secret.db", you must authorize yourself.

Q: what is the state of this project?
A: a lot of the basic tests has been written, but many more advanced tests needs to be written.
the ruby tool needs to work satisfying.
the tests of the ruby tool has a few tests, but many more advanced tests needs to be written.
when the ruby tool is good, then the C tool needs to be written.
when the ruby tool is good, then the objective C wrapper around the C tool needs to be written.
finally the C tool needs to be integrated into the NewtonCommander filemanager.

Q: how will the unittests invoke the copymove process?
A: the copymove process has a commandline interface similar to ftp, where you type in commands via stdin.
In ruby it's scripted using expect.rb.
The commandline interface is ONLY for unittesting purposes. When used via the filemanager, then
Distributed Objects (NSProxy) is used.
A config.json file is used for transfering filenames (to avoid unicode issues).

Q: how will the filemanager invoke the copymove process?
A: using DistributedObjects.

Q: if this is opensourced what should it be named?
A: I'm considering registering the domain "copymove.com" to host this project.

Q: the new Finder in Lion should have Folder Merging, how does it work?
A: I dunno.. waiting for Lion


== TODOs


NSProxy separation between frontend UI and worker process.
I already have the NCWorker subproject which is not fully mature..
I will need to have multiple worker programs bundled with the Commander.
The NCWorker was made with the assumption that it was the only worker program needed.
What needs to be done is that NCWorker is reworked so that it supports multiple workers.
It needs to be better tested too.

NCWorker needs to be splitted up into two static libraries:
host_process
child_process
Should it just rely on delegates, or should one rely on subclassing?
I would prefer delegates.
The host_process code already uses delegates, so no need to change anything there (NCWorker and NCWorkerController)
The child_process code uses delegates (NCWorkerPlugin and NCWorkerPluginDelegate), however the actual worker code is embedded in the NCWorker project. It must be a separate project.
The create_worker() code, must be able to spawn different executables, e.g.
worker = create_worker(@"copymove");
worker->delegate = self
worker->start_executable();
worker->request("set_operation", "copy");
worker->request("perform_scan");
worker->request("perform_operation");
// -----------------
worker = create_worker(@"lister");
worker->delegate = self
worker->start_executable();
worker->request("set_dir", path_to_dir);
worker->request("perform_listing");
//
Test apps that I can use for demoing the new worker framework..
app#1:  run unix command.. with a textfield where you can type in stuff and a dropdown where you can select uid
app#2:  benchmark how long time it takes to spawn the helper
app#3:  kill the worker

Names that I need for this task:
host_process_library     worker_host        worker_parent     worker_main     worker_master      worker_foreground
child_process_library    worker_child       worker_child      worker_task     worker_process     worker_background


progressbars in the UI. I never managed to get it working in the when I first wrote the original copy sheet.
so this time it's the MOST important task.


use rename() when move is within the same volume.
currently we use copy followed by delete.


show dialog boxes to the user whenever there is a name conflict, so
that the user can decide what to do about the file.


run worker as a privileged process, so that permissions can be copied


follow symlinks:
- always
- top level
- never
don't follow symlinks


delete dirs after move.. what if they are not-empty, should we then delete them?
the user may have chosen to "skip" a few files, should they be deleted?
there may be subdirs such as ".svn" that was excluded, should they be deleted?
write to source dir.. while move is going on.. in this case we don't want the
source dir to be deleted.
probably best only to delete dirs if they are empty.
this could be a user preference.

when there is a directory name collision then wait replacing the dir
until all the subdirs have been copied, so that we don't loose any data


measure size of resource fork


when resource fork is stored in ._ files then use it as resource fork data the same way
as Finder does. This is on volumes that doesn't support resource fork.


html output, that nicely show status for all tests wether it has failed or completed successfully.


simulate mode.. where you can see a log of what should happen if everything
goes according to plan


case sensitive/insensitive
copy from case-sensitive filesystem to case-insensitive filesystem
copy from case-insensitive filesystem to case-sensitive filesystem


skip all which cannot be opened for reading

resume mode.. The Continue button would be very useful in case of copying from/to an FTP or from a CD with many errors, where interruptions occur and you need to restart, but you don't want to start all over from the beginning.

skip file types that cannot be read

safety of move-operations when there is a name conflict. If the user chooses "overwrite",
would it be wise to unlink the target file "after" the operation was successful?

exercise permission denied reading

exercise permission denied traversing source dir

exercise permission denied traversing target dir

exercise permission denied writing to target file

exercise permission denied opening target file

exercise out of disk space

exercise hardlinks

exercise HFS compression

overwrite if size differs




== FEATURES

Merge directories when copying/moving files

Unattended copy:
- replace all
- skip all


Append mode

auto-rename new files
auto-rename old files

replace if size is smaller
replace if size is larger

replace oldest
replace newest


exclude items from copy/move by a list of regexp patterns




