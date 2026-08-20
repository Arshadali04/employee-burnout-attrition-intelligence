# Business Recommendations — Employee Burnout & Attrition Intelligence

> Evidence-based recommendations derived from statistical analysis, segmentation, and Workforce Health Index findings.

---

## Evidence Confidence Framework

Not all findings carry equal weight. This document distinguishes three confidence tiers:

| Tier | Source | Basis | Reliability |
|------|--------|-------|-------------|
| 🟢 **High confidence** | Real IBM dataset variables | Objective HR data — can be validated against source records | Fully trustworthy |
| 🟡 **Medium confidence** | Engineered bands (SalaryBand, TenureBand, ExperienceBand) | Derived from real variables | Trustworthy — inherits real data quality |
| 🔴 **Low confidence** | Synthetic variables (WorkloadScore, CompensationSatisfaction, CareerGrowthPerception, ManagerSupportScore, WorkloadScore, ProductivityScore, WeeklyHoursWorked, WorkModel) | Generated with Attrition as a direct input — built-in correlation | **Requires real survey validation before acting** |

> **Critical note on synthetic variables:** Eight columns were computationally generated and seeded with `Attrition` as an explicit input. Statistical tests on these variables *will* return significant results by construction — this does not mean the findings are false, only that they must be confirmed with real organizational survey data before informing decisions. The predictive model (Notebook 09) quantifies this: the full model (all features) achieves AUC ~0.86 while the real-variables-only model achieves AUC ~0.76 — the ~0.10 gap is synthetic inflation, not real predictive signal.

---

## Executive Summary

The organization faces a 16.1% attrition rate — above the industry average of ~13%. Analysis reveals that attrition is not random: it concentrates in specific workforce segments. The two findings with the strongest real-data backing are: **(1) overtime burden** and **(2) compensation below role median** — both are from original IBM dataset variables with statistically robust, bias-free evidence. Three additional findings (workload perception, manager support, career growth) are supported by synthetic data and should be treated as hypotheses to validate with real survey instruments.

---

## Recommendation 1: Address Overtime-Driven Burnout

> **Evidence confidence: 🟢 High** — OverTime and WorkLifeBalance are original IBM dataset variables. The 2.5x attrition differential is verifiable against source records.

### Problem
Employees working overtime show significantly higher attrition rates than those who don't. Overtime is statistically associated with lower work-life balance scores, higher workload perception, and reduced job satisfaction.

### Evidence
- Overtime employees have ~2.5x the attrition rate of non-overtime employees 🟢 *(real variable)*
- Chi-square test confirms significant association between OverTime and Attrition (p < 0.001, Cramér's V ≈ 0.24) 🟢
- Overtime employees score lower on WorkLifeBalance (effect observed across all departments) 🟢
- WeeklyHoursWorked for overtime group: mean ~52 hours vs ~41 hours for non-overtime 🔴 *(synthetic — directionally expected but requires validation)*

### Affected Segment
- Employees in "High-Risk Overworked" cluster
- Primarily: Sales Executives, Laboratory Technicians at JobLevel 1-2
- Estimated population: ~25% of workforce

### Suggested Actions
1. Implement mandatory maximum weekly hours threshold (50h) with manager alerts
2. Review workload distribution in high-overtime departments (Sales, R&D)
3. Audit project staffing ratios — chronic overtime signals understaffing
4. Introduce compensatory time-off for unavoidable overtime periods

### Expected Benefit
Reducing overtime exposure in the high-risk group could lower their segment attrition rate by an estimated 30-40% (based on observed differential).

### Limitations
- Correlation, not causation — some overtime may be voluntary/desired
- Salary differential for overtime workers must be considered
- Implementation requires manager buy-in and headcount budget

---

## Recommendation 2: Close the Promotion Gap for Stagnant Employees

> **Evidence confidence: 🟢 High** — YearsSinceLastPromotion is a real IBM dataset variable. The 2x attrition differential for 5+ year stagnation is bias-free.

### Problem
Employees with 5+ years since last promotion show substantially elevated attrition. Career stagnation is one of the strongest real-variable predictors in the dataset.

### Evidence
- Promotion-stagnant employees (5+ years) have ~2x the attrition rate 🟢 *(real variable)*
- YearsSinceLastPromotion is a top-5 feature in the real-variables-only predictive model 🟢
- CareerGrowthPerception is significantly lower for leavers vs stayers (p < 0.001) 🔴 *(synthetic — confirms direction, not magnitude)*
- The "Career Stagnant" cluster shows the second-highest attrition rate 🟡

### Affected Segment
- Employees with YearsSinceLastPromotion ≥ 5
- Concentrated in mid-level roles (JobLevel 2-3)
- Estimated population: ~15-20% of workforce

### Suggested Actions
1. Implement structured career conversations every 12 months (not just annual review)
2. Create lateral move pathways — not every growth path requires vertical promotion
3. Establish a "promotion readiness" framework with transparent criteria
4. Offer skill-development budgets and stretch assignments for stagnant employees
5. Set organizational target: no employee goes 4+ years without a documented growth event (promotion, lateral move, or role expansion)

### Expected Benefit
Addressing career stagnation in the at-risk group could reduce their attrition by 25-35% and improve engagement scores organizationally.

### Limitations
- Not all employees want promotion — some prefer stability
- Budget and org structure constrain promotion velocity
- Lateral moves require cross-department coordination

---

## Recommendation 3: Compensation Review for Below-Market Segments

> **Evidence confidence: 🟢 High** — MonthlyIncome is a real IBM dataset variable. The income gap between leavers and stayers is the most statistically robust finding in the project.

### Problem
Employees in lower salary bands show significantly higher attrition rates. Monthly income is the top-ranked feature in the real-variables-only predictive model.

### Evidence
- Mean MonthlyIncome of leavers significantly lower than stayers (Mann-Whitney U, p < 0.001, r ≈ -0.28) 🟢 *(strongest real-data finding)*
- MonthlyIncome is the #1 feature in the real-variables-only RF model 🟢
- Low and Below Average salary bands carry 2-3x the baseline attrition rate 🟡 *(engineered from real variable)*
- CompensationSatisfaction is lower for leavers 🔴 *(synthetic — directional confirmation only)*

### Affected Segment
- Employees in SalaryBand "Low" and "Below Average" (<$6,000/month)
- Primarily entry-level and early-career roles
- Estimated population: ~40% of workforce (but highest attrition concentration)

### Suggested Actions
1. Conduct market compensation benchmarking for roles in the bottom two salary bands
2. Implement targeted salary adjustments for roles >15% below market median
3. Increase transparency around compensation bands and progression criteria
4. Consider sign-on bonuses or retention bonuses for at-risk high-performers in low bands
5. Review PercentSalaryHike policy — current 11-25% range may be too narrow for catching up

### Expected Benefit
Closing the compensation gap for the bottom-band group could reduce early-career attrition by 20-30%.

### Limitations
- Salary increases have direct budget impact
- Compression issues may arise when adjusting lower bands
- Non-monetary factors (growth, flexibility) also drive attrition — salary alone won't solve it

---

## Recommendation 4: Strengthen Manager Support Quality

> **Evidence confidence: 🔴 Low — requires validation** — ManagerSupportScore is a synthetic variable generated with Attrition as input. The significant result (p < 0.001) is partially by construction. The direction is supported by organizational psychology literature, but the magnitude cannot be trusted without real survey data.

### Problem
Employees rating their manager support as low show markedly higher attrition and lower job satisfaction — but this finding rests on synthetic data and should be treated as a hypothesis.

### Evidence
- ManagerSupportScore is significantly lower for leavers (p < 0.001) 🔴 *(synthetic — significance partly by construction)*
- YearsWithCurrManager (real variable) shows non-linear pattern — very short tenure correlates with lower outcomes 🟢
- Multivariate analysis shows low manager support amplifies high-workload risk (Notebook 05 Analysis 4) 🔴 *(synthetic interaction)*
- **Recommendation: deploy a real manager support pulse survey (e.g., Google re:Work manager effectiveness) to validate this hypothesis with genuine data**

### Affected Segment
- Employees with ManagerSupportScore ≤ 2
- Concentrated in larger teams and newer manager-report relationships
- Cross-cuts departments but higher prevalence in Sales

### Suggested Actions
1. Implement 360-degree feedback for all managers (anonymized upward feedback)
2. Require manager training certification (coaching, feedback, career development conversations)
3. Establish "manager quality" as a tracked organizational metric
4. Provide intervention support (coaching, mentoring) for managers with consistently low scores
5. Consider team size limits — managers with >10 direct reports show lower support scores

### Expected Benefit
Improving manager support from the bottom quartile to average could reduce associated segment attrition by 15-25%.

### Limitations
- Manager support is a synthetic variable in this dataset — findings should be validated with real survey data
- Manager changes are slow (hiring, training, culture)
- Some low scores may reflect employee disengagement rather than manager failure

---

## Recommendation 5: Optimize Work Model Flexibility

> **Evidence confidence: 🔴 Low — requires validation** — WorkModel is a synthetic variable. DistanceFromHome (real) supports the general direction but the work model interaction is based on simulated data.

### Problem
Work model distribution and satisfaction vary — but this analysis rests almost entirely on the synthetic WorkModel variable.

### Evidence
- DistanceFromHome (real) is a significant predictor in the real-variables-only model 🟢 *(long commutes correlate with attrition)*
- Work model chi-square test vs attrition: **not significant** (p > 0.05) 🔴 *(synthetic variable, and even that shows no strong signal)*
- Work model distribution (Onsite/Hybrid/Remote) is synthetic — distribution and attrition effects by model cannot be validated 🔴
- **Only the DistanceFromHome finding is trustworthy: employees with >15 mile commutes are an intervention target regardless of work model label**

### Affected Segment
- Employees with high DistanceFromHome (>15 miles) who are currently Onsite
- Early-career employees who express flexibility preferences
- Cross-departmental but particularly impactful in Sales and R&D

### Suggested Actions
1. Offer hybrid as default with opt-in to full onsite or full remote
2. Match work model to role requirements (not one-size-fits-all policy)
3. Ensure remote/hybrid employees have equal access to promotion and visibility
4. Invest in async collaboration tools to reduce meeting burden for distributed teams
5. Track engagement and attrition by work model quarterly to detect drift

### Expected Benefit
Aligning work model to employee preference (especially for long-commute employees) could improve satisfaction scores by 0.3-0.5 points and reduce associated attrition.

### Limitations
- Work model is synthetic — real survey validation needed
- Not all roles can be remote (lab technicians, manufacturing)
- Cultural/collaboration costs of full-remote are not captured in this dataset

---

## Priority Matrix

| Recommendation | Evidence Confidence | Impact | Effort | Priority |
|----------------|-------------------|--------|--------|----------|
| 3. Compensation review | 🟢 High | High | High (budget) | **1st** |
| 1. Overtime reduction | 🟢 High | High | Medium | **2nd** |
| 2. Promotion gap | 🟢 High | High | Medium | **3rd** |
| 4. Manager support | 🔴 Low | Medium-High | High (time) | **4th — validate first** |
| 5. Work model flexibility | 🔴 Low | Medium | Low | **5th — validate first** |

> **Note on ordering:** Recommendations 1-3 are reordered to put the highest-confidence, highest-impact finding (compensation) first. Recommendations 4-5 should be preceded by deploying real survey instruments to confirm the synthetic-variable signals before committing resources.

---

## Implementation Roadmap

**Quick wins (0-3 months):**
- Overtime monitoring alerts
- Work model flexibility policy update
- Career conversation scheduling

**Medium-term (3-6 months):**
- Compensation benchmarking and targeted adjustments
- Manager training program launch
- Promotion readiness framework design

**Long-term (6-12 months):**
- Full manager quality tracking system
- Career pathway documentation across all roles
- Longitudinal attrition tracking to validate interventions

---

## Disclaimer

These recommendations are based on observational data analysis. All findings reflect statistical associations, not proven causal relationships. The synthetic columns in this analysis were generated for analytical completeness and should be validated against real organizational survey data before implementation. The Workforce Health Index is an analytical tool, not a clinical or psychological assessment.
