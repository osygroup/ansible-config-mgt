#! /bin/sh

for k in $(git branch -r | grep -v -e develop -e dev -e prod -e HEAD -e master | sed /\*/d); do 
  if [ -z "$(git log --since='60 days ago' -s $k)" ]; then
    echo "$k" >> prune.txt
  fi
done

git for-each-ref --sort=-committerdate refs/remotes/ --format='%(refname:short) %(authorname) (%(committerdate:relative))' | grep -w -f prune.txt >> list.txt

curl -F file=@list.txt -F "initial_comment=Hello Service-Transcode team, kindly prune the following old branches (last commit date in bracket):" -F channels=C0294EZMK9N -H "Authorization: Bearer xoxb-2272093962023-2274771267591-7PnEiANCSZnH1HbGRQGRVZEu" https://slack.com/api/files.upload