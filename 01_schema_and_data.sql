-- ============================================================
-- Hospital Management System - Database Schema & Sample Data
-- Course: C11665 - DPR400210: Database Programming
-- Student: 249mohamed
-- ============================================================

-- ──────────────────────────────────────────────
-- TABLE: departments
-- ──────────────────────────────────────────────
CREATE TABLE departments (
    department_id   INTEGER PRIMARY KEY,
    dept_name       VARCHAR(100) NOT NULL,
    location        VARCHAR(100),
    budget          DECIMAL(12,2)
);

-- ──────────────────────────────────────────────
-- TABLE: doctors
-- ──────────────────────────────────────────────
CREATE TABLE doctors (
    doctor_id       INTEGER PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    specialty       VARCHAR(100),
    department_id   INTEGER REFERENCES departments(department_id),
    hire_date       DATE,
    salary          DECIMAL(10,2),
    years_experience INTEGER
);

-- ──────────────────────────────────────────────
-- TABLE: patients
-- ──────────────────────────────────────────────
CREATE TABLE patients (
    patient_id      INTEGER PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE,
    gender          VARCHAR(10),
    phone           VARCHAR(20),
    city            VARCHAR(80)
);

-- ──────────────────────────────────────────────
-- TABLE: appointments
-- ──────────────────────────────────────────────
CREATE TABLE appointments (
    appointment_id  INTEGER PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(patient_id),
    doctor_id       INTEGER REFERENCES doctors(doctor_id),
    appointment_date DATE,
    diagnosis       VARCHAR(200),
    treatment_cost  DECIMAL(10,2),
    status          VARCHAR(30)   -- 'Completed','Pending','Cancelled'
);

-- ──────────────────────────────────────────────
-- SAMPLE DATA: departments
-- ──────────────────────────────────────────────
INSERT INTO departments VALUES
(1, 'Cardiology',     'Block A', 500000.00),
(2, 'Neurology',      'Block B', 450000.00),
(3, 'Orthopedics',    'Block C', 380000.00),
(4, 'Pediatrics',     'Block D', 320000.00),
(5, 'General Surgery','Block E', 600000.00);

-- ──────────────────────────────────────────────
-- SAMPLE DATA: doctors
-- ──────────────────────────────────────────────
INSERT INTO doctors VALUES
(1,  'Dr. Alice Mutoni',    'Cardiologist',      1, '2015-03-10', 95000.00, 12),
(2,  'Dr. Bob Nkurunziza',  'Neurologist',       2, '2018-07-22', 88000.00, 8),
(3,  'Dr. Claire Uwase',    'Orthopedic Surgeon',3, '2016-01-15', 91000.00, 10),
(4,  'Dr. David Habimana',  'Pediatrician',      4, '2020-09-01', 78000.00, 5),
(5,  'Dr. Emma Ingabire',   'General Surgeon',   5, '2013-11-20', 105000.00,14),
(6,  'Dr. Frank Bizimana',  'Cardiologist',      1, '2019-04-05', 89000.00, 7),
(7,  'Dr. Grace Umutoni',   'Neurologist',       2, '2017-06-30', 92000.00, 9),
(8,  'Dr. Henry Nshimiyimana','Orthopedic Surgeon',3,'2021-02-14',76000.00, 4),
(9,  'Dr. Irene Mukamana',  'Pediatrician',      4, '2014-08-19', 98000.00, 13),
(10, 'Dr. James Rwigamba',  'General Surgeon',   5, '2022-03-01', 72000.00, 3);

-- ──────────────────────────────────────────────
-- SAMPLE DATA: patients
-- ──────────────────────────────────────────────
INSERT INTO patients VALUES
(1,  'Jean Mugisha',      '1980-05-14', 'Male',   '+250781001001', 'Kigali'),
(2,  'Marie Uwimana',     '1995-11-23', 'Female', '+250781001002', 'Butare'),
(3,  'Paul Nkusi',        '1972-03-08', 'Male',   '+250781001003', 'Musanze'),
(4,  'Alice Kamanzi',     '2010-07-19', 'Female', '+250781001004', 'Kigali'),
(5,  'Robert Tuyishime',  '1965-09-30', 'Male',   '+250781001005', 'Gisenyi'),
(6,  'Sophie Ndayisaba',  '1990-12-01', 'Female', '+250781001006', 'Kigali'),
(7,  'Eric Hakizimana',   '1988-04-25', 'Male',   '+250781001007', 'Rwamagana'),
(8,  'Diane Umubyeyi',    '2001-08-11', 'Female', '+250781001008', 'Kigali'),
(9,  'Claude Nsabimana',  '1975-02-17', 'Male',   '+250781001009', 'Nyagatare'),
(10, 'Yvonne Murebwayire','1999-06-05', 'Female', '+250781001010', 'Kigali'),
(11, 'Patrick Ntibazilikana','1983-10-22','Male', '+250781001011', 'Huye'),
(12, 'Christine Mukeshimana','1970-01-30','Female','+250781001012','Kigali'),
(13, 'Samuel Gasana',     '1993-07-14', 'Male',   '+250781001013', 'Rubavu'),
(14, 'Anita Bazubagira',  '2005-03-28', 'Female', '+250781001014', 'Kigali'),
(15, 'Alexis Niyonzima',  '1960-11-09', 'Male',   '+250781001015', 'Gicumbi');

-- ──────────────────────────────────────────────
-- SAMPLE DATA: appointments
-- ──────────────────────────────────────────────
INSERT INTO appointments VALUES
(1,  1,  1, '2024-01-10', 'Hypertension',          1500.00, 'Completed'),
(2,  2,  2, '2024-01-15', 'Migraine',               1200.00, 'Completed'),
(3,  3,  3, '2024-01-20', 'Knee Replacement',       8500.00, 'Completed'),
(4,  4,  4, '2024-02-05', 'Childhood Asthma',        900.00, 'Completed'),
(5,  5,  5, '2024-02-10', 'Appendectomy',           6000.00, 'Completed'),
(6,  6,  1, '2024-02-14', 'Arrhythmia',             2200.00, 'Completed'),
(7,  7,  6, '2024-02-20', 'Heart Failure',          3100.00, 'Completed'),
(8,  8,  7, '2024-03-01', 'Epilepsy',               1800.00, 'Completed'),
(9,  9,  3, '2024-03-08', 'Fracture - Femur',       4200.00, 'Completed'),
(10, 10, 4, '2024-03-12', 'Chickenpox',              750.00, 'Completed'),
(11, 11, 5, '2024-03-19', 'Hernia Repair',          5500.00, 'Completed'),
(12, 12, 1, '2024-04-02', 'Coronary Artery Disease',3800.00, 'Completed'),
(13, 13, 8, '2024-04-10', 'Spinal Disc Problem',    3300.00, 'Completed'),
(14, 14, 9, '2024-04-18', 'Pediatric Fever',         500.00, 'Completed'),
(15, 15, 2, '2024-04-25', 'Parkinson Disease',      2900.00, 'Completed'),
(16, 1,  6, '2024-05-03', 'Follow-up Cardiology',   1100.00, 'Completed'),
(17, 2,  7, '2024-05-11', 'Follow-up Neurology',    1000.00, 'Completed'),
(18, 3,  5, '2024-05-20', 'Post-op Review',         1400.00, 'Completed'),
(19, 4,  9, '2024-06-01', 'Vaccination',             300.00, 'Completed'),
(20, 5,  10,'2024-06-08', 'Wound Care',              600.00, 'Completed'),
(21, 6,  1, '2024-06-15', 'Stress Test',            1700.00, 'Pending'),
(22, 7,  2, '2024-06-20', 'MRI Consultation',       2500.00, 'Pending'),
(23, 8,  3, '2024-06-25', 'Bone Density Scan',      1300.00, 'Pending'),
(24, 9,  4, '2024-07-01', 'Growth Assessment',       450.00, 'Cancelled'),
(25, 10, 5, '2024-07-05', 'Gallbladder Surgery',    7200.00, 'Pending');
