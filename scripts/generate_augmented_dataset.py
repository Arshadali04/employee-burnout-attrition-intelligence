"""
Generate augmented dataset with synthetic columns added to IBM HR Attrition data.
Synthetic columns are correlated with existing real columns for realism.
"""

import pandas as pd
import numpy as np
from pathlib import Path

np.random.seed(42)

raw_path = Path(__file__).parent.parent / "data" / "raw" / "WA_Fn-UseC_-HR-Employee-Attrition.csv"
output_path = Path(__file__).parent.parent / "data" / "processed" / "employee_attrition_augmented.csv"
output_path.parent.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(raw_path)
df.columns = df.columns.str.strip()
n = len(df)


# --- 1. WorkloadScore (1-5) ---
# Higher for: OverTime=Yes, higher JobLevel, certain roles
base_workload = np.random.normal(3.0, 0.8, n)
base_workload += (df['OverTime'].str.strip() == 'Yes').astype(float) * 0.8
base_workload += (df['JobLevel'] - 1) * 0.15
base_workload += (df['Attrition'].str.strip() == 'Yes').astype(float) * 0.3
df['WorkloadScore'] = np.clip(np.round(base_workload), 1, 5).astype(int)


# --- 2. WeeklyHoursWorked ---
# Normal around 40-45, shifted up for overtime, by job level
base_hours = np.random.normal(42, 4, n)
base_hours += (df['OverTime'].str.strip() == 'Yes').astype(float) * np.random.uniform(5, 15, n)
base_hours += (df['JobLevel'] - 1) * 1.5
base_hours -= df['WorkLifeBalance'] * 0.8
df['WeeklyHoursWorked'] = np.clip(np.round(base_hours, 1), 35, 70)


# --- 3. MonthlyMeetings ---
# Poisson-distributed, higher for managers and higher job levels
lambda_meetings = 8 + (df['JobLevel'] - 1) * 3
lambda_meetings += df['JobRole'].str.strip().isin(['Manager', 'Research Director']).astype(float) * 5
df['MonthlyMeetings'] = np.random.poisson(lambda_meetings)
df['MonthlyMeetings'] = np.clip(df['MonthlyMeetings'], 2, 40)


# --- 4. CompensationSatisfaction (1-5) ---
# Correlated with: salary relative to role median, percent salary hike
role_median_income = df.groupby(df['JobRole'].str.strip())['MonthlyIncome'].transform('median')
salary_ratio = df['MonthlyIncome'] / role_median_income
base_comp_sat = np.random.normal(3.0, 0.7, n)
base_comp_sat += (salary_ratio - 1) * 1.5
base_comp_sat += (df['PercentSalaryHike'] - 11) * 0.08
base_comp_sat -= (df['Attrition'].str.strip() == 'Yes').astype(float) * 0.4
df['CompensationSatisfaction'] = np.clip(np.round(base_comp_sat), 1, 5).astype(int)


# --- 5. CareerGrowthPerception (1-5) ---
# Inversely correlated with YearsSinceLastPromotion, positively with Training
base_career = np.random.normal(3.2, 0.8, n)
base_career -= df['YearsSinceLastPromotion'] * 0.15
base_career += df['TrainingTimesLastYear'] * 0.12
base_career += (df['PercentSalaryHike'] - 11) * 0.05
base_career -= (df['Attrition'].str.strip() == 'Yes').astype(float) * 0.5
df['CareerGrowthPerception'] = np.clip(np.round(base_career), 1, 5).astype(int)


# --- 6. ManagerSupportScore (1-5) ---
# Correlated with YearsWithCurrManager, EnvironmentSatisfaction
base_mgr = np.random.normal(3.1, 0.8, n)
base_mgr += np.minimum(df['YearsWithCurrManager'], 7) * 0.1
base_mgr += (df['EnvironmentSatisfaction'] - 2.5) * 0.25
base_mgr -= (df['Attrition'].str.strip() == 'Yes').astype(float) * 0.3
df['ManagerSupportScore'] = np.clip(np.round(base_mgr), 1, 5).astype(int)


# --- 7. WorkModel (Remote/Hybrid/Onsite) ---
# Department tendencies + distance from home influence
probs = np.zeros((n, 3))  # [Remote, Hybrid, Onsite]

for i in range(n):
    dept = str(df.iloc[i]['Department']).strip()
    distance = df.iloc[i]['DistanceFromHome']

    if dept == 'Research & Development':
        probs[i] = [0.15, 0.35, 0.50]
    elif dept == 'Sales':
        probs[i] = [0.25, 0.40, 0.35]
    else:  # Human Resources
        probs[i] = [0.20, 0.35, 0.45]

    # Higher distance -> more likely remote/hybrid
    if distance > 15:
        probs[i][0] += 0.15
        probs[i][2] -= 0.15
    elif distance > 8:
        probs[i][1] += 0.10
        probs[i][2] -= 0.10

probs = probs / probs.sum(axis=1, keepdims=True)
work_models = []
for i in range(n):
    work_models.append(np.random.choice(['Remote', 'Hybrid', 'Onsite'], p=probs[i]))
df['WorkModel'] = work_models


# --- 8. ProductivityScore (1-5) ---
# Correlated with PerformanceRating, JobInvolvement, inversely with extreme workload
base_prod = np.random.normal(3.2, 0.7, n)
base_prod += (df['PerformanceRating'] - 3) * 0.6
base_prod += (df['JobInvolvement'] - 2.5) * 0.3
base_prod -= np.maximum(df['WorkloadScore'] - 4, 0) * 0.4  # Extreme workload hurts productivity
df['ProductivityScore'] = np.clip(np.round(base_prod), 1, 5).astype(int)


# --- Drop useless constant columns ---
df = df.drop(columns=['EmployeeCount', 'Over18', 'StandardHours'])

# --- Clean string columns ---
str_cols = df.select_dtypes(include='object').columns
for col in str_cols:
    df[col] = df[col].str.strip()

# --- Create EmployeeID as proper identifier ---
df = df.rename(columns={'EmployeeNumber': 'EmployeeID'})

# --- Create salary band ---
df['SalaryBand'] = pd.cut(
    df['MonthlyIncome'],
    bins=[0, 3000, 6000, 10000, 15000, 99999],
    labels=['Low', 'Below Average', 'Average', 'Above Average', 'High']
)

# --- Create experience band ---
df['ExperienceBand'] = pd.cut(
    df['TotalWorkingYears'],
    bins=[-1, 2, 5, 10, 20, 99],
    labels=['Entry (0-2)', 'Early (3-5)', 'Mid (6-10)', 'Senior (11-20)', 'Expert (20+)']
)

# --- Create tenure band ---
df['TenureBand'] = pd.cut(
    df['YearsAtCompany'],
    bins=[-1, 1, 3, 5, 10, 99],
    labels=['New (0-1)', 'Settling (2-3)', 'Established (4-5)', 'Veteran (6-10)', 'Lifer (10+)']
)

print(f"Dataset shape: {df.shape}")
print(f"Columns: {df.columns.tolist()}")
print(f"\nSynthetic columns added:")
synthetic_cols = ['WorkloadScore', 'WeeklyHoursWorked', 'MonthlyMeetings',
                  'CompensationSatisfaction', 'CareerGrowthPerception',
                  'ManagerSupportScore', 'WorkModel', 'ProductivityScore']
for col in synthetic_cols:
    if col == 'WorkModel' or df[col].dtype == 'object' or hasattr(df[col], 'cat'):
        print(f"  {col}: {df[col].value_counts().to_dict()}")
    else:
        col_numeric = pd.to_numeric(df[col], errors='coerce')
        print(f"  {col}: mean={col_numeric.mean():.2f}, std={col_numeric.std():.2f}, min={col_numeric.min()}, max={col_numeric.max()}")

print(f"\nEngineered columns: SalaryBand, ExperienceBand, TenureBand")
print(f"\nAttrition distribution: {df['Attrition'].value_counts().to_dict()}")

df.to_csv(output_path, index=False)
print(f"\nSaved to: {output_path}")
