#!/bin/bash
#download images from tumblr archives by visiting archive links to collect all images in said posts (since archive does not include multiple images from single posts)
if [ $# -eq 0 ] || ([ -z "$1" ] && [ -f "$1" ]); then
	echo "Usage: $0 bestGirl/textdocument
	http://a-titty-ninja.tumblr.com/bestgirls/$bestGirl
	textdocument: Document that contains bestGirl on new lines
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


function full_program () {

	START=`date +%s`
	bestGirl=$1
	mkdir Best\ Girls 2> /dev/null
	mkdir $bestGirl 2> /dev/null
	cd $bestGirl
	if [ ! -z $bestGirl ]; then
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
		#http://a-titty-ninja.tumblr.com/bestgirls
		tURL=http://a-titty-ninja.tumblr.com/tagged/$bestGirl
		#printf "\033[A"
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
				curl -s $tURL > page1
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
				curl -s $tURL/page/$NUM > page$NUM
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
	fi

	cd ..
	cp -R $bestGirl Best\ Girls

	END=`date +%s`
	
	SizeOfDir=$(du -h $bestGirl)
	NumImages=$(ls $bestGirl | wc -l)
	SUMIMAGES=$[$SUMIMAGES+$NumImages]
	TMPCOUNTER=$[$TMPCOUNTER+1]
	rm -r $bestGirl
}


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
#Maxwell Jones ©2017
#This code can be used with proper citation