import requests
from bs4 import BeautifulSoup, SoupStrainer

payload = {
    'inUserName': 'username',
    'inUserPass': 'password'
}

with requests.Session() as s:
    p = s.post('https://www.tumblr.com/login', data=payload)
    print(p.text)

    r = s.get('https://www.tumblr.com/following')
    # print(r.text)
    soup = BeautifulSoup(r.text, 'html.parser')
    print(soup.prettify())
