#!/usr/bin/env python3

import os
import sys
from time import time

import multiprocessing

import zipfile

from DownloadController import DownloadController

# TODO:
#
# Add Cateragorization for images via tags given on tumblr
#   - Tag Directories
#   - Add metadata file to map tags to files
#
# Metadata files for information:
#   last update, image names, ...

multiproc = False

def zipdir(path, ziph):
    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file))


# Use generator?
def read_file(file):
    users = []
    for line in file:
        users.append(line.strip("\n\r"))
    return users


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
    global multiproc

    users = parse_arguments(argv)
    depth = 5
    l = len(argv)

    root = 'Archives'

    print(f'Depth: {depth}')
    print(users)
    print('=================================')

    if not os.path.exists(root):
        os.mkdir(root)

    total_time = time()

    if not multiproc: # Iterate
        for user in users:
            print(f'[{user}]')
            ts = time()
            downloader = DownloadController(user=user, dst_dir=root, depth=5)
            downloader.download_user()
            print(f'[{user}]:[{round(time() - ts,2)}]')
            print('=================================')
    else: # Create new process
        p_workers = []
        for user in users:
            print(f'[{user}]')
            downloader = DownloadController(user=user, dst_dir=root, depth=5, verbose=False)
            p_worker = multiprocessing.Process(target=downloader.download_user)
            p_worker.start()
            p_workers.append(p_worker)
        for p in p_workers:
            p.join()

    print(f'[Total exec time: {round(time() - total_time, 2)}]')


if __name__ == "__main__":
    main(sys.argv[1:])
