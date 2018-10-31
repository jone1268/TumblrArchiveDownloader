#!/bin/bash

DIR="dir"
readFile="ReadFile.txt"
numFiles=$(ls $DIR | wc -l)
index=1

cd $DIR
for file in *
do
	mv -v "$file" "tfile_$index"
	index=$[$index+1]
done