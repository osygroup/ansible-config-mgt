#! /bin/sh
DELBRANCH=$(git branch -r | grep -e testdel -e pier | sed 's/origin\///')
BRANCH=$(DELBRANCH 2>/dev/null)
if [[ "$BRANCH" -gt "0" ]]; then
    git push origin --delete $DELBRANCH
fi
