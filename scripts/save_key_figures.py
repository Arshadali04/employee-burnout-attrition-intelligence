"""
Save Key Figures for Portfolio
================================
Generates 12 publication-quality PNG charts from the processed dataset
and saves them to images/. Run this after notebooks 01-09 have executed.

Usage: python scripts/save_key_figures.py
"""

import os
import sys
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
from pathlib import Path

warnings.filterwarnings('ignore')

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE = Path(__file__).parent.parent
DATA = BASE / 'data' / 'processed' / 'employee_attrition_augmented.csv'
OUT  = BASE / 'images'
OUT.mkdir(exist_ok=True)

# ── Theme ─────────────────────────────────────────────────────────────────────
TEAL  = '#1B4F72'
BLUE  = '#2E86C1'
RED   = '#E74C3C'
GREEN = '#27AE60'
AMBER = '#F39C12'
GRAY  = '#7F8C8D'

sns.set_style('whitegrid')
plt.rcParams.update({
    'figure.dpi': 150,
    'font.family': 'DejaVu Sans',
    'font.size': 11,
    'axes.titlesize': 13,
    'axes.labelsize': 11,
    'axes.spines.top': False,
    'axes.spines.right': False,
})

SAVED = []

def save(name):
    path = OUT / name
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    SAVED.append(name)
    print(f'  [saved] {name}')


# ── Load data ─────────────────────────────────────────────────────────────────
df = pd.read_csv(DATA)
df['Attrition_Binary'] = (df['Attrition'] == 'Yes').astype(int)
overall_rate = df['Attrition_Binary'].mean()
print(f'Loaded {len(df):,} rows, {df.shape[1]} columns\n')

# ── Figure 01: Attrition Overview ─────────────────────────────────────────────
fig, axes = plt.subplots(1, 3, figsize=(15, 5))

# Distribution
counts = df['Attrition'].value_counts()
colors_pie = [TEAL, RED]
axes[0].bar(['Stayed', 'Left'], [counts.get('No', 0), counts.get('Yes', 0)],
            color=[TEAL, RED], edgecolor='white', linewidth=0.5)
axes[0].set_title('Overall Attrition Distribution')
axes[0].set_ylabel('Number of Employees')
for i, (lbl, val) in enumerate(zip(['Stayed', 'Left'],
                                     [counts.get('No',0), counts.get('Yes',0)])):
    axes[0].text(i, val + 10, f'{val:,}\n({val/len(df)*100:.1f}%)',
                 ha='center', fontsize=11, fontweight='bold')

# By Department
dept_rates = df.groupby('Department')['Attrition_Binary'].mean().sort_values(ascending=True)
axes[1].barh(dept_rates.index, dept_rates.values * 100,
             color=[RED if r > overall_rate else TEAL for r in dept_rates.values])
axes[1].axvline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5,
                label=f'Overall {overall_rate*100:.1f}%')
for i, v in enumerate(dept_rates.values):
    axes[1].text(v * 100 + 0.2, i, f'{v*100:.1f}%', va='center', fontsize=10)
axes[1].set_title('Attrition Rate by Department')
axes[1].set_xlabel('Attrition Rate (%)')
axes[1].legend()

# By Job Level
jl_rates = df.groupby('JobLevel')['Attrition_Binary'].mean()
jl_counts = df.groupby('JobLevel')['Attrition_Binary'].count()
bars = axes[2].bar(jl_rates.index, jl_rates.values * 100,
                   color=[RED if r > overall_rate else TEAL for r in jl_rates.values],
                   edgecolor='white')
axes[2].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5,
                label=f'Overall {overall_rate*100:.1f}%')
for bar, r, n in zip(bars, jl_rates.values, jl_counts.values):
    axes[2].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
                 f'{r*100:.0f}%', ha='center', fontsize=9)
axes[2].set_title('Attrition Rate by Job Level')
axes[2].set_xlabel('Job Level (1=Entry, 5=Executive)')
axes[2].set_ylabel('Attrition Rate (%)')
axes[2].legend()

plt.suptitle('Employee Attrition — Workforce Overview', fontsize=15, fontweight='bold')
plt.tight_layout()
save('01_attrition_overview.png')

# ── Figure 02: Income vs Attrition ────────────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(13, 5))

sns.boxplot(data=df, x='Attrition', y='MonthlyIncome',
            palette={'No': TEAL, 'Yes': RED}, ax=axes[0])
axes[0].set_title('Monthly Income: Stayers vs Leavers')
axes[0].set_xlabel('Attrition Status')
axes[0].set_ylabel('Monthly Income ($)')
med_no  = df[df['Attrition']=='No']['MonthlyIncome'].median()
med_yes = df[df['Attrition']=='Yes']['MonthlyIncome'].median()
axes[0].annotate(f'Median\n${med_no:,.0f}',
                 xy=(0, med_no), xytext=(0.15, med_no + 500),
                 arrowprops=dict(arrowstyle='->', color='black'), fontsize=9)
axes[0].annotate(f'Median\n${med_yes:,.0f}',
                 xy=(1, med_yes), xytext=(1.15, med_yes + 500),
                 arrowprops=dict(arrowstyle='->', color='black'), fontsize=9)

sal_order = ['Low', 'Below Average', 'Average', 'Above Average', 'High']
sal_rates = (df.groupby('SalaryBand')['Attrition_Binary']
               .mean().reindex(sal_order) * 100)
sal_counts = df.groupby('SalaryBand')['Attrition_Binary'].count().reindex(sal_order)
bars = axes[1].bar(sal_order, sal_rates,
                   color=[RED if r > overall_rate*100 else TEAL for r in sal_rates.fillna(0)],
                   edgecolor='white')
axes[1].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5, label=f'Overall {overall_rate*100:.1f}%')
for bar, r, n in zip(bars, sal_rates.fillna(0), sal_counts.fillna(0)):
    axes[1].text(bar.get_x() + bar.get_width()/2, r + 0.3, f'{r:.0f}%', ha='center', fontsize=9)
axes[1].set_title('Attrition Rate by Salary Band')
axes[1].set_xlabel('Salary Band'); axes[1].set_ylabel('Attrition Rate (%)')
axes[1].tick_params(axis='x', rotation=20)
axes[1].legend()

plt.suptitle('Compensation & Attrition', fontsize=15, fontweight='bold')
plt.tight_layout()
save('02_income_attrition.png')

# ── Figure 03: Overtime & Workload ────────────────────────────────────────────
fig, axes = plt.subplots(1, 3, figsize=(15, 5))

ot_rates = df.groupby('OverTime')['Attrition_Binary'].mean() * 100
bars = axes[0].bar(ot_rates.index, ot_rates.values,
                   color=[TEAL, RED], edgecolor='white', width=0.4)
axes[0].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5)
for bar, r in zip(bars, ot_rates.values):
    axes[0].text(bar.get_x() + bar.get_width()/2, r + 0.3,
                 f'{r:.1f}%', ha='center', fontsize=12, fontweight='bold')
axes[0].set_title('Attrition Rate by OverTime')
axes[0].set_ylabel('Attrition Rate (%)')

# Relative risk annotation
rr = ot_rates.get('Yes', 0) / ot_rates.get('No', 1)
axes[0].text(0.5, 0.9, f'Relative Risk: {rr:.1f}x', transform=axes[0].transAxes,
             ha='center', fontsize=12, fontweight='bold', color=RED)

wl_rates = df.groupby('WorkloadScore')['Attrition_Binary'].mean() * 100
wl_counts = df.groupby('WorkloadScore')['Attrition_Binary'].count()
axes[1].bar(wl_rates.index, wl_rates.values,
            color=[RED if r > overall_rate*100 else TEAL for r in wl_rates.values],
            edgecolor='white')
axes[1].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5)
axes[1].set_title('Attrition Rate by Workload Score')
axes[1].set_xlabel('Workload Score (1=Light, 5=Extreme)')
axes[1].set_ylabel('Attrition Rate (%)')

sns.boxplot(data=df, x='OverTime', y='WeeklyHoursWorked',
            palette={'No': TEAL, 'Yes': RED}, ax=axes[2])
axes[2].set_title('Weekly Hours by OverTime Status')
axes[2].set_ylabel('Weekly Hours Worked')

plt.suptitle('Overtime, Workload & Attrition', fontsize=15, fontweight='bold')
plt.tight_layout()
save('03_overtime_workload.png')

# ── Figure 04: Statistical Key Findings Summary ───────────────────────────────
fig, ax = plt.subplots(figsize=(12, 7))
ax.axis('off')

tests = [
    ('Income vs Attrition',       'Mann-Whitney U', 'p < 0.001', 'r ≈ -0.28', 'Leavers earn significantly less',               'High'),
    ('OverTime vs Attrition',      'Chi-Square',     'p < 0.001', "V ≈ 0.24",  'OT employees ~2.5x more likely to leave',       'High'),
    ('JobSat across Departments',  'Kruskal-Wallis', 'p > 0.05',  "η² ≈ 0.00", 'No dept-specific satisfaction gap',             'High'),
    ('WorkModel vs Attrition',     'Chi-Square',     'p > 0.05',  "V ≈ 0.03",  'Work model alone not predictive',               'High'),
    ('Workload vs Satisfaction',   'Spearman ρ',     'p < 0.001', "ρ ≈ -0.15", 'Weak negative: workload↑ satisfaction↓',        'High'),
    ('ManagerSupport vs Attrition','Mann-Whitney U', 'p < 0.001', "r ≈ -0.22", 'Leavers perceive less manager support',         'Medium*'),
    ('CareerGrowth vs Attrition',  'Mann-Whitney U', 'p < 0.001', "r ≈ -0.31", 'Leavers see fewer career opportunities',         'Medium*'),
    ('Sat ~ Dept × JobLevel',      'Two-way ANOVA',  'See table',  'See table', 'Interaction effect tested',                      'High'),
]

headers = ['Variable Pair', 'Test', 'p-value', 'Effect Size', 'Finding', 'Confidence']
col_widths = [0.22, 0.12, 0.09, 0.10, 0.33, 0.10]

# Header
y_pos = 0.95
x_pos = 0.01
for header, w in zip(headers, col_widths):
    ax.text(x_pos, y_pos, header, fontsize=10, fontweight='bold',
            transform=ax.transAxes, color='white',
            bbox=dict(boxstyle='round,pad=0.3', facecolor=TEAL, alpha=0.9))
    x_pos += w

# Rows
for i, row in enumerate(tests):
    y_pos -= 0.10
    x_pos = 0.01
    bg = '#F2F3F4' if i % 2 == 0 else 'white'
    for val, w in zip(row, col_widths):
        color = RED if '*' in str(row[-1]) else TEAL
        if val == row[-1]:  # confidence column
            fc = '#FFE0E0' if '*' in val else '#E0FFE0'
        else:
            fc = bg
        ax.text(x_pos + 0.005, y_pos, val, fontsize=9, transform=ax.transAxes,
                verticalalignment='center',
                bbox=dict(boxstyle='round,pad=0.2', facecolor=fc, alpha=0.7))
        x_pos += w

ax.text(0.01, 0.03, '* Medium confidence — synthetic variables have built-in attrition correlation; validated by real-data model (Notebook 09)',
        fontsize=8, transform=ax.transAxes, color=GRAY, style='italic')

ax.set_title('Statistical Analysis Summary — 8 Hypothesis Tests',
             fontsize=14, fontweight='bold', pad=15)
plt.tight_layout()
save('04_statistical_summary.png')

# ── Figure 05: WHI Distribution (if available) ────────────────────────────────
if 'WHI' in df.columns:
    cat_colors = {
        'Critical': RED, 'At Risk': AMBER, 'Moderate': '#F7DC6F',
        'Healthy': GREEN, 'Thriving': TEAL
    }
    cat_order = ['Critical', 'At Risk', 'Moderate', 'Healthy', 'Thriving']

    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    for cat in cat_order:
        subset = df[df.get('WHI_Risk_Category', pd.Series()) == cat]['WHI'] if 'WHI_Risk_Category' in df.columns else pd.Series()
        if len(subset) > 0:
            axes[0].hist(subset, bins=20, alpha=0.7, color=cat_colors[cat],
                        label=f'{cat} (n={len(subset)})', edgecolor='white')

    axes[0].set_xlabel('Workforce Health Index (0-100)')
    axes[0].set_ylabel('Count')
    axes[0].set_title('WHI Distribution by Risk Category')
    axes[0].legend(fontsize=9)

    if 'WHI_Risk_Category' in df.columns:
        cat_att = df.groupby('WHI_Risk_Category')['Attrition_Binary'].agg(['mean','count']).reindex(cat_order)
        bars = axes[1].bar(cat_order, cat_att['mean'] * 100,
                           color=[cat_colors[c] for c in cat_order], edgecolor='white')
        axes[1].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5,
                        label=f'Overall {overall_rate*100:.1f}%')
        for bar, (_, row) in zip(bars, cat_att.iterrows()):
            if not pd.isna(row['mean']):
                axes[1].text(bar.get_x() + bar.get_width()/2, row['mean']*100 + 0.3,
                            f"{row['mean']*100:.1f}%\n(n={row['count']:.0f})",
                            ha='center', fontsize=9)
        axes[1].set_ylabel('Attrition Rate (%)')
        axes[1].set_title('Attrition Rate by WHI Risk Category')
        axes[1].legend()

    plt.suptitle('Workforce Health Index — Distribution & Attrition Validation',
                fontsize=14, fontweight='bold')
    plt.tight_layout()
    save('05_whi_distribution.png')
else:
    print('  [skip] WHI not in dataset -- — run notebook 08 first for figure 05')

# ── Figure 06: Key Attrition Drivers Comparison ───────────────────────────────
fig, axes = plt.subplots(2, 3, figsize=(15, 10))

# Satisfaction comparison
for metric, ax, title in [
    ('JobSatisfaction',      axes[0,0], 'Job Satisfaction (1-4)'),
    ('WorkLifeBalance',      axes[0,1], 'Work-Life Balance (1-4)'),
    ('EnvironmentSatisfaction', axes[0,2], 'Environment Satisfaction (1-4)'),
]:
    sns.boxplot(data=df, x='Attrition', y=metric,
                palette={'No': TEAL, 'Yes': RED}, ax=ax)
    ax.set_title(title); ax.set_xlabel('Attrition')

# Tenure comparison
sns.boxplot(data=df, x='Attrition', y='YearsAtCompany',
            palette={'No': TEAL, 'Yes': RED}, ax=axes[1,0])
axes[1,0].set_title('Tenure (Years at Company)')

sns.boxplot(data=df, x='Attrition', y='YearsSinceLastPromotion',
            palette={'No': TEAL, 'Yes': RED}, ax=axes[1,1])
axes[1,1].set_title('Years Since Last Promotion')

sns.boxplot(data=df, x='Attrition', y='TotalWorkingYears',
            palette={'No': TEAL, 'Yes': RED}, ax=axes[1,2])
axes[1,2].set_title('Total Working Years (Experience)')

plt.suptitle('Key Attrition Drivers — Leavers vs Stayers',
             fontsize=15, fontweight='bold')
plt.tight_layout()
save('06_attrition_drivers.png')

# ── Figure 07: Tenure Attrition ───────────────────────────────────────────────
tenure_order = ['New (0-1)', 'Settling (2-3)', 'Established (4-5)', 'Veteran (6-10)', 'Lifer (10+)']

fig, ax = plt.subplots(figsize=(12, 5))
rates  = df.groupby('TenureBand')['Attrition_Binary'].mean().reindex(tenure_order) * 100
counts = df.groupby('TenureBand')['Attrition_Binary'].count().reindex(tenure_order)
bars = ax.bar(tenure_order, rates,
              color=[RED if r > overall_rate*100 else TEAL for r in rates.fillna(0)],
              edgecolor='white')
ax.axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5,
           label=f'Overall {overall_rate*100:.1f}%')
for bar, r, n in zip(bars, rates.fillna(0), counts.fillna(0)):
    ax.text(bar.get_x() + bar.get_width()/2, r + 0.3,
            f'{r:.0f}%\n(n={n:.0f})', ha='center', fontsize=10)
ax.set_xlabel('Tenure Band'); ax.set_ylabel('Attrition Rate (%)')
ax.set_title('Attrition Rate by Tenure — Danger Zone in Early Tenure',
             fontsize=13, fontweight='bold')
ax.legend()
plt.tight_layout()
save('07_tenure_attrition.png')

# ── Figure 08: Promotion Gap ──────────────────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(13, 5))

promo_bins = pd.cut(df['YearsSinceLastPromotion'], bins=[-1,1,3,5,15],
                    labels=['0-1yr','2-3yrs','4-5yrs','6+yrs'])
promo_rates = df.groupby(promo_bins)['Attrition_Binary'].mean() * 100
bars = axes[0].bar(promo_rates.index, promo_rates.values,
                   color=[RED if r > overall_rate*100 else TEAL for r in promo_rates.values],
                   edgecolor='white')
axes[0].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5)
for bar, r in zip(bars, promo_rates.values):
    axes[0].text(bar.get_x() + bar.get_width()/2, r + 0.3, f'{r:.1f}%',
                 ha='center', fontsize=11, fontweight='bold')
axes[0].set_title('Attrition by Promotion Gap')
axes[0].set_xlabel('Years Since Last Promotion')
axes[0].set_ylabel('Attrition Rate (%)')

df['PromoStagnant'] = (df['YearsSinceLastPromotion'] >= 5).astype(int)
stagnant_rate = df[df['PromoStagnant']==1]['Attrition_Binary'].mean() * 100
active_rate   = df[df['PromoStagnant']==0]['Attrition_Binary'].mean() * 100
axes[1].bar(['Not Stagnant\n(<5 yrs)', 'Stagnant\n(5+ yrs)'],
            [active_rate, stagnant_rate],
            color=[TEAL, RED], edgecolor='white', width=0.4)
axes[1].axhline(overall_rate * 100, color=GRAY, linestyle='--', lw=1.5,
                label=f'Overall {overall_rate*100:.1f}%')
for i, r in enumerate([active_rate, stagnant_rate]):
    axes[1].text(i, r + 0.3, f'{r:.1f}%', ha='center', fontsize=13, fontweight='bold')
axes[1].set_ylabel('Attrition Rate (%)')
axes[1].set_title('Stagnant vs Active Career Progression')
axes[1].legend()
rr_promo = stagnant_rate / active_rate
axes[1].text(0.5, 0.9, f'Risk Ratio: {rr_promo:.1f}x', transform=axes[1].transAxes,
             ha='center', fontsize=12, fontweight='bold', color=RED)

plt.suptitle('Career Stagnation & Attrition', fontsize=15, fontweight='bold')
plt.tight_layout()
save('08_promotion_gap.png')

# ── Done ──────────────────────────────────────────────────────────────────────
print(f'\n{"="*50}')
print(f'Saved {len(SAVED)} figures to images/')
for fname in SAVED:
    print(f'  images/{fname}')
print('='*50)
