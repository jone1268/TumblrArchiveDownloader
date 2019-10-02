#!/usr/bin/env python3

import os
import sys
from time import time

from queue import Queue
from threading import Thread
import multiprocessing

import requests
from bs4 import BeautifulSoup, SoupStrainer

from re import compile
import zipfile

from halo import Halo

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

class Spinners:
    def __init__(self):
        self.posts = Halo(text=f'Gathering Posts', spinner='dots', color='blue')
        self.image_links = Halo(text=f'Gathering Image Links', spinner='dots', color='blue')
        self.prepare_links = Halo(text=f'Preparing Image Links', spinner='dots', color='blue')
        self.download_images = Halo(text=f'Downloading Images', spinner='dots', color='blue')

path = "Archives"

global_image_links = []
global_image_counter = 0
multiproc = False
spinners = Spinners()

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
        if img is not None and "media.tumblr.com" in img and "avatar" not in img and "tumblr_" in img:
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
    return images_to_download


def download_image(directory, user, link):
    global global_image_counter
    global spinners
    image_name = "[" + str(user) + "]" + "_" + link.rsplit("/", 1)[1]
    download_path = str(directory) + "/" + str(image_name)
    r = requests.get(link)
    with open(str(download_path), "wb") as f:
        f.write(r.content)
    global_image_counter += 1
    spinners.download_images.text = f'Downloading Images [{global_image_counter}/{len(global_image_links)}]'


# Use generator?
def read_file(file):
    users = []
    for line in file:
        users.append(line.strip("\n\r"))
    return users


def spawn_get_image_links_workers(user, post_links):
    post_queue = Queue()
    for t in range(10):
        worker = Post_Image_Worker(post_queue)
        worker.daemon = True
        worker.start()
    for post_link in post_links:
        post_queue.put((user, post_link))
    post_queue.join()


def spawn_download_image_workers(archive_dir, user, links):
    image_queue = Queue()
    for t in range(10):
        worker = Image_Download_Worker(image_queue)
        worker.daemon = True
        worker.start()
    for link in links:
        image_queue.put((archive_dir, user, link))
    image_queue.join()


def download_user(user, depth, verbose=False):
    global global_image_links
    global global_image_counter
    global spinners

    ts = time()

    if verbose:
        spinners.posts.start()
    
    post_links = get_post_links(user, depth)
    
    if verbose:
        spinners.posts.succeed()

    if len(post_links) == 0:
        print('=================================')
        return

    archive_dir = str(path) + "/" + str(user)

    post_image_time = time()

    if verbose:
        spinners.image_links.start()

    spawn_get_image_links_workers(user, post_links)
    
    if verbose:
        spinners.image_links.succeed()

    if verbose:
        spinners.prepare_links.start()

    links = prepare_image_links(archive_dir, user, global_image_links)
    global_image_links = links

    if len(links) == 0:
        spinners.prepare_links.stop_and_persist(symbol='⚠', text='No new images to Download with given depth')
        return

    if verbose:
        spinners.prepare_links.succeed(text=f'New Images to Download: {len(links)}')

    image_download_time = time()

    if verbose:
        spinners.download_images.start(text=f'Downloading Images [{global_image_counter}/{len(links)}]')

    spawn_download_image_workers(archive_dir, user, links)

    if verbose:
        spinners.download_images.succeed(text=f'Downloading Complete')

    print(f'[{user}]:[{time() - ts}]')
    print('=================================')


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
    global multiproc

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
        elif str(arg) == "-m":
            multiproc = True
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
    global multiproc

    users = parse_arguments(argv)
    depth = 5
    l = len(argv)

    print(f'Depth: {depth}')
    print(users)
    print('=================================')

    if not os.path.exists(path):
        os.mkdir(path)

    # Have all the users that we want to download images from

    total_time = time()

    # Create new process
    if multiproc:
        p_workers = []
        for user in users:
            print(f'[{user}]')
            p_worker = multiprocessing.Process(target=download_user, args=(user, depth))
            p_worker.start()
            p_workers.append(p_worker)
        for p in p_workers:
            p.join()
    else:
        for user in users:
            print(f'[{user}]')
            download_user(user, depth, True)
            global_image_counter = 0
            global_image_links.clear()

    print(f'[Total exec time: {time() - total_time}]')


if __name__ == "__main__":
    main(sys.argv[1:])
