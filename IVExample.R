setwd("R:/Simulations/R_Code")

rm(list=ls())
set.seed(12071990)


### 0. Settings

### Load packages
library("MASS")
library("ggplot2")
library("gridExtra")


### Simulated data
p <- 10
n <- 1000
### Covariate correlation coefficients
rho <- .5
Sigma <- matrix(0,nrow=p, ncol=p)

for(k in 1:p){
  for(j in 1:p){
    Sigma[k,j] <- rho^abs(k-j)
  }
}

# Simulate covariates
X <- mvrnorm(n = n, mu=rep(0,p), Sigma)

# Coefficients
gamma <- rep(0,p)

for(j in 1:abs(p/2)){
  gamma[j] <- 1*(-1)^(j) / j^2
}


# Simulate covariates
X <- mvrnorm(n = n, mu=rep(0,p), Sigma)

# Simulate outcome
y <- X%*%gamma + rnorm(n)

b_MCO <- solve(t(X)%*%X) %*% (t(X)%*%y)
eps <- y-X%*%b_MCO
sigma <- sd(eps)
Var_MCO <- sigma^2*solve(t(X)%*%X/n)
Var_Robust <- solve(t(X)%*%X/n) %*% (t(X)%*%diag(as.vector(eps^2))%*%X/n) %*% solve(t(X)%*%X/n)

summary(lm(y ~X))


### Moindres carr�s simples
n <- 1000
a <- 0
b <- 1
v_eps <- 2
J <- 1e5
Results <- matrix(NA,ncol=1,nrow=J)

for(j in 1:J){
  x <- rnorm(n)
  y <- a + b*x + rnorm(n,sd=sqrt(v_eps))
  
  b_MCO <- mean(x*y)/mean(x^2)
  
  Results[j] <- sqrt(n)*(b_MCO-b)
}
Results <- as.data.frame(Results)

ggplot(Results, aes(x=V1)) + 
  geom_histogram(binwidth = .03, alpha=.5, position='identity',fill="steelblue", aes(y = ..density..)) +
  scale_x_continuous(name="Estimate") +
  ggtitle("MCO distribution") + 
  stat_function(fun = dnorm, args=list(mean=0, sd=sd(Results$V1)), colour="darkorchid3", size=1) +
  theme(plot.title = element_text(lineheight=.8, face="bold"),legend.position="none") 



### Exemple variables instrumentales

p <- 2
n <- 100

# Parameters of the model
rho <- .5 # correlation coefficient
Sigma <- matrix(0,nrow=p, ncol=p)

for(k in 1:p){
  for(j in 1:p){
    Sigma[k,j] <- rho^abs(k-j)
  }
}

a_z <- 1
b_z <- 2
b <- 1


J <- 1e4
Results <- matrix(NA,ncol=2,nrow=J)

for(j in 1:J){
  eps <- mvrnorm(n = n, mu=rep(0,p), Sigma)
  z <- rnorm(n)
  
  x <- a_z + b_z*z + eps[,2]
  y <- b*x + eps[,1]
  
  b_MCO <- mean(x*y)/mean(x^2)
  b_2SLS <-  mean(z*y)/mean(z*x)
  
  Results[j,] <- c(sqrt(n)*(b_MCO-b),sqrt(n)*(b_2SLS-b))
}
Results <- as.data.frame(Results)

plot1 <- ggplot(Results, aes(x=V1)) + 
  geom_histogram(binwidth = .03, alpha=.5, position='identity',fill="steelblue", aes(y = ..density..)) +
  scale_x_continuous(name="Estimate") +
  ggtitle("MCO distribution") + 
  stat_function(fun = dnorm, args=list(mean=0, sd=sd(Results$V1)), colour="darkorchid3", size=1) +
  theme(plot.title = element_text(lineheight=.8, face="bold"),legend.position="none") 

plot2 <- ggplot(Results, aes(x=V2)) + 
  geom_histogram(binwidth = .03, alpha=.5, position='identity',fill="steelblue", aes(y = ..density..)) +
  scale_x_continuous(name="Estimate") +
  ggtitle("2SLS distribution") + 
  stat_function(fun = dnorm, args=list(mean=0, sd=sqrt(1/b_z^2)), colour="darkorchid3", size=1) +
  theme(plot.title = element_text(lineheight=.8, face="bold"),legend.position="none") 

grid.arrange(plot1, plot2, ncol=2)

x_hat <- predict(lm(x ~ z))
summary(lm(y ~ x_hat))