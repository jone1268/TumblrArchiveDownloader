#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup, SoupStrainer
import os
import sys
from time import time
import zipfile
from queue import Queue
from threading import Thread

# TODO:
# Use Threads to improve batch image download time
# Test using Threads with getting post_links
# Use threads when downloading images
#
# Metadata files for information:
#   last update, image names, ...

# https://www.toptal.com/python/beginners-guide-to-concurrency-and-parallelism-in-python

path = "Archives"

gloabal_image_links = []

def zipdir(path, ziph):
    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file))

# Print iterations progress
# https://stackoverflow.com/a/3160819


def printProgressBar(iteration, total, prefix='', suffix='', decimals=1, length=100, fill='█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100
                                                     * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end='\r')
    # Print New Line on Complete
    if iteration == total:
        print()


def get_post_links(user, max_pages=5, input_override=0, print_override=1):
    if user == "":
        print("No user provided")
        return
    if type(max_pages) is not int:
        print("Depth is not an integer")
        print("Using default depth")
        max_pages = 0
    page = 1
    post_links = []
    posts_flag = 1
    if max_pages <= 0:
        max_pages = 100
    # print("[Obtaining Pages]")
    if print_override == 0:
        printProgressBar(0, max_pages, prefix='Progress:',
                         suffix='Complete', length=50)
    while page <= max_pages and posts_flag > 0:
        posts_flag = 0
        url = "https://" + str(user) + ".tumblr.com/page/" + str(page)
        response = requests.get(url)
        plain_text = response.text
        post_url_len = len(str(str(user) + ".tumblr.com/post/"))
        for post in BeautifulSoup(plain_text, 'html.parser', parse_only=SoupStrainer('a')):
            if post.has_attr('href'):
                if post['href'] is not None and "plus.google" not in post['href']:
                    if str("http://" + str(user) + ".tumblr.com/post/") in post['href'][:post_url_len + 7]:
                        post_links.append(post['href'])
                        posts_flag += 1
                    if str("https://" + str(user) + ".tumblr.com/post/") in post['href'][:post_url_len + 8]:
                        post_links.append(post['href'])
                        posts_flag += 1

        post_links = sorted(set(post_links))
        if print_override == 0:
            if posts_flag > 0:
                printProgressBar(
                    page, max_pages, prefix='Progress:', suffix='Complete', length=50)
            elif page <= max_pages:
                printProgressBar(
                    max_pages, max_pages, prefix='Progress:', suffix='Complete', length=50)
        page += 1

    if len(post_links) == 0:
        print("[Could not find any posts]")
        return

    # print("[Total number of posts: " + str(len(post_links)) + "]")
    return post_links


def get_image_links_from_post(user, post_link):
    image_links = []
    page_source = requests.get(str(post_link))
    plain_text = page_source.text
    soup = BeautifulSoup(plain_text, 'html.parser')
    for link in soup.find_all('img'):
        img = link.get('src')
        if img is not None and "media.tumblr.com" in img and "avatar" not in img:
            s = img.rsplit('_', 1)
            image_url = s[0]
            ext = s[1].split('.', 1)[1]
            final_image_url = image_url + "_1280." + ext
            # print(final_image_url)
            image_links.append(final_image_url)
    image_links = sorted(set(image_links))
    gloabal_image_links.extend(image_links)


def download_image_links(user, image_links, input_override=0, print_override=1, zip_override=0):
    localImages = []
    images_to_download = []
    if os.path.exists(str(user)):
        localImages = os.listdir(str(user))
    for image in image_links:
        image_name = str(user) + "_" + image.rsplit("/", 1)[1]
        if image_name not in localImages:
            images_to_download.append(image)
    l = len(images_to_download)
    # print("[Total number of images: " + str(l) + "]")
    if input_override == 1:
        ans = input(
            "Would you like to download [" + str(l) + "] images? (y/n) ")
    else:
        ans = "y"
    if ans == "y" or ans == "Y":
        if not os.path.exists(str(user)):
            os.mkdir(str(user))
        os.chdir(str(user))
        # Initial call to print 0% progress
        if l > 0:
            if print_override == 0:
                printProgressBar(0, l, prefix='Progress:',
                                 suffix='Complete', length=50)
            for i, image in enumerate(images_to_download):
                image_name = str(user) + "_" + image.rsplit("/", 1)[1]
                r = requests.get(image)
                with open(str(image_name), "wb") as f:
                    f.write(r.content)
                if print_override == 0:
                    printProgressBar(i + 1, l, prefix='Progress:',
                                     suffix='Complete', length=50)
            # print("[Enjoy the downloaded images from " + str(user) + "!]")
    else:
        print("[Download Canceled]")
    os.chdir("..")

    if zip_override == 0:
        zipf = zipfile.ZipFile(str(user + '.zip'), 'w', zipfile.ZIP_DEFLATED)
        zipdir(str(user + '/'), zipf)
        zipf.close()


def prepare_image_links(directory, user, image_links):
    localImages = []
    images_to_download = []
    if not os.path.exists(str(directory)):
        os.mkdir(str(directory))
    if os.path.exists(str(directory)):
        localImages = os.listdir(str(directory))
    # Fix name comparison
    # Maybe use metadata file to compare to?
    for image in image_links:
        image_name = "[" + str(user) + "]" + "_" + image.rsplit("/", 1)[1]
        if image_name not in localImages:
            images_to_download.append(image)
    l = len(images_to_download)
    # print("[Total number of images: " + str(l) + "]")
    # print(images_to_download)
    return images_to_download


def download_image(directory, user, link):
    image_name = "[" + str(user) + "]" + "_" + link.rsplit("/", 1)[1]
    download_path = str(directory) + "/" + str(image_name)
    r = requests.get(link)
    with open(str(download_path), "wb") as f:
        f.write(r.content)
    # print("Downloaded image: ", link)


# Use generator?
def read_file(file):
    users = []
    for line in file:
        users.append(line.strip("\n\r"))
    return users

def download_user(user, depth):
    ts = time()
    post_links = get_post_links(user, 2)
    archive_dir = str(path) + "/" + str(user)
    # print("[Saving to: " + str(archive_dir) + "]")
    post_queue = Queue()
    for t in range(8):
        worker = Post_Image_Worker(post_queue)
        worker.daemon = True
        worker.start()
    for post_link in post_links:
        post_queue.put((user, post_link))
    post_queue.join()

    # Remove any duplicates
    print(len(gloabal_image_links))
    no_dup_image_list = list(dict.fromkeys(gloabal_image_links))
    print(len(no_dup_image_list))
    gloabal_image_links.clear()

    print("[Number of images to Download: " + str(len(no_dup_image_list)) + "]")

    links = prepare_image_links(archive_dir, user, no_dup_image_list)

    image_queue = Queue()
    for t in range(8):
        worker = Image_Download_Worker(image_queue)
        worker.daemon = True
        worker.start()
    for link in links:
        image_queue.put((archive_dir, user, link))
    image_queue.join()
    print(str(user) + " took " + str(time() - ts))


class Post_Image_Worker(Thread):
    def __init__(self, queue):
        Thread.__init__(self)
        self.queue = queue

    def run(self):
        while True:
            user, post_link = self.queue.get()
            try:
                get_image_links_from_post(user, post_link)
            finally:
                self.queue.task_done()


class Image_Download_Worker(Thread):
    def __init__(self, queue):
        Thread.__init__(self)
        self.queue = queue

    def run(self):
        while True:
            directory, user, link = self.queue.get()
            try:
                download_image(directory, user, link)
            finally:
                self.queue.task_done()


def main(argv):
    users = []
    depth = 5
    for arg in argv:
        try:
            print(arg)
            f = open(arg, 'r')
            users.extend(read_file(f))
            f.close()
        except FileNotFoundError:
            # This argument is a user
            print('File not exist, probably a user')
            users.append(arg)
    print(users)
    if not os.path.exists(path):
        os.mkdir(path)
    # Have all the users that we want to download images from

    # Start with testing normal functionality then move to using Threads
    # Threading
    total_time = time()

    for user in users:
        download_user(user, depth)

    print("Total exec time: " + str(time() - total_time))


if __name__ == "__main__":
    main(sys.argv[1:])
