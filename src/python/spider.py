import requests
from bs4 import BeautifulSoup
import os, sys

def spider(user, max_pages):
    page = 1
    post_links = []
    image_links = []
    posts_flag = 1
    while page <= max_pages and posts_flag > 0:
        posts_flag = 0
        url = "https://" + str(user) + ".tumblr.com/page/" + str(page)
        # url = 'https://tastefulahegao.tumblr.com/' + str(page)
        source_code = requests.get(url)
        print("[Retreived webpage!]" + " [Page " + str(page) + "]")
        plain_text = source_code.text
        soup = BeautifulSoup(plain_text, 'html.parser')
        for post in soup.find_all('article'):
            for link in post.find_all('a'):
                href = link.get('href')
                if href is not None and "/post/" in href and "plus.google" not in href:
                    post_links.append(href)
                    posts_flag += 1
                    print(href)
        post_links = sorted(set(post_links))
        print(posts_flag)
        page += 1

    for p in post_links:
        # print(p)
        page_source = requests.get(str(p))
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
    print("\n Total number of images: " + str(len(image_links)))
    for i in image_links:
        print(i)
    ans = raw_input("Would you like to download [" + str(len(image_links)) + "]? (y/n)")
    if ans == "y" or ans == "Y":
        # os.mkdir(str(user))
        for i in image_links:
            image_name = i.rsplit("/", 1)[1]
            print(image_name)




spider("kerorira", 1)
# spider("tastefulahegao", 1)

# index = 1
# print("\n")
# for i in image_links:
#     s = i.rsplit('_',1)
#     image_url = s[0]
#     ext = s[1].split('.', 1)[1]
#     final_image_url = image_url + "_1280." + ext
#     print(final_image_url)
#     r = requests.get(final_image_url)
#     open(str(index) + ".png", 'wb').write(r.content)
#     index += 1
