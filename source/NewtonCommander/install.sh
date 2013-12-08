#!/bin/sh

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

# repair permissions
$CHOWN root:wheel "$THEFILE"
$CHMOD 4555 "$THEFILE"

exit 0
