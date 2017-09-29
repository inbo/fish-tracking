# final model
library(pscl)

# Read scaled data set
scaled <- read.table("./scaled_data.csv", sep = ",", quote = "\"", row.names = 1)

nb2 <- zeroinfl(count_max ~ WindSpeed_scaled +  WindDir_scaled + Tilt_scaled * degree_scaled + Noise_scaled + CurrentSpeed_scaled + CurrentDir_scaled + offset(log(maxi)),
              data = scaled, dist = "negbin")
summary(nb2)

## Test maringal effects = assess partial effects
#here we use predict

# Create an artifical grid for each of the covariate values
require(stats)
head(scaled)

# Covariate WindSpeed
newdata <- NULL
head (newdata)

newdata <- seq(min(scaled$WindSpeed_scaled), max(scaled$WindSpeed_scaled), by = .1)
newdata <- data.frame(newdata)
colnames(newdata) <- c("WindSpeed_scaled")
newdata$CurrentSpeed_scaled <- median(scaled$CurrentSpeed_scaled)
newdata$CurrentDir_scaled   <- median(scaled$CurrentDir_scaled)
newdata$WindDir_scaled      <- median(scaled$WindDir_scaled)
newdata$Tilt_scaled         <- median(scaled$Tilt_scaled)
newdata$Noise_scaled        <- median(scaled$Noise_scaled)
newdata$degree_scaled       <- median(scaled$degree_scaled)
newdata$Wave_scaled         <- median(scaled$Wave_scaled)
newdata$maxi                <- median(scaled$maxi)


summary(newdata)

# Predict the expected values for each variable
#although we ask for se (se.fit=TRUE), we don't get them...
P1<- predict(nb2,newdata=newdata,
             se.fit=TRUE,MC=2500)
P1

P1<-as.list(P1)

newdata$P1 <- P1

#Plot output

plot(x=newdata$WindSpeed_scaled,
     y=newdata$P1,
     xlab="Wind Speed (scaled)",
     ylab="Predicted Counts",
     type="n")

lines(x=newdata$WindSpeed_scaled,
      y=newdata$P1,
      lwd=3)

lines(x = newdata$CurrentSpeed_scaled,
      y = exp(newdata$P1 + 1.96 * P1$se.fit),
      lwd = 3,
      lty = 2)
lines(x = MyData$WindSpeed_scaled,
      y = exp(newdata$P1 - 1.96 * P1$se.fit),
      lwd = 3,
      lty = 2)

dev.copy(tiff,'Marginal_effect_WindSpeed.tiff')
dev.off()
