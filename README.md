# 🏥 Hospital Management System — CTEs & SQL Window Functions

**Course:** C11665 - DPR400210: Database Programming  
**Instructor:** Eric Maniraguha  
**Institution:** University of Lay Adventists of Kigali (UNILAK)  
**Student:** Mohamed | ID: 249mohamed  
**Submission Deadline:** Monday, June 29, 2026  

---

## 📋 Table of Contents

1. [Business Problem](#business-problem)
2. [Database Schema](#database-schema)
3. [ER Diagram](#er-diagram)
4. [Part A – CTE Implementations](#part-a--cte-implementations)
5. [Part B – Window Function Implementations](#part-b--window-function-implementations)
6. [Analysis and Findings](#analysis-and-findings)
7. [References](#references)
8. [Academic Integrity Statement](#academic-integrity-statement)

---

## 🏥 Business Problem

Modern hospitals generate enormous amounts of operational data across departments, doctors, patients, and appointments. Without proper analytical tools, hospital administrators struggle to:

- Identify which departments generate the most revenue
- Track individual doctor performance and workload
- Detect high-cost treatment outliers for insurance reviews
- Monitor patient visit patterns and forecast future costs
- Segment patients by spending level for customized care plans

This project builds a **Hospital Management System** database and applies advanced SQL techniques — **Common Table Expressions (CTEs)** and **Window Functions** — to answer these business questions with precision.

---

## 🗄️ Database Schema

The system uses **4 related tables**:

### `departments`
| Column | Type | Constraint |
|--------|------|------------|
| department_id | INTEGER | PRIMARY KEY |
| dept_name | VARCHAR(100) | NOT NULL |
| location | VARCHAR(100) | |
| budget | DECIMAL(12,2) | |

### `doctors`
| Column | Type | Constraint |
|--------|------|------------|
| doctor_id | INTEGER | PRIMARY KEY |
| full_name | VARCHAR(100) | NOT NULL |
| specialty | VARCHAR(100) | |
| department_id | INTEGER | FOREIGN KEY → departments |
| hire_date | DATE | |
| salary | DECIMAL(10,2) | |
| years_experience | INTEGER | |

### `patients`
| Column | Type | Constraint |
|--------|------|------------|
| patient_id | INTEGER | PRIMARY KEY |
| full_name | VARCHAR(100) | NOT NULL |
| date_of_birth | DATE | |
| gender | VARCHAR(10) | |
| phone | VARCHAR(20) | |
| city | VARCHAR(80) | |

### `appointments`
| Column | Type | Constraint |
|--------|------|------------|
| appointment_id | INTEGER | PRIMARY KEY |
| patient_id | INTEGER | FOREIGN KEY → patients |
| doctor_id | INTEGER | FOREIGN KEY → doctors |
| appointment_date | DATE | |
| diagnosis | VARCHAR(200) | |
| treatment_cost | DECIMAL(10,2) | |
| status | VARCHAR(30) | 'Completed' / 'Pending' / 'Cancelled' |

---

## 📊 ER Diagram

![ER Diagram](er_diagram/er_diagram.png)

**Relationships:**
- `departments` **1 : N** `doctors` — One department employs many doctors
- `doctors` **1 : N** `appointments` — One doctor handles many appointments
- `patients` **1 : N** `appointments` — One patient books many appointments

---

## Part A – CTE Implementations

### CTE 1: Simple CTE — High-Cost Appointments

**Business Value:** Identifies all completed appointments costing above the hospital average. These are flagged for insurance reimbursement review and cost-management audits.

```sql
WITH high_cost_appointments AS (
    SELECT
        appointment_id, patient_id, doctor_id,
        appointment_date, diagnosis, treatment_cost
    FROM appointments
    WHERE treatment_cost > (SELECT AVG(treatment_cost) FROM appointments)
      AND status = 'Completed'
)
SELECT
    h.appointment_id,
    p.full_name   AS patient_name,
    d.full_name   AS doctor_name,
    h.diagnosis,
    h.treatment_cost,
    h.appointment_date
FROM high_cost_appointments h
JOIN patients p ON p.patient_id = h.patient_id
JOIN doctors  d ON d.doctor_id  = h.doctor_id
ORDER BY h.treatment_cost DESC;
```

**Screenshot:**  
![CTE 1 Result](screenshots/cte1_simple.png)

**Interpretation:** 8 appointments exceeded the average cost. Knee Replacement (8,500), Gallbladder Surgery (7,200), and Appendectomy (6,000) were the highest-cost procedures — all surgical interventions requiring closer cost monitoring.

---

### CTE 2: Multiple CTEs — Department Revenue Performance

**Business Value:** By chaining two CTEs, we first compute per-department revenue, then compare each against the hospital-wide average — all in a single, readable query.

```sql
WITH dept_revenue AS (
    SELECT dept.department_id, dept.dept_name,
           SUM(a.treatment_cost) AS total_revenue,
           COUNT(a.appointment_id) AS total_appointments
    FROM departments dept
    JOIN doctors doc ON doc.department_id = dept.department_id
    JOIN appointments a ON a.doctor_id = doc.doctor_id
    WHERE a.status = 'Completed'
    GROUP BY dept.department_id, dept.dept_name
),
hospital_avg AS (
    SELECT AVG(total_revenue) AS avg_revenue FROM dept_revenue
)
SELECT dr.dept_name, dr.total_revenue, dr.total_appointments,
       ROUND(ha.avg_revenue, 2) AS hospital_avg_revenue,
       ROUND(dr.total_revenue - ha.avg_revenue, 2) AS variance_from_avg,
       CASE WHEN dr.total_revenue >= ha.avg_revenue THEN 'Above Average' ELSE 'Below Average' END
FROM dept_revenue dr CROSS JOIN hospital_avg ha
ORDER BY dr.total_revenue DESC;
```

**Screenshot:**  
![CTE 2 Result](screenshots/cte2_multiple.png)

**Interpretation:** General Surgery and Cardiology are the top-performing departments by revenue. Pediatrics is below the hospital average, partly due to lower individual treatment costs per visit.

---

### CTE 3: Recursive CTE — Monthly Appointment Calendar

**Business Value:** Uses a recursive CTE to generate all 12 months of 2024, then LEFT JOINs actual appointment data. This immediately reveals any months with zero activity — critical for capacity planning.

```sql
WITH RECURSIVE month_series(month_num, month_start) AS (
    SELECT 1, DATE '2024-01-01'
    UNION ALL
    SELECT month_num + 1, month_start + INTERVAL '1 month'
    FROM month_series WHERE month_num < 12
),
monthly_appointments AS (
    SELECT EXTRACT(MONTH FROM appointment_date)::INTEGER AS month_num,
           COUNT(*) AS appt_count,
           SUM(treatment_cost) AS monthly_revenue
    FROM appointments
    WHERE EXTRACT(YEAR FROM appointment_date) = 2024
    GROUP BY EXTRACT(MONTH FROM appointment_date)
)
SELECT ms.month_num, strftime(ms.month_start, '%B %Y') AS month_label,
       COALESCE(ma.appt_count, 0) AS appointments,
       COALESCE(ma.monthly_revenue, 0) AS revenue
FROM month_series ms
LEFT JOIN monthly_appointments ma ON ma.month_num = ms.month_num
ORDER BY ms.month_num;
```

**Screenshot:**  
![CTE 3 Result](screenshots/cte3_recursive.png)

**Interpretation:** Appointments are concentrated in January–July 2024, with months August–December showing zero activity in this dataset (future appointments not yet recorded). The recursive CTE ensures every month appears in the report even without data.

---

### CTE 4: CTE with Aggregation — Doctor Performance Summary

**Business Value:** Aggregates each doctor's total revenue, appointment count, and cost range. Provides management with a complete performance dashboard to reward top doctors and support lower performers.

```sql
WITH doctor_performance AS (
    SELECT d.doctor_id, d.full_name AS doctor_name, d.specialty,
           dept.dept_name,
           COUNT(a.appointment_id)  AS total_appointments,
           SUM(a.treatment_cost)    AS total_revenue,
           ROUND(AVG(a.treatment_cost), 2) AS avg_treatment_cost,
           MIN(a.treatment_cost)    AS min_cost,
           MAX(a.treatment_cost)    AS max_cost
    FROM doctors d
    JOIN departments dept ON dept.department_id = d.department_id
    LEFT JOIN appointments a ON a.doctor_id = d.doctor_id AND a.status = 'Completed'
    GROUP BY d.doctor_id, d.full_name, d.specialty, dept.dept_name
)
SELECT doctor_name, specialty, dept_name, total_appointments,
       total_revenue, avg_treatment_cost, min_cost, max_cost
FROM doctor_performance
ORDER BY total_revenue DESC NULLS LAST;
```

**Screenshot:**  
![CTE 4 Result](screenshots/cte4_aggregation.png)

**Interpretation:** Dr. Emma Ingabire (General Surgery) and Dr. Claire Uwase (Orthopedics) lead in total revenue due to high-cost surgical procedures. Dr. Irene Mukamana and Dr. David Habimana handle more volume but at lower per-visit costs.

---

### CTE 5: CTE with JOIN Operations — Multi-Department Patients

**Business Value:** Patients visiting multiple departments require coordinated care plans. This CTE identifies them so case managers can prioritize inter-departmental coordination.

```sql
WITH patient_dept_visits AS (
    SELECT a.patient_id,
           COUNT(DISTINCT doc.department_id) AS dept_count,
           COUNT(a.appointment_id)           AS total_visits,
           SUM(a.treatment_cost)             AS lifetime_spend
    FROM appointments a
    JOIN doctors doc ON doc.doctor_id = a.doctor_id
    GROUP BY a.patient_id
),
multi_dept_patients AS (
    SELECT * FROM patient_dept_visits WHERE dept_count >= 2
)
SELECT p.full_name AS patient_name, p.gender, p.city,
       mdp.dept_count AS departments_visited,
       mdp.total_visits, mdp.lifetime_spend
FROM multi_dept_patients mdp
JOIN patients p ON p.patient_id = mdp.patient_id
ORDER BY mdp.dept_count DESC, mdp.lifetime_spend DESC;
```

**Screenshot:**  
![CTE 5 Result](screenshots/cte5_joins.png)

**Interpretation:** 5 patients visited 2 or more departments. These are the most complex cases clinically and highest earners for the hospital. They should be assigned dedicated care coordinators.

---

## Part B – Window Function Implementations

### 1. Ranking Functions

#### ROW_NUMBER() — Sequential Doctor Ranking

**Business Use:** Generate a unique ordered list of doctors by revenue. Unlike RANK(), ROW_NUMBER guarantees no duplicate positions.

```sql
SELECT d.full_name AS doctor_name, d.specialty, dept.dept_name,
       SUM(a.treatment_cost) AS total_revenue,
       ROW_NUMBER() OVER (ORDER BY SUM(a.treatment_cost) DESC) AS row_num
FROM doctors d
JOIN departments dept ON dept.department_id = d.department_id
JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty, dept.dept_name
ORDER BY total_revenue DESC;
```

![ROW_NUMBER Result](screenshots/wf1_row_number.png)

---

#### RANK() — Ranking with Gaps

**Business Use:** Fair rankings where tied doctors share the same rank but the next position is skipped.

```sql
SELECT d.full_name AS doctor_name, d.specialty,
       SUM(a.treatment_cost) AS total_revenue,
       RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC) AS revenue_rank
FROM doctors d JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty
ORDER BY revenue_rank;
```

![RANK Result](screenshots/wf2_rank.png)

---

#### DENSE_RANK() — Ranking without Gaps + Performance Tiers

**Business Use:** Assign Gold/Silver/Bronze tiers to doctors based on revenue ranking.

```sql
SELECT d.full_name AS doctor_name, d.specialty,
       SUM(a.treatment_cost) AS total_revenue,
       DENSE_RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC) AS dense_rank,
       CASE DENSE_RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC)
           WHEN 1 THEN 'Gold' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Bronze' ELSE 'Standard'
       END AS performance_tier
FROM doctors d JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty
ORDER BY dense_rank;
```

![DENSE_RANK Result](screenshots/wf3_dense_rank.png)

---

#### PERCENT_RANK() — Salary Percentile Within Department

**Business Use:** Know where each doctor's salary falls within their department (top 10%? bottom 50%?).

```sql
SELECT d.full_name AS doctor_name, dept.dept_name, d.salary,
       ROUND(PERCENT_RANK() OVER (PARTITION BY d.department_id ORDER BY d.salary) * 100, 2)
           AS salary_percentile
FROM doctors d JOIN departments dept ON dept.department_id = d.department_id
ORDER BY dept.dept_name, d.salary;
```

![PERCENT_RANK Result](screenshots/wf4_percent_rank.png)

---

### 2. Aggregate Window Functions

#### SUM() OVER() — Running Total Revenue

**Business Use:** Track the hospital's cumulative revenue over time to monitor financial growth.

```sql
SELECT appointment_date, treatment_cost,
       SUM(treatment_cost) OVER (
           ORDER BY appointment_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total_revenue
FROM appointments WHERE status = 'Completed'
ORDER BY appointment_date;
```

![SUM OVER Result](screenshots/wf5_sum_over.png)

---

#### AVG() OVER() — Doctor Salary vs Department Average

**Business Use:** Instantly see if any doctor is overpaid or underpaid relative to their department.

```sql
SELECT d.full_name AS doctor_name, dept.dept_name, d.salary,
       ROUND(AVG(d.salary) OVER (PARTITION BY d.department_id), 2) AS dept_avg_salary,
       ROUND(d.salary - AVG(d.salary) OVER (PARTITION BY d.department_id), 2) AS diff_from_avg
FROM doctors d JOIN departments dept ON dept.department_id = d.department_id
ORDER BY dept.dept_name, d.salary DESC;
```

![AVG OVER Result](screenshots/wf6_avg_over.png)

---

#### MIN() OVER() — Minimum Treatment Cost per Specialty

**Business Use:** Benchmark each appointment's cost against the cheapest in the same specialty.

```sql
SELECT a.appointment_id, d.specialty, a.diagnosis, a.treatment_cost,
       MIN(a.treatment_cost) OVER (PARTITION BY d.specialty) AS min_cost_in_specialty
FROM appointments a JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
ORDER BY d.specialty, a.treatment_cost;
```

![MIN OVER Result](screenshots/wf7_min_over.png)

---

#### MAX() OVER() — Maximum Treatment Cost per Department

**Business Use:** Flag the highest-cost treatment in each department as a reference for outlier detection.

```sql
SELECT a.appointment_id, dept.dept_name, a.diagnosis, a.treatment_cost,
       MAX(a.treatment_cost) OVER (PARTITION BY dept.department_id) AS max_cost_in_dept
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
JOIN departments dept ON dept.department_id = d.department_id
WHERE a.status = 'Completed'
ORDER BY dept.dept_name, a.treatment_cost DESC;
```

![MAX OVER Result](screenshots/wf8_max_over.png)

---

### 3. Navigation Functions

#### LAG() — Compare Current vs Previous Visit Cost

**Business Use:** Detect whether a returning patient's treatment cost increased, decreased, or stayed the same since their last visit.

```sql
SELECT p.full_name AS patient_name, a.appointment_date, a.diagnosis, a.treatment_cost,
       LAG(a.treatment_cost) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date) AS prev_visit_cost,
       ROUND(a.treatment_cost - COALESCE(
           LAG(a.treatment_cost) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date), 0
       ), 2) AS cost_change
FROM appointments a JOIN patients p ON p.patient_id = a.patient_id
ORDER BY a.patient_id, a.appointment_date;
```

![LAG Result](screenshots/wf9_lag.png)

---

#### LEAD() — Next Appointment Cost Forecast

**Business Use:** Give patients and financial staff advance notice of what their next visit will cost, supporting budgeting and insurance pre-authorization.

```sql
SELECT p.full_name AS patient_name, a.appointment_date, a.diagnosis, a.treatment_cost,
       LEAD(a.treatment_cost) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date) AS next_visit_cost,
       LEAD(a.appointment_date) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date) AS next_visit_date
FROM appointments a JOIN patients p ON p.patient_id = a.patient_id
ORDER BY a.patient_id, a.appointment_date;
```

![LEAD Result](screenshots/wf10_lead.png)

---

### 4. Distribution Functions

#### NTILE(4) — Patient Cost Quartile Segmentation

**Business Use:** Divide patients into four cost tiers (Platinum, Gold, Silver, Bronze) for differentiated insurance pricing and service packages.

```sql
SELECT p.full_name AS patient_name,
       SUM(a.treatment_cost) AS total_spend,
       NTILE(4) OVER (ORDER BY SUM(a.treatment_cost) DESC) AS cost_quartile,
       CASE NTILE(4) OVER (ORDER BY SUM(a.treatment_cost) DESC)
           WHEN 1 THEN 'Platinum (Highest Cost)' WHEN 2 THEN 'Gold'
           WHEN 3 THEN 'Silver' WHEN 4 THEN 'Bronze (Lowest Cost)'
       END AS cost_tier
FROM appointments a JOIN patients p ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
GROUP BY a.patient_id, p.full_name
ORDER BY cost_quartile, total_spend DESC;
```

![NTILE Result](screenshots/wf11_ntile.png)

---

#### CUME_DIST() — Cumulative Distribution of Doctor Salaries

**Business Use:** Understand what percentage of doctors earn at or below a given salary. Supports fair compensation benchmarking across the hospital.

```sql
SELECT d.full_name AS doctor_name, d.specialty, d.salary,
       ROUND(CUME_DIST() OVER (ORDER BY d.salary) * 100, 2) AS cumulative_pct
FROM doctors d ORDER BY d.salary;
```

![CUME_DIST Result](screenshots/wf12_cume_dist.png)

---

## 📈 Analysis and Findings

### Descriptive Analysis — What Happened?

- The hospital recorded **25 appointments** across 5 departments between January and July 2024.
- Total completed revenue was **$55,950**, with an average appointment cost of **$2,797**.
- **General Surgery** generated the highest department revenue, driven by high-cost surgical procedures (appendectomy, hernia repair, gallbladder surgery).
- **8 appointments** exceeded the average treatment cost — primarily surgical procedures.
- **15 patients** were treated; **5 of them** visited more than one department, representing multi-specialty care cases.

### Diagnostic Analysis — Why Did It Happen?

- General Surgery and Orthopedics dominate revenue because surgical procedures are inherently more resource-intensive and costly than consultations.
- Pediatric appointments generate lower revenue per visit because childhood conditions (vaccination, fever, asthma) require less expensive treatments.
- The 5 multi-department patients have complex chronic or post-operative conditions requiring follow-up across specialties — explaining their higher lifetime spend.
- Dr. Irene Mukamana (Pediatrics, 13 years experience) earns the highest salary in that department but handles lower-revenue cases, creating a salary–revenue mismatch that management should evaluate.

### Prescriptive Analysis — What Actions Should Be Taken?

1. **Revenue Optimization:** Invest in expanding General Surgery capacity (more operating rooms, surgical staff) as it consistently generates the highest ROI per appointment.
2. **Cost Control:** Flag the 8 high-cost appointments from CTE 1 for quarterly insurance audit reviews to prevent unnecessary over-treatment.
3. **Patient Care Coordination:** Assign dedicated case managers to the 5 multi-department patients identified in CTE 5 to ensure continuity of care and reduce redundant tests.
4. **Salary Equity Review:** Use PERCENT_RANK() findings to conduct a compensation review — some senior doctors in low-revenue specialties may be over-compensated relative to hospital revenue contribution.
5. **Capacity Planning:** The recursive CTE (CTE 3) shows all appointments cluster in January–July. The hospital should run promotional health screening campaigns in August–December to reduce the seasonal revenue gap.

---

## 📚 References

- Molinaro, A. (2009). *SQL Cookbook*. O'Reilly Media.
- Date, C. J. (2011). *SQL and Relational Theory*. O'Reilly Media.
- PostgreSQL Documentation — [Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- PostgreSQL Documentation — [WITH Queries (CTEs)](https://www.postgresql.org/docs/current/queries-with.html)
- DuckDB Documentation — [SQL Reference](https://duckdb.org/docs/sql/query_syntax/with)
- UNILAK Course Notes: C11665 - DPR400210 Database Programming, Eric Maniraguha (2026)

---

## ✅ Academic Integrity Statement

I, Mohamed (Student ID: 249mohamed), hereby declare that this assignment is entirely my own original work. All SQL queries, the database schema, the business scenario, and the analysis presented in this repository were designed and written by me for the purpose of this course assignment.

No portion of this work has been copied from classmates, online repositories, or any other external source without proper attribution. I understand that academic misconduct — including plagiarism and unauthorized collaboration — is treated seriously by UNILAK and may result in disciplinary action.

I have read, understood, and complied with UNILAK's Academic Integrity Policy.

> *"Whoever is faithful in very little is also faithful in much." — Luke 16:10*

---

*Submitted to: University of Lay Adventists of Kigali (UNILAK)*  
*Course: C11665 - DPR400210: Database Programming*  
*Instructor: Eric Maniraguha*  
*Date: June 29, 2026*
