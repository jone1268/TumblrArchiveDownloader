#!/bin/bash
#download images from tumblr archives by visiting archive links to collect all images in said posts (since archive does not include multiple images from single posts)
if [ $# -eq 0 ] || ([ -z "$1" ] && [ -f "$1" ]); then
	echo "Usage: $0 tumblrUserName/textdocument
	tumblrUserName.tumblr.com
	textdocument: Document that contains tumblrUserName on new lines
	Downloads all images from given Tumble User's Archive
	Updates exisiting directories if images are missing"
	exit
fi

#Make adjustment to rename all image links with 1280 for highest resolution available


function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"m "$sec"s
}

function wgetVersion () {
	wget -mpNHk -D .media.tumblr.com,$tumblrUserName.tumblr.com,static.tumblr.com -R "*avatar*","*\?*" http://$tumblrUserName.tumblr.com &> /dev/null
	END1=`date +%s`
	RUNTIME=$[$END1-$START]
	echo "[Time To Retrieve Webpage Files and Images: " $(show_time $RUNTIME)"]"
	echo "[Images Downloaded]"
	echo "[Working: Handling Files]"
	#printf "\033[A"

	for dir in ./* ; do
		if [[ "$dir" != *"68.media.tumblr.com" ]] && [[ "$dir" != *"static.tumblr.com" ]]; then
			rm -rf "$dir"
		fi
	done
	rm -r secure.static.tumblr.com 2> /dev/null

	#Error Handling to keep file structure from being destroyed

	#Check and Handle 68.media.tumblr.com directory
	echo "[Handling 68.media.tumblr.com Directory]"
	#printf "\033[A"
	if [ ! -z $(ls | egrep "68.media.tumblr.com") ]; then
		cd 68.media.tumblr.com
		find . -mindepth 2 -type f -exec mv {} . \;
		rm -R -- */
		cd ..
	fi
		
	#Check and Handle static.tumblr.com directory
	echo "[Handling static.tumblr.com Directory]"
	#printf "\033[A"
	if [ ! -z $(ls | egrep "static.tumblr.com") ]; then
		cd static.tumblr.com
		find . -mindepth 4 -type f -exec mv {} . \;
		rm -R -- */
		cd ..
	fi

	find . -mindepth 2 -type f -exec mv {} . \;
	rm -R -- */
		
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
	sort -u $imagesToCompareDups >> $imagesToCompare
	file="$imagesToCompare"
	echo "[Working: Handling Duplicates]"
	#printf "\033[A"
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
				#echo "fileToDelete: $fileToDelete"
				rm $fileToDelete 2> /dev/null
			fi
		fi
	done < "$file"
	rm $imagesToCompare $imagesToCompareDups $fileList *inline* 2> /dev/null

}

function curlVersion () {
	#Wget is a fucking bitch and can't get past even with some fucking bullshit cookies
	#BUT CURL IS MY MOTHER FUCKIN MAN DUDE
	#Not recursive which kind of sucks, but does what I need well which is very good still
	#Create Curl Downloader to download $tumblrUserName.tumblr.com/page/#####
	#Loop through pages until there are no images left.
	#Steps to Go through
	#	1:	Curl Page #
	#	2:	Grep through page for 68.media.tumblr.com
	#	3:	Add those links to a file
	#	4:	Repeat steps 1-3 until there are no more images for a page. (Have to look into which output i should look at)
	#	5:	Download images from file containing the links

	printf "Naughty Naughty\n"

	exitCode2=1
	while [ $exitCode2 -eq 1 ]; do
		printf "Number of Pages to Curl [Enter -1 for all pages]\n"
		printf "[Enter number and press [ENTER]]: "
		read ioNum
		re='^[0-9]+$'
		if ! [[ $ioNum =~ $re ]]; then
			echo "[ERROR]: Please Enter A Number"
		else
			exitCode2=0
		fi
	done
	printf "[Working: Grabbing Webpage Files]\n"
	exit
	#printf "\033[A"
	curlImageList="curlImageList.txt"
	touch $curlImageList
	NUM=1
	exitCode=0
	allPagesCode=0
	if [ $ioNum -eq -1 ]; then
		tmpCounter=1
		allPagesCode=1
	else
		tmpCounter=$ioNum
	fi
	while [ $exitCode -eq 0 ] && [ $tmpCounter -gt 0 ]; do
		if [ $NUM -eq 1 ]; then
			curl -s $tumblrUserName.tumblr.com > page1
			mediaCount=$(egrep -o '68.media.tumblr.com/' page1 | wc -l)
			#echo "mediaCount: $mediaCount"
			while [ $mediaCount -gt 0 ]; do
				imageResult=$(egrep '68.media.tumblr.com/' page1 | head -$[$mediaCount])
				cutImageUrl=${imageResult##*://68.media}
				cutImageUrl=${cutImageUrl%%\"*}
				#echo "cutImageUrl: $cutImageUrl"
				cutImageUrl="68.media"$cutImageUrl
				#echo "cutImageUrl: $cutImageUrl"
				ImageExt=${cutImageUrl##*.}
				PreImage=${cutImageUrl%_[0-9]*}
				cutImageUrl="$PreImage""_1280.""$ImageExt"
				if [[ $cutImageUrl != *"avatar"* ]] && [[ $cutImageUrl != *"inline"* ]]; then
					echo "$cutImageUrl" >> $curlImageList
				fi
				mediaCount=$[$mediaCount-1]
			done
			rm page1
		else
			curl -s $tumblrUserName.tumblr.com/page/$NUM > page$NUM
			#Check if page has nothing
			avatarCount=$(egrep -o '68.media.tumblr.com/avatar' page$NUM | wc -l)
			mediaCount=$(egrep -o '68.media.tumblr.com/' page$NUM | wc -l)
			avatar68Difference=$[$mediaCount-$avatarCount]
			#echo "mediaCount: $mediaCount"
			if [ $avatar68Difference -eq 0 ]; then
				#Stop grabbing pages
				#Exit Loop
				exitCode=1
			else
				#Loop through file and add results to curlImageList.txt
				while [ $mediaCount -gt 0 ]; do
					imageResult=$(egrep '68.media.tumblr.com/' page$NUM | head -$[$mediaCount])
					cutImageUrl=${imageResult##*://68.media}
					cutImageUrl=${cutImageUrl%%\"*}
					#echo "cutImageUrl: $cutImageUrl"
					cutImageUrl="68.media"$cutImageUrl
					#echo "cutImageUrl: $cutImageUrl"
					ImageExt=${cutImageUrl##*.}
					PreImage=${cutImageUrl%_[0-9]*}
					cutImageUrl="$PreImage""_1280.""$ImageExt"
					if [[ $cutImageUrl != *"avatar"* ]] && [[ $cutImageUrl != *"inline"* ]]; then
						echo "$cutImageUrl" >> $curlImageList
					fi
					mediaCount=$[$mediaCount-1]
				done
			fi
			rm page$NUM
		fi
		printf "Grabbing Page: \e[36m%d\n\e[0m" "$NUM"
		printf "\033[A"
		if [ $allPagesCode -eq 0 ]; then
			tmpCounter=$[$tmpCounter-1]
		fi
		NUM=$[$NUM+1]
	done
	
	printf "\033[A"
	printf "[Working: Grabbing Webpage Files]\t\e[32m[COMPLETE]\e[0m\n"
		
	END1=`date +%s`
	RUNTIME=$[$END1-$START]
	echo "[Time To Retrieve Webpage Files: " $(show_time $RUNTIME)"]"
	printf "\e[31m\e[5m[Working: Downloading Images]\e[0m\n"
	noDupsCurlImageList="noDupsCurlImageList.txt"
	touch $noDupsCurlImageList
	sort -u $curlImageList >> $noDupsCurlImageList
	rm $curlImageList
	NumOfImagesCurl=$(wc -l < $noDupsCurlImageList)
	tmpNumC=$NumOfImagesCurl
	tmpNumC=$[$tmpNumC/10]
	strFormat=""
	while [ $tmpNumC -gt 0 ]; do
		strFormat=$strFormat" "
		tmpNumC=$[$tmpNumC/10]
	done
	
	while IFS= read line; do
		printf "Images Left:\t%d%s\n" "$NumOfImagesCurl" "$strFormat"
		wget -nc $line -q --show-progress
		printf "\033[A"
		printf "\033[A"
		NumOfImagesCurl=$[$NumOfImagesCurl-1]
	done < "$noDupsCurlImageList"

	rm $noDupsCurlImageList

	printf "\033[A"
	printf "\033[K"
	printf "[Downloading Images]\t\e[32m[COMPLETE]\e[0m\n"
}

function full_program () {

	START=`date +%s`
	tumblrUserName=$1
	mkdir Completed\ Archives
	printf "################################################################################################\nGrabbing Archive Images from $tumblrUserName.tumblr.com\n################################################################################################\n"	
	mkdir $tumblrUserName
	cd $tumblrUserName
if [ ! -z $tumblrUserName ]; then
	if wget --spider http://$tumblrUserName.tumblr.com/ 2>/dev/null; then
		#wgetVersion


		wget -mpNHk -D .media.tumblr.com,$tumblrUserName.tumblr.com,static.tumblr.com -R "*avatar*","*\?*" http://$tumblrUserName.tumblr.com &> /dev/null
		END1=`date +%s`
		RUNTIME=$[$END1-$START]
		echo "[Time To Retrieve Webpage Files and Images: " $(show_time $RUNTIME)"]"
		echo "[Images Downloaded]"
		echo "[Working: Handling Files]"
		#printf "\033[A"

		for dir in ./* ; do
			if [[ "$dir" != *"68.media.tumblr.com" ]] && [[ "$dir" != *"static.tumblr.com" ]]; then
				rm -rf "$dir"
			fi
		done
		rm -r secure.static.tumblr.com 2> /dev/null

		#Error Handling to keep file structure from being destroyed

		#Check and Handle 68.media.tumblr.com directory
		echo "[Handling 68.media.tumblr.com Directory]"
		#printf "\033[A"
		if [ ! -z $(ls | egrep "68.media.tumblr.com") ]; then
			cd 68.media.tumblr.com
			find . -mindepth 2 -type f -exec mv {} . \;
			rm -R -- */
			cd ..
		fi
		
		#Check and Handle static.tumblr.com directory
		echo "[Handling static.tumblr.com Directory]"
		#printf "\033[A"
		if [ ! -z $(ls | egrep "static.tumblr.com") ]; then
			cd static.tumblr.com
			find . -mindepth 4 -type f -exec mv {} . \;
			rm -R -- */
			cd ..
		fi

		find . -mindepth 2 -type f -exec mv {} . \;
		rm -R -- */
		
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
		sort -u $imagesToCompareDups >> $imagesToCompare
		file="$imagesToCompare"
		echo "[Working: Handling Duplicates]"
		#printf "\033[A"
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
					#echo "fileToDelete: $fileToDelete"
					rm $fileToDelete 2> /dev/null
				fi
			fi
		done < "$file"
		rm $imagesToCompare $imagesToCompareDups $fileList *inline* 2> /dev/null

	else
		#Wget is a fucking bitch and can't get past even with some fucking bullshit cookies
		#BUT CURL IS MY MOTHER FUCKIN MAN DUDE
		#Not recursive which kind of sucks, but does what I need well which is very good still
		#Create Curl Downloader to download $tumblrUserName.tumblr.com/page/#####
		#Loop through pages until there are no images left.
		#Steps to Go through
		#	1:	Curl Page #
		#	2:	Grep through page for 68.media.tumblr.com
		#	3:	Add those links to a file
		#	4:	Repeat steps 1-3 until there are no more images for a page. (Have to look into which output i should look at)
		#	5:	Download images from file containing the links

		printf "Naughty Naughty\n"

		exitCode2=1
		while [ $exitCode2 -eq 1 ]; do
			printf "Number of Pages to Curl [Enter -1 for all pages]\n"
			printf "[Enter number and press [ENTER]]: "
			read ioNum
			re='^[0-9]+$'
			if ! [[ $ioNum =~ $re ]]; then
				echo "[ERROR]: Please Enter A Number"
			else
				exitCode2=0
			fi
		done
		printf "[Working: Grabbing Webpage Files]\n"
		exit
		#printf "\033[A"
		curlImageList="curlImageList.txt"
		touch $curlImageList
		NUM=1
		exitCode=0
		allPagesCode=0
		if [ $ioNum -eq -1 ]; then
			tmpCounter=1
			allPagesCode=1
		else
			tmpCounter=$ioNum
		fi
		while [ $exitCode -eq 0 ] && [ $tmpCounter -gt 0 ]; do
			if [ $NUM -eq 1 ]; then
				curl -s $tumblrUserName.tumblr.com > page1
				mediaCount=$(egrep -o '68.media.tumblr.com/' page1 | wc -l)
				#echo "mediaCount: $mediaCount"
				while [ $mediaCount -gt 0 ]; do
					imageResult=$(egrep '68.media.tumblr.com/' page1 | head -$[$mediaCount])
					cutImageUrl=${imageResult##*://68.media}
					cutImageUrl=${cutImageUrl%%\"*}
					#echo "cutImageUrl: $cutImageUrl"
					cutImageUrl="68.media"$cutImageUrl
					#echo "cutImageUrl: $cutImageUrl"
					ImageExt=${cutImageUrl##*.}
					PreImage=${cutImageUrl%_[0-9]*}
					cutImageUrl="$PreImage""_1280.""$ImageExt"
					if [[ $cutImageUrl != *"avatar"* ]] && [[ $cutImageUrl != *"inline"* ]]; then
						echo "$cutImageUrl" >> $curlImageList
					fi
					mediaCount=$[$mediaCount-1]
				done
				rm page1
			else
				curl -s $tumblrUserName.tumblr.com/page/$NUM > page$NUM
				#Check if page has nothing
				avatarCount=$(egrep -o '68.media.tumblr.com/avatar' page$NUM | wc -l)
				mediaCount=$(egrep -o '68.media.tumblr.com/' page$NUM | wc -l)
				avatar68Difference=$[$mediaCount-$avatarCount]
				#echo "mediaCount: $mediaCount"
				if [ $avatar68Difference -eq 0 ]; then
					#Stop grabbing pages
					#Exit Loop
					exitCode=1
				else
					#Loop through file and add results to curlImageList.txt
					while [ $mediaCount -gt 0 ]; do
						imageResult=$(egrep '68.media.tumblr.com/' page$NUM | head -$[$mediaCount])
						cutImageUrl=${imageResult##*://68.media}
						cutImageUrl=${cutImageUrl%%\"*}
						#echo "cutImageUrl: $cutImageUrl"
						cutImageUrl="68.media"$cutImageUrl
						#echo "cutImageUrl: $cutImageUrl"
						ImageExt=${cutImageUrl##*.}
						PreImage=${cutImageUrl%_[0-9]*}
						cutImageUrl="$PreImage""_1280.""$ImageExt"
						if [[ $cutImageUrl != *"avatar"* ]] && [[ $cutImageUrl != *"inline"* ]]; then
							echo "$cutImageUrl" >> $curlImageList
						fi
						mediaCount=$[$mediaCount-1]
					done
				fi
				rm page$NUM
			fi
			printf "Grabbing Page: \e[36m%d\n\e[0m" "$NUM"
			printf "\033[A"
			if [ $allPagesCode -eq 0 ]; then
				tmpCounter=$[$tmpCounter-1]
			fi
			NUM=$[$NUM+1]
		done
		
		printf "\033[A"
		printf "[Working: Grabbing Webpage Files]\t\e[32m[COMPLETE]\e[0m\n"
		
		END1=`date +%s`
		RUNTIME=$[$END1-$START]
		echo "[Time To Retrieve Webpage Files: " $(show_time $RUNTIME)"]"
		printf "\e[31m\e[5m[Working: Downloading Images]\e[0m\n"
		noDupsCurlImageList="noDupsCurlImageList.txt"
		touch $noDupsCurlImageList
		sort -u $curlImageList >> $noDupsCurlImageList
		rm $curlImageList
		#printf "\033[A"
		NumOfImagesCurl=$(wc -l < $noDupsCurlImageList)
		tmpNumC=$NumOfImagesCurl
		tmpNumC=$[$tmpNumC/10]
		strFormat=""
		while [ $tmpNumC -gt 0 ]; do
			strFormat=$strFormat" "
			tmpNumC=$[$tmpNumC/10]
		done
		
		while IFS= read line; do
			printf "Images Left:\t%d%s\n" "$NumOfImagesCurl" "$strFormat"
			wget -nc $line -q --show-progress
			printf "\033[A"
			printf "\033[A"
			
			NumOfImagesCurl=$[$NumOfImagesCurl-1]
		done < "$noDupsCurlImageList"

		rm $noDupsCurlImageList
		printf "\033[A"
		printf "\033[K"
		printf "[Downloading Images]\t\e[32m[COMPLETE]\e[0m\n"
	fi
	
	exit

	cd ..
	cp -R $tumblrUserName Completed\ Archives
	END=`date +%s`
	NumImages=$(ls $tumblrUserName | wc -l)
	SUMIMAGES=$[$SUMIMAGES+$NumImages]
	echo "Number of Images Downloaded: $NumImages"
	SizeOfDir=$(du -h $tumblrUserName)
	echo "Size of Image Folder: $SizeOfDir"
	RUNTIME=$[$END-$START]
	echo "Runtime of Program: " $(show_time $RUNTIME)
	rm -r $tumblrUserName
	TMPCOUNTER=$[$TMPCOUNTER+1]
fi
#ALSO
#Take code from previous versions (preferably V7) for an updater function if the directory exists in Completed Archives
#Because I don't want to download all images again if I don't have to
#See about making this code easier to read and faster probs



}

count_total_dir_images () {
	DL="DirListingForImageCount.txt"
	ls Completed\ Archives > $DL
	sed -i '' -e '$a\' $DL
	totalImages=0
	while IFS= read -r line; do
		tmpImageCount=$(ls Completed\ Archives/$line | wc -l)
		echo "$line: $tmpImageCount"
		totalImages=$[$totalImages+tmpImageCount]
	done < "$DL"
	echo "Total Image Count: $totalImages"
	rm $DL
}

function UpdateCompleteDirectories () {
	DirListing="DirListing.txt"
	ls Completed\ Archives > $DirListing
	cat $DirListing
	sed -i '' -e '$a\' $DirListing
	UpdateAll=0
	count_total_dir_images
	while IFS= read -r line; do
		read -p "Update: $line ? [Y/N/(E)nd]: " userInput </dev/tty
		echo "userInput: $userInput"
		case $userInput in
			[Yy]*) 
					full_program $line
					;;
			[Nn]*) 
					echo "Not Updating $line"
					;; #Don't update, move to next
	#		[Aa]*) 	##change to be separate from if statement. Have it be an argument for exec
	#				UpdateAll=1
	#				echo "Updating All Directories"
	#				echo "$totalImages"
	#				estTime=$(echo "scale=6; 6/10000*$totalImages" | bc)
	#				echo "EST: $estTime hour(s)"
	#				full_program $line
	#				;;
			[Ee]*)
					echo "[Ending Updating Opperation]"
					rm $DirListing
					exit
					;;
			*)
					echo "Bad Input. Not Upadating: $line"
					;;
		esac
	done < "$DirListing"
	rm $DirListing
}

SUMIMAGES=0
TMPCOUNTER=0
SUPERSTART=`date +%s`

if [ ! -f "$1" ]; then
	if [ "$1" == "-u" ] || [ "$1" == "-U" ]; then
		UpdateCompleteDirectories
	else
		for var in "$@"
		do
			full_program $var
		done
	fi
elif [ -f "$1" ]; then
	infile=$1
	sed -i '' -e '$a\' $1
	while IFS= read -r line; do
		full_program $line
	done < "$infile"
fi

SUPEREND=`date +%s`
TOTALRUNTIME=$[$SUPEREND-$SUPERSTART]
echo "Total of Program: " $(show_time $TOTALRUNTIME)
echo "Number of Archives: $TMPCOUNTER"
echo "Total Images Downloaded Successfully: $SUMIMAGES"
echo "Images Downloaded from:"

if [ ! -f "$1" ]; then
	for var2 in "$@"
	do
		echo "$var2"
	done
elif [ -f "$1" ]; then
	infile=$1
	while IFS= read -r line; do
		echo "$line"
	done < "$infile"
fi

printf "\n[END OF PROGRAM]\n"
#Maxwell Jones ©2017
#This code can be used with proper citation