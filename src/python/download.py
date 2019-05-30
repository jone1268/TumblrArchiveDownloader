#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup, SoupStrainer
import os
import sys
from time import time
import zipfile
from queue import Queue
from threading import Thread
from re import compile
import multiprocessing


# TODO:
# Convert to electron-python app
#
# Add Cateragorization for images via tags given on tumblr
#   - Tag Directories
#   - Add metadata file to map tags to files
#
# Metadata files for information:
#   last update, image names, ...
#
# Progress Logging

path = "Archives"

global_image_links = []
global_image_counter = 0


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
    percent = ("{0:." + str(decimals) + "f}").format(100 *
                                                     (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end='\r')
    # Print New Line on Complete
    if iteration == total:
        print()


def get_post_links(user, max_pages=5):
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
    while page <= max_pages and posts_flag > 0:
        posts_flag = 0
        url = "https://" + str(user) + ".tumblr.com/page/" + str(page)
        response = requests.get(url)
        plain_text = response.text
        post_url_len = len(str(str(user) + ".tumblr.com/post/"))
        for post in BeautifulSoup(plain_text, 'html.parser', parse_only=SoupStrainer('a')):
            if post.has_attr('href'):
                if post['href'] is not None and "plus.google" not in post['href']:
                    if (str("http://" + str(user) + ".tumblr.com/post/") in post['href'][:post_url_len + 7] or
                            str("https://" + str(user) + ".tumblr.com/post/") in post['href'][:post_url_len + 8]):
                        post_links.append(get_short_link(post['href']))
                        posts_flag += 1

        post_links = sorted(set(post_links))
        page += 1

    if len(post_links) == 0:
        print("[Could not find any posts]")
        return []

    return post_links


def get_short_link(link):
    # Get post number
    p = compile('/post/[0-9]+')
    post_num = p.findall(link)[0]
    base_post_link = compile("/post/[0-9]+").split(link, 1)[0]
    new_link = str(base_post_link) + str(post_num)
    return new_link


def get_image_links_from_post(user, post_link):
    global global_image_links
    image_links = []
    page_source = requests.get(str(post_link))
    plain_text = page_source.text
    soup = BeautifulSoup(plain_text, 'html.parser')
    # Check for reblogs : Don't want these
    for p in soup.find_all('a'):
        if p.has_attr('class'):
            if p['class'][0] == 'reblog-link':
                return
    for link in soup.find_all('img'):
        img = link.get('src')
        if img is not None and "media.tumblr.com" in img and "avatar" not in img:
            s = img.rsplit('_', 1)
            image_url = s[0]
            ext = s[1].split('.', 1)[1]
            final_image_url = image_url + "_1280." + ext
            image_links.append(final_image_url)
    image_links = sorted(set(image_links))
    global_image_links.extend(image_links)
    global_image_links = list(set(global_image_links))


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
    print("[Total number of New images: " + str(l) + "]")
    return images_to_download


def download_image(directory, user, link):
    global global_image_counter
    image_name = "[" + str(user) + "]" + "_" + link.rsplit("/", 1)[1]
    download_path = str(directory) + "/" + str(image_name)
    r = requests.get(link)
    with open(str(download_path), "wb") as f:
        f.write(r.content)
    global_image_counter += 1
    printProgressBar(global_image_counter, len(global_image_links),
                     prefix='Progress:', suffix='Complete', length=50)


# Use generator?
def read_file(file):
    users = []
    for line in file:
        users.append(line.strip("\n\r"))
    return users


def spawn_get_image_links_workers(user):
    post_queue = Queue()
    for t in range(10):
        worker = Post_Image_Worker(post_queue)
        worker.daemon = True
        worker.start()
    for post_link in post_links:
        post_queue.put((user, post_link))
    post_queue.join()


def spawn_download_image_workers(user, links):
    image_queue = Queue()
    for t in range(10):
        worker = Image_Download_Worker(image_queue)
        worker.daemon = True
        worker.start()
    for link in links:
        image_queue.put((archive_dir, user, link))
    image_queue.join()


def download_user(user, depth):
    global global_image_links
    global global_image_counter

    ts = time()

    print("[Get Posts from " + str(user) + "]")
    get_post_links_time = time()
    post_links = get_post_links(user, depth)

    if len(post_links) == 0:
        print("=================================")
        return

    print("[Number of posts: " + str(len(post_links)) + "]:[" + str(time() - get_post_links_time) + "]")

    archive_dir = str(path) + "/" + str(user)

    post_image_time = time()
    spawn_get_image_links_workers(user)
    print("[Obtained image links]:[" + str(time() - post_image_time) + "]")

    print("[Number of images to Download: " + str(len(global_image_links)) + "]")

    links = prepare_image_links(archive_dir, user, global_image_links)

    global_image_links = links

    if len(links) == 0:
        print("[No new images to Download with given depth]")
        return

    print("[Downloading Images]")
    image_download_time = time()
    spawn_download_image_workers(user, links)
    print("[Finsihed Downloading]:[" + str(time() - image_download_time) + "]")

    print("[" + str(user) + "]:[" + str(time() - ts) + "]")
    print("=================================")


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


def parse_arguments(argv):
    users = []
    for index, arg in enumerate(argv):
        if str(arg) == "-d":
            # Depth tag induced
            if (index+1) is l:
                # Missing depth value
                # Use default
                pass
            else:
                depth = int(argv[index+1])
                break
        else:
            try:
                # print(arg)
                f = open(arg, 'r')
                users.extend(read_file(f))
                f.close()
            except FileNotFoundError:
                # This argument is a user
                # print('File not exist, probably a user')
                users.append(arg)
    return sorted(set(users))


def main(argv):
    global global_image_links
    global global_image_counter

    users = parse_arguments(argv)
    depth = 5
    multiproc = False
    l = len(argv)

    print("Depth: %d" % depth)
    print(users)
    print("=================================")

    if not os.path.exists(path):
        os.mkdir(path)

    # Have all the users that we want to download images from

    total_time = time()

    # Create new process
    if multiproc == True:
        p_workers = []

        for user in users:
            print("[" + str(user) + "]")
            # download_user(user, depth)
            p_worker = multiprocessing.Process(target=download_user, args=(user, depth))
            p_worker.start()
            p_workers.append(p_worker)
        for p in p_workers:
            p.join()
        # global_image_counter = 0
        # global_image_links.clear()
    else:
        for user in users:
            print("[" + str(user) + "]")
            download_user(user, depth)
            global_image_counter = 0
            global_image_links.clear()

    print("[Total exec time: " + str(time() - total_time) + "]")


if __name__ == "__main__":
    main(sys.argv[1:])
