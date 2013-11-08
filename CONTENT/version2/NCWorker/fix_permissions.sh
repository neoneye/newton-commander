echo 'before fix of permissions'
ls -la NCWorker

echo 'fixing permissions'
sudo chown root NCWorker
# sudo chgrp wheel NCWorker
# sudo chmod 6755 NCWorker
sudo chmod 4755 NCWorker

echo 'after fix of permissions'
ls -la NCWorker