# PACE Strategy Document — Waze User Churn Project

**Google Advanced Data Analytics Certificate · Capstone project (Courses 1–5)**

The [PACE framework](https://www.coursera.org/professional-certificates/google-advanced-data-analytics) (**P**lan → **A**nalyze → **C**onstruct → **E**xecute) guided every stage of this project. This document records the decisions, reasoning and reflections behind each notebook in the [`notebooks/`](../notebooks) folder.

---

## 1. Project at a glance

| | |
|---|---|
| **Business problem** | Waze leadership wants to understand and predict **user churn** (users who stop using the app) so the company can act before users leave. |
| **Data** | `waze_dataset.csv` — 14,999 users, 13 columns (usage, driving behaviour, device, churn label). 700 rows (4.7%) have no label. |
| **Target variable** | `label` — `retained` (≈82%) vs. `churned` (≈18%) |
| **Stakeholders** | Operations Manager, Director of Data Analysis, Project Manager and the Waze leadership team |
| **Deliverables** | Exploratory analysis, visualisations, a hypothesis test, a logistic regression model, tuned tree-based ML models and an executive summary at each stage |

### Executive summary

- About **17.7%** of labeled users churned, and the rate is nearly identical on iPhone (≈17.8%) and Android (≈17.6%).
- **Usage frequency is the clearest signal.** The more days a user drove in the last month, the less likely they were to churn; users who cover very long distances per driving day churn more often.
- Device type has **no statistically significant effect** on the number of drives (Welch’s t-test, p ≈ 0.14).
- A baseline **logistic regression** model reached ≈82% accuracy but only ≈9% recall on churned users: accuracy looks good only because the classes are imbalanced.
- **Tree-based models** (random forest, XGBoost) with engineered features made use of many more predictors and improved recall, but still miss most churners. The model is useful as a supplementary signal, **not** as a stand-alone decision tool.
- The data has quality issues (missing labels, physically impossible distances, inconsistent day counts) that should be clarified with the data owners.

---

## 2. Course 1 — Foundations of Data Science (`01_foundations_data_exploration.ipynb`)

### Plan
- **How can you best prepare to understand and organise the provided information?** Read the project brief and data dictionary, identify the target (`label`), the variable types and the business question before touching the data.
- **What additional activities would a resourceful learner perform before coding?** Review the data dictionary, check what tooling is needed (pandas, NumPy, matplotlib), and write down hypotheses about what drives churn.

### Analyze
- **Will the information be sufficient for the goal?** Largely yes: the dataset has usage, driving and device variables plus a churn label. Missing context (tenure history, app crashes, reasons for leaving) limits how far conclusions can go.
- **Summary statistics and ranges:** `df.info()` and `describe()` showed 14,999 rows × 13 columns, one object column for `label`, one for `device`, and 700 missing `label` values.
- **Unusual averages:** several usage columns are strongly right-skewed (mean well above median). Missing-label rows look similar to non-missing rows and are split iPhone 447 / Android 253, in line with overall device share, so there is no evidence of a systematic cause.

### Construct
- Not applicable to this stage; the work was data understanding and feature creation (`km_per_drive`, `km_per_driving_day`, `drives_per_driving_day`).

### Execute
- **What to investigate further?** Why labels are missing and how “churn” is defined; the extreme distance values.
- **What looks anomalous?** Very high `driven_km_drives` and per-day distances; users with zero driving days.
- **What additional data could strengthen the dataset?** Month-by-month history, app crash/error logs, support contacts, region and plan information.

---

## 3. Course 2 — Go Beyond the Numbers: Translate Data into Insights (`02_eda_and_visualization.ipynb`)

### Plan
- Goal: explore every variable, find outliers and problems, and build clear visuals for leadership.

### Analyze
- Box plots and histograms for every numeric variable; pie charts for device and label; scatter and overlay plots to compare variable pairs.
- **Distributions:** `sessions`, `drives`, `total_sessions`, `driven_km_drives` and `duration_minutes_drives` are right-skewed; `n_days_after_onboarding`, `activity_days` and `driving_days` are roughly uniform. Device split ≈ 65% iPhone / 35% Android.
- **Data problems:** 700 missing labels; `driving_days` maxes at 30 while `activity_days` reaches 31; mean per-day distance up to ≈15,420 km (impossible); more than 1,000 users with zero driving days vs. ≈250 with zero activity days; half of users logged ≥40% of all sessions in the last month.

### Construct
- Built a polished set of visualisations (see [`images/`](../images)) with consistent colour, labels and titles for non-technical stakeholders.

### Execute
- **Key findings:** churn ≈17.7%, equal across devices; churn falls steadily as driving days rise (≈40% at 0 driving days → 0% at 30); users with very long distances per driving day churn more.
- **Open questions for the data team:** why 700 labels are missing; why so many long-tenured users spiked in usage last month; why the day counts disagree; how distance and `total_sessions` are measured.

---

## 4. Course 3 — The Power of Statistics (`03_hypothesis_testing.ipynb`)

### Plan
- **Research question:** Is there a statistically significant difference in the average number of drives between iPhone and Android users?

### Analyze
- Computed average drives by device: iPhone ≈ 67.9, Android ≈ 66.2.
- Encoded `device` as `device_type` (iPhone = 1, Android = 2) in a new column to preserve the original data.

### Construct
- **H0:** no difference in mean drives between iPhone and Android users. **HA:** there is a difference.
- Two-sample **Welch’s t-test** (independent groups, unequal variances allowed), significance level 5%.
- Result: t ≈ 1.46, **p ≈ 0.143**.

### Execute
- p > 0.05, so we **fail to reject H0**: the observed difference could easily be random sampling variation.
- **Business insight:** device type alone does not explain differences in drive volume. Retention efforts should focus on behavioural variables rather than on platform differences in this metric.

---

## 5. Course 4 — Regression Analysis (`04_regression_modeling.ipynb`)

### Plan
- Build a **binomial logistic regression** to estimate each user’s probability of churning.

### Analyze
- EDA before modeling: class balance (≈82/18), missing values (700 in `label`, dropped as <5% and no evidence of a non-random cause), outliers in seven usage variables, correlations among predictors.

### Construct
- **Feature engineering:** `km_per_driving_day` (infinite values from zero driving days set to 0) and `professional_driver` (≥60 drives **and** ≥15 driving days). Professional drivers churn at ≈7.6% vs. ≈19.9% for everyone else.
- **Outliers:** capped at the 95th percentile instead of being dropped.
- **Multicollinearity (|r| > 0.7):** `sessions` ↔ `drives` (≈0.997) and `driving_days` ↔ `activity_days` (≈0.95), so `sessions` and `driving_days` were removed.
- Stratified train/test split to preserve the class ratio; logistic regression without regularisation; log-odds linearity check for `activity_days`.

### Execute
- Test accuracy ≈ **82.4%**, precision ≈ **52.7%**, recall ≈ **9.1%**.
- **Interpretation:** accuracy is misleading on an imbalanced target; the model misses ~9 in 10 churners. `activity_days` was by far the strongest predictor (negative coefficient: more active days → lower churn odds).
- **Recommendation:** do not use this model for decisions; improve it with better features, class-imbalance handling and non-linear models.

---

## 6. Course 5 — The Nuts and Bolts of Machine Learning (`05_machine_learning.ipynb`)

### Plan
- Predict churn using tree-based ensemble models. A **false negative** (a churner we fail to flag) is the costly error, while a false positive only costs a retention message, so models are tuned and compared on **recall**.

### Analyze
- Further feature engineering: `professional_driver`, `total_sessions_per_day`, `km_per_hour`; ID column and rows with missing labels dropped.

### Construct
- 60/20/20 **train / validation / test** split (stratified).
- **Random forest** and **XGBoost** tuned with grid search and cross-validation, refit on recall.
- Champion selected on the validation set; test set used once for a final, unbiased estimate.

### Execute
- Tuned random forest cross-validated recall ≈ 0.14 (vs. ≈ 0.09 for logistic regression); XGBoost was selected as the champion model, with recall on the test set around 17%.
- Tree models spread importance across many features, with engineered features among the most important, which underlines the value of feature engineering.
- **Recommendation:** not suitable as a stand-alone decision tool yet. Next steps: wider hyperparameter search (e.g. `scale_pos_weight`), resampling or class weights, decision-threshold tuning to favour recall, and richer data (monthly history, crash logs, support contacts, tenure/region).

---

## 7. Reflections and lessons learned

1. **Accuracy is not enough.** With an 82/18 class split, a model that never predicts churn is already 82% accurate; recall and precision tell the real story.
2. **Domain-driven features beat raw columns.** Engineered ratios and the `professional_driver` flag added signal that raw counts lacked.
3. **Document data quality early.** Impossible distances and inconsistent day counts affect every later stage and should be raised with the data owners.
4. **Keep a hold-out set untouched.** Separate validation and test sets give an honest performance estimate at the cost of less training data.
5. **PACE keeps projects honest.** Re-visiting Plan → Analyze → Construct → Execute at each course made each deliverable traceable to a business question.
