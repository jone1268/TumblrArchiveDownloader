#!/bin/bash
#download images from tumblr archives by visiting archive links to collect all images in said posts (since archive does not include multiple images from single posts)
if [ $# -eq 0 ] || ( ([ -z "$1" ] && [ -f "$1" ]) || ([ -z "$2" ] && [ -f "$2" ]) ); then
	echo "Usage: $0 [-fc] tumblrUserName/textdocument
	tumblrUserName.tumblr.com
	textdocument: Document that contains tumblrUserName on new lines
	[-fc] forceCurlOption: enter -fc for this option to force program to use Page By Page Image aquirement.
					Leave Blank for default
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

 # 	read -n 1 -p "CONTINUE?:" inp

	printf "\e[31m\e[5m[Working: Grabbing Webpage Files]\e[0m\n"


	wget -mpNHk -D .media.tumblr.com,$tumblrUserName.tumblr.com,static.tumblr.com -R "*avatar*","*\?*" http://$tumblrUserName.tumblr.com &> /dev/null

	# wget -mpNHk -D .media.tumblr.com,$tumblrUserName.tumblr.com,static.tumblr.com -R "*avatar*","*\?*","*_[0-9][0-9][0-9].*","*_[0-9][0-9][a-z][a-z].*","*_[0-9][0-9][0-9][a-z][a-z].*" http://$tumblrUserName.tumblr.com &> /dev/null


	checkCount=$(ls | wc -l)

	if [ $checkCount -le 10 ]; then
		cd ..
		rm -r $tumblrUserName
		mkdir $tumblrUserName 2> /dev/null
		cd $tumblrUserName
		wget -mpNHk -D .media.tumblr.com,$tumblrUserName.com,static.tumblr.com -R "*avatar*","*\?*" http://$tumblrUserName.com &> /dev/null
	fi

	printf "\033[A"
	printf "[Working: Grabbing Webpage Files]\t\e[32m[COMPLETE]\e[0m\n"
	END1=`date +%s`
	RUNTIMEWF=$[$END1-$START]
	echo "[Time To Retrieve Webpage Files and Images: " $(show_time $RUNTIMEWF)"]"
	#printf "\e[42m[Images Downloaded]\e[0m\n"

	for dir in ./* ; do
		if [[ "$dir" != *"78.media.tumblr.com" ]] && [[ "$dir" != *"static.tumblr.com" ]]; then
			rm -rf "$dir"
		fi
	done
	rm -r secure.static.tumblr.com 2> /dev/null

	#Error Handling to keep file structure from being destroyed

	#Check and Handle 78.media.tumblr.com directory
	printf "[Handling 78.media.tumblr.com Directory]\r"
	#printf "\033[A"
	if [ ! -z $(ls | egrep "78.media.tumblr.com") ]; then
		cd 78.media.tumblr.com
		find . -mindepth 2 -type f -exec mv {} . \;
		rm -R -- */
		cd ..
	fi
	printf "\033[K"

	#Check and Handle static.tumblr.com directory
	printf "[Handling static.tumblr.com Directory]\r"
	#printf "\033[A"
	if [ ! -z $(ls | egrep "static.tumblr.com") ]; then
		cd static.tumblr.com
		find . -mindepth 4 -type f -exec mv {} . \;
		rm -R -- */
		cd ..
	fi
	printf "\033[K"

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


	#clear all ouput from function
	printf "\033[A\033[K\033[A\033[K"

}

function curlVersion () {

	#Wget is a fucking bitch and can't get past even with some fucking bullshit cookies
	#BUT CURL IS MY MOTHER FUCKIN MAN DUDE
	#Not recursive which kind of sucks, but does what I need well which is very good still
	#Create Curl Downloader to download $tumblrUserName.tumblr.com/page/#####
	#Loop through pages until there are no images left.
	#Steps to Go through
	#	1:	Curl Page #
	#	2:	Grep through page for 78.media.tumblr.com
	#	3:	Add those links to a file
	#	4:	Repeat steps 1-3 until there are no more images for a page. (Have to look into which output i should look at)
	#	5:	Download images from file containing the links

	exitCode2=1
	while [ $exitCode2 -eq 1 ]; do
		printf "\e[1mNumber of Pages to Curl\e[0m [Enter 100 for all pages]\n"
		printf "[Enter number and press [ENTER]]: "
		read ioNum
		re='^[0-9]+$'
		if ! [[ $ioNum =~ $re ]]; then
			printf "[ERROR]: Please Enter A Number\r"
			sleep 1
			printf "\033[K"
		else
			exitCode2=0
		fi
		printf "\033[A\033[K\033[A"
	done
	printf "\033[K"
	printf "\e[1m[Working: Grabbing Webpage Files]\e[0m\n"

	curlImageList="curlImageList.txt"
	touch $curlImageList
	NUM=1
	exitCode=0
	allPagesCode=0
	if [ $ioNum -eq 100 ]; then
		tmpCounter=1
		allPagesCode=1
	else
		tmpCounter=$ioNum
	fi
	while [ $exitCode -eq 0 ] && [ $tmpCounter -gt 0 ]; do
		if [ $NUM -eq 1 ]; then
			curl -s $tumblrUserName.tumblr.com > page1
			mediaCount=$(egrep -o '78.media.tumblr.com/' page1 | wc -l)
			#echo "mediaCount: $mediaCount"
			while [ $mediaCount -gt 0 ]; do
				imageResult=$(egrep '78.media.tumblr.com/' page1 | head -$[$mediaCount])
				cutImageUrl=${imageResult##*://78.media}
				cutImageUrl=${cutImageUrl%%\"*}
				#echo "cutImageUrl: $cutImageUrl"
				cutImageUrl="78.media"$cutImageUrl
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
			avatarCount=$(egrep -o '78.media.tumblr.com/avatar' page$NUM | wc -l)
			mediaCount=$(egrep -o '78.media.tumblr.com/' page$NUM | wc -l)
			avatar68Difference=$[$mediaCount-$avatarCount]
			#echo "mediaCount: $mediaCount"
			if [ $avatar68Difference -eq 0 ]; then
				#Stop grabbing pages
				#Exit Loop
				exitCode=1
			else
				#Loop through file and add results to curlImageList.txt
				while [ $mediaCount -gt 0 ]; do
					imageResult=$(egrep '78.media.tumblr.com/' page$NUM | head -$[$mediaCount])
					cutImageUrl=${imageResult##*://78.media}
					cutImageUrl=${cutImageUrl%%\"*}
					#echo "cutImageUrl: $cutImageUrl"
					cutImageUrl="78.media"$cutImageUrl
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

	printf "\033[A\033[K"
	printf "\e[1m[Webpage Files]\e[0m\t\e[32m[COMPLETE]\e[0m\n"

	END1=`date +%s`
	RUNTIMEWF=$[$END1-$START]
	echo "[Time To Retrieve Webpage Files: " $(show_time $RUNTIMEWF)"]"
	printf "\e[31m\e[5m[Working: Downloading Images]\e[0m\n"
	noDupsCurlImageList="noDupsCurlImageList.txt"
	touch $noDupsCurlImageList
	sort -u $curlImageList >> $noDupsCurlImageList
	rm $curlImageList
	NumOfImagesCurl=$(wc -l < $noDupsCurlImageList)

	while IFS= read line; do
		printf "Images Left:\t%d\n" "$NumOfImagesCurl"
		wget $line -q --show-progress
		printf "\033[A\033[K\033[A\033[K"
		NumOfImagesCurl=$[$NumOfImagesCurl-1]
	done < "$noDupsCurlImageList"

	rm $noDupsCurlImageList

	printf "\033[A\033[K"
	printf "\e[1m[Downloading Images]\e[0m\t\e[32m[COMPLETE]\e[0m\n"

	#clear all output from function
	printf "\033[A\033[K\033[A\033[K\033[A\033[K"

}

function full_program () {

	START=`date +%s`
	tumblrUserName=$1
	forceCurlOptionFullProgram=$2
	mkdir Completed\ Archives 2> /dev/null
	mkdir $tumblrUserName 2> /dev/null
	cd $tumblrUserName

#	printf "################################################################################################\n"
#	printf "Grabbing Archive Images from $tumblrUserName.tumblr.com\n"
#	printf "################################################################################################\n"

if [ ! -z $tumblrUserName ]; then
	if [ -z $forceCurlOptionFullProgram ] && wget --spider http://$tumblrUserName.tumblr.com/ 2>/dev/null; then
		#echo "WgetVersion"
		wgetVersion
	elif [ ! -z $forceCurlOptionFullProgram ]; then
		#echo "CurlVersion | With Code"
		curlVersion
	else
		#echo "CurlVersion"
		curlVersion
	fi

#	printf "Finished [Temp]\n"

	cd ..
	cp -R $tumblrUserName Completed\ Archives

	END=`date +%s`

	SizeOfDir=$(du -h $tumblrUserName)
	NumImages=$(ls $tumblrUserName | wc -l)
	SUMIMAGES=$[$SUMIMAGES+$NumImages]
	TMPCOUNTER=$[$TMPCOUNTER+1]
	rm -r $tumblrUserName
fi
#ALSO
#Take code from previous versions (preferably V7/UpdaterCode File) for an updater function if the directory exists in Completed Archives
#Because I don't want to download all images again if I don't have to
#See about making this code easier to read and faster probs



}

#MAIN

NAMECOUNTER=0
SUMIMAGES=0
TMPCOUNTER=0
SIZEDIRS=0
SUPERSTART=`date +%s`

if [ ! -f "$1" ]; then
	if [ "$1" == "-u" ] || [ "$1" == "-U" ]; then
		#visit later
		continue
	elif [ "$1" == "-fc" ]; then
		for var2 in "$@"
		do
			if [ "$var" == "-fc" ]; then
				continue
			else
				printf "|$var2|\n"
				NAMECOUNTER=$[$NAMECOUNTER+1]
			fi
		done
		for var in "$@"
		do
			if [ "$var" == "$1" ]; then
				forceCurlOption=$1
				continue
			else
				full_program $var $forceCurlOption
			fi
		done
	else
		for var2 in "$@"
		do
			if [ "$var" == "-fc" ]; then
				continue
			else
				printf "|$var2|\n"
				NAMECOUNTER=$[$NAMECOUNTER+1]
			fi
		done
		for var in "$@"
		do
			full_program $var
			#Output Formating
			RUNTIMEP=$[$END-$START]
			printf "\033[$[$NAMECOUNTER]A\033[K"
			printf "|$var|\e[32m[COMPLETE]\e[0m[NumImages: %d][SizeDir: %s][Runtime: $(show_time $RUNTIMEP)]""\r" "$NumImages" "$SizeOfDir"
			printf "\033[$[$NAMECOUNTER]B"
			NAMECOUNTER=$[$NAMECOUNTER-1]
		done
	fi
elif [ -f "$1" ]; then
	infile=$1
	sed -i '' -e '$a\' $1
	#ARRAYSIZE=$(wc -l < $infile)
	#argsArray[$ARRAYSIZE]
	while IFS= read -r line; do
		printf "|$line|\n"
		argsArray[$NAMECOUNTER]="$line"
		NAMECOUNTER=$[$NAMECOUNTER+1]
	done < "$infile"

	for var in "${argsArray[@]}"
	do
		full_program $var
		#Output Formating
		RUNTIMEP=$[$END-$START]
		printf "\033[$[$NAMECOUNTER]A\033[K"
		printf "|$var|\e[32m[COMPLETE]\e[0m[NumImages: %d][SizeDir: %s][Runtime: $(show_time $RUNTIMEP)]""\r" "$NumImages" "$SizeOfDir"
		printf "\033[$[$NAMECOUNTER]B"
		NAMECOUNTER=$[$NAMECOUNTER-1]
	done
fi

SUPEREND=`date +%s`
TOTALRUNTIME=$[$SUPEREND-$SUPERSTART]
echo "[Total Runtime of Program: " "$(show_time $TOTALRUNTIME)""]"
echo "[Number of Archives: $TMPCOUNTER]"
echo "[Total Images Downloaded Successfully: $SUMIMAGES]"

printf "[END OF PROGRAM]\n"
#Maxwell Jones 2017
