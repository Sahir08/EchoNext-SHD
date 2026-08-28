#Structural Heart Disease (SHD) Prediction from ECG Metadata
#EchoNext Dataset - Logistic Regression Analysis

#This script builds and validates a logistic regression model predicting
#moderate-or-greater structural heart disease (SHD) using ECG-derived
#variables and patient demographics. Steps:
#1. Data cleaning and exploratory analysis
#2. Train/test split
#3. Stepwise model building, compared using AIC and BIC
#4. Final model evaluation (ROC/AUC, calibration)
#5. Odds ratio interpretation for each predictor

#Dataset: echonext_metadata_100k.csv (should be in the same folder as this script)

#SETUP
#Run once if you don't have these installed already:
#install.packages(c("dplyr", "ggplot2", "ggcorrplot", "pROC", "jtools", "huxtable"))

library(dplyr)
library(ggplot2)
library(ggcorrplot)
library(pROC)

#VARIABLES
#patient_key: De-identified patient identifier
#acquisition_year: Year the ECG was acquired
#location_setting: Clinical context of ECG - inpatient, emergency, outpatient, or procedural
#race_ethnicity: hispanic, white, black, unknown, other, asian
#most_recent_ecg: Binary flag indicating whether the ECG is the most recent for the patient
#sex: Patient sex (0 = female, 1 = male)
#ventricular_rate: Ventricular rate (bpm)
#atrial_rate: Atrial rate (bpm)
#pr_interval: PR interval (ms)
#qrs_duration: QRS duration (ms)
#qt_corrected: Corrected QT interval (ms)
#age_at_ecg: Age at time of ECG acquisition (capped at 90 years)

#1. LOAD AND CLEAN DATA
raw <- read.csv("echonext_metadata_100k.csv")

#Create dataset of ecg variables
final <- subset(raw, select = c(shd_moderate_or_greater_flag,
                                 patient_key,
                                 acquisition_year,
                                 location_setting,
                                 race_ethnicity,
                                 most_recent_ecg,
                                 sex,
                                 ventricular_rate,
                                 atrial_rate,
                                 pr_interval,
                                 qrs_duration,
                                 qt_corrected,
                                 age_at_ecg))

#Make categorical variables factors
final$sex <- as.factor(final$sex)
final$location_setting <- as.factor(final$location_setting)
final$race_ethnicity <- as.factor(final$race_ethnicity)
final$hrtdis <- as.factor(final$shd_moderate_or_greater_flag)

#2. EXPLORATORY ANALYSIS
#Descriptive stats for each variable
summary(final)

#Check missing values
sum(is.na(final)) #Total missing values
colSums(is.na(final)) #Missing values per column

#Histograms of continuous variables
hist(final$ventricular_rate)
hist(final$atrial_rate)
hist(final$qrs_duration)
hist(final$qt_corrected)
hist(final$age_at_ecg)
hist(final$acquisition_year)

#Categorical variable counts
table(final$sex)
table(final$race_ethnicity)
table(final$location_setting)

#Outcome distribution
ggplot(final, aes(x = hrtdis)) +
  geom_bar() +
  labs(title = "Count of Heart Disease",
       x = "Heart Disease (yes/no)",
       y = "Count") +
  theme_classic()

table(final$hrtdis)
prop.table(table(final$hrtdis))

#Heart disease by sex
ggplot(final, aes(x = sex, fill = factor(hrtdis))) +
  geom_bar(position = "dodge") +
  scale_fill_manual(
    values = c("0" = "grey", "1" = "black"),
    labels = c("no", "yes")
  ) +
  labs(
    title = "Count of Heart Disease by Sex",
    x = "Sex (male/female)",
    y = "Count",
    fill = "Heart Disease"
  ) +
  theme_classic()

#Heart disease by location
ggplot(final, aes(x = location_setting, fill = factor(hrtdis))) +
  geom_bar(position = "dodge") +
  scale_fill_manual(
    values = c("0" = "grey", "1" = "black"),
    labels = c("no", "yes")
  ) +
  labs(
    title = "Count of Heart Disease by Location",
    x = "Location",
    y = "Count",
    fill = "Heart Disease"
  ) +
  theme_classic()

#Heart disease by race
ggplot(final, aes(x = race_ethnicity, fill = factor(hrtdis))) +
  geom_bar(position = "dodge") +
  scale_fill_manual(
    values = c("0" = "grey", "1" = "black"),
    labels = c("no", "yes")
  ) +
  labs(
    title = "Count of Heart Disease by Race",
    x = "Race",
    y = "Count",
    fill = "Heart Disease"
  ) +
  theme_classic()

#Correlation matrix for continuous variables
continuous_vars <- final[, c("ventricular_rate", "atrial_rate",
                              "qrs_duration", "qt_corrected", "age_at_ecg",
                              "acquisition_year", "pr_interval")]

cor_matrix <- cor(continuous_vars, use = "complete.obs")

rownames(cor_matrix) <- c("Ventricular Rate (bpm)",
                           "Atrial Rate (bpm)",
                           "QRS Duration (ms)",
                           "QT Corrected (ms)",
                           "Age at ECG (years)",
                           "Acquisition Year", "Pr Interval (ms)")

colnames(cor_matrix) <- rownames(cor_matrix)

ggcorrplot(cor_matrix,
           type = "full",
           lab = TRUE,
           lab_size = 3,
           colors = c("#6D9EC1", "white", "#E46726"),
           title = "Correlation Matrix of Continuous Variables",
           ggtheme = theme_minimal()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
        axis.text.y = element_text(size = 9))

#3. TRAIN/TEST SPLIT
final_regress_complete <- na.omit(final)
#Dataset now has 89,619 observations

set.seed(123)
sample_size <- floor(0.80 * nrow(final_regress_complete))
train_indices <- sample(seq_len(nrow(final_regress_complete)), size = sample_size)

train_data <- final_regress_complete[train_indices, ]
test_data  <- final_regress_complete[-train_indices, ]

#4. STEPWISE MODEL BUILDING (compared using AIC)
#Predictors added one at a time, comparing AIC at each step
#Decision rule: if new AIC < old AIC, keep the new variable since the model fits better
#AIC balances goodness of fit against model simplicity - lower AIC is better
#https://builtin.com/data-science/what-is-aic

null_model <- glm(shd_moderate_or_greater_flag ~ 1,
                   data = final_regress_complete, family = binomial)

model_1 <- glm(shd_moderate_or_greater_flag ~ qt_corrected,
                data = final_regress_complete, family = binomial)

model_2 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration,
                data = final_regress_complete, family = binomial)

model_3 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex,
                data = final_regress_complete, family = binomial)

model_4 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg,
                data = final_regress_complete, family = binomial)

model_5 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                 atrial_rate,
                data = final_regress_complete, family = binomial)

model_6 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                 atrial_rate + pr_interval,
                data = final_regress_complete, family = binomial)

model_7 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                 atrial_rate + pr_interval + race_ethnicity,
                data = final_regress_complete, family = binomial)

model_8 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                 atrial_rate + pr_interval + race_ethnicity + acquisition_year,
                data = final_regress_complete, family = binomial)

model_9 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                 atrial_rate + pr_interval + race_ethnicity + location_setting,
                data = final_regress_complete, family = binomial)

model_10 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                  atrial_rate + pr_interval + race_ethnicity + location_setting + ventricular_rate,
                data = final_regress_complete, family = binomial)

model_11 <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex + age_at_ecg +
                  atrial_rate + pr_interval + race_ethnicity + location_setting + ventricular_rate +
                  most_recent_ecg,
                data = final_regress_complete, family = binomial)

#Compare models
AIC(null_model, model_1, model_2, model_3, model_4, model_5, model_6,
    model_7, model_8, model_9, model_10, model_11)
BIC(null_model, model_1, model_2, model_3, model_4, model_5, model_6,
    model_7, model_8, model_9, model_10, model_11)
#Both AIC and BIC suggest model_11 (the full model) is best

#Pseudo R^2 for each model, showing fit improve as predictors are added
print(1 - (model_1$deviance  / model_1$null.deviance))
print(1 - (model_2$deviance  / model_2$null.deviance))
print(1 - (model_3$deviance  / model_3$null.deviance))
print(1 - (model_4$deviance  / model_4$null.deviance))
print(1 - (model_5$deviance  / model_5$null.deviance))
print(1 - (model_6$deviance  / model_6$null.deviance))
print(1 - (model_7$deviance  / model_7$null.deviance))
print(1 - (model_8$deviance  / model_8$null.deviance))
print(1 - (model_9$deviance  / model_9$null.deviance))
print(1 - (model_10$deviance / model_10$null.deviance))
print(1 - (model_11$deviance / model_11$null.deviance)) #0.1246

#5. FINAL MODEL: TRAIN/TEST VALIDATION
model_11_final <- glm(shd_moderate_or_greater_flag ~ qt_corrected + qrs_duration + sex +
                        age_at_ecg + atrial_rate + pr_interval + race_ethnicity +
                        location_setting + ventricular_rate + most_recent_ecg,
                      data = train_data, family = binomial)

test_probs <- predict(model_11_final, newdata = test_data, type = "response")
test_roc <- roc(test_data$shd_moderate_or_greater_flag, test_probs, ci = TRUE)
auc(test_roc) #This is the scientific result reported in the paper

roc_train <- roc(train_data$shd_moderate_or_greater_flag,
                 predict(model_11_final, newdata = train_data, type = "response"))
auc(roc_train)

#ROC curve with confidence interval band
plot(test_roc,
     main = "ROC Curve for SHD Prediction (Model 11)",
     col = "#1c4587",
     lwd = 3,
     print.auc = TRUE,
     print.auc.x = 0.5, print.auc.y = 0.3,
     auc.polygon = TRUE,
     max.auc.polygon = TRUE,
     grid = TRUE)

ciobj <- ci.se(test_roc, specificities = seq(0, 1, l = 25))
plot(ciobj, type = "shape", col = "#1c458722")

#6. CALIBRATION
#Checks if a predicted 10% risk actually matches 10% of real patients
test_data$probs <- test_probs
calibration_data <- test_data %>%
  mutate(bin = ntile(probs, 10)) %>%
  group_by(bin) %>%
  summarize(pred = mean(probs), obs = mean(as.numeric(as.character(shd_moderate_or_greater_flag))))

ggplot(calibration_data, aes(x = pred, y = obs)) +
  geom_point() + geom_line() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.2)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.2)) +
  labs(title = "Calibration Plot for Model 11 - Test Set",
       x = "Predicted Probability",
       y = "Actual Proportion with SHD") +
  theme_minimal()

#7. ODDS RATIO INTERPRETATION (full-dataset model)
summary(model_11)
#qt_corrected: log odds of medium/severe heart disease increase by 0.008 per unit increase in corrected QT interval, all else equal
#qrs_duration: log odds increase by 0.016 per unit increase in QRS duration, all else equal
#age_at_ecg: log odds increase by 0.018 per unit increase in age at ECG, all else equal
#atrial_rate: log odds increase by 0.002 per unit increase in atrial rate, all else equal
#pr_interval: log odds increase by 0.005 per unit increase in PR interval, all else equal
#ventricular_rate: log odds increase by 0.008 per unit increase in ventricular rate, all else equal
#most_recent_ecg: log odds decrease by 0.513 per unit increase in most recent ECG, all else equal

table(final_regress_complete$sex)
#Expected log odds of medium/severe heart disease is 0.23 higher in males than females on average

table(final_regress_complete$race_ethnicity)
#Expected log odds of medium/severe heart disease relative to Asian patients:
#Black: 0.25 higher | Hispanic: 0.16 lower | Other: 0.14 higher | Unknown: 0.18 higher | White: 0.27 lower

table(final_regress_complete$location_setting)
#Expected log odds of medium/severe heart disease relative to emergency patients:
#Inpatient: 0.55 higher | Outpatient: 0.38 lower | Procedural: 0.17 higher

#Predicted probabilities from the full model
predicted_probs <- predict(model_11, type = "response")
final_regress_complete$predicted_prob <- predicted_probs

ggplot(final_regress_complete, aes(x = predicted_probs, fill = factor(shd_moderate_or_greater_flag))) +
  geom_histogram(alpha = 0.6, position = "identity", bins = 50) +
  labs(title = "Distribution of Predicted Probabilities", x = "Predicted Probability", y = "Count", fill = "Actual SHD") +
  theme_minimal()

roc_obj <- roc(final_regress_complete$shd_moderate_or_greater_flag, predicted_probs)
auc(roc_obj)
plot(roc_obj, main = paste("ROC Curve (AUC =", round(auc(roc_obj), 3), ")"), col = "blue", lwd = 2)
#Interpretation: if you randomly pick one patient with SHD and one without, there's about a
#73% chance the model gives a higher predicted probability to the patient who actually has it

#Standardizing coefficients so predictors are comparable on the same scale
#(log-odds change per 1 SD increase, instead of per raw unit)

#Ventricular Rate
exp(0.0083088) #Odds ratio per 1 bpm increase
sd(final_regress_complete$ventricular_rate) #18.75
exp(18.75065 * 0.0083088) #Odds ratio per 1 SD increase (~17% higher odds)

#QT Corrected
exp(0.0084965)
sd(final_regress_complete$qt_corrected) #37.78
exp(37.77838 * 0.0084965) #~38% higher odds per 1 SD

#QRS Duration
exp(0.0163041)
sd(final_regress_complete$qrs_duration) #20.86
exp(20.85593 * 0.0163041) #~41% higher odds per 1 SD

#Age at ECG
exp(0.0188501)
sd(final_regress_complete$age_at_ecg) #15.99
exp(15.98592 * 0.0188501) #~35% higher odds per 1 SD

#Atrial Rate
exp(0.0022564)
sd(final_regress_complete$atrial_rate) #19.64
exp(19.64103 * 0.0022564) #~4% higher odds per 1 SD

#PR Interval
exp(0.0058844)
sd(final_regress_complete$pr_interval) #32.49
exp(32.49044 * 0.0058844) #~21% higher odds per 1 SD

#Sex (male vs female)
exp(0.2293866) #~26% higher odds of SHD in males vs females, all else equal

#Race/ethnicity - unadjusted odds ratios (reference: Asian)
model_race_only <- glm(shd_moderate_or_greater_flag ~ race_ethnicity,
                       data = final_regress_complete, family = binomial)

race_coefs <- summary(model_race_only)$coefficients
exp(cbind(OR = race_coefs[,1],
          CI_low = race_coefs[,1] - 1.96 * race_coefs[,2],
          CI_high = race_coefs[,1] + 1.96 * race_coefs[,2]))

#Most recent ECG flag - unadjusted odds ratio
model_recent_only <- glm(shd_moderate_or_greater_flag ~ most_recent_ecg,
                         data = final_regress_complete, family = binomial)

recent_coefs <- summary(model_recent_only)$coefficients
exp(cbind(OR = recent_coefs[,1],
          CI_low = recent_coefs[,1] - 1.96 * recent_coefs[,2],
          CI_high = recent_coefs[,1] + 1.96 * recent_coefs[,2]))

#8. SUMMARY STATS BY OUTCOME GROUP
final_regress_complete %>%
  group_by(shd_moderate_or_greater_flag) %>%
  summarize(
    n = n(),
    mean_age = mean(age_at_ecg, na.rm=TRUE),
    sd_age = sd(age_at_ecg, na.rm=TRUE),
    mean_qrs = mean(qrs_duration, na.rm=TRUE),
    sd_qrs = sd(qrs_duration, na.rm=TRUE),
    mean_qtc = mean(qt_corrected, na.rm=TRUE),
    sd_qtc = sd(qt_corrected, na.rm=TRUE),
    mean_pr = mean(pr_interval, na.rm=TRUE),
    sd_pr = sd(pr_interval, na.rm=TRUE),
    mean_vr = mean(ventricular_rate, na.rm=TRUE),
    sd_vr = sd(ventricular_rate, na.rm=TRUE),
    mean_ar = mean(atrial_rate, na.rm=TRUE),
    sd_ar = sd(atrial_rate, na.rm=TRUE),
    n_male = sum(sex == "1"),
    pct_male = mean(sex == "1") * 100
  )

table(final_regress_complete$race_ethnicity, final_regress_complete$shd_moderate_or_greater_flag)
table(final_regress_complete$location_setting, final_regress_complete$shd_moderate_or_greater_flag)
table(final_regress_complete$sex, final_regress_complete$shd_moderate_or_greater_flag)

#9. FINAL ROC PLOTS (styled, train vs test)
plot_roc_styled <- function(roc_obj, title) {
  plot(roc_obj,
       main       = title,
       col        = "#1c4587",
       lwd        = 3,
       print.auc  = TRUE,
       print.auc.x = 0.5, print.auc.y = 0.3,
       auc.polygon      = TRUE,
       auc.polygon.col  = "#d6e4f7",
       max.auc.polygon  = TRUE,
       max.auc.polygon.col = "#f0f0f0",
       grid             = TRUE,
       grid.col         = "#cccccc",
       grid.lty         = 1,
       xlab = "Specificity",
       ylab = "Sensitivity",
       xlim = c(1, 0),
       ylim = c(0, 1),
       axes = FALSE)

  axis(1, at = seq(1, 0, by = -0.2), labels = seq(1, 0, by = -0.2))
  axis(2, at = seq(0, 1, by = 0.2),  labels = seq(0, 1, by = 0.2))
  box()
}

roc_train_full <- roc(final_regress_complete$shd_moderate_or_greater_flag, predicted_probs)
plot_roc_styled(roc_train_full, paste("ROC Curve - Training Set, Model 11 (AUC =", round(auc(roc_train_full), 3), ")"))
plot_roc_styled(test_roc, paste("ROC Curve - Test Set, Model 11 (AUC =", round(auc(test_roc), 3), ")"))
