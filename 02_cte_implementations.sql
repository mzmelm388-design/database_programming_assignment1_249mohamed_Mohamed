-- ============================================================
-- Part A: Common Table Expressions (CTEs)
-- Hospital Management System
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- CTE 1: SIMPLE CTE
-- Business Purpose: Identify high-cost treatments (above average)
-- to flag them for insurance review and cost management.
-- ────────────────────────────────────────────────────────────
WITH high_cost_appointments AS (
    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        appointment_date,
        diagnosis,
        treatment_cost
    FROM appointments
    WHERE treatment_cost > (SELECT AVG(treatment_cost) FROM appointments)
      AND status = 'Completed'
)
SELECT
    h.appointment_id,
    p.full_name        AS patient_name,
    d.full_name        AS doctor_name,
    h.diagnosis,
    h.treatment_cost,
    h.appointment_date
FROM high_cost_appointments h
JOIN patients p ON p.patient_id = h.patient_id
JOIN doctors  d ON d.doctor_id  = h.doctor_id
ORDER BY h.treatment_cost DESC;


-- ────────────────────────────────────────────────────────────
-- CTE 2: MULTIPLE CTEs
-- Business Purpose: Compare each department's revenue against
-- hospital-wide average to identify top-performing units.
-- ────────────────────────────────────────────────────────────
WITH dept_revenue AS (
    -- Step 1: Total completed revenue per department
    SELECT
        dept.department_id,
        dept.dept_name,
        SUM(a.treatment_cost) AS total_revenue,
        COUNT(a.appointment_id) AS total_appointments
    FROM departments dept
    JOIN doctors     doc ON doc.department_id  = dept.department_id
    JOIN appointments a  ON a.doctor_id        = doc.doctor_id
    WHERE a.status = 'Completed'
    GROUP BY dept.department_id, dept.dept_name
),
hospital_avg AS (
    -- Step 2: Hospital-wide average revenue across departments
    SELECT AVG(total_revenue) AS avg_revenue
    FROM dept_revenue
)
SELECT
    dr.dept_name,
    dr.total_revenue,
    dr.total_appointments,
    ROUND(ha.avg_revenue, 2)                                      AS hospital_avg_revenue,
    ROUND(dr.total_revenue - ha.avg_revenue, 2)                   AS variance_from_avg,
    CASE
        WHEN dr.total_revenue >= ha.avg_revenue THEN 'Above Average'
        ELSE 'Below Average'
    END                                                            AS performance_status
FROM dept_revenue    dr
CROSS JOIN hospital_avg ha
ORDER BY dr.total_revenue DESC;


-- ────────────────────────────────────────────────────────────
-- CTE 3: RECURSIVE CTE
-- Business Purpose: Generate a series of months for a full-year
-- appointment calendar to detect months with no activity.
-- ────────────────────────────────────────────────────────────
WITH RECURSIVE month_series AS (
    -- Anchor: Start from January 2024
    SELECT
        1                           AS month_num,
        DATE '2024-01-01'           AS month_start
    UNION ALL
    -- Recursive: Add one month at a time up to December
    SELECT
        month_num + 1,
        month_start + INTERVAL '1 month'
    FROM month_series
    WHERE month_num < 12
),
monthly_appointments AS (
    SELECT
        EXTRACT(MONTH FROM appointment_date)::INTEGER AS month_num,
        COUNT(*)                                       AS appt_count,
        SUM(treatment_cost)                            AS monthly_revenue
    FROM appointments
    WHERE EXTRACT(YEAR FROM appointment_date) = 2024
    GROUP BY EXTRACT(MONTH FROM appointment_date)
)
SELECT
    ms.month_num,
    TO_CHAR(ms.month_start, 'Month YYYY')     AS month_label,
    COALESCE(ma.appt_count,    0)              AS appointments,
    COALESCE(ma.monthly_revenue, 0.00)         AS revenue
FROM month_series       ms
LEFT JOIN monthly_appointments ma ON ma.month_num = ms.month_num
ORDER BY ms.month_num;


-- ────────────────────────────────────────────────────────────
-- CTE 4: CTE WITH AGGREGATION
-- Business Purpose: Rank doctors by their total revenue
-- contribution so hospital management can reward top performers.
-- ────────────────────────────────────────────────────────────
WITH doctor_performance AS (
    SELECT
        d.doctor_id,
        d.full_name                        AS doctor_name,
        d.specialty,
        dept.dept_name,
        COUNT(a.appointment_id)            AS total_appointments,
        SUM(a.treatment_cost)              AS total_revenue,
        ROUND(AVG(a.treatment_cost), 2)    AS avg_treatment_cost,
        MIN(a.treatment_cost)              AS min_cost,
        MAX(a.treatment_cost)              AS max_cost
    FROM doctors d
    JOIN departments dept ON dept.department_id = d.department_id
    LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
                             AND a.status = 'Completed'
    GROUP BY d.doctor_id, d.full_name, d.specialty, dept.dept_name
)
SELECT
    doctor_name,
    specialty,
    dept_name,
    total_appointments,
    total_revenue,
    avg_treatment_cost,
    min_cost,
    max_cost
FROM doctor_performance
ORDER BY total_revenue DESC NULLS LAST;


-- ────────────────────────────────────────────────────────────
-- CTE 5: CTE COMBINED WITH JOIN OPERATIONS
-- Business Purpose: Identify patients who have visited multiple
-- departments — a key indicator of complex, multi-specialty care
-- needs requiring coordinated treatment plans.
-- ────────────────────────────────────────────────────────────
WITH patient_dept_visits AS (
    -- Count distinct departments each patient visited
    SELECT
        a.patient_id,
        COUNT(DISTINCT doc.department_id)   AS dept_count,
        COUNT(a.appointment_id)             AS total_visits,
        SUM(a.treatment_cost)               AS lifetime_spend
    FROM appointments a
    JOIN doctors doc ON doc.doctor_id = a.doctor_id
    GROUP BY a.patient_id
),
multi_dept_patients AS (
    -- Filter to those who visited 2+ departments
    SELECT *
    FROM patient_dept_visits
    WHERE dept_count >= 2
)
SELECT
    p.full_name          AS patient_name,
    p.gender,
    p.city,
    mdp.dept_count       AS departments_visited,
    mdp.total_visits,
    mdp.lifetime_spend
FROM multi_dept_patients mdp
JOIN patients p ON p.patient_id = mdp.patient_id
ORDER BY mdp.dept_count DESC, mdp.lifetime_spend DESC;
