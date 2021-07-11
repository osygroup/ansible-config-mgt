#! /bin/sh
DELBRANCH=$(git branch -r | grep -e testdel -e pier | sed 's/origin\///' 2>/dev/null)
if [ "$DELBRANCH" -gt "0" ]; then
    git push origin --delete $gest
fi
