# TumblrArchiveDownloader
Downloads a Tumblr Archive given a Tumblr user

# Usage

# Python
```
python3.7 download.py [username, ...] [filename, ...]

-d <depth> can be inserted infront of any user to define the depth for said user
ex:
python3.7 download.py -d 10 user1 user2 -d 3 user3
(user1 and user2 will have depth of 10 whereas user3 will have depth of 3)
```
Can have variable usernames and filenames in same command.  
*-d* tag is optional.  
Default depth is 5. Add *-d* tag to change depth. Depth of -1 will go 100 pages.
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
