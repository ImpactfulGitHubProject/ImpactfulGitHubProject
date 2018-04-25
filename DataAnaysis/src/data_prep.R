## Data Loading and Exploration
# by Gui Lin
# Date: 2018-04

# reload data #####
library(dplyr)
library(caret)


#search api: https://github.com/search?utf8=✓&q=created%3A%3E2018-01-01+stars%3A%3E3+forks%3A%3E3&type=Repositories&ref=advsearch&l=&l=

library(data.table)
library(dplyr)

# UDF ####
 f_fetch_from_db <- function(mydb=mydb,verses_sql) {
  rs = dbSendQuery(mydb,verses_sql)
  return(fetch(rs, n=-1))
}

 f_get_age <- function(dob, age.day = today(), units = "years", floor = TRUE) {
  calc.age = interval(dob, age.day) / duration(num = 1, units = units)
  if (floor) return(as.integer(floor(calc.age)))
  return(calc.age)
 }

 f_get_Rsquare <- function(actual, preditced){
   1 - (sum((actual-predicted)^2)/sum((actual-mean(actual))^2))
 }

# Retrieve data from mysql ####
library(RMySQL)
mydb = dbConnect(MySQL(), host = "127.0.0.1", user = "root", password = "password", dbname = "github");
dbListTables(mydb)
data_issues <- f_fetch_from_db(mydb, verses_sql = "SELECT * FROM issues")
data_repoData <- f_fetch_from_db(mydb,verses_sql = "select * from repositories_data")
data_users <- f_fetch_from_db(mydb,verses_sql = "select * from users")
lapply(dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

load("data/data.RD")

# Retrieve data from github2, updated date = 20180412 ####
mydb = dbConnect(MySQL(), host = "127.0.0.1", user = "root", password = "password", dbname = "github2");
dbListTables(mydb)
#data_issues <- f_fetch_from_db(mydb, verses_sql = "SELECT * FROM issues")
data_repoData <- f_fetch_from_db(mydb,verses_sql = "select * from repositories_data")
data_users <- f_fetch_from_db(mydb,verses_sql = "select * from users")
data_readme <-  f_fetch_from_db(mydb,verses_sql = "select * from readme_info")
data_contributors <- f_fetch_from_db(mydb,verses_sql = "select * from contributors")
data_noreadme <- f_fetch_from_db(mydb,verses_sql = "select * from noreadme")
lapply(dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)


## noted that for survey data, un-qualified (bad language) data points are removed.
data_survey <-  fread(file="data/Survey on Impact of GitHub Repository (Responses).txt",stringsAsFactors = F,sep = "\t", encoding="UTF-8") #for data.table
colnames(data_survey)<- c("timestamp","occupation","freq(yr)","freq(visits)" ,"rFork","rStar","rWatch","comments")
data_survey$occupation <- as.factor(data_survey$occupation)
# plot occupation distribution
data_survey %>% group_by(occupation) %>% mutate(count=n()) %>% filter(count>1) %>%   ggplot(aes(x=occupation))+ geom_bar() + ggtitle("occupation distribution") #+ coord_flip()


# Calculate impact based on fork, start and watch ####
# normalize across each survey point
imp <- data_frame(
  pF = data_survey$rFork/(data_survey$rFork+data_survey$rStar+data_survey$rWatch),
  pS = data_survey$rStar/(data_survey$rFork+data_survey$rStar+data_survey$rWatch),
  pW =  data_survey$rWatch/(data_survey$rFork+data_survey$rStar+data_survey$rWatch)
)
imp %>% summary()
# avergae over all the scoress
imp_wF <- sum(imp$pF)/(sum(imp$pF) + sum(imp$pS) + sum(imp$pW))
imp_wS <- sum(imp$pS)/(sum(imp$pF) + sum(imp$pS) + sum(imp$pW))
imp_wW <- sum(imp$pW)/(sum(imp$pF) + sum(imp$pS) + sum(imp$pW))


print(paste("impact weight for fork: ", imp_wF)) # 0.3641
print(paste("impact weight for star: ", imp_wS)) # 0.3363
print(paste("impact weight for watch: ", imp_wW))# 0.2996

rm(imp)

data_repoData$imp <-
  imp_wF*data_repoData$forks +
  imp_wS*data_repoData$stars +
  imp_wW*data_repoData$watch


## from the data, we can see that the maximum imp is from repo "https://github.com/robbyrussell/oh-my-zsh". it has a very andlarge community and a very good readme. It has twitter and facebook channel.



## Calculate repo age ####
library(lubridate)
data_repoData$age <- f_get_age(as_date(data_repoData$created_at), age.day = as_date("2018-04-12")) # TODO: can add more accurate age.day
data_repoData$age_active <- f_get_age(as_date(data_repoData$latest_update), age.day = as_date("2018-04-12")) # TODO: can add more accurate age.day
# note that there some noises in the data, i.e., latest_update not defined as 89,429.
data_repoData$yr_active <- f_get_age(as_date(data_repoData$created_at), age.day = as_date(data_repoData$latest_update))
  # plot age related graph
data_repoData %>% group_by(age) %>% mutate(count=n())  %>%   ggplot(aes(x=age))+ geom_bar() + ggtitle("age distribution") + xlab("years of creation by 2018")+ coord_flip() #seems most projects are 5-9 years old.
  data_repoData %>% mutate(age_active = ifelse(age-age_active<0 | age_active <0, -1, age_active )) %>% group_by(age_active) %>% ggplot(aes(x=age_active)) + geom_bar()
data_repoData <- data_repoData %>% mutate(age_active = ifelse(age-age_active<0 | age_active <0 |is.na(age_active), -1, age_active )) %>% mutate(yr_active = ifelse(age-age_active<0 | age_active <0 |is.na(age_active), -1, yr_active ))
  data_repoData %>% group_by(yr_active)  %>%   ggplot(aes(x=yr_active))+ geom_bar()



# Data Exploration and Preparation ####
data_input <-data_repoData %>%
  select(login,repo_id, repo_name,branches,releases,issues,contributors,commits,size,language,organization,source,parent,isfork,age,age_active, yr_active, avg_followers, avg_following,forks,stars,watch,imp,created_at,latest_update) %>%
  distinct(repo_id,.keep_all=TRUE) %>%
  mutate(organization = ifelse(is.na(organization),"NA",organization),language = ifelse(is.na(language),"NA",language)) %>%
    mutate(organization = as.factor(organization),language=as.factor(language),login = as.factor(login))


save(data_repoData,data_users, data_noreadme,data_readme,data_input, file="data/data_input_v2_201804.RData")
load("data/data_input_v2_201804.RData")
saveRDS(data_input,file="data/data_input_v2_201804.RDS")




# load and combine v2, v2+gd1, v2+gd2 data into training and testing set. ###
f_load_and_process <- function(path_input_file){
  data_input2_cut <-  readRDS(file=path_input_file) %>% mutate(imp_log = log10(imp+1)) %>% mutate(imp_cut = ifelse(imp_log>=2,2,floor(imp_log)) ) %>% mutate(imp_cut = as.factor(imp_cut))
  data_input2_cut
}

f_check_good_pct <- function(data_input2_cut.v2.gd){
    tmp.total.age <- data_input2_cut.v2.gd%>%  group_by(year=year(as.Date(created_at))) %>% summarise(totalcount=n())
      data_input2_cut.v2.gd %>% filter(imp_cut==2|imp_cut==1) %>% group_by(year=year(as.Date(created_at))) %>% summarise(count=n()) %>% left_join(tmp.total.age) %>% mutate(rate=count*100/totalcount)
}

# load version 2, good data
data_input2_cut.v2.gd <- f_load_and_process("data/data_input_v2_g_201804.RDS")
# load version 2, good2 data
data_input2_cut.v2.gd.2 <- f_load_and_process( "data/data_input_v2_g_2_201804.RDS")
# load version 2 data
data_input2_cut <-  f_load_and_process("data/data_input_v2_201804.RDS")



   #==check ####
      f_check_good_pct(data_input2_cut)
      f_check_good_pct(data_input2_cut.v2.gd)
      f_check_good_pct(data_input2_cut.v2.gd.2)

      data_input2_cut.v2.gd %>% View()
      data_input2_cut.v2.gd %>% group_by(imp_cut) %>% summarise(ct=n())

# split and balance data #####
set.seed(9237)
split<-createDataPartition(y = data_input2_cut$imp_cut, p = 0.7, list = FALSE)
data_train_cut<-data_input2_cut[split,]
data_vali_cut<-data_input2_cut[-split,]
rm(split)
rm(data_input2_cut)
data_train_cut <-  data_train_cut %>% rbind(data_input2_cut.v2.gd,data_input2_cut.v2.gd.2)
data_train_cut <- data_train_cut %>% distinct(repo_id,.keep_all = TRUE)
# try to rebalance the sample and train the model again
print("Before upsampling, check the class frequency")
data_train_cut %>%  group_by(imp_cut) %>% summarise(count = n())
  # record distribution results ####
        # #for data_v2:
        # # A tibble: 3 x 2
        #   imp_cut count
        #    <fctr> <int>
        # 1       0 90566
        # 2       1   774
        # 3       2    96

        # for data_v2+g+g2
        # # A tibble: 3 x 2
        #   imp_cut count
        #    <fctr> <int>
        # 1       0 91993
        # 2       1  9555
        # 3       2  5552

        # for data_v2+g+g2, after deplicate removal
        # # A tibble: 3 x 2
        #   imp_cut count
        #    <fctr> <int>
        # 1       0 91993
        # 2       1  9541
        # 3       2  5475

data_train_cut_bl <- upSample(x = data_train_cut,
                         y = data_train_cut$imp_cut) %>% select(-Class)
data_vali_cut_bl <- upSample(x = data_vali_cut,
                         y = data_vali_cut$imp_cut) %>% select(-Class)
print("After up sampling")
data_train_cut_bl %>% group_by(imp_cut) %>% summarise(count = n())
data_vali_cut_bl  %>% group_by(imp_cut) %>% summarise(count = n())
predictors <- c("branches","releases","issues","commits","size","yr_creation","label", "isfork","yr_active", "avg_following","ave_followers","contributors","url_num","wiki","command","contact","copyright","rsize","hasReadme","lang","parent")
save(data_train_cut,data_vali_cut,data_train_cut_bl,data_vali_cut_bl,predictors,file="data/model_inputs_v2_g_201804.RData")
