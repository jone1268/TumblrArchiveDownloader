#!/bin/bash
webfile=$1
NumOfLines=$(egrep -o '"name-link"' $webfile | wc -l)
echo "NumOfLines: $NumOfLines"
followerPage=$(egrep 'data-page-root' $webfile)
followerPage=${followerPage#*following/}
followerPage=${followerPage%%\"*}
echo "FollowerPage: $followerPage"
y=25
NUM=$(($followerPage / $y))
NUM=$[$NUM+1]
line=$(egrep '"name-link"' $webfile)
while [ $NumOfLines -gt 0 ]; do
	line=${line#*\"name-link\"}
	linecut2=${line%%.tumblr*}
	linecut3=${linecut2##*//}
	echo "$linecut3" >> usersDoc$NUM.txt
	NumOfLines=$[$NumOfLines-1]
done