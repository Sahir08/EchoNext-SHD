# Predicting Structural Heart Disease from ECG Metadata
 
## Abstract
 
Structural heart disease represents one of the leading causes of morbidity across the world. While echocardiography is the gold standard for diagnosing such conditions, the test is not always available. Electrocardiography (ECG) is widely available and inexpensive and shows enough information to predict structural heart disease before echocardiography. We created a multivariable logistic regression model to predict moderate-or-greater structural heart disease based on an echocardiographically confirmed diagnosis, using an analysis sample of 89,619 ECGs from the EchoNext dataset of patients seen at Columbia University Irving Medical Center. Eleven nested models were evaluated using McFadden’s pseudo-R², BIC, and AIC. A train/test split of 80/20 was employed with a fixed random seed (seed = 123). All continuous features were scaled before model fitting. On the test set, the model produced an AUROC of 0.7302. The training set AUROC was 0.7309, which suggests little overfitting. The features that had the greatest standardized odds ratios were QRS duration (1.41 per standard deviation increase), QTc interval (1.38), and age (1.35). The model also showed good calibration across all deciles of risk. This suggests that commonly derived ECG parameters have utility in detecting structural heart disease and could support a role as a clinical decision support tool. Screening with ECG before referral for echocardiography could be useful, particularly when echocardiography is not widely available.
 
**Keywords:** structural heart disease, electrocardiography, logistic regression, screening, echocardiography
 
## About this repository
 
This repository contains the R analysis behind the paper above, submitted to the *Princeton Journal of Interdisciplinary Research (PJIR)*. The script performs exploratory data analysis, stepwise logistic regression model selection, train/test validation, and odds ratio interpretation for predicting structural heart disease (SHD) from routine ECG parameters.
 
## Dataset
 
The analysis uses the **EchoNext dataset**, consisting of 89,619 ECGs from patients at Columbia University Irving Medical Center, linked to echocardiography-confirmed structural heart disease outcomes. The dataset is not included in this repository. To run the script, place a copy of `echonext_metadata_100k.csv` in the same folder as `EchoNext_SHD_cleaned.R`.
 
Variables used include: ventricular rate, atrial rate, PR interval, QRS duration, corrected QT (QTc), age at ECG, sex, race/ethnicity, clinical setting, and acquisition year.
 
## Methodology
 
1. **Exploratory data analysis** — distributions and missingness checks for all variables
2. **Model selection** — 11 nested logistic regression models, built by adding one predictor at a time, compared via AIC, BIC, and McFadden's pseudo-R²
3. **Validation** — 80/20 train/test split (seed = 123), with AUROC evaluated on both sets to check for overfitting
4. **Calibration** — predicted probabilities checked against observed outcome rates across risk deciles
5. **Interpretation** — standardized odds ratios computed for each predictor to compare effect sizes on a common scale
## Key result
 
- **Test set AUROC:** 0.7302
- **Training set AUROC:** 0.7309 (negligible overfitting)
- **Strongest predictors (by standardized odds ratio):** QRS duration (OR = 1.41), QTc (OR = 1.38), age (OR = 1.35)
## Running the script
 
1. Open `EchoNext_SHD_cleaned.R` in RStudio
2. Place `echonext_metadata_100k.csv` in the same folder
3. Set the working directory to the script's location (Session → Set Working Directory → To Source File Location)
4. Run with **Source with Echo** (Ctrl/Cmd + Shift + Enter) so all plots display
Required packages: `dplyr`, `ggplot2`, `ggcorrplot`, `pROC`
 
## Author
 
Sahir Suri

