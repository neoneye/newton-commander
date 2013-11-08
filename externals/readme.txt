
Procedure for adding new externals


[ 18:38:45 ~/git/Work ] $ git submodule add git://github.com/TouchCode/TouchJSON.git externals/TouchJSON
Cloning into externals/TouchJSON...
remote: Counting objects: 1528, done.
remote: Compressing objects: 100% (523/523), done.
remote: Total 1528 (delta 935), reused 1472 (delta 892)
Receiving objects: 100% (1528/1528), 3.35 MiB | 609 KiB/s, done.
Resolving deltas: 100% (935/935), done.
[ 18:39:14 ~/git/Work ] $


[ 18:38:45 ~/git/Work ] $ git submodule add git://github.com/psychs/cocoaoniguruma.git externals/cocoaoniguruma
Cloning into externals/TouchJSON...
remote: Counting objects: 1528, done.
remote: Compressing objects: 100% (523/523), done.
remote: Total 1528 (delta 935), reused 1472 (delta 892)
Receiving objects: 100% (1528/1528), 3.35 MiB | 609 KiB/s, done.
Resolving deltas: 100% (935/935), done.
[ 18:39:14 ~/git/Work ] $



Procedure for updating externals

git submodule init
git submodule update



Procedure for updateing all submodules to the HEAD version

git submodule foreach git pull origin master