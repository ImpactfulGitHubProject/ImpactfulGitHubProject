import json, requests
import mysql.connector
import pprint
import sys
import time
import random
import urllib2
import re

#1pB[ZYY=[4X(VCVQ
AUTH = 'd6fb416c6ce4e1ebc9cb68d44b9c25476a4131a5'
flag_set = 0
#d6fb416c6ce4e1ebc9cb68d44b9c25476a4131a5
GITHUB_URL = 'https://api.github.com'
GITHUB_API = GITHUB_URL + '/repos/%(owner)s/%(repo)s/%(action)s'

db = mysql.connector.connect(
    host='localhost', database='github',
    user='root', password='',
    use_unicode=True, charset="utf8"
)


def add_repo_data(repo_data):
    repo_data['repo_id'] = insert_repo_data(repo_data)

    if repo_data['repo_id'] == -1: return 0

    return repo_data['repo_id']


def insert_repo_data(repo_data):
    cur = db.cursor(buffered=True)
    #print(repo_data['repo_id'])
    query = "SELECT * FROM repositories_data where repo_id = %s"
    args = (repo_data['repo_id'],)
    cur.execute(query, args)

    if cur.rowcount >= 1:
        #print ("skipping repo as already exists")
        return -1

    contributors_count = repo_data['contributors']
    issues_count = repo_data['issues']

    query = "insert into repositories_data(name, login, repo_name, branches, releases, watch, forks, stars, issues, contributors, latest_update,repo_id,commits,created_at,size,language,isfork,private,source,parent,organization) values(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    args = (repo_data['name'], repo_data['login'], repo_data['repo_name'], repo_data['branches'], repo_data['releases'],
            repo_data['watch'], repo_data['forks'], repo_data['stars'], issues_count, contributors_count,
            repo_data['latest_update'], repo_data['repo_id'], repo_data['commits'],repo_data['created_at'],repo_data['size'],repo_data['language'],repo_data['isfork'],repo_data['private'],repo_data['source'],repo_data['parent'],repo_data['organization'])
    cur.execute(query, args)
    db.commit()
    return cur.lastrowid

def insert_commit_data(commit_data):
    cur = db.cursor(buffered=True)
    query = "SELECT * FROM repo_commits where repo_id = %s and sha=%s"
    args=(commit_data['repo_id'],commit_data['sha'])
    cur.execute(query, args)
    if cur.rowcount >= 1:
        #print ("skipping commit as already exists")
        return -1

    query = "insert into repo_commits(email, name, login, message, date,repo_id, contr_id, sha, parent) values(%s, %s, %s, %s,%s, %s, %s, %s,%s)"
    args = (commit_data['email'], commit_data['name'], commit_data['login'], commit_data['message'],commit_data['date'], commit_data['repo_id'], commit_data['contr_id'], commit_data['sha'],commit_data['parent'])
    cur.execute(query, args)
    db.commit()
    return cur.lastrowid

def insert_user_data(user_data):
    cur = db.cursor(buffered=True)
    query="select * from users where user_id=%s" %user_data['user_id']
    cur.execute(query)
    if cur.rowcount >= 1:
        #print ("skipping user as already exists")
        return -1
    query="insert into users(login,user_id,type,site_admin,name,company,blog, location, email, public_repos, public_gists, followers, following, created_at,updated_at,hireable) values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    args=(user_data['login'],user_data['user_id'],user_data['type'],user_data['site_admin'],user_data['name'],user_data['company'],user_data['blog'],user_data['location'],
    user_data['email'],user_data['public_repos'],user_data['public_gists'],user_data['followers'],user_data['following'],user_data['created_at'],user_data['updated_at'],user_data['hireable'])
    cur.execute(query, args)
    db.commit()
    return cur.lastrowid

def insert_contributor_data(contr_data):
    cur = db.cursor(buffered=True)

    query = "SELECT * FROM contributors where repo_id = %s and contributor_id=%s"
    args = (contr_data['repo_id'], contr_data['contributor_id'])
    cur.execute(query, args)

    if cur.rowcount >= 1:
        #print ("skipping contributor as already exists")
        return -1

    contributors_count = repo_data['contributors']
    issues_count = repo_data['issues']

    query = "insert into contributors(contributor_id, name, repo_id, contributions) values(%s, %s, %s, %s)"
    args = (contr_data['contributor_id'], contr_data['name'], contr_data['repo_id'], contr_data['contributions'])
    cur.execute(query, args)
    db.commit()
    return cur.lastrowid


def set_access_token():
    global flag_set
    if(flag_set == 0):
        AUTH = '84462fea70ae7f72eeaeeae6f2600bdd790361b1'
        flag_set = 1
    else:
        AUTH = 'd6fb416c6ce4e1ebc9cb68d44b9c25476a4131a5'
        flag_set = 0
    return '?access_token=%s' % AUTH

def insert_issue_data(issue_data):
    cur = db.cursor(buffered=True)
    query="select * from issues where repo_id= %s and issue_id= %s"
    args=(issue_data['repo_id'], issue_data['issue_id'])
    cur.execute(query,args)
    if cur.rowcount >= 1:
        #print ("skipping issue as already exists")
        return -1

    query="insert into issues (repo_id,issue_id,title,state,milestone,comments,created_at,updated_at,closed_at,body,assignee_id)values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    args=(issue_data['repo_id'],issue_data['issue_id'],issue_data['title'],issue_data['state'],issue_data['milestone'],
    issue_data['comments'],issue_data['created_at'],issue_data['updated_at'],issue_data['closed_at'],issue_data['body'],issue_data['assignee_id'])
    cur.execute(query, args)
    db.commit()
    return cur.lastrowid

def get_repo_data(owner, repo, action, params=''):
    url = GITHUB_API % {
    'owner': owner,
    'repo': repo,
    'action': action
    }
    url += set_access_token()
    if len(params) > 0: url += '&' + params
    #print ("Getting repo data for owner : %s, repo : %s, action : %s, url : %s" % (owner, repo, action, url))
    return requests.get(url)


def get_all_public_repos(id):
    return requests.get(
        'https://api.github.com/repositories?since=%s&access_token=84462fea70ae7f72eeaeeae6f2600bdd790361b1' % (id))

def get_all_public_repos1(id):
    return requests.get(
        'https://api.github.com/repositories?since=%s&access_token=d6fb416c6ce4e1ebc9cb68d44b9c25476a4131a5' % (id))


def get_repo(owner, repo):
    url = GITHUB_URL + '/repos/%(owner)s/%(repo)s' % {
    'owner': owner,
    'repo': repo
    }
    url += set_access_token()
    #print ('Getting repo info for owner : %s, repo : %s, url : %s' % (owner, repo, url))
    return requests.get(url)


def get_contr_commits(owner, repo, action, contr=''):
    all_user_commits = list()
    page_count = 1
    while True:
        params = ''
        if len(contr) > 0: params = 'author=' + contr
        if len(params) > 0:
            params = params + '&page=%d' % page_count
        else:
            params = params + 'page=%d' % page_count
        user_commits = get_repo_data(owner, repo, 'commits', params)
        if user_commits != None and user_commits.status_code == 200 and len(user_commits.json()) > 0:
            all_user_commits = all_user_commits + user_commits.json()
        else:
            break
        page_count = page_count + 1

    if len(all_user_commits) <= 0: return []
    #print ('Getting commits for owner : %s, repo : %s, action : %s, contributor : %s' % (owner, repo, action, contr))
    contr_commits = list()

    for commit in all_user_commits:
        if commit['committer'] == None: continue
        commiter = get_user_details(commit['committer']['login'])
       #print ("committer status code : %s" % commiter.status_code)
        if commiter == None or commiter.status_code != 200: continue
        commiter = commiter.json()
        user_commits_data = {
        'login': commiter['login'],
        'name': commiter['name'],
        'email': commiter['email'],
        'date': commit['commit']['committer']['date'],
        'message': commit['commit']['message'],
        }
        contr_commits.append(user_commits_data)

    return contr_commits


def get_user_details(user):
    url = GITHUB_URL + '/users/%(user)s' % {
    'user': user
    }
    url += set_access_token()
    #print ('Getting user details for user : %s, url : %s' % (user, url))
    return requests.get(url)

def getHtml(url):
    header = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:48.0) Gecko/20100101 Firefox/48.0"}
    request = urllib2.Request(url=url,headers=header)
    response = urllib2.urlopen(request)
    text = response.read()
    return text

def getCommits(html):
    pattern = re.compile('<span class="num text-emphasized">\\n.*')
    items = re.findall(pattern,html)
    pattern = re.compile(r'\d+.*')
    item = re.findall(pattern, items[0])

    #print(item[0])
    str = item[0].split(',')
    commits_num = 0
    for data in str:
        commits_num*=1000
        commits_num += int(data)
    #print(commits_num)
    return commits_num


def get_url(owner, repo):
    url = 'https://www.github.com' + '/%(owner)s/%(repo)s' % {
    'owner': owner,
    'repo': repo
    }
    #print ('Getting repo info for owner : %s, repo : %s, url : %s' % (owner, repo, url))
    return url

def get_commits(owner, repo):
    git_url = get_url(owner, repo)
    #print(git_url)
    html = getHtml(git_url)
    commits = getCommits(html)
    return commits

cur1 = db.cursor(buffered=True)
query1 = "select startid1 from startid"
cur1.execute(query1)
data1 = cur1.fetchone()
startid =data1[0]
print("----------startid-------%s"%startid)
randnum = 0
flag_auth = 1
requests.adapters.DEFAULT_RETRIES = 3
while True:
    if(startid>=128700000):
        print(startid)
        break
    startid = (startid/1000)*1000
    nextstartid = startid+1000
    randnum1 = random.randint(1, 9)
    while True:
        if(randnum1>0):
            startid+=100
            randnum1-=1
        else:
            break
    time.sleep(5)
    #change auth token_access
    if(flag_auth == 0):
        AUTH = '84462fea70ae7f72eeaeeae6f2600bdd790361b1'
        all_public_repos = get_all_public_repos(startid)
        flag_auth = 1
    else:
        AUTH = 'd6fb416c6ce4e1ebc9cb68d44b9c25476a4131a5'
        all_public_repos = get_all_public_repos1(startid)
        flag_auth = 0
    
    limitstartid = startid+100
    all_public_repos = get_all_public_repos(startid)
    repo = all_public_repos.json()
    if all_public_repos == None or all_public_repos.status_code != 200: sys.exit()

    limit_num=0
    while True:
        randnum = random.randint(1, 100)
        try:
            repo_num = repo[randnum]['id']
        except:
            continue
        if(repo_num<limitstartid):
            break
        else:
            limit_num+=1
            if(limit_num>=20):
                limit_num=0
                limitstartid+=100

    print(repo[randnum]['id'])

    #print ("-----------------the total count is --------------------: %s" % len(repo))
    if(repo[randnum]):
        repo_data = {}
        #print(repo[randnum])
        #print ("-------------------------------Start------------------------")
        repo = repo[randnum]
        r = get_repo(repo['ow'
                          ''
                          'ner']['login'], repo['name'])
        if r == None or r.status_code != 200: continue
        r = r.json()
        if(r['private']=="true"):
            continue
        else:
            user = get_user_details(r['owner']['login'])
            if user == None or user.status_code != 200: continue
            
            user = user.json()
            username = user['login']
            repo_data['name'] = user['name']
            repo_data['login'] = user['login']
            reponame = repo['name']
            repo_data['repo_name'] = repo['name']
            repo_data['repo_id'] = repo['id']

            # release
            all_release = list()
            page_count=1
            while True:
                releases = get_repo_data(repo_data['login'], repo_data['repo_name'], 'tags','page=%d' % page_count)
                if releases != None and releases.status_code == 200 and len(releases.json()) > 0:
                    all_release = all_release + releases.json()
                else:
                    break
                page_count = page_count + 1
            repo_data['releases'] = len(all_release)
            repo_data['watch'] = r['subscribers_count']
            repo_data['forks'] = r['forks_count']
            repo_data['stars'] = r['stargazers_count']
            repo_data['issues'] = r['open_issues_count']
            repo_data['created_at']=r['created_at']
            repo_data['size']=r['size']
            repo_data['language']=r['language']
            repo_data['private']=r['private']
            repo_data['isfork']=r['fork']
            try:
                repo_data['organization']=r['organization']['id']
            except:
                repo_data['organization']=-1
            try:
                repo_data['parent']=r['parent']['id']
            except:
                repo_data['parent']=-1
            try:
                repo_data['source']=r['source']['id']
            except:
                repo_data['source']=-1

            stars = get_repo_data(repo_data['login'], repo_data['repo_name'], 'branches')
            repo_data['branches'] = len(stars.json()) if stars != None and stars.status_code == 200 else 0


            #contributors
            all_contributors = list()
            page_count = 1
            while True:
                contributors = get_repo_data(repo_data['login'], repo_data['repo_name'], 'contributors', 'page=%d' % page_count)
                if contributors != None and contributors.status_code == 200 and len(contributors.json()) > 0:
                    all_contributors = all_contributors + contributors.json()
                else:
                    break
                page_count = page_count + 1

            repo_data['contributors'] = len(all_contributors)

            #latest commit(it is the first commit)
            page_count=1
            total_commits=0
            allcommits=list()

            '''
            while True:
                commits=get_repo_data(repo_data['login'], repo_data['repo_name'], 'commits', 'page=%d' % page_count)
                #print(commits)
                if commits != None and commits.status_code == 200 and len(commits.json()) > 0:
                    total_commits=total_commits+len(commits.json())
                    if page_count==1:
                            latestCommit = commits.json()[0]


                    allcommits=allcommits+commits.json()
                    page_count=page_count+1
                else:
                        break
            
            try:
                repo_data['latest_update'] = latestCommit['commit']['author']['date']
            except:
                repo_data['latest_update']='Not Defined'
            repo_data['commits'] = total_commits
            '''
            #commits
            try:
                total_commits = get_commits(username,reponame)
            except:
                total_commits = 0
        
            repo_data['latest_update'] = 'Not Defined'
            repo_data['commits'] = total_commits
            #total_commits = 0
            contr_data = {}
            contr_user_data={}
            for contr in all_contributors:
                contr_data['name'] = contr['login']
                contr_data['contributor_id'] = contr['id']
                contr_data['repo_id'] = repo['id']
                contr_data['contributions'] = contr['contributions']
                insert_contributor_data(contr_data)
                try:
                    user_response=get_user_details(contr['login'])
                except:
                    continue
                user_details=user_response.json()
                try:
                    contr_user_data['login']=user_details['login']
                    contr_user_data['user_id']=user_details['id']
                    contr_user_data['type']=user_details['type']
                    contr_user_data['site_admin']=user_details['site_admin']
                    contr_user_data['name']=user_details['name']
                    contr_user_data['company']=user_details['company']
                    contr_user_data['blog']=user_details['blog']
                    contr_user_data['location']=user_details['location']
                    contr_user_data['email']=user_details['email']
                    contr_user_data['public_repos']=user_details['public_repos']
                    contr_user_data['public_gists']=user_details['public_gists']
                    contr_user_data['followers']=user_details['followers']
                    contr_user_data['following']=user_details['following']
                    contr_user_data['created_at']=user_details['created_at']
                    contr_user_data['updated_at']=user_details['updated_at']
                    contr_user_data['hireable']=user_details['hireable']
                    insert_user_data(contr_user_data)
                except:
                    print("insert-error")

            '''
            commit_data={}
            for comm in allcommits:
                commit_data['sha']=comm['sha']
                try:
                    commit_data['email']=comm['commit']['committer']['email']
                except:
                    commit_data['email']='Not Defined'
                try:
                    commit_data['name']=comm['commit']['committer']['name']
                except:
                    commit_data['name']='Not Defined'
                try:
                    commit_data['login']=comm['commit']['committer']['login']
                except:
                    commit_data['login']='Not Defined'
                try:
                    commit_data['message']=comm['commit']['message']
                except:
                    commit_data['message']='Not Defined'
                commit_data['date']=comm['commit']['committer']['date']
                commit_data['repo_id']=repo['id']
                try:
                    commit_data['contr_id']=comm['commit']['committer']['id']
                except:
                    commit_data['contr_id']='Not Defined'
                commit_data['sha']=comm['sha']
                try:
                    commit_data['parent']=comm['parents'][0]['sha']
                except:
                    commit_data['parent']='Not Defined'
                if comm['committer'] is not None:
                    try:
                        commit_data['contr_id']=comm['committer']['id']
                        commit_data['login']=comm['committer']['login']
                    except:
                        commit_data['contr_id']=commit_data['contr_id']
                        commit_data['login']=commit_data['login']
                insert_commit_data(commit_data)
                '''
            #issues
            '''
            page_count=1
            allissues=list()
            while True:
                issues=get_repo_data(repo_data['login'], repo_data['repo_name'], 'issues', 'page=%d' % page_count)
                if issues != None and issues.status_code == 200 and len(issues.json()) > 0:
                    allissues=allissues+issues.json()
                    page_count=page_count+1
                else:
                        break
            for oneissue in allissues:
                issue={}
                issue['repo_id']=repo['id']
                issue['issue_id']=oneissue['id']
                issue['title']=oneissue['title']
                try:
                    issue['milestone']=oneissue['milestone']['id']
                except:
                    issue['milestone']=None
                issue['comments']=oneissue['comments']
                issue['created_at']=oneissue['created_at']
                issue['updated_at']=oneissue['updated_at']
                issue['closed_at']=oneissue['closed_at']
                if oneissue['body'] is None:
                    issue['body']=oneissue['body']
                else:
                    issue['body']=oneissue['body'].encode('ascii', 'ignore').decode('ascii')
                issue['state']=oneissue['state']
                try:
                    issue['assignee_id']=oneissue['assignee']['id']
                except:
                    issue['assignee_id']=None
                #print (issue)
                insert_issue_data(issue)
            '''
            
            add_repo_data(repo_data)
            startid=nextstartid
            print("----------startid-------%s" % startid)
            sql = "UPDATE startid SET startid1 = '%s'" % startid
            cur1.execute(sql)
            db.commit()
