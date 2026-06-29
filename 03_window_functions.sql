-- ============================================================
-- Part B: SQL Window Functions
-- Hospital Management System
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- SECTION 1: RANKING FUNCTIONS
-- ────────────────────────────────────────────────────────────

-- 1a. ROW_NUMBER() — Unique sequential rank per doctor by revenue
-- Business Use: Generate unique IDs for ordered reporting lists.
SELECT
    d.full_name                                     AS doctor_name,
    d.specialty,
    dept.dept_name,
    SUM(a.treatment_cost)                           AS total_revenue,
    ROW_NUMBER() OVER (
        ORDER BY SUM(a.treatment_cost) DESC
    )                                               AS row_num
FROM doctors d
JOIN departments dept  ON dept.department_id = d.department_id
JOIN appointments a    ON a.doctor_id        = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty, dept.dept_name
ORDER BY total_revenue DESC;


-- 1b. RANK() — Rank with gaps for tied values
-- Business Use: Fair leaderboard that skips positions after ties.
SELECT
    d.full_name                                     AS doctor_name,
    d.specialty,
    SUM(a.treatment_cost)                           AS total_revenue,
    RANK() OVER (
        ORDER BY SUM(a.treatment_cost) DESC
    )                                               AS revenue_rank
FROM doctors d
JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty
ORDER BY revenue_rank;


-- 1c. DENSE_RANK() — Rank without gaps for tied values
-- Business Use: Tiered performance bands (Gold/Silver/Bronze).
SELECT
    d.full_name                                     AS doctor_name,
    d.specialty,
    SUM(a.treatment_cost)                           AS total_revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(a.treatment_cost) DESC
    )                                               AS dense_rev_rank,
    CASE
        WHEN DENSE_RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC) = 1 THEN 'Gold'
        WHEN DENSE_RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC) = 2 THEN 'Silver'
        WHEN DENSE_RANK() OVER (ORDER BY SUM(a.treatment_cost) DESC) = 3 THEN 'Bronze'
        ELSE 'Standard'
    END                                             AS performance_tier
FROM doctors d
JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.full_name, d.specialty
ORDER BY dense_rev_rank;


-- 1d. PERCENT_RANK() — Percentile position within department
-- Business Use: Understand relative standing (top 10%? bottom 20%?).
SELECT
    d.full_name                                       AS doctor_name,
    dept.dept_name,
    d.salary,
    ROUND(
        PERCENT_RANK() OVER (
            PARTITION BY d.department_id
            ORDER BY d.salary
        )::DECIMAL * 100, 2
    )                                                 AS salary_percentile_in_dept
FROM doctors d
JOIN departments dept ON dept.department_id = d.department_id
ORDER BY dept.dept_name, d.salary;


-- ────────────────────────────────────────────────────────────
-- SECTION 2: AGGREGATE WINDOW FUNCTIONS
-- ────────────────────────────────────────────────────────────

-- 2a. SUM() OVER() — Running total of revenue by date
-- Business Use: Track cumulative earnings growth over the year.
SELECT
    appointment_date,
    treatment_cost,
    SUM(treatment_cost) OVER (
        ORDER BY appointment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                AS running_total_revenue
FROM appointments
WHERE status = 'Completed'
ORDER BY appointment_date;


-- 2b. AVG() OVER() — Department average salary alongside each doctor
-- Business Use: Instantly compare each doctor's pay to dept average.
SELECT
    d.full_name                                      AS doctor_name,
    dept.dept_name,
    d.salary,
    ROUND(AVG(d.salary) OVER (
        PARTITION BY d.department_id
    ), 2)                                            AS dept_avg_salary,
    ROUND(d.salary - AVG(d.salary) OVER (
        PARTITION BY d.department_id
    ), 2)                                            AS diff_from_dept_avg
FROM doctors d
JOIN departments dept ON dept.department_id = d.department_id
ORDER BY dept.dept_name, d.salary DESC;


-- 2c. MIN() OVER() — Cheapest treatment in same specialty
-- Business Use: Benchmark minimum cost per specialty for pricing.
SELECT
    a.appointment_id,
    d.specialty,
    a.diagnosis,
    a.treatment_cost,
    MIN(a.treatment_cost) OVER (
        PARTITION BY d.specialty
    )                                                AS min_cost_in_specialty
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
ORDER BY d.specialty, a.treatment_cost;


-- 2d. MAX() OVER() — Most expensive treatment per department
-- Business Use: Flag departments with extreme cost outliers.
SELECT
    a.appointment_id,
    dept.dept_name,
    a.diagnosis,
    a.treatment_cost,
    MAX(a.treatment_cost) OVER (
        PARTITION BY dept.department_id
    )                                                AS max_cost_in_dept
FROM appointments a
JOIN doctors     d    ON d.doctor_id     = a.doctor_id
JOIN departments dept ON dept.department_id = d.department_id
WHERE a.status = 'Completed'
ORDER BY dept.dept_name, a.treatment_cost DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 3: NAVIGATION FUNCTIONS
-- ────────────────────────────────────────────────────────────

-- 3a. LAG() — Compare each appointment's cost to previous one (same patient)
-- Business Use: Detect if a returning patient's cost increased or decreased.
SELECT
    p.full_name                                         AS patient_name,
    a.appointment_date,
    a.diagnosis,
    a.treatment_cost,
    LAG(a.treatment_cost) OVER (
        PARTITION BY a.patient_id
        ORDER BY a.appointment_date
    )                                                   AS prev_visit_cost,
    ROUND(
        a.treatment_cost - COALESCE(
            LAG(a.treatment_cost) OVER (
                PARTITION BY a.patient_id
                ORDER BY a.appointment_date
            ), 0
        ), 2
    )                                                   AS cost_change
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
ORDER BY a.patient_id, a.appointment_date;


-- 3b. LEAD() — Look at the next appointment cost for the same patient
-- Business Use: Forecast upcoming treatment costs for budget planning.
SELECT
    p.full_name                                         AS patient_name,
    a.appointment_date,
    a.diagnosis,
    a.treatment_cost,
    LEAD(a.treatment_cost) OVER (
        PARTITION BY a.patient_id
        ORDER BY a.appointment_date
    )                                                   AS next_visit_cost,
    LEAD(a.appointment_date) OVER (
        PARTITION BY a.patient_id
        ORDER BY a.appointment_date
    )                                                   AS next_visit_date
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
ORDER BY a.patient_id, a.appointment_date;


-- ────────────────────────────────────────────────────────────
-- SECTION 4: DISTRIBUTION FUNCTIONS
-- ────────────────────────────────────────────────────────────

-- 4a. NTILE(4) — Divide patients into cost quartiles
-- Business Use: Segment patients into cost tiers for insurance pricing.
SELECT
    p.full_name                                         AS patient_name,
    SUM(a.treatment_cost)                               AS total_spend,
    NTILE(4) OVER (
        ORDER BY SUM(a.treatment_cost) DESC
    )                                                   AS cost_quartile,
    CASE NTILE(4) OVER (ORDER BY SUM(a.treatment_cost) DESC)
        WHEN 1 THEN 'Platinum (Highest Cost)'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze (Lowest Cost)'
    END                                                 AS cost_tier
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
GROUP BY a.patient_id, p.full_name
ORDER BY cost_quartile, total_spend DESC;


-- 4b. CUME_DIST() — Cumulative distribution of doctor salaries
-- Business Use: Understand what fraction of doctors earn at or below
-- a given salary level to support HR compensation benchmarking.
SELECT
    d.full_name                                         AS doctor_name,
    d.specialty,
    d.salary,
    ROUND(
        CUME_DIST() OVER (
            ORDER BY d.salary
        )::DECIMAL * 100, 2
    )                                                   AS cumulative_pct
FROM doctors d
ORDER BY d.salary;
