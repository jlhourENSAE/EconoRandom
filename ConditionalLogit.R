### Conditional Logit Model
### Jeremy L Hour
### 7 mars 2016
### EDITED: 15/03/2017

### Set working directory
setwd("//ulysse/users/JL.HOUR/1A_These/B. ENSAE Classes/EconoRandom")

rm(list=ls())


### 0. Settings
### Load packages
library("maxLik")

### Load user-defined functions
source("functions/MNLlogLik.R")


### 1. Load data: simulate a choice model
data("mtcars")
J = nrow(mtcars)
p = ncol(mtcars)

# Form non-random part of utility X_j%*%beta + xi_j
set.seed(12071990)
beta = .1*rnorm(11)/apply(mtcars,2,sd)
util = as.matrix(mtcars)%*%beta + rnorm(J, sd=1)

# Simulate consumer's decisions
n = 10000
eps = matrix(-log(-log(runif(n*J))), nrow=n, ncol=J) # Simulate type I GEV
totutil = rep(1,n) %x% t(util - 5) + 3*eps 

y = mapply(function(x) which(totutil[x,]==max(totutil[x,])),1:n) # buy the care with largest utility
y = y*apply(totutil,1,function(x) any(x>0)) # if negative utility, don't buy a car

marketshare = data.frame("Car"=c("None",rownames(mtcars)),
                          "MS"=as.numeric(100*table(y)/n) )
print(marketshare)

### 2. ML Estimation
par0 = rep(0,p+1)
MLfit = maxBFGS(MNLlogLik, start=par0, print.level=4, finalHessian=T, y=y, X=cbind(rep(1,J),mtcars) )
summary(MLfit)

### 3. Regression on relative market shares
s = as.vector(table(y)/n)
y_tilde = log(s[-1]) - log(s[1])

regfit = lm(y_tilde ~ .,data=mtcars)
summary(regfit)


### Plot
plot(beta,MLfit$estimate[-1], pch=19, col="forestgreen",
     xlab="True coefficients",
     ylab="Estimates",
     ylim=c(-.8,.8),
     main="Demand coefficients")
points(beta,coef(regfit)[-1], pch=22, col="firebrick")
abline(h=0,
       lty=2,col="grey")
box() 
legend(.07,-.4,
       legend=c("ML", "Linear Reg"),
       col=c("forestgreen","firebrick"), pch=c(19,22))

### Conclusion:
### The two methods (ML and regression on market shares)
### give roughly the same numerical values