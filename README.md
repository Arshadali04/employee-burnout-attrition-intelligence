# Employee Burnout & Attrition Intelligence

A comprehensive data analytics project investigating workplace factors associated with employee burnout, disengagement, and attrition — identifying workforce segments that need intervention.

---

## Business Problem

Organizations face hidden costs when employees disengage before they leave. This project moves beyond simple "who leaves?" analysis to investigate the **deeper pattern of disengagement** that precedes and surrounds attrition: workload stress, career stagnation, compensation dissatisfaction, and weak management support.

**Core Question:** *"What workplace factors are associated with employee burnout, disengagement, and attrition, and can we identify workforce segments that need intervention?"*

---

## Objectives

1. Profile the workforce and identify attrition patterns across demographics, compensation, workload, and career factors
2. Quantify relationships between burnout indicators and attrition using statistical testing
3. Segment the workforce into data-driven groups for targeted intervention
4. Build a Workforce Health Index as a composite organizational health metric
5. Deliver actionable, evidence-based recommendations for HR leadership
6. Create an interactive Tableau dashboard for business stakeholders
7. Build an Excel analytical workbook for independent KPI validation and scenario modeling

---

## Dataset

**Source:** IBM HR Analytics Employee Attrition & Performance (Kaggle) + Synthetic Augmentation

| Aspect | Detail |
|--------|--------|
| Rows | 1,470 employees |
| Columns | 43 (32 real + 8 synthetic + 3 engineered) |
| Target | Attrition (Yes: 237, No: 1,233 — 16.1% rate) |
| Departments | Sales, Research & Development, Human Resources |
| Job Roles | 9 distinct roles |

### Real vs Synthetic Breakdown

**Real columns (32):** All original IBM HR dataset fields — demographics, compensation, job characteristics, satisfaction scores, tenure metrics, performance.

**Synthetic columns (8):** Added to cover variables central to the burnout/engagement analysis that the original dataset lacks:
- `WorkloadScore` (1-5) — correlated with OverTime, JobLevel
- `WeeklyHoursWorked` — correlated with OverTime, WorkLifeBalance
- `MonthlyMeetings` — correlated with JobLevel, role
- `CompensationSatisfaction` (1-5) — correlated with salary-to-role-median ratio
- `CareerGrowthPerception` (1-5) — correlated with promotion gap, training
- `ManagerSupportScore` (1-5) — correlated with manager tenure, environment satisfaction
- `WorkModel` (Remote/Hybrid/Onsite) — correlated with department, distance
- `ProductivityScore` (1-5) — correlated with performance rating, involvement

**Engineered columns (3):** SalaryBand, ExperienceBand, TenureBand (derived from real columns)

> Full generation methodology documented in `docs/data_dictionary.md`

---

## Architecture & Tools

| Tool | Role |
|------|------|
| **Python** (Pandas, NumPy, Matplotlib, Seaborn, SciPy, scikit-learn) | EDA, statistical analysis, segmentation, Workforce Health Index |
| **MySQL** | Relational data model, validation queries, analytical SQL |
| **Excel** | Interactive workbook — KPI validation, pivot analysis, what-if scenarios |
| **Tableau** | Primary visual storytelling dashboard for business audience |

---

## Methodology

```
Data Sourcing → Profiling → Quality Assessment → MySQL Schema
    → Python Cleaning → Feature Engineering → EDA (Univariate/Bivariate/Multivariate)
    → Statistical Analysis → Employee Segmentation (K-Means)
    → Workforce Health Index → Predictive Modeling (LR + Random Forest)
    → KPI Dictionary → Excel Workbook → Tableau Dashboard → Business Recommendations
```

---

## Key Visualisations

| | | |
|--|--|--|
| ![Attrition Overview](images/01_attrition_overview.png) | ![Income & Attrition](images/02_income_attrition.png) | ![Overtime & Workload](images/03_overtime_workload.png) |
| ![Attrition Drivers](images/06_attrition_drivers.png) | ![WHI Distribution](images/05_whi_distribution.png) | ![Promotion Gap](images/08_promotion_gap.png) |
| ![Tenure Attrition](images/07_tenure_attrition.png) | ![Statistical Summary](images/04_statistical_summary.png) | |

*Run `python scripts/save_key_figures.py` to regenerate these images from the processed dataset.*

---

## Key Findings

### Statistical Evidence (real IBM variables — fully validated)
1. **Income Gap:** Leavers earn significantly less (Mann-Whitney U, p < 0.001, r ≈ -0.28). Top-ranked real predictor.
2. **Overtime & Attrition:** ~2.5x attrition rate differential (Chi-square, p < 0.001, Cramér's V ≈ 0.24).
3. **Career Stagnation:** 5+ years since promotion → ~2x attrition rate. Top-5 real predictor.
4. **Tenure:** Entry-career employees (0-3 years tenure) carry the highest flight risk.

### Predictive Model Results
- **Logistic Regression** — Test AUC: see Notebook 09
- **Random Forest (all features)** — Best overall AUC (includes synthetic variables)
- **Random Forest (real variables only)** — Honest benchmark; no synthetic bias
- **Synthetic variable inflation quantified** — AUC gap between full and real-only model

> See `notebooks/09_predictive_modeling.ipynb` for full model results and the real-vs-synthetic confidence framework.
6. **Work-Life Balance:** Lower balance scores associated with higher attrition, compounded by overtime.

### Employee Segments (K-Means Clustering)
Data-driven segments identified through clustering on satisfaction, workload, and growth metrics:
- **High-Risk Overworked** — High workload, low balance, elevated attrition
- **Career Stagnant** — Low growth perception, long promotion gaps
- **Compensation Sensitive** — Below-market pay, low compensation satisfaction
- **Stable Engaged** — Balanced metrics, low attrition risk
- **Thriving Performers** — High across all dimensions

### Workforce Health Index
- Composite score (0-100) from 7 normalized, data-weighted components
- Validated: statistically significant difference between leavers (lower WHI) and stayers
- Risk categories: Critical (<30), At Risk (30-50), Moderate (50-70), Healthy (70-85), Thriving (85+)

---

## Dashboard Overview (Tableau)

6-page interactive story:
1. **Executive Workforce Overview** — KPIs, health distribution, top-risk segments
2. **Attrition Drivers** — Salary, overtime, promotion, tenure breakdowns
3. **Workforce Health** — Index components, department comparison, risk heatmaps
4. **Employee Segments** — Segment profiles, demographics, selectable drill-through
5. **Management & Career** — Manager support, promotion, training, growth patterns
6. **Recommendations** — Evidence-backed intervention strategies

---

## Excel Workbook

Interactive analytical model with:
- KPI Dashboard (dynamic dropdowns, conditional formatting, card layout)
- Pivot Analysis (shared slicers, 4 pivot tables + charts)
- What-If Scenario Model (Data Tables, Goal Seek)
- KPI Validation (cross-check vs Tableau with pass/fail formulas)

---

## Recommendations Summary

| Priority | Recommendation | Expected Impact |
|----------|---------------|-----------------|
| 1 | Reduce overtime burden (cap hours, redistribute workload) | 30-40% attrition reduction in affected segment |
| 2 | Close promotion gaps (structured career paths, lateral moves) | 25-35% reduction |
| 3 | Compensation adjustment for below-market roles | 20-30% reduction |
| 4 | Manager quality program (training, feedback, team-size limits) | 15-25% reduction |
| 5 | Work model flexibility alignment | Satisfaction improvement 0.3-0.5 points |

> Full detail in `reports/business_recommendations.md`

---

## Limitations

1. **Cross-sectional data** — single snapshot, not longitudinal. Cannot establish causation.
2. **Synthetic augmentation** — 8 columns are simulated. Real organizational data needed for validation.
3. **Class imbalance** — 16.1% attrition. Statistical tests are robust to this, but interpretation requires care.
4. **Ordinal as interval** — Satisfaction scores (1-4, 1-5) treated as continuous for averaging.
5. **Performance rating** — Only values 3 and 4 exist, limiting variance.
6. **No temporal dimension** — Cannot measure trends over time or seasonal effects.
7. **Workforce Health Index** — Analytical summary, not a validated psychometric instrument.

---

## Repository Structure

```
employee-burnout-attrition-intelligence/
├── data/
│   ├── raw/                          # Original IBM HR Attrition CSV
│   ├── processed/                    # Augmented dataset with synthetic columns
│   └── external/                     # Any supplementary data
├── notebooks/
│   ├── 01_data_understanding.ipynb
│   ├── 02_data_cleaning.ipynb
│   ├── 03_univariate_eda.ipynb
│   ├── 04_bivariate_eda.ipynb
│   ├── 05_multivariate_analysis.ipynb
│   ├── 06_statistical_analysis.ipynb
│   ├── 07_employee_segmentation.ipynb
│   ├── 08_workforce_health_index.ipynb
│   └── 09_predictive_modeling.ipynb  ← Logistic Regression + Random Forest + real-vs-synthetic analysis
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_load_data.sql
│   ├── 04_data_validation.sql
│   ├── 05_analysis_queries.sql
│   └── 06_views.sql
├── dashboard/
│   └── tableau/                      # Tableau workbook + setup guide
├── excel/
│   └── Employee_Burnout_Analysis.xlsx
├── reports/
│   └── business_recommendations.md
├── docs/
│   ├── data_dictionary.md
│   └── kpi_dictionary.md
├── scripts/
│   ├── generate_augmented_dataset.py
│   └── save_key_figures.py             ← regenerates images/ from processed data
├── images/
│   ├── 01_attrition_overview.png
│   ├── 02_income_attrition.png
│   ├── 03_overtime_workload.png
│   ├── 04_statistical_summary.png
│   ├── 05_whi_distribution.png
│   ├── 06_attrition_drivers.png
│   ├── 07_tenure_attrition.png
│   └── 08_promotion_gap.png
├── images/                           # Dashboard screenshots
├── requirements.txt
└── README.md
```

---

## How to Run

### Prerequisites
- Python 3.10+
- MySQL 8.0+ (optional — for SQL layer)
- Tableau Desktop (for dashboard)
- Microsoft Excel (for workbook)

### Setup
```bash
# Clone repository
git clone https://github.com/yourusername/employee-burnout-attrition-intelligence.git
cd employee-burnout-attrition-intelligence

# Install Python dependencies
pip install -r requirements.txt

# Generate augmented dataset
python scripts/generate_augmented_dataset.py

# Run notebooks in order (01 through 09) — outputs are already embedded
jupyter notebook notebooks/

# Regenerate key figures
python scripts/save_key_figures.py

# MySQL setup (optional)
mysql -u root -p < sql/01_create_database.sql
mysql -u root -p employee_analytics < sql/02_create_tables.sql
# ... continue with 03-06
```

---

## Future Improvements

- Longitudinal tracking with time-series attrition data
- Predictive modeling (logistic regression, random forest, XGBoost) for attrition probability
- Real employee survey data to validate synthetic columns
- Integration with HRIS for live dashboard refresh
- A/B testing framework for intervention effectiveness measurement
- NLP analysis of exit interview text data
- Cost modeling (replacement cost per segment, ROI of interventions)

---

## Author

Built as a portfolio project demonstrating end-to-end data analytics capabilities: data engineering (SQL), exploratory analysis (Python), statistical rigor, machine learning (clustering), business intelligence (Tableau), and stakeholder communication.

---

*Quality > speed. Analytical depth > chart count. Evidence > assumptions.*
