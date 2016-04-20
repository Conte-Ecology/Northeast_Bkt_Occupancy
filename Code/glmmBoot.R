# Function for getting bootstrapped glmer predictions in parallel
glmmBoot <- function(dat, form, R, nc){
  # dat = data for glmer (lme4) logistic regression
  # form = formula of glmer equation for fitting
  # R = total number of bootstrap draws - should be multiple of nc b/c divided among cores evenly
  # nc = number of cores to use in parallel
  
  library(parallel)
  cl <- makeCluster(nc) # Request # cores
  clusterExport(cl, c("dat", "form", "nc", "R"), envir = environment()) # Make these available to each core
  clusterSetRNGStream(cl = cl, 6546540)
  
  out <- clusterEvalQ(cl, {
    library(lme4)
    library(boot) # used for the inv.logit function
    b.star <- NULL
    pres.star <- NULL 
    pred.star <- NULL
    n <- length(dat$pres)
    for(draw in 1:(R/nc)){
      df.star <- dat[sample(1:n, size=n, replace=T), ] # bootstrap data
      #df.star <- dat[sample(1:n, size=n, replace=F), ] 
      mod <- glmer(form, family = binomial(link = "logit"), data = df.star, control = glmerControl(optimizer="bobyqa"))
      b.star <- rbind(b.star, coef(mod))
      pres.star <- rbind(pres.star, df.star$pres)
      pred.star <- rbind(pred.star, inv.logit(predict(mod, df.star, allow.new.levels = TRUE)))
    }
    
    # make into lists formatted for the ROCR package
    lab <- list(pres.star)
    for(i in 1:dim(pres.star)[1]){
      lab[[i]] <- as.integer(pres.star[i, ])
    }
    
    pred <- list(pred.star)
    for(i in 1:dim(pred.star)[1]){
      pred[[i]] <- as.numeric(pred.star[i,])
    }
    
    pred.all <- list(pred, lab)
    names(pred.all) <- c("predictions", "observed")
    
    return(pred.all)
  }) # end cluster call
  stopCluster(cl) 
  
  #assign("out", out, envir = .GlobalEnv) # allow access outside function to help debugging
  
  # combine lists from each core to format for ROCR
  lab1 <- out[[1]]$observed
  for(i in 2:length(out)){
    foo <- out[[i]]$observed
    lab1 <- c(lab1, foo)
  }
  
  pred1 <- out[[1]]$predictions
  for(i in 2:length(out)){
    foo <- out[[i]]$predictions
    pred1 <- c(pred1, foo)
  }
  
  pred.mod <- list(pred1, lab1)
  names(pred.mod) <- c("predictions", "observed")
  
  return(pred.mod)
} # end function

system.time(pred.M35 <- glmmBoot(dat=df.fit, form=formula(glmm.M35), R=1000, nc=4))
system.time(pred.M35v <- glmmBoot(dat=df.valid, form=formula(glmm.M35), R=1000, nc=4))
system.time(pred.M51 <- glmmBoot(dat=df.fit, form=formula(glmm.M51), R=1000, nc=4))
system.time(pred.M51v <- glmmBoot(dat=df.valid, form=formula(glmm.M51), R=1000, nc=4))

library(ROCR)
p35 <- prediction(pred.M35$predictions, pred.M35$observed)
p51 <- prediction(pred.M51$predictions, pred.M51$observed)
p35v <- prediction(pred.M35v$predictions, pred.M35v$observed)
p51v <- prediction(pred.M51v$predictions, pred.M51v$observed)
perf35 <- performance(p35, "tpr", "fpr")
perf35v <- performance(p35v, "tpr", "fpr")
perf51 <- performance(p51, "tpr", "fpr")
perf51v <- performance(p51v, "tpr", "fpr")






