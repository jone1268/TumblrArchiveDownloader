#!/bin/bash
webfile=$1
#NumOfLines=$(egrep -o '/tagged/[a-z]*[A-Z]*"><img' $webfile | wc -l)
#echo "NumOfLines: $NumOfLines"
NumOfGirls=$(egrep -o '/tagged/[a-zA-Z-]*"><img' $webfile | wc -l)
echo "Number of Girls: $NumOfGirls"
fileName="BestGirls.txt"
touch $fileName
while [ $NumOfGirls -gt 0 ]; do
	line=$(egrep -o '/tagged/[a-zA-Z-]*"><img' $webfile | head -$[$NumOfGirls])
	#echo $line
	#cut string
	linecut=${line##*/tagged/}
	linecut2=${linecut%%\"><img}
	#echo "LineCut2: $linecut2"
	alreadyInFile=$(egrep $linecut2 $fileName)
	#echo "already in file: $alreadyInFile"
	if [ -z "$alreadyInFile" ]; then
		echo "$linecut2" >> $fileName
	fi
	NumOfGirls=$[$NumOfGirls-1]
done