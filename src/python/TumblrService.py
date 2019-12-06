#!/usr/bin/env python3

"""
PURPOSE OF TUMBLR SERVICE:

Should be the interaction layer between Download Controller and Tumblr
Make Requests to Tumblr and return necessary data only
"""

import requests
from bs4 import BeautifulSoup, SoupStrainer
from re import compile

class TumblrService:

    def __init__(self, download_controller):
        self.image_links = []
        self.dlc = download_controller

    @staticmethod
    def get_short_link(link):
        # Get post number
        p = compile('/post/[0-9]+')
        post_num = p.findall(link)[0]
        base_post_link = p.split(link, 1)[0]
        new_link = f'{base_post_link}{post_num}'
        return new_link

    """
    Gathers links for posts per page of user
    """
    def get_post_links(self, user, max_pages=5):
        if user == '':
            return
        
        if type(max_pages) is not int:
            max_pages = 5
        
        page = 1
        post_links = []
        full_archive = False
        previous_posts = []

        if max_pages <= 0:
            max_pages = '?'
            full_archive = True

        while True:
            posts_flag = 0
            posts = self.parse_post_links(user, page)
            post_links.extend(posts)
            self.dlc.spinners.posts.text = f'Gathering Posts | Page: [{page}/{max_pages}]'
            page += 1
            if not full_archive and page > max_pages:
                # Reached requested pages
                break
            if len(posts) == 0 or previous_posts == posts:
                # Current page did not have any posts, stop looping
                break
            previous_posts = posts.copy()
        if len(post_links) == 0:
            print('[Could not find any posts]')
            return []
        return sorted(set(post_links))

    """
    Parses for post links
    """
    def parse_post_links(self, user, page):
        posts = []
        response = requests.get(f'https://{user}.tumblr.com/page/{page}')
        plain_text = response.text
        post_url_len = len(f'{user}.tumblr.com/post/')
        for post in BeautifulSoup(plain_text, 'html.parser', parse_only=SoupStrainer('a')):
            if not post.has_attr('href'):
                continue
            if post['href'] is None:
                continue
            if "plus.google" in post['href']:
                continue
            if f'http://{user}.tumblr.com/post/' not in post['href'][:post_url_len + 7] \
            and f'https://{user}.tumblr.com/post/' not in post['href'][:post_url_len + 8]:
                continue
            posts.append(self.get_short_link(post['href']))
        return posts

    """
    Gathers image urls from a post url provided
    """
    def get_image_links_from_post(self, post_link):
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
            if img is not None \
            and 'media.tumblr.com' in img \
            and 'avatar' not in img \
            and 'tumblr_' in img:
                s = img.rsplit('_', 1)
                image_url = s[0]
                ext = s[1].split('.', 1)[1]
                final_image_url = f'{image_url}_1280.{ext}'
                image_links.append(final_image_url)
        image_links = sorted(set(image_links))
        self.image_links.extend(image_links)
        self.image_links = list(set(self.image_links))
        self.dlc.image_link_counter += 1
        self.dlc.spinners.image_links.text = f'Gathering Image Links | Post: [{self.dlc.image_link_counter}/{self.dlc.num_image_links}]'


    """
    Downloads image to location given
    """
    def download_image(self, location, user, link):
        image_content = requests.get(link).content

        image_name = self.dlc.get_image_name(user, link)
        download_path = f'{location}/{image_name}'

        with open(str(download_path), 'wb') as f:
            f.write(image_content)
        f.close()

        self.dlc.image_counter += 1
        self.dlc.total_size += (len(image_content) / 1000000)
        size_measure = 'MBs'
        if self.dlc.total_size > 1024:
            self.dlc.total_size = self.dlc.total_size / 1024
            size_measure = 'GBs'
        self.dlc.spinners.download_images.text = f'Downloading Images [{self.dlc.image_counter}/{len(self.image_links)}] {round(self.dlc.total_size,2)} {size_measure}'
        

