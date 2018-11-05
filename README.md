# TumblrArchiveDownloader
Downloads a Tumblr Archive given a Tumblr user

Bash Script downloads whole archive, however uses wget recursive downloading. This is slow and has to locally download the whole archive files in order to find the images.

Python solution is better. Spiders through pages of user and collects post links.
Then follows post links to grab images.
