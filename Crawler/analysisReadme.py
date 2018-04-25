# -*- coding: utf-8 -*-
import re
import os
import mysql.connector

db = mysql.connector.connect(
    host='localhost', database='github',
    user='root', password=''
)

cur1 = db.cursor(buffered=True)
query1 = "select startid1 from startid"
cur1.execute(query1)
data1 = cur1.fetchone()
print(data1[0])
cur = db.cursor(buffered=True)
query = "select * from repositories_data WHERE repo_id>'%s' order by repo_id"% data1[0]
cur.execute(query)
result_set = cur.fetchall()
for data in result_set:
    #print(data)
    query1 = "select * from readme_info where repo_id = '%s'"% data[0]
    cur1.execute(query1)
    if cur1.rowcount >= 1:
        continue
    query1 = "select * from noreadme where repo_id = '%s'" % data[0]
    cur1.execute(query1)
    if cur1.rowcount >= 1:
        continue
    try:
        fileRead = open("D:/readme/%s.txt" % data[0], 'r')
    except:
        cur1 = db.cursor(buffered=True)
        sql = "Insert Into noreadme (login, repo_name, repo_id) VALUES (%s,%s,%s)"
        args = (data[1], data[2], data[0])
        cur1.execute(sql, args)
        db.commit()

        print("not find readme")
        continue
    #print("-------------------"+str(data[0])+"-------------------")
    linenum = 0
    existurlnum = 0
    existwikinum = 0
    existexplan = 0
    existcontact = 0
    existcopyright = 0
    # file size
    file_size = float(os.path.getsize(r'D:/readme/%s.txt'% data[0])) / 1024
    file_size = round(file_size, 2)
    if(file_size>800):
        cur1 = db.cursor(buffered=True)
        sql = "Insert Into bigfile (login, repo_name, repo_id) VALUES (%s,%s,%s)"
        args = (data[2], data[3], data[0])
        cur1.execute(sql, args)
        db.commit()
        continue

    #print(file_size)
    for line in fileRead.readlines():
        length = len(line)
        try:
            line = line.decode('gbk')
        except:
            line = line
        #print(length)
        if (length > 1):
            rs = line.replace('\n', '')
            # Total number of statistics
            linenum = linenum + 1
            #print(rs)
            # match string with 1.https://    2.git://
            if (re.search('http://', rs, re.I) != None or re.search('https://', rs, re.I) != None or re.search('git://',rs,re.I) != None or re.search('www.', rs, re.I) != None):
                # print("url")
                existurlnum = existurlnum + 1
                # match string with 1.wiki    2.wikipedia
            if (re.search('wiki', rs, re.I) != None or re.search('wikipedia', rs, re.I)):
                existwikinum = existwikinum + 1
                # print("wiki")
                # Whether there is a detailed explanation of the source code
                # match string with config,install,License,Source
            if (re.search('config', rs, re.I) != None or re.search('install', rs, re.I) or re.search('Source', rs, re.I) or re.search('Requirement', rs, re.I) or re.search(ur'安装', rs,re.I) or re.search(ur'源码',rs,re.I)):
                existexplan = existexplan + 1
                # match string with 1.wiki    2.wikipedia
            if (re.search('contact', rs, re.I) != None or re.search('about us', rs, re.I) or re.search(ur'联系', rs,re.I) or re.search(
                    ur'手机', rs, re.I) or re.search(ur'邮箱', rs, re.I)):
                existcontact = existcontact + 1
            # match string with 1.wiki    2.wikipedia
            if (re.search('copyright', rs, re.I) != None or re.search('License', rs, re.I) or re.search('Version', rs,re.I) or re.search(
                    ur'版权', rs, re.I) or re.search(ur'版本', rs, re.I)):
                existcopyright = existcopyright + 1
    #print(linenum)
    #print(existurlnum)
    #print(existwikinum)
    #print(existexplan)
    #print(existcontact)
   # print(existcopyright)
    cur1 = db.cursor(buffered=True)
    sql = "Insert Into readme_info (repo_id, url_num, wiki,command,contact,copyright,rsize) VALUES (%s,%s,%s,%s,%s,%s,%s)"
    args = (data[0],existurlnum,existwikinum,existexplan,existcontact,existcopyright,file_size)
    cur1.execute(sql, args)
    db.commit()
    sql = "UPDATE startid SET startid1 = '%s'" % data[0]
    # print(sql)
    cur1.execute(sql)
    db.commit()
    fileRead.close()

