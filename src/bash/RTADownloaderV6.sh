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

function full_program () {

	mkdir Completed\ Archives
	START=`date +%s`
	tumblrUserName=$1

	DIR="$tumblrUserName""tmp"
	mkdir $DIR
	cd $DIR

	printf "################################################################################################\nGrabbing Archive Webpage from $tumblrUserName.tumblr.com/archive\n################################################################################################\n"

	#grab archive webpage
	if wget --spider http://$tumblrUserName.tumblr.com/archive 2>/dev/null; then
		echo "Working: Retrieving Webpage Files"
		wget -r -nd http://$tumblrUserName.tumblr.com/archive/ -q
		END1=`date +%s`
		RUNTIME=$[$END1-$START]

		

		echo "Time To Retrieve Webpage Files: " $(show_time $RUNTIME)
		printf "#######################\n"
		printf "Searching Webpage Files\n"
		printf "#######################\n"
		#Directory Management
		rm index.html robots.txt
		cd ..
		ls $DIR > $tumblrUserName.txt
		mv $tumblrUserName.txt $DIR
		cd $DIR
		tumblrUserNameImageDir="$tumblrUserName""ImageDir"
		mkdir $tumblrUserNameImageDir
		CUTPOINT="\"og:image\" content=\""
		file="$tumblrUserName.txt"
		imagelinkstempfile="imagelinkstempfile.txt"
		touch $imagelinkstempfile
		imagenamestempfile="imagenamestempfile.txt"
		touch $imagenamestempfile
		#Read file to read other files in Directory
		sed -i -e '$a\' $file


		while IFS= read line; do
			#echo "File being read: $line"
			NumberOfLinesOGImage=$(egrep -c '"og:image"' $line)
			#echo "Number of Lines og:image: $NumberOfLinesOGImage"
			NumberOfImages=$(egrep -o '"og:image"' $line | wc -l)
			#echo "Number of Images: $NumberOfImages"
			#ImageSlash=$(egrep 'image/' $line)
			#echo "ImageSlash: $ImageSlash"
			ImageSlashNum=$(egrep -o 'image/[0-9]*\"' $line | wc -l)
			#quickly work on ImageSlash URLS
			while [ $ImageSlashNum -gt 0 ]; do
				ImageSlash=$(egrep 'image/[0-9]*\"' $line | head -$[$ImageSlashNum])
				#echo "ImageSlash: $ImageSlash"
				tmpCut="img src=\""
				ImageSlash=${ImageSlash##*$tmpCut}
				ImageSlash=${ImageSlash%%\"*}
				ImageExt=${ImageSlash##*.}
				PreImage=${ImageSlash%_[0-9]*}
				_1280ImageLink="$PreImage""_1280.""$ImageExt"
				#echo "_1280ImageLink: $_1280ImageLink"
				if [[ "$_1280ImageLink" != *"<a href="* ]]; then
					LineExists2=$(grep $_1280ImageLink $imagelinkstempfile)
				fi
				if [ -z "$LineExists2" ]; then
					if [[ "$_1280ImageLink" != *"<a href="* ]]; then
						echo "$_1280ImageLink" >> $imagelinkstempfile
						#echo "$PostImageURLTemp" >> $imagelinkstempfile
					fi
				fi
				ImageName=${_1280ImageLink##*/}
				if [[ "$ImageName" != *"<a href="* ]]; then
					LineExists3=$(grep $ImageName $imagenamestempfile)
				fi
				#echo "$LineExists3"
				if [ -z "$LineExists3" ]; then
					if [[ "$ImageName" != *"<a href="* ]]; then
						echo "$ImageName" >> $imagenamestempfile
					fi
				fi
				ImageSlashNum=$[$ImageSlashNum-1]
			done

			if [ $NumberOfLinesOGImage -eq 1 ]; then
				#echo "Only one image or Multiple with html in one line"
				LinkPhoto=$(egrep '"link-photo"' $line)
				if [ ! -z "$LinkPhoto" ]; then
					PostImageURL=$LinkPhoto
					CUTPOINTLinkPhoto="\"link-photo\"><img src=\""
					PostImageURL=${PostImageURL#*$CUTPOINTLinkPhoto}
					PostImageURLTemp=${PostImageURL%%\"*}

					#checkStaticImage=$(egrep 'static.tumblr' $PostImageURLTemp)
					if [[ "$PostImageURLTemp" == *"static.tumblr"* ]]; then
						LineExists2=$(grep $PostImageURLTemp $imagelinkstempfile)
						if [ -z "$LineExists2" ]; then
							if [[ "$PostImageURLTemp" != *"<a href="* ]]; then
								echo "$PostImageURLTemp" >> $imagelinkstempfile
							fi
						fi
						ImageName=${PostImageURLTemp##*/}
						LineExists3=$(grep $ImageName $imagenamestempfile)
						if [ -z "$LineExists3" ]; then
							if [[ "$ImageName" != *"<a href="* ]]; then
								echo "$ImageName" >> $imagenamestempfile
							fi
						fi
					fi

					ImageExt=${PostImageURLTemp##*.}
					PreImage=${PostImageURLTemp%_[0-9]*}
					_1280ImageLink="$PreImage""_1280.""$ImageExt"
					if [[ "$_1280ImageLink" != *"<a href="* ]]; then
						LineExists2=$(grep $_1280ImageLink $imagelinkstempfile)
					fi
					#echo "$LineExists2"
					if [ -z "$LineExists2" ]; then
						if [[ "$_1280ImageLink" != *"<a href="* ]]; then
							echo "$_1280ImageLink" >> $imagelinkstempfile
							#echo "$PostImageURLTemp" >> $imagelinkstempfile
						fi
					fi
					ImageName=${_1280ImageLink##*/}
					if [[ "$ImageName" != *"<a href="* ]]; then
						LineExists3=$(grep $ImageName $imagenamestempfile)
					fi
					#echo "$LineExists3"
					if [ -z "$LineExists3" ]; then
						if [[ "$ImageName" != *"<a href="* ]]; then
							echo "$ImageName" >> $imagenamestempfile
						fi
					fi
				fi
				
				if [ -z "$LinkPhoto" ]; then
					PostImage=$(egrep '"og:image"' $line)	
					#echo "PostImage: $PostImage"
					PostImageURL=$PostImage
					while [ $NumberOfImages -gt 0 ]; do #loop through images in post
						PostImageURL=${PostImageURL#*$CUTPOINT}
						PostImageURLTemp=${PostImageURL%%\"*}

						#checkStaticImage=$(egrep 'static.tumblr' $PostImageURLTemp)
						if [[ "$PostImageURLTemp" == *"static.tumblr"* ]]; then
							LineExists2=$(grep $PostImageURLTemp $imagelinkstempfile)
							if [ -z "$LineExists2" ]; then
								if [[ "$PostImageURLTemp" != *"<a href="* ]]; then
									echo "$PostImageURLTemp" >> $imagelinkstempfile
								fi
							fi
							ImageName=${PostImageURLTemp##*/}
							LineExists3=$(grep $ImageName $imagenamestempfile)
							if [ -z "$LineExists3" ]; then
								if [[ "$ImageName" != *"<a href="* ]]; then
									echo "$ImageName" >> $imagenamestempfile
								fi
							fi
						fi

						ImageExt=${PostImageURLTemp##*.}
						PreImage=${PostImageURLTemp%_[0-9]*}
						_1280ImageLink="$PreImage""_1280.""$ImageExt"
						LineExists2=$(grep $_1280ImageLink $imagelinkstempfile)
						#echo "$LineExists2"
						if [ -z "$LineExists2" ]; then
							if [[ "$_1280ImageLink" != *"<a href="* ]]; then
								echo "$_1280ImageLink" >> $imagelinkstempfile
							fi
						fi
						ImageName=${_1280ImageLink##*/}
						LineExists3=$(grep $ImageName $imagenamestempfile)
						#echo "$LineExists3"
						if [ -z "$LineExists3" ]; then
							if [[ "$ImageName" != *"<a href="* ]]; then
								echo "$ImageName" >> $imagenamestempfile
							fi
						fi
						NumberOfImages=$[$NumberOfImages-1]
					done
				fi
			fi
			#printf "\n"

			if [ $NumberOfLinesOGImage -gt 1 ]; then
				#echo "More than one og:image Lines"
				#echo "NumberOfLinesOGImage: $NumberOfLinesOGImage"
				while [ $NumberOfImages -gt 0 ]; do #loop through images in post
					PostImageURL=$(egrep '"og:image"' $line | head -$[$NumberOfImages])
					PostImageURL=${PostImageURL##*$CUTPOINT}
					PostImageURLTemp=${PostImageURL%%\"*}

					#checkStaticImage=$(egrep 'static.tumblr' $PostImageURLTemp)
					if [[ "$PostImageURLTemp" == *"static.tumblr"* ]]; then
						LineExists2=$(grep $PostImageURLTemp $imagelinkstempfile)
						if [ -z "$LineExists2" ]; then
							if [[ "$PostImageURLTemp" != *"<a href="* ]]; then
								echo "$PostImageURLTemp" >> $imagelinkstempfile
							fi
						fi
						ImageName=${PostImageURLTemp##*/}
						LineExists3=$(grep $ImageName $imagenamestempfile)
						if [ -z "$LineExists3" ]; then
							if [[ "$ImageName" != *"<a href="* ]]; then
								echo "$ImageName" >> $imagenamestempfile
							fi
						fi
					fi

					ImageExt=${PostImageURLTemp##*.}
					PreImage=${PostImageURLTemp%_[0-9]*}
					_1280ImageLink="$PreImage""_1280.""$ImageExt"
					LineExists2=$(grep $_1280ImageLink $imagelinkstempfile)
					#echo "$LineExists2"
					if [ -z "$LineExists2" ]; then
						if [[ "$_1280ImageLink" != *"<a href="* ]]; then
							echo "$_1280ImageLink" >> $imagelinkstempfile
						fi
					fi
					ImageName=${_1280ImageLink##*/}
					LineExists3=$(grep $ImageName $imagenamestempfile)
					#echo "$LineExists3"
					if [ -z "$LineExists3" ]; then
						if [[ "$ImageName" != *"<a href="* ]]; then
							echo "$ImageName" >> $imagenamestempfile
						fi
					fi
					NumberOfImages=$[$NumberOfImages-1]
				done
			fi
		done < "$file"

	currentimagelist="currentimagelist.txt"
	ImageLinksToDownloadFile="ImageLinksToAdd.txt"
	CheckIfDirExists=$(ls ../Completed\ Archives | egrep $tumblrUserName)
	echo "CheckIfDirExists: $CheckIfDirExists"
	if [ -z "$CheckIfDirExists" ]; then
		ImageLinksToDownloadFile=$imagelinkstempfile
	else
		echo "$(ls ../Completed\ Archives/$tumblrUserName)" > $currentimagelist
		ImageLinksToAdd=$(egrep -v -f $currentimagelist $imagelinkstempfile)
		echo "$ImageLinksToAdd" >> $ImageLinksToDownloadFile
	fi
	echo "ImageLinksToDownloadFile: $ImageLinksToDownloadFile"
	NumberofImagesToDownload=$(cat $ImageLinksToDownloadFile | wc -l)
	echo "Possible Number of Images in Queue to Download: $NumberofImagesToDownload"
	sed -i -e '$a\' "$ImageLinksToDownloadFile"

	printf "#######################\n"
	printf "Downloading Images Now\n"
	printf "#######################\n"

	while IFS= read line; do
		if wget --spider $line 2>/dev/null; then
			wget -nc --directory-prefix=$tumblrUserNameImageDir $line -q --show-progress
			#if [ $[$NumberofImagesToDownload%10] -eq 0 ]; then
			#	echo "Images Left: $NumberofImagesToDownload"
			#fi
			#NumberofImagesToDownload=$[$NumberofImagesToDownload-1]
		fi
	done < "$ImageLinksToDownloadFile"

	END2=`date +%s`
	DLTIME=$[$END2-$END1]
	echo "Image Download Time: " $(show_time $DLTIME)
	
	cd ..
	mv $DIR/$tumblrUserNameImageDir .
	rm -r $DIR

	if [ ! -z "$CheckIfDirExists" ]; then
		UpdateImageCount=$(ls $tumblrUserNameImageDir | wc -l)
		printf "\nUpdating Image Directory: $CheckIfDirExists | [Number of New Images: $UpdateImageCount]\n"
	fi
	mv $tumblrUserNameImageDir $tumblrUserName
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
	else
		wget --spider http://$tumblrUserName.tumblr.com/archive
		echo "Webpage not found or Forbidden Access"
		cd ..
		rm -r $DIR
	fi
}

count_total_dir_images () {
	DL="DirListingForImageCount.txt"
	ls Completed\ Archives > $DL
	sed -i -e '$a\' $DL
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
	sed -i -e '$a\' $DirListing
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
	sed -i -e '$a\' $1
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