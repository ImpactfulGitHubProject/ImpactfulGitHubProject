import json, requests
import mysql.connector
import pprint
import sys

 
db = mysql.connector.connect(
    host='localhost', database='github',
    user='root', password='',
    use_unicode=True, charset="utf8"
)

def update_repo(repo):
    cur = db.cursor(buffered=True)
    sql = "UPDATE repositories_data SET total_followers =%s, avg_followers=%s where repo_id=%s"
    args= (repo['total'],repo['avg'],repo['id'])
    cur.execute(sql, args)
    db.commit()
def update_repo1(repo):
    cur = db.cursor(buffered=True)
    sql = "UPDATE repositories_data SET total_following =%s, avg_following=%s where repo_id=%s"
    args= (repo['total'],repo['avg'],repo['id'])
    cur.execute(sql, args)
    db.commit()
    
cur = db.cursor(buffered=True)
query = "SELECT  repo_id FROM repositories_data order by repo_id ASC"
cur.execute(query)
result_set = cur.fetchall()
for repo_data in result_set:
    print(repo_data[0])
    repo={}
    repo['id']=repo_data[0]
    #print("----------------------%s"%repo_data[0])
    contributorquery="SELECT SUM(users.followers), count(users.user_id) from contributors, users where contributors.repo_id=%s and contributors.contributor_id=users.user_id"%repo_data[0]
    cur1 = db.cursor(buffered=True)
    cur1.execute(contributorquery)
    contributor_set= cur1.fetchall()
    for result in contributor_set:
        if(result[1]>0):
            total=result[0]
            avg=int(total/result[1])
            repo['total']=total
            repo['avg']=avg
        else:
            repo['total']=0
            repo['avg']=0
        #print(repo)
        update_repo(repo)
        break
    contributorquery1="SELECT SUM(users.following), count(users.user_id) from contributors, users where contributors.repo_id=%s and contributors.contributor_id=users.user_id"%repo_data[0]
    cur1 = db.cursor(buffered=True)
    cur1.execute(contributorquery1)
    contributor_set1= cur1.fetchall()
    for result in contributor_set1:
        if(result[1]>0):
            total=result[0]
            avg=int(total/result[1])
            repo['total']=total
            repo['avg']=avg
        else:
            repo['total']=0
            repo['avg']=0

        update_repo1(repo)
        break