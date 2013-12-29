#!/bin/sh

cd $TARGET_BUILD_DIR
cd Newton\ Commander.app/Contents

if [ -f "MacOS/NewtonCommanderHelper" ]; then
  #echo "File exists"
  exit 0
else
  #echo "File does not exists"
  cp "Resources/NewtonCommanderBrowse.bundle/Contents/Resources/NewtonCommanderHelper" MacOS/.
  exit 0
fi
