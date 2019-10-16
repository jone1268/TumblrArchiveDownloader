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

    # TODO:
    # Make each user have a depth argument
    # i.e.: -d 10 user1 user2 -d 3 user3 (user2 would have same depth as previous depth provided)
    # return list of objects: (list({user: "user1", depth: 10}, ...), multiproc)

    users = []
    depth = 5
    depth_flag = False
    multiproc = False
    for index, arg in enumerate(argv):
        if depth_flag:
            depth_flag = False
            continue
        if str(arg) == '-d':
            # Depth tag induced
            try:
                depth = int(argv[index+1])
                depth_flag = True
                continue
            except:
                print('Invalid depth provided. Using default depth: 5')
        elif str(arg) == '-m':
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
    return (sorted(set(users)), depth, multiproc)


def main(argv):

    users, depth, multiproc = parse_arguments(argv)
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
            downloader = DownloadController(user=user, dst_dir=root, depth=depth)
            downloader.download_user()
            print(f'[{user}]:[{round(time() - ts,2)}]')
            print('=================================')
    else: # Create new process
        p_workers = []
        for user in users:
            print(f'[{user}]')
            downloader = DownloadController(user=user, dst_dir=root, depth=depth, verbose=False)
            p_worker = multiprocessing.Process(target=downloader.download_user)
            p_worker.start()
            p_workers.append(p_worker)
        for p in p_workers:
            p.join()

    print(f'[Total exec time: {round(time() - total_time, 2)}]')


if __name__ == "__main__":
    main(sys.argv[1:])
