#!/bin/bash

fileList="fileList.txt"
	for file in **; do
		[[ -f "$file" ]] || continue
		echo "$file" >> $fileList
	done
	imagesToCompare="imagesToCompare.txt"
	imagesToCompareDups="imagesToCompareDups.txt"
	touch $imagesToCompare $imagesToCompareDups
	file="$fileList"
	while IFS= read line; do
		nameCheck=$line
		nameCheck=${nameCheck%_[0-9]**}
		echo "$nameCheck" >> $imagesToCompareDups
	done < "$file"
	# read -n 1 -p "DUPS:" inp
	# echo $inp
	sort -u $imagesToCompareDups >> $imagesToCompare
	# read -n 1 -p "SORT?:" inp
	# echo $inp
	file="$imagesToCompare"

	printf "[Working: Handling Duplicates]\r"
	printf "\033[K"

	while IFS= read line; do
		countOccurance=$(egrep -o $line $imagesToCompareDups | wc -l)
		if [ $countOccurance -gt 1 ]; then
			if [[ $line == *"tumblr_static"* ]]; then
				searchString=$line"_[0-9][0-9][0-9]_.*"
				fileToDelete=$(egrep -h $searchString $fileList)
				#echo "fileToDelete: $fileToDelete"
				rm $fileToDelete 2> /dev/null
			else
				searchString=$line"_[0-9][0-9][0-9].*"
				fileToDelete=$(egrep -h $searchString $fileList | head -1)
				echo "fileToDelete: $fileToDelete"
				rm $fileToDelete 2> /dev/null
			fi
		fi
	done < "$file"
	rm $imagesToCompare $imagesToCompareDups $fileList *inline* 2> /dev/null