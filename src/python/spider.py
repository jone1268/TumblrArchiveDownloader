import requests
from bs4 import BeautifulSoup
import os, sys
import time

# Print iterations progress
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█'):
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
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end = '\r')
    # Print New Line on Complete
    if iteration == total:
        print()

def spider(user, max_pages):
    page = 1
    post_links = []
    image_links = []
    posts_flag = 1
    if max_pages <= 0:
        max_pages = 100
    print("[Obtaining Pages]")
    printProgressBar(0, max_pages, prefix = 'Progress:', suffix = 'Complete', length = 50)
    while page <= max_pages and posts_flag > 0:
        posts_flag = 0
        url = "https://" + str(user) + ".tumblr.com/page/" + str(page)
        # url = 'https://tastefulahegao.tumblr.com/' + str(page)
        source_code = requests.get(url)
        # print("[Retreived webpage!]" + " [Page " + str(page) + "]")
        plain_text = source_code.text
        soup = BeautifulSoup(plain_text, 'html.parser')
        for post in soup.find_all('article'):
            for link in post.find_all('a'):
                href = link.get('href')
                if href is not None and "/post/" in href and "plus.google" not in href:
                    post_links.append(href)
                    posts_flag += 1
                    # print(href)
        post_links = sorted(set(post_links))
        # print(posts_flag)
        if posts_flag > 0:
            printProgressBar(page, max_pages, prefix = 'Progress:', suffix = 'Complete', length = 50)
        elif page <= max_pages:
            printProgressBar(max_pages, max_pages, prefix = 'Progress:', suffix = 'Complete', length = 50)
        page += 1

    print("[Parsing for Images]")
    printProgressBar(0, len(post_links), prefix = 'Progress:', suffix = 'Complete', length = 50)
    for i, p in enumerate(post_links):
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
        printProgressBar(i + 1, len(post_links), prefix = 'Progress:', suffix = 'Complete', length = 50)

    image_links = sorted(set(image_links))
    l = len(image_links)
    print("[Total number of images: " + str(l) + "]")
    ans = input("Would you like to download [" + str(l) + "] images? (y/n) ")
    if ans == "y" or ans == "Y":
        os.mkdir(str(user))
        os.chdir(str(user))
        # Initial call to print 0% progress
        printProgressBar(0, l, prefix = 'Progress:', suffix = 'Complete', length = 50)
        for i, image in enumerate(image_links):
            image_name = str(user) + "_" + image.rsplit("/", 1)[1]
            r = requests.get(image)
            open(str(image_name), "wb").write(r.content)
            printProgressBar(i + 1, l, prefix = 'Progress:', suffix = 'Complete', length = 50)
        print("[Enjoy the downloaded images!]")
    else:
        print("[Download Canceled]")

start_time = time.time()

# spider("kerorira", 6)
print("--- %s seconds ---" % (time.time() - start_time))
