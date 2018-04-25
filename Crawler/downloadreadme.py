import json, requests
import mysql.connector
import pprint
import sys
import urllib
import os
import re
import socket
import traceback
import urllib2
import time

GITHUB_URL = "https://www.github.com"
GITHUB_API = GITHUB_URL +'/%(owner)s/%(repo)s/master/'
GITHUB_URL1 = "https://raw.githubusercontent.com"

db = mysql.connector.connect(
    host='localhost', database='github',
    user='root', password='',
    use_unicode=True, charset="utf8"
)

def getHtml(url):
    header = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:48.0) Gecko/20100101 Firefox/48.0"}
    request = urllib2.Request(url=url,headers=header)
    response = urllib2.urlopen(request)
    text = response.read()
    return text

def findfolder(html):
    rlist = []
    pattern = re.compile('<td class="content">\\n.*',re.I)
    items = re.findall(pattern,html)
    for item in items:
        pattern = re.compile('href=".*"',re.I)
        fitem = re.findall(pattern,item)
        fitem = fitem[0].split('"')
        rlist.append(fitem[1])
        #print(fitem[1])
    return rlist

def getReadme(html):
    pattern = re.compile('href=".*readme.*"',re.I)
    items = re.findall(pattern,html)
    #print(items)
    item = 'no'
    item_list = []
    if(len(items)!=0):
        #print(items[0])
        for item in items:
            item = item.split('"')
            item = item[1].split('/')
            #print(item)
            if(len(item)==6):
                item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]
            elif(len(item)==7):
                item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]
            
            item_list.append(item)
    else:
        pattern = re.compile('href=".*readme"',re.I)
        items = re.findall(pattern,html)
        #print(items)
        if(len(items)!=0):
            for item in items:
                item = item.split('"')
                item = item[1].split('/')
                if(len(item)==6):
                    item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]
                elif(len(item)==7):
                    item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]
                item_list.append(item)
    
    #print(item)
    return item_list

def getReadme1(html):
    pattern = re.compile('href=".*readme.*"',re.I)
    items = re.findall(pattern,html)
    #print(items)
    item = 'no'
    item_list = []
    if(len(items)!=0):
        item = items[0].split('"')
        item = item[1].split('/')
        if(len(item)==7):
            item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]
        elif(len(item)==8):
            item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]+'/'+item[7]
        
        item_list.append(item)
    else:
        pattern = re.compile('href=".*readme"',re.I)
        items = re.findall(pattern,html)
        #print(items)
        if(len(items)!=0):
            item = items[0].split('"')
            item = item[1].split('/')
            if(len(item)==7):
                item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]
            elif(len(item)==8):
                item = '/'+item[1]+'/'+item[2]+'/'+item[4]+'/'+item[5]+'/'+item[6]+'/'+item[7]
            item_list.append(item)
    #print(item)
    return item_list


def get_url(owner, repo):
    url = GITHUB_URL + '/%(owner)s/%(repo)s' % {
    'owner': owner,
    'repo': repo
    }
    #print ('Getting repo info for owner : %s, repo : %s, url : %s' % (owner, repo, url))
    return url

def get_repo_data(owner, repo,repo_id,str1, params=''):
    url = GITHUB_URL1 +str1
    if len(params) > 0: url += '&' + params
    f = urllib.urlopen(url)
    print(url)
    #print(repo_id)
    return requests.get(url)

def download(owner, repo,repo_id,str1, params=''):
    url = GITHUB_URL1 +str1
    if len(params) > 0: url += '&' + params
    f = urllib.urlopen(url)
    output = open("/etc/Python/%s.txt" % repo_id, "w+")
    while True:
        firstLine = f.readline()
        output.write(firstLine + "\n")
        if (firstLine == ''):
            break
        # print firstLine
    output.close()

cur1 = db.cursor(buffered=True)
query1 = "select startid1 from startid"
cur1.execute(query1)
data1 = cur1.fetchone()
print(data1[0])
cur = db.cursor(buffered=True)
query = "select login, repo_name, repo_id from addrepo WHERE repo_id>'%s'order by repo_id"% data1[0]
cur.execute(query)
result_set = cur.fetchall()
#socket.setdefaulttimeout(2000.0)
for data in result_set:
    #print(data[2])
    if(data[2]>=data1[0]):#6130228
        sql = "UPDATE startid SET startid1 = '%s'" % data[2]
        # print(sql)
        cur1.execute(sql)
        db.commit()
        try:
            git_url = get_url(data[0], data[1])
            #print(git_url)
            html = getHtml(git_url)
            #print(html)
            readme_list = getReadme(html)
            #print(readme_list)
            if(len(readme_list)==0):
                folderurl = findfolder(html)
                folderurl = GITHUB_URL+folderurl[0]
                html = getHtml(folderurl)
                readme_list = getReadme1(html)
            #print(readme)
        except:
            cur1 = db.cursor(buffered=True)
            sql = "Insert Into noreadme (login, repo_name, repo_id)VALUES (%s,%s,%s)"
            args = (data[0], data[1],data[2])
            try:
                cur1.execute(sql, args)
                db.commit()
            except:
                print("double")
            
            continue
        if(len(readme_list)>0):
            #print(readme[0])
            for readme in readme_list:
                try:
                    r = get_repo_data(data[0], data[1], data[2],readme)
                except:
                    continue
                if r == None or r.status_code != 200:
                    #print("No readme!!!")
                    
                    continue
                else:
                #print("download!!!")
                    download(data[0], data[1], data[2],readme)
                    print(data[2])
                    print(r)
                    break
        else:
            print("no")
            cur1 = db.cursor(buffered=True)
            sql = "Insert Into noreadme (login, repo_name, repo_id)VALUES (%s,%s,%s)"
            args = (data[0], data[1],data[2])
            try:
                cur1.execute(sql, args)
                db.commit()
            except:
                print("double")
    else:
        continue
