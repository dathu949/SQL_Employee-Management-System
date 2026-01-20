-- create database
create database Employee;
-- use db
use Employee;
-- create tables
-- create table1 job department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);

-- create table 2 salary bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
	ON DELETE CASCADE ON UPDATE CASCADE
);

-- create table 3 Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
	FOREIGN KEY (Job_ID) REFERENCES JobDepartment(Job_ID)
	ON DELETE SET NULL ON UPDATE CASCADE
    );	
    
-- create table 4 Qualification
CREATE TABLE Qualification (
QualID INT PRIMARY KEY,
Emp_ID INT,
Position VARCHAR(50),
Requirements VARCHAR(255),
Date_In DATE,
FOREIGN KEY (Emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);

-- create table 5 Leaves
CREATE TABLE Leaves (
leave_ID INT PRIMARY KEY,
emp_ID INT,
date DATE,
reason TEXT,
FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);

-- create table 6 Payroll
CREATE TABLE Payroll (
payroll_ID INT PRIMARY KEY,
emp_ID INT,
job_ID INT,
salary_ID INT,
leave_ID INT,
date DATE,
report TEXT,
total_amount DECIMAL(10,2),
FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
ON DELETE SET NULL ON UPDATE CASCADE
);
-- check the data for all the tables
select * from salarybonus;

-- Analysis Questions
-- 1. EMPLOYEE INSIGHTS

-- A. How many unique employees are currently in the system?
select count(distinct emp_ID) as unique_emp from Employee;

-- B. Which departments have the highest number of employees?
select j.jobdept,count(e.emp_ID) as highest_number_emp from employee e
join JobDepartment j
on e.job_ID = j.job_ID
group by j.jobdept
order by highest_number_emp desc;

-- using rank function
select * from(select j.jobdept, count(emp_ID) as emp_count, dense_rank() over(order by count(emp_ID) desc) as dep_rank
 from employee e
join JobDepartment j
on e.job_ID = j.job_ID
group by j.jobdept) as s
where dep_rank = 1;

-- c. What is the average salary per department?
select j.jobdept, avg(amount) as avg_salary from salarybonus s 
join jobdepartment j 
on s.job_ID = j.job_ID
group by j.jobdept;

-- D. Who are the top 5 highest-paid employees?
select concat(firstname,lastname) as emp_name,s.amount from employee e 
join salarybonus s 
on e.job_ID = s.job_ID
group by s.amount, emp_name
order by amount desc limit 5 offset 0;

-- using rank function
select * from(select concat(firstname,lastname) as emp_name,s.amount,dense_rank() over(order by s.amount desc) as 
high_paid  from employee e 
join salarybonus s 
on e.job_ID = s.job_ID) as t
where high_paid <= 5;

-- E. What is the total salary expenditure across the company?
-- including bonus
select sum(amount + bonus) as total_expenditure from salarybonus;
-- without bonus
select sum(amount) as total_expenditure from salarybonus;

-- 2. JOB ROLE AND DEPARTMENT ANALYSIS

-- A. How many different job roles exist in each department?
select * from jobdepartment;
select jobdept,count(name) as count_job_roles from jobdepartment
group by jobdept;

-- B. What is the average salary range per department?
select j.jobdept,concat(min(s.amount),'-',max(s.amount)) as salary_range,avg(amount) as avg_salary 
from salarybonus s
join jobdepartment j
on s.Job_ID = j.Job_ID
group by j.jobdept;

-- C. Which job roles offer the highest salary? 
select j.name, max(s.amount) as sum_salary from jobdepartment j 
join salarybonus s 
on j.job_ID = s.job_ID
group by j.name
order by sum_salary desc; 
-- C. Which job roles offer the highest salary? 
-- using rank function

select * from(select job_role, high_salary, dense_rank() over(order by high_salary desc) 
as role_max_salary from 
 (select j.name as job_role, max(amount) as high_salary from jobdepartment j 
 join salarybonus s 
 on j.job_ID = s.job_ID
 group by j.name) as s) as s1
 where role_max_salary = 1;

-- D. Which departments have the highest total salary allocation?
select j.jobdept, sum(s.amount + s.bonus) as total_salary from salarybonus s
join jobdepartment j 
on s.Job_ID = j.Job_ID
group by j.jobdept
order by total_salary desc;
-- D. Which departments have the highest total salary allocation?
-- using Rank function
select * from(select j.jobdept,sum(s.amount + s.bonus) as total, dense_rank() over(order by sum(s.amount + s.bonus) desc) 
as total_salary from salarybonus s
join jobdepartment j 
on s.Job_ID = j.Job_ID
group by j.jobdept) as t
where total_salary = 1;

-- 3. QUALIFICATION AND SKILLS ANALYSIS

-- A. How many employees have at least one qualification listed?
select * from qualification where QualID is not null;
select count(emp_id) as emp_count from qualification where QualID is not null;

-- B. Which positions require the most qualifications?
select position,count(requirements) as most_qualification from qualification 
group by position 
order by most_qualification desc;

-- C. Which employees have the highest number of qualifications?
select concat(firstname, ' ',lastname) as emp_name,count(requirements) as no_of_qualifications from employee e 
join qualification q 
on e.emp_ID = q.emp_ID
group by emp_name;

-- 4. LEAVE AND ABSENCE PATTERNS

-- A. Which year had the most employees taking leaves?
select * from leaves;
select year(date), count(*) as leave_count from leaves
group by year(date)
order by leave_count desc;

-- B. What is the average number of leave days taken by its employees per department?
select jobdept,avg(leave_days) as avg_leave_days from(select e.emp_ID,jobdept, extract(day from date) as leave_days 
from employee e 
left join leaves l 
on l.emp_ID = e.emp_ID
join jobdepartment j
on e.job_ID = j.job_ID
group by jobdept, emp_ID,leave_days) as s
group by jobdept;

-- C. Which employees have taken the most leaves?
select sum(extract(day from date)) as leaves_count, concat(firstname,lastname) as emp_name,e.emp_ID from employee e 
join leaves l 
on e.emp_ID = l.emp_ID
group by emp_name,e.emp_ID
order by leaves_count desc;

-- D. What is the total number of leave days taken company-wide?
-- department wide
select jobdept, sum(extract(day from l.date)) as leave_days from leaves l 
join employee e 
on l.emp_ID = e.emp_ID
join jobdepartment j
on e.job_ID = j.job_ID
group by jobdept
order by leave_days desc;
----- 
-- company wide
select sum(extract(day from date)) as total_leave_days from leaves;

-- E. How do leave days correlate with payroll amounts?

select p.emp_ID,extract(day from l.date) as leave_day,p.date as pay_roll_date, p.total_amount from leaves l 
join payroll p on l.leave_ID = p.leave_ID;

-- 5. PAYROLL AND COMPENSATION ANALYSIS

-- A. What is the total monthly payroll processed?
select * from payroll;
select sum(total_Amount) as total_montly_payroll from payroll;

-- B. What is the average bonus given per department?
select avg(bonus) as avg_bonus_department, jobdept from salarybonus s 
join jobdepartment j 
on s.Job_ID = j.Job_ID
group by jobdept
order by avg_bonus_department desc;

-- C. Which department receives the highest total bonuses?
select sum(bonus) as sum_bonus_department, jobdept from salarybonus s 
join jobdepartment j 
on s.Job_ID = j.Job_ID
group by jobdept
order by sum_bonus_department desc limit 1 offset 0;

-- D. What is the average value of total_amount after considering leave deductions? 
select avg(total_amount) as avg_amount from payroll;

