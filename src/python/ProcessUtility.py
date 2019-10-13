#!/usr/bin/env python3

"""
PURPOSE OF PROCESS CONTROLLER

Should spawn threads and processes
"""

from threading import Thread

class DownloadWorker(Thread):
    def __init__(self, tumblr_service, queue, worker_type):
        Thread.__init__(self)
        self.queue = queue
        self.worker_type = worker_type
        self.tumblrService = tumblr_service


    def get_image_links(self):
        try:
            self.tumblrService.get_image_links_from_post(self.queue.get())
        finally:
            self.queue.task_done()


    def download_images(self):
        directory, user, link = self.queue.get()
        try:
            self.tumblrService.download_image(directory, user, link)
        finally:
            self.queue.task_done()


    def run(self):
        while not self.queue.empty():
            if self.worker_type == 'image_links':
                self.get_image_links()
            elif self.worker_type == 'download_images':
                self.download_images()
