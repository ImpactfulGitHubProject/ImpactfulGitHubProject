pdf('data/20140420_plot_cor.pdf')
predictors <- c("branches","releases","issues","commits","size",  "isfork", "avg_following", "contributors","url_num","wiki","command","contact","copyright","rsize","imp")

data_train_cut%>%
    select(one_of(predictors)) %>%
  #mutate(parent=ifelse(parent=="-1",0,1)) %>%
    cor(use = "na.or.complete") %>%
    corrplot(method="shade",shade.col=NA, tl.col="black", tl.srt=45, title = "pearson correlation matrix for numeric features", mar = c(0,0,1,0))


data_train_cut_bl%>%
    select(one_of(predictors)) %>%
  #mutate(parent=ifelse(parent=="-1",0,1)) %>%
    cor(use = "na.or.complete") %>%
    corrplot(method="shade",shade.col=NA, tl.col="black", tl.srt=45, title = "pearson correlation matrix for numeric features (balanced training set)", mar = c(0,0,1,0))

dev.off()
