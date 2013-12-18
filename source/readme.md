# Project Overview

Newton Commander consists of multiple Xcode projects.

    NewtonCommander/NewtonCommander.xcodeproj
	This is the main project that builds the entire app.
	
	NCWorker/NCWorker.xcodeproj
	This project builds the worker child process.
	
	SharedCode Core+Worker/SharedCode Core+Worker.xcodeproj
	This is code shared between the the main app and its child processes.
	
	NCCore/NCCore.xcodeproj
	This is custom views and utilities used by the NewtonCommander.xcodeproj	

