# Predicting Structural Heart Disease from ECG Metadata
 
## Abstract
 
Structural heart disease represents one of the leading causes of morbidity across the world. While echocardiography is the gold standard for diagnosing such conditions, the test is not always available. Electrocardiography (ECG) is a readily available and cost-effective alternative that provides sufficient signal to detect structural heart disease prior to echocardiographic evaluation. Using the EchoNext dataset of 100,000 ECGs from patients enrolled at Columbia University Irving Medical Center, a multivariable logistic regression model was developed to identify the presence of moderate-or-greater structural heart disease, as confirmed by echocardiography. All eleven nested models were compared using AIC, BIC, and McFadden's pseudo-R². An 80/20 split for training and test data was used, using a fixed random seed (seed = 123), and all continuous variables were standardized prior to fitting the model. The resulting model demonstrated an AUROC of 0.7302 on the test set; an AUROC of 0.7309 on the training set indicated negligible overfitting. The variable with the highest standardized odds ratio was QRS duration (OR = 1.41 per standard deviation increase), followed by corrected QT (QTc) duration (OR = 1.38) and age (OR = 1.35). The model was well-calibrated across all deciles of risk. Parameters commonly obtained through routine ECGs thus have meaningful power to detect structural heart disease. Using ECG as a screening tool prior to referral for echocardiography would appear to be beneficial — especially where such echocardiography is not readily available.
 
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

