#! /bin/sh
git fetch --prune
DELBRANCH=$(git branch -r --merged origin/main | grep -v -e develop -e dev -e prod -e HEAD | sed 's/origin\///')
if [ "$DELBRANCH" ]; then
    echo deleting branch $DELBRANCH
    # git push origin --delete $DELBRANCH
fi


for k in $(git branch -r | grep -v -e develop -e dev -e prod -e HEAD | sed /\*/d); do 
  if [ -z "$(git log -1 --since='200 days ago' -s $k)" ]; then
    echo "$k" >> prune.txt
  fi
done

RESULT=$(cat prune.txt 2>/dev/null)

if [ "$RESULT" ]; then
    echo Hello Service-Transcode team, 
    echo 'Kindly prune the following old branches (last commit date in bracket):'
    git for-each-ref --sort=-committerdate refs/remotes/ --format='%(refname:short) %(authorname) %(committerdate:relative)' | grep -f prune.txt
fi

# curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' ${{ secrets.SLACK_WEBHOOK }}
