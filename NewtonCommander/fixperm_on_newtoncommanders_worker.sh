#!/bin/sh

#
# Newton Commander - helper script for SETUID
# Copyright 2010 - Simon Strandgaard <simon@opcoder.com>, All rights reserved.
#
# PURPOSE: 
# This script is used to set the SETUID bit on NCWorker (Newton Commander's helper program)
#
# you can do the following by typing: sudo visudo
# this way you can add the following line to your /etc/sudoers
# neoneye  ALL=(ALL) NOPASSWD: /usr/bin/fixperm_on_newtoncommanders_worker.sh
#
#
# USAGE:
# sudo /usr/bin/fixperm_on_newtoncommanders_worker.sh /some/long/path/to/executable/to/setuid/bit/on
#
#

sudo -n true
if [ "$?" -ne "0" ]
then
	echo "ERROR: cannot sudo. This script must be added to /etc/sudoers in order to work"
	exit 1
fi

if [ "$#" -ne "1" ]
then
  echo "ERROR: wrong number of arguments"
  exit 1
fi

THEFILE=$1

if [ ! -f "$THEFILE" ]
then
  echo "ERROR: file does not exist"
  exit 1
fi

CHOWN=/usr/sbin/chown
CHMOD=/bin/chmod

echo "BEFORE"
ls -la "$THEFILE"

echo "running CHOWN"
sudo -n $CHOWN root:wheel "$THEFILE"

echo "running CHMOD"
sudo -n $CHMOD 4555 "$THEFILE"

echo "AFTER"
ls -la "$THEFILE"

exit 0
