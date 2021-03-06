library(mvtnorm)
library(Matrix)
library(MASS)

## generates matrices with certain number of latent factors
## strength represents how large the covariances can be (larger means stronger relationships)
getMat <- function(numFactors, numSpecies, strength) {
  vectors <- lapply(1:numFactors, function(x, y) {
    runif(numSpecies, -y, y) ##  could go to rnorm() too
  }, strength)
  
  cov <- lapply(vectors, function(x) {
    x %*% t(x)
  })
  
  A <- matrix(0, nrow = numSpecies, ncol = numSpecies)
  
  for (i in 1:numFactors) {
    A <- A + cov[[i]]
  }
  return(A)
}

set.seed(13211)

numFactors <- 2
strength <- 1
numSpecies <- 30

testMat <- getMat(numFactors, numSpecies, strength)


#### given a matrix, simulate occurrence data ####

numSites <- 100
numSpecies <- 15

# mat: expects covariance matrix
# no fixed effects

## WARNING - hasn't been checked to make sure an increase in signal induces more misspecification
simData <- function(mat, signal,  numSpecies, numSites) {
  #browser()
  X <- matrix(rnorm(numSites), numSites, 1) ## value for every site
  
  X.coef <- signal
  X.shift <- matrix(rnorm(numSpecies,sd =3), numSpecies, 1) ## each species gets a shift from same effect, this will introduce nonlinearity in the covariance between species
  ## tried sd=5 didn't make it better
  eta <- tcrossprod(as.matrix(X), X.coef)
  
  
  sim_y <- matrix(NA, nrow = numSites, ncol = numSpecies)
  for (i in 1:numSites) {
    samples <- mvrnorm(1, eta[i]+X.shift, mat) ## expects covariance matrix
    sim_y[i,] <- rbinom(numSpecies, size = 1, prob = pnorm(samples))
  }
  
  return(sim_y)
}

signal = 1

test1 <- simData(testMat,  signal, numSpecies, numSites)
#test1


## thing that introduces more/less nonlinearity: how signal to shift magnitude differs

## use good species to site ratio from correctly specified

## 100 sites, 15 species

signal = c(0.1, 0.5, 1, 2, 5)
numFactors <- c(1, 2, 5, 10, 15)

scenarios = expand.grid(numFactors = numFactors, signal=signal) ## 25

setwd("~/Desktop/communityDimensions")
write.csv(scenarios,"R/simulation_setup/simulation_study_data/nonlinearScenarios.csv",row.names=F)



trueMats = lapply( scenarios[,1], getMat,numSpecies, strength)

simulatedData = mapply(simData, trueMats, scenarios[,2], numSpecies, numSites, SIMPLIFY = F)

save(trueMats, file = "R/simulation_setup/simulation_study_data/matrices/testMats_nonlinear.RData")

save(simulatedData, file = "R/simulation_setup/simulation_study_data/observed_occurrence/testData_nonlinear.RData") ## need to check