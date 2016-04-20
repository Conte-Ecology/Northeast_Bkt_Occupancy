save(glmm.M35, glmm.M51, data2, data.fit2, df.fit, df.valid, auc.comp, df.fit.all, auc.boot.M35v, auc.boot.M51v, file="Data_For_Ana.RData")

# Models
glmm.M35 <- glmer(pres ~ flow + tmax.stream + rise.slope + forest + wetland + dams + (1 + forest + wetland|fHuc10), family = binomial(link = "logit"), data = df.fit, control = glmerControl(optimizer="bobyqa"))
summary(glmm.M35) # environmental model

glmm.M51 <- glmer(pres ~ area + precip + tmax + forest + wetland + surfC + dams + hydroAB + (1 + forest + wetland|fHuc10), family = binomial(link = "logit"), data = df.fit, control = glmerControl(optimizer="bobyqa")) # climate model
summary(glmm.M51)

# Data
data2 # data for all catchments
data.fit2 # data used for standardizing for model fitting
df.fit # calibration (training) data for fitting models (standardized all but dams)
df.valid # data for validation (10% of data held out)
auc.comp # data frame for comparing AUC with 95% CI
df.fit.all # data for all catchments standardized for model fitting

# Predictions
pred.valid <- inv.logit(predict(glmm.M35, df.valid, allow.new.levels = TRUE))
pred.valid2 <- inv.logit(predict(glmm.M51, df.valid, allow.new.levels = TRUE))

# ROC plot
library(AUC)
streamV.roc <- roc(pred.valid, as.factor(df.valid$pres))
climateV.roc <- roc(pred.valid2, as.factor(df.valid$pres))

par(mar=c(3,3,2,1), mgp=c(2,.7,0), tck=-.01)
plot(streamV.roc)
plot(climateV.roc, add=T, col='red')
legend(0.6, 0.2, legend=c("Environmental", "Climate"), col=c(1,2), lty=c(1,1))

# Compare AUCs
row.names(auc.comp) <- c("Environmental Validation", "Climate Validation")
auc.comp$Model <- as.factor(row.names(auc.comp))

se <- ggplot(auc.comp, aes(Model, Mean,
                           ymin = LCI, ymax=UCI, colour = Model))
se + geom_linerange() + geom_point(aes(Model, AUC), colour = 'black') #+ geom_pointrange() 


############ Semivariograms (Torgeogram) #############
df.fit.all$psi.climate <- inv.logit(predict(glmm.M51, df.fit.all, allow.new.levels = TRUE))
df.fit.all$psi.stream <- inv.logit(predict(glmm.M35, df.fit.all, allow.new.levels = TRUE))

data.geo <- merge(df.fit.all[ , c("FEATUREID", "psi.stream", "psi.climate", "pres")], data[ , c("FEATUREID", "Latitude", "Longitude")], by="FEATUREID", all.x=T)
str(data.geo)
summary(data.geo)

# dists <- dist(data.geo[ , c("Latitude", "Longitude")])
# summary(dists) 
#     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 0.000266 0.822900 1.300000 1.356000 1.834000 3.975000 

rm(dists) # vector length = 331,286,670 (kills laptop)

library(geoR)
df.geo <- as.geodata(data.geo, coords.col=c(5,6), data.col=c(2,3))
str(df.geo)

#plot(df.geo)
breaks = seq(0, 2, length.out = 25)
Torge <- variog(df.geo, breaks=breaks, pairs.min=10)

v1.summary <- cbind(c(1:10), Torge$v, Torge$n)
colnames(v1.summary) <- c("lag", "semi-variance", "semi-variance", "# of pairs")
v1.summary
plot(Torge, type='b', pch = c(1,2))

hawkins.cressie <- variog(df.geo, estimator.type="modulus")
plot(hawkins.cressie)

# just look at small distances (within ~10km)
breaks = seq(0, 0.1, length.out = 25)
Torge.sm <- variog(df.geo, breaks=breaks)
v1.summary <- cbind(c(1:(length(breaks)-1)), Torge.sm$v, Torge.sm$n)
colnames(v1.summary) <- c("lag", "semi-variance", "semi-variance", "# of pairs")
v1.summary
plot(Torge.sm, type='l')

# Semivariogram of P/A data

df.geo.pres <- as.geodata(data.geo, coords.col=c(5,6), data.col=c(4))
breaks = seq(0, 1, length.out = 25)
Torge <- variog(df.geo.pres, breaks=breaks, pairs.min=10)

v1.summary <- cbind(c(1:10), Torge$v, Torge$n)
colnames(v1.summary) <- c("lag", "semi-variance", "semi-variance", "# of pairs")
v1.summary
plot(Torge, type='b', pch = c(1,2,3))



################ Plots of Effects ###########

### Effect of forest
# simulate coef values
n.sims=1000
simCoef <- as.data.frame(fixef(sim(glmm.M35, n.sims=n.sims)))
names(simCoef) <- names(fixef(glmm.M35))

# Plot effect of catchment forest on occurrence prob at a typical HUC10 basin # Gelman p. 44
eff.forest <- data.frame(forest.raw=seq(0,100,length.out=100), tmax.stream=rep(0,100), flow=rep(0,100), rise.slope=rep(0,100))
eff.forest$forest <- (eff.forest$forest.raw - mean(data.fit2$forest, na.rm=T))/sd(data.fit2$forest, na.rm=T)

sim.prob.forest <- matrix(NA, nrow=nrow(eff.forest), ncol=n.sims)
for (i in 1:n.sims){
  sim.prob.forest[,i] <- exp(simCoef[i,1] + simCoef[i,"forest"]*eff.forest$forest) / (1 + exp(simCoef[i,1] + simCoef[i,"forest"]*eff.forest$forest))
}
sim.prob.forest <- as.data.frame(sim.prob.forest)

eff.forest$mean <- apply(sim.prob.forest[,1:n.sims], 1, mean)
eff.forest$lower <- apply(sim.prob.forest[,1:n.sims], 1, quantile, probs=c(0.025))
eff.forest$upper <- apply(sim.prob.forest[,1:n.sims], 1, quantile, probs=c(0.975))

ggplot(eff.forest, aes(x = forest.raw, y = mean)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), fill="grey") +
  geom_line(colour = "black", size = 2) +
  #labs(title = "Occupancy in CT, MA, NH & NY") +
  xlab("Percent forest cover upstream") +
  ylab("Occupancy probability") +
  theme_bw() + 
  ylim(0, 1) +
  theme(axis.text.y = element_text(size=15),
        axis.text.x = element_text(size=15),
        axis.title.x = element_text(size=17, face="bold"),
        axis.title.y = element_text(size=17, angle=90, face="bold"),
        plot.title = element_text(size=20))


### Effect of rise.slope
# simulate coef values
n.sims=1000
simCoef <- as.data.frame(fixef(sim(glmm.M35, n.sims=n.sims)))
names(simCoef) <- names(fixef(glmm.M35))

# Plot effect of catchment rise.slope on occurrence prob at a typical HUC10 basin # Gelman p. 44
eff.rise.slope <- data.frame(rise.slope.raw=seq(0.5,1,length.out=100), forest=rep(0,100), flow=rep(0,100), rise.slope=rep(0,100))
eff.rise.slope$rise.slope <- (eff.rise.slope$rise.slope.raw - mean(data.fit2$rise.slope, na.rm=T))/sd(data.fit2$rise.slope, na.rm=T)

sim.prob.rise.slope <- matrix(NA, nrow=nrow(eff.rise.slope), ncol=n.sims)
for (i in 1:n.sims){
  sim.prob.rise.slope[,i] <- exp(simCoef[i,1] + simCoef[i,"rise.slope"]*eff.rise.slope$rise.slope) / (1 + exp(simCoef[i,1] + simCoef[i,"rise.slope"]*eff.rise.slope$rise.slope))
}
sim.prob.rise.slope <- as.data.frame(sim.prob.rise.slope)

eff.rise.slope$mean <- apply(sim.prob.rise.slope[,1:n.sims], 1, mean)
eff.rise.slope$lower <- apply(sim.prob.rise.slope[,1:n.sims], 1, quantile, probs=c(0.025))
eff.rise.slope$upper <- apply(sim.prob.rise.slope[,1:n.sims], 1, quantile, probs=c(0.975))

ggplot(eff.rise.slope, aes(x = rise.slope.raw, y = mean)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), fill="grey") +
  geom_line(colour = "black", size = 2) +
  #labs(title = "Occupancy in CT, MA, NH & NY") +
  xlab("Stream temperature sensitivity") +
  ylab("Occupancy probability") +
  scale_x_reverse() +
  theme_bw() + 
  ylim(0, 1) +
  theme(axis.text.y = element_text(size=15),
        axis.text.x = element_text(size=15),
        axis.title.x = element_text(size=17, face="bold"),
        axis.title.y = element_text(size=17, angle=90, face="bold"),
        plot.title = element_text(size=20))




### Effect of tmax.stream

# simulate coef values
n.sims=1000
simCoef <- as.data.frame(fixef(sim(glmm.M35, n.sims=n.sims)))
names(simCoef) <- names(fixef(glmm.M35))

# Plot effect of catchment tmax.stream on occurrence prob at a typical HUC10 basin # Gelman p. 44
eff.tmax.stream <- data.frame(tmax.stream.raw=seq(10,30,length.out=100), forest=rep(0,100), flow=rep(0,100), rise.slope=rep(0,100))
eff.tmax.stream$tmax.stream <- (eff.tmax.stream$tmax.stream.raw - mean(data.fit2$tmax.stream, na.rm=T))/sd(data.fit2$tmax.stream, na.rm=T)

sim.prob.tmax.stream <- matrix(NA, nrow=nrow(eff.tmax.stream), ncol=n.sims)
for (i in 1:n.sims){
  sim.prob.tmax.stream[,i] <- exp(simCoef[i,1] + simCoef[i,"tmax.stream"]*eff.tmax.stream$tmax.stream) / (1 + exp(simCoef[i,1] + simCoef[i,"tmax.stream"]*eff.tmax.stream$tmax.stream))
}
sim.prob.tmax.stream <- as.data.frame(sim.prob.tmax.stream)

eff.tmax.stream$mean <- apply(sim.prob.tmax.stream[,1:n.sims], 1, mean)
eff.tmax.stream$lower <- apply(sim.prob.tmax.stream[,1:n.sims], 1, quantile, probs=c(0.025))
eff.tmax.stream$upper <- apply(sim.prob.tmax.stream[,1:n.sims], 1, quantile, probs=c(0.975))

ggplot(eff.tmax.stream, aes(x = tmax.stream.raw, y = mean)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), fill="grey") +
  geom_line(colour = "black", size = 2) +
  #labs(title = "Occupancy in CT, MA, NH & NY") +
  xlab("Annual maximum stream temperature (C)") +
  ylab("Occupancy probability") +
  theme_bw() + 
  ylim(0, 1) +
  theme(axis.text.y = element_text(size=15),
        axis.text.x = element_text(size=15),
        axis.title.x = element_text(size=17, face="bold"),
        axis.title.y = element_text(size=17, angle=90, face="bold"),
        plot.title = element_text(size=20))


### Effect of catchment flow
eff.flow <- data.frame(flow.raw=seq(1,50,length.out=100))
eff.flow$flow <- (eff.flow$flow.raw - mean(data.fit2$flow, na.rm=T))/sd(data.fit2$flow, na.rm=T)

sim.prob.flow <- matrix(NA, nrow=nrow(eff.flow), ncol=n.sims)
for (i in 1:n.sims){
  sim.prob.flow[,i] <- exp(simCoef[i,1] + simCoef[i,"flow"]*eff.flow$flow) / (1 + exp(simCoef[i,1] + simCoef[i,"flow"]*eff.flow$flow))
}
sim.prob.flow <- as.data.frame(sim.prob.flow)

eff.flow$mean <- apply(sim.prob.flow[,1:n.sims], 1, mean)
eff.flow$lower <- apply(sim.prob.flow[,1:n.sims], 1, quantile, probs=c(0.025))
eff.flow$upper <- apply(sim.prob.flow[,1:n.sims], 1, quantile, probs=c(0.975))

ggplot(eff.flow, aes(x = (flow.raw), y = mean)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), fill="grey") +
  geom_line(colour = "black", size = 2) +
  #labs(title = "Occupancy in CT, MA, NH & NY") +
  xlab("Mean annual flow") +
  ylab("Occupancy probability") +
  theme_bw() + 
  ylim(0, 1) +
  theme(axis.text.y = element_text(size=15),
        axis.text.x = element_text(size=15),
        axis.title.x = element_text(size=17, face="bold"),
        axis.title.y = element_text(size=17, angle=90, face="bold"),
        plot.title = element_text(size=20))



