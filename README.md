# GitHubProjectImpact
This is a project which tries to understand what are indicators of GitHub Project Impact and what are the factors that affect GitHub project impact. With this project, we want to provide actionable suggestions to GitHub developers on how to improve the impact of their projects.

To understand what are indicators of project impact, we conducted a google survey to among GitHub project users. The survey can be found at https://goo.gl/forms/3UClqoxqhrhA21Vd2. You are welcome to provide us your opinions on impact indicating factors. 


To Contribute, following these steps: 

step 1: Set up a working copy on your computer
    
     1.1 Go to our project (https://github.com/ShuangLiuTJU/GitHubProjectImpact), click the Fork button on the right top corner. This will create a copy of the repository in your own GitHub account and you'll see a note saying "forked from ShuangLiuTJU/GitHubProjectImpact" beneath your copy.
    
     1.2 Now open your Git terminal and clone a local copy with the clone command "git clone https://github.com/ShuangLiuTJU/GitHubProjectImpact.git". Note that you need to be consisitent and use either HTTPs or SSH format, but not both. Failing to do so may cause you some permission deny problems, which you may find the following blog useful: https://segmentfault.com/q/1010000003061640
   
     1.3 Now type command "cd  GitHubProjectImpact" to go in your local folder, set up a new remote that points to the original project so that you can grab any changes and bring them into your local copy, you can do this with command "git remote add upstream https://github.com/ShuangLiuTJU/GitHubProjectImpact.git" (Remember to keep consistent with the HTTPs or SSH format).
   
    Now you have one local copy and two remotes of this project, i.e., origin master and upstream master. Origin master is the project in your own fork of the GitHub project, you can read or write to the origin master. Upstream master is the main project that your origin forked from, you can only read from this remote. 
    
Step 2: Work normally and commit your work
    
     2.1  use command "git checkout master" to make sure you are on the master branch
    
     2.2  use commnad "git pull upstream master && git push origin master" to synch your local copy with the upstream master and push the changes to your origin master. 
   
     2.3 "checkout -b hotfix/modifyreadme" to checkout a new branch to work on.

Step 3: Create a Pull Request
    
     3.1 git push -u origin hotfix/modifyreadme will create a branch in your GitHub project and link it with the remote one (with -u). Swap back to the browser and navigate to your fork of the project (in my case https://github.com/AbigailLiu/GitHubProjectImpact) and you'll find that your new branch is listed at the top with a "Compare & pull request" button. Click the button, follow the instructions and create a pull request. If you do not see the "Compare & pull request" button, you can create a pull request from the project page by clicking on the "new pull request" button and then follow the instructions to create a pull request. 

     Alternatively, you can follow the well written Guideline https://akrabat.com/the-beginners-guide-to-contributing-to-a-github-project/. There is also a good writing on commit message writing tips https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html, which we would appreciate contributors to follow. 
