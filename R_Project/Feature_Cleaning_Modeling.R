####PACKAGE LIBRARY####
#######################

# In R-studios we install the package only once. Once we install it we load it with library
# install.packages("broom", type="binary")
# install.packages("ggplot2")
# install.packages("Hmisc")
# install.packages("e1071")
# install.packages("blorr")
library("blorr")
library("broom")
library("ggplot2")
library("Hmisc")
library("e1071")
library("survival")
# install.packages("rms")
library("rms")
# install.packages("survival")
# install.packages("reprex")
library("tidyverse")
library("reprex")
# install.packages("dplyr")
library("dplyr")
# install.packages("tidyverse")
#####################PROJECT####################################


# 1. We load the data. 
credit_data <- read.csv(file = 'cs-training.csv')


# 2. We start feature by feature plotting and fixing the data inside.
# 2.0 The output variable 
summary(credit_data$SeriousDlqin2yrs)
# The dataset is extremely disbalanced 1: 10026 (6.684%) 0 : 139974 (93.316%)
# This must be in our mind all the time while cleaning !!! We drop/impute ... only if it does not further
# destroy the balance or if we see that the rows with 1 are actually fake rows (damaged data).

# 2.1. Number (X)


summary(credit_data$X)
# We see that this is a simple numerator feature. Since R already creates an index doing the same in a dataframe
# We can just drop this feature. It has no predictive qualities.
credit_data_dropped_number = subset(credit_data, select = -c(X))

# 2.2 NumberOfTimes90DaysLate, NumberOfTime60-89DaysPastDueNotWorse, NumberOfTime30-59DaysPastDueNotWorse


summary(credit_data$NumberOfTimes90DaysLate)
summary(credit_data$NumberOfTime30.59DaysPastDueNotWorse)
summary(credit_data$NumberOfTime60.89DaysPastDueNotWorse)
# Immediately from the summary we see issues. Based on the data there are people late 98 times in all categories
# This is impossible. Even if we take the shortest time period of 30 days and multiply with 98 times, this would mean
# that in the period of 2 years the person was late 2940 days. 2940 days is more than 8 years. Hence these features
# need to be cleaned of outliers. We perform boxplots to see better how many of these rows are there and their nature.

a = data.frame(group = "30-59", value = c(credit_data$NumberOfTime30.59DaysPastDueNotWorse))
b = data.frame(group = "60-89", value = c(credit_data$NumberOfTime60.89DaysPastDueNotWorse))
c = data.frame(group = "90", value = c(credit_data$NumberOfTimes90DaysLate))
plot.data = rbind(a,b,c) 
# this function will bind or join the rows. See data at bottom.
ggplot(plot.data, aes(x=group, y=value, fill=group)) +
geom_boxplot()
# ggplot2 is amazing ... 
# We see a lot of issues with these 3 features. They do not have any values between circa 20 and circa 95.
# They have all outliers however at 96 and 98. We drop these outliers from all three features.
credit_data_cleaned_days_past<-credit_data_dropped_number[!(credit_data_dropped_number$NumberOfTime60.89DaysPastDueNotWorse > 95 | credit_data_dropped_number$NumberOfTime30.59DaysPastDueNotWorse > 95 | credit_data_dropped_number$NumberOfTimes90DaysLate > 95),]
# We lost in total 269 rows which is not bad at all. Just checking quickly did we disbalance the dataset additionally 
summary(credit_data_cleaned_days_past$SeriousDlqin2yrs)
# The proportion is now 6.598% so we made the dataset 0,0086% more disbalanced but we dropped 269 rows
# that made no sense. This is acceptable.

#2.3 RevolvingUtilizationOfUnsecuredLines


# Defined as ratio of the total amount of money owed to total credit limit.

d = data.frame(group = "RevolvingUtilizationOfUnsecuredLines", value = c(credit_data_cleaned_days_past$RevolvingUtilizationOfUnsecuredLines))
ggplot(d, aes(x=group, y=value, fill=group)) +
geom_boxplot()
# The boxplot shows outliers but widely spread. We need to pick an exact point where we will cut.
# We will do this based on the proportion of SeriousDlqin2yrs. We do not want to lose a huge proportion of 1s.
length(which(credit_data_cleaned_days_past$SeriousDlqin2yrs == 1 & credit_data_cleaned_days_past$RevolvingUtilizationOfUnsecuredLines > 13 ))
# We see there are 14 defaulters where the RevolvingUtilization > 13 How many rows are there in total
length(which(credit_data_cleaned_days_past$RevolvingUtilizationOfUnsecuredLines > 13 ))
# There are 238 samples in total. This means that the proportion of defaulters in this group is 5.58%.
# The proportion is actually lower than in the whole population. This means we can cut outliers above this point.
# Already from 10 we are cutting too many rows. From 17 we are missing 1 datapoint so 13 seems to be the perfect point.
credit_data_cleaned_Utilization<-credit_data_cleaned_days_past[!(credit_data_cleaned_days_past$RevolvingUtilizationOfUnsecuredLines >13),]

#2.4 Age


e = data.frame(group = "Age", value = c(credit_data_cleaned_Utilization$age))
ggplot(e, aes(x=group, y=value, fill=group)) +
  geom_boxplot()

# There is one definetely eronous entry age = 0 which we will def. clean, but there are also ages above 100. 
# We apply the same logic as before, what is the default % in this group. Will we disbalance the dataframe further by 
# dropping them.

length(which(credit_data_cleaned_Utilization$SeriousDlqin2yrs == 1 & credit_data_cleaned_Utilization$age > 99 ))
length(which(credit_data_cleaned_Utilization$age > 99 ))
# There are 13 entries and 1 is a defaulter, around 7.11% . What about young people ?
length(which(credit_data_cleaned_Utilization$SeriousDlqin2yrs == 1 & credit_data_cleaned_Utilization$age < 30 ))
length(which(credit_data_cleaned_Utilization$age < 30 ))
# There are 972 rows that default younger than 30. All in total 8666 people. This is almost 12% !!!
# We see that younger people are proner to default than older(specially the super old). This makes us feel comfortable
# about dropping the 0 and the very old (>99)

credit_data_cleaned_age<-credit_data_cleaned_Utilization[!(credit_data_cleaned_Utilization$age <1),]
credit_data_cleaned_age<-credit_data_cleaned_age[!(credit_data_cleaned_age$age > 99),]

#2.5  DebtRatio


f = data.frame(group = "DebtRatio", value = c(credit_data_cleaned_age$DebtRatio))
ggplot(f, aes(x=group, y=value, fill=group)) +
  geom_boxplot()
# Massive amounts of outliers again, are these real data rows or not ?
length(which(credit_data_cleaned_age$DebtRatio > 3490 ))
# There are a whooping 3736 entries that have debt ratio >3490 ! We need to check are these "normal" rows.
# We will check it with the usual procedure, by checking the % of 1s in this group but also we will check are these rows
# the same rows that have N/A in the monthly income, because they look suspicious.
length(which(credit_data_cleaned_age$DebtRatio > 3490 & credit_data_cleaned_age$MonthlyIncome > 0))
# HA HA only 12 rows have any income given out of the 3736 !! Immediately we suspect these rows even more
length(which(credit_data_cleaned_age$SeriousDlqin2yrs == 1 & credit_data_cleaned_age$DebtRatio > 3490))
# The proportion of defaulters in these extremely suspicious rows is the population average, 6.68%. We can just drop
# these rows because they are highly suspicious and do not contribute in their balance to the dataset further.

credit_data_cleaned_DebtRatio<-credit_data_cleaned_age[!(credit_data_cleaned_age$DebtRatio >3490),]

# 2.6 NumberOfOpenCreditLinesandLones and NumberofRealestateLoansandLines

g = data.frame(group = "Number of Open Credit Loans/Lines", value = c(credit_data_cleaned_DebtRatio$NumberOfOpenCreditLinesAndLoans))
h = data.frame(group = "Number of Real estate Loans/Lines", value = c(credit_data_cleaned_DebtRatio$NumberRealEstateLoansOrLines))
plot.data2 = rbind(g,h) 

ggplot(plot.data2, aes(x=group, y=value, fill=group)) +
  geom_boxplot()

# Again we see outliers but muuuuuuuuch less pronounced than in other features. The boxplots even have bodies :)
# Let's observe the usual statistics about these potential outliers, specially do they have income and proportion of 1s
# in output variable.
length(which(credit_data_cleaned_DebtRatio$NumberOfOpenCreditLinesAndLoans > 20 )) #3728 people
length(which(credit_data_cleaned_DebtRatio$NumberOfOpenCreditLinesAndLoans > 20 &  credit_data_cleaned_DebtRatio$MonthlyIncome > 1)) # 3444 people
length(which(credit_data_cleaned_DebtRatio$NumberOfOpenCreditLinesAndLoans > 20 &  credit_data_cleaned_DebtRatio$SeriousDlqin2yrs == 1)) # 258
# We see that apart for 3728 - 3443 = 285 people all of them have income. We also see that the proportion
# of defaulters is quite high in this group hence we cannot just drop all of them out, they are valid datarows.

# Now let's see for the realestate lines. 
# They look quite good but just in any case let's repeat the usual procedure for the outlier check.
length(which(credit_data_cleaned_NumberOfLines$NumberRealEstateLoansOrLines > 10 )) #80 people
length(which(credit_data_cleaned_NumberOfLines$NumberRealEstateLoansOrLines > 10 &  credit_data_cleaned_NumberOfLines$MonthlyIncome > 1)) # All have income
length(which(credit_data_cleaned_NumberOfLines$NumberRealEstateLoansOrLines > 10 &  credit_data_cleaned_NumberOfLines$SeriousDlqin2yrs == 1)) # 20 !
# Wow we see that there is a 25% default rate in people with income and high number of lines. These lines look great , no need to drop anything


# 2.7 Monthly Income and Number of Dependents
# I first did the boxplots but both have some N/A values so better we input the N/A and then check if
# We should clean them even more

# For income we use median to input
credit_data_cleaned_DebtRatio$MonthlyIncome[is.na(credit_data_cleaned_DebtRatio$MonthlyIncome)] <- median(credit_data_cleaned_DebtRatio$MonthlyIncome, na.rm=TRUE)

# For Number of Depenedands the mode (most frequent value) which is 0. better like this than mode(..) so there is no implicit char conversion
credit_data_cleaned_DebtRatio$NumberOfDependents[is.na(credit_data_cleaned_DebtRatio$NumberOfDependents)] <- 0

na_count <-sapply(credit_data_cleaned_DebtRatio, function(y) sum(length(which(is.na(y)))))
na_count <- data.frame(na_count)

# As we see from na_count there are no more N/A values in the dataframe


i = data.frame(group = "Monthly income", value = c(credit_data_cleaned_DebtRatio$MonthlyIncome))

ggplot(i, aes(x=group, y=value, fill=group)) +
  geom_boxplot()

# Here the big positive outliers are fine, just very rich people. 

j = data.frame(group = "Number of Dependends", value = c(credit_data_cleaned_DebtRatio$NumberOfDependents))

ggplot(j, aes(x=group, y=value, fill=group)) +
  geom_boxplot()

# This all looks pretty much good at this point , all the features were cleaned. After the first models are fit,
# We can do additional cleaning by revisiting any of these points. However probably no need

credit_data_cleaned <- credit_data_cleaned_DebtRatio
# I do this so we can work with the _cleaned without ruining the DebtRatio df.
# Just in case we fuck up something

# 3.0 Skewdnes/Scaling/Preparing for model

hist.data.frame(credit_data_cleaned)


# Features are extremely skewed we can see it easily on the histograms, except age pretty much all of them.
# Some features like Number of Dependents have almost all 0 (which is ok) but might cause problem with logs.
# Let's quantify the skew using library e1071 and the skewness function

skew <-sapply(credit_data_cleaned, function(y) skewness(y))
skew <- data.frame(skew)

# The skew is massive. We need to pick which way to solve it . Possibilities are 
# 1) Log , might be problematic because of 0 . We either add small values per feature bla bla but sounds stupid 
# Solution : We use the fact we have no negative values in the dataframe, which means the square root is perfect.
# It solves skewnes quite well https://towardsdatascience.com/top-3-methods-for-handling-skewed-data-1334e0debf45

credit_data_cleaned_deskewed <- sqrt(credit_data_cleaned)

skew2 <-sapply(credit_data_cleaned_deskewed, function(y) skewness(y))
skew2 <- data.frame(skew2)

hist.data.frame(credit_data_cleaned_deskewed)


# The effectiveness is easily observeed by looking at the skew2 and skew tables

# Checking if nothing else was fucked
na_count2 <-sapply(credit_data_cleaned_deskewed, function(y) sum(length(which(is.na(y)))))
na_count2 <- data.frame(na_count)
sapply(credit_data_cleaned_deskewed, class)
# All good !


credit_data_cleaned_deskewed$SeriousDlqin2yrs <- as.factor(credit_data_cleaned_deskewed$SeriousDlqin2yrs)


model <- glm(SeriousDlqin2yrs ~ ., data = credit_data_cleaned_deskewed, family = binomial(link = 'logit'))

blr_regress(model)
mod1b <- lrm(y ~ x)
summary(model)
blr_model_fit_stats(model)
model %>%
  blr_gains_table() %>%
  blr_roc_curve()


