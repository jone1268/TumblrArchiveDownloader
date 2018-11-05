# TumblrArchiveDownloader
Downloads a Tumblr Archive given a Tumblr user

Bash Script downloads whole archive, however uses wget recursive downloading. This is slow and has to locally download the whole archive files in order to find the images.

Python solution is better. Spider crawls through pages of user and collects post links.
Then follows post links to grab images.

# Usage

# Python
```
python3 spider.py -i <inputfile> -u <username> -d <depth>
```
If depth flag is left empty, spider will call with depth of 0, which is seen as full archive. Currently only goes to maximum of 100 pages.
# Bash V6
```
Usage: $0 tumblrUserName/textdocument
tumblrUserName.tumblr.com
textdocument: Document that contains tumblrUserName on new lines
Downloads all images from given Tumble User's Archive
Updates exisiting directories if images are missing
```
# Bash V10
```
Usage: $0 [-fc] tumblrUserName/textdocument
tumblrUserName.tumblr.com
textdocument: Document that contains tumblrUserName on new lines
[-fc] forceCurlOption: enter -fc for this option to force program to use Page By Page Image aquirement.
        Leave Blank for default
Downloads all images from given Tumble User's Archive
Updates exisiting directories if images are missing
```
