#!/usr/bin/env python3

"""
PURPOSE OF DOWNLOAD CONTROLLER:

Download controller should handle th process of downloading images from Tumblr User provided
Should handle main flow of calls to Tumblr Service
"""

import os
from queue import Queue

from TumblrService import TumblrService
from ProcessUtility import DownloadWorker

from halo import Halo

class Spinners:
    def __init__(self):
        self.posts = Halo(text=f'Gathering Posts', spinner='dots', color='blue')
        self.image_links = Halo(text=f'Gathering Image Links', spinner='dots', color='blue')
        self.download_images = Halo(text=f'Downloading Images', spinner='dots', color='blue')

class DownloadController:

    def __init__(self, user, dst_dir, depth=5, max_threads=10, verbose=True):
        self.user = user
        self.dst_dir = f'{dst_dir}/{user}'
        self.depth = depth
        self.verbose = verbose

        self.image_links = []
        self.image_counter = 0
        self.total_size = 0.0

        self.max_threads = max_threads

        self.spinners = Spinners()
        self.TS = TumblrService(self)


    def download_user(self):
        if self.verbose: self.spinners.posts.start(text=f'Gathering Posts [0/{self.depth}]')

        post_links = self.TS.get_post_links(self.user, self.depth)

        if self.verbose: self.spinners.posts.succeed()

        if len(post_links) == 0:
            print('=================================')
            return

        if self.verbose: self.spinners.image_links.start()

        self.spawn_get_image_links_workers(post_links)

        links = self.prepare_image_links(self.dst_dir, self.user, self.TS.image_links)

        if len(links) == 0:
            self.spinners.image_links.stop_and_persist(symbol='⚠', text='No new images to Download with given depth')
            return

        if self.verbose: self.spinners.image_links.succeed(text=f'New Images to Download: {len(links)}')

        if self.verbose: self.spinners.download_images.start(text=f'Downloading Images [{self.image_counter}/{len(links)}]')

        self.spawn_download_image_workers(links)

        if self.verbose: self.print_download_complete()


    def print_download_complete(self):
        size_measure = 'MBs'
        if self.total_size > 1024:
            self.total_size = self.total_size / 1024
            size_measure = 'GBs'
        self.spinners.download_images.succeed(text=f'Downloading Complete {round(self.total_size,2)} {size_measure}')


    @staticmethod
    def get_image_name(user, src):
        return f'[{user}]_{src.rsplit("/", 1)[1]}'

    """
    Prepares what images to download
    TODO: This is broken, FIX IT
    TODO: Make this better
    """
    def prepare_image_links(self, location, user, image_links):
        localImages = []
        images_to_download = []
        if not os.path.exists(str(location)):
            os.mkdir(str(location))
        if os.path.exists(str(location)):
            localImages = os.listdir(str(location))
        for link in image_links:
            image_name = self.get_image_name(user, link)
            if image_name not in localImages:
                images_to_download.append(link)
        return images_to_download


    def spawn_get_image_links_workers(self, post_links):
        q = Queue()
        list(map(q.put, post_links))
        for t in range(self.max_threads):
            worker = DownloadWorker(self.TS, q, 'image_links')
            worker.daemon = True
            worker.start()
        q.join()


    def spawn_download_image_workers(self, links):
        q = Queue()
        for link in links:
            q.put((self.dst_dir, self.user, link))
        for t in range(self.max_threads):
            worker = DownloadWorker(self.TS, q, 'download_images')
            worker.daemon = True
            worker.start()
        q.join()

