# Newton Commander

A dual tab file manager for Mac OS X.

### Stabile features
- Each tab runs in its own child process. 
- Closing a tab kills the child process.
- Copy operation

### Experimental features
- A tab can be started as a different user, allowing you to see otherwise restricted files.
- Move operation


### Screenshot
![Screenshot of copy sheet](http://i.imgur.com/gtQisaE.png)
![Screenshot of child-process running as root](http://i.imgur.com/NNVUq6m.jpg)


# Build Instructions

Prerequisites
- Xcode 5.0.2 (5A3005)
- OS X 10.9.x or 10.8.x

Follow these steps
- Open the `NewtonCommander.xcodeproj` in the root folder.
- Compile and run.
- Enter your admin password, so that worker process can run.


