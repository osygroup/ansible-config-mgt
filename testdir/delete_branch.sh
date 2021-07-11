#! /bin/sh
if [ DELBRANCH=$(git branch -r | grep -e testdel -e pier | sed 's/origin\///') ]; then
    git push origin --delete $DELBRANCH
fi
