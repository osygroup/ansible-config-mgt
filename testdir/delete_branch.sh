#! /bin/sh
DELBRANCH=$(git branch -r | grep -e testdel -e pier | sed 's/origin\///')
if [[ "$DELBRANCH" ]]; then
    git push origin --delete $DELBRANCH
fi
