--Data Exploration: MonkeyPox Analysis

--Skills displayed: 
--Case Statements, Grouping Functions, Correlated Subqueries, Multiple Table Queries and Joins, Analytical Functions,
--Common Table Expression, Creating Tables

--Datasets:
Select Country, Confirmed_Cases, Suspected_Cases, Hospitalized
from [MonkeyPox Analysis]..[Total Cases by Country]

Select Date_confirmation, Country, City, Age, Gender, Symptoms, [Travel_history (Y/N/NA)] 
from [MonkeyPox Analysis]..[Cases Detection Timeline]

--Total Percentage of Patients that were Hospitalized by Country
Select Country, Confirmed_Cases, Hospitalized, 
Case
	When Confirmed_Cases = 0
	Then Null
	Else (Hospitalized/Confirmed_Cases)*100
End as Percentage_Hospitalized
From [MonkeyPox Analysis]..[Total Cases by Country]
order by Percentage_Hospitalized desc

--Percentage of Patients Hospitalized in the United States
Select Country, Confirmed_Cases, Hospitalized, (Hospitalized/Confirmed_Cases)*100 as Percentage_Hospitalized
from [MonkeyPox Analysis]..[Total Cases by Country]
where Country = 'United States'

--Looking at the top ten countries with highest number of total cases
Select Country, sum(Confirmed_Cases+Suspected_Cases) as 'Total Cases'
from [Total Cases by Country]
group by country
order by [Total Cases] desc
offset 0 rows
fetch next 10 rows only

--Number of confirmed cases by City
Select c.city, count(t.Confirmed_Cases) as 'Confirmed Cases by City'
from [Total Cases by Country] t
join [Cases Detection Timeline] c
on t.country = c.country
where city is not null
group by city, Confirmed_Cases
order by 1, 2

--Number of unique symptoms reported
select s.symptoms, c.cnt as 'Count of Symptoms reported'
from [Cases Detection Timeline] s
inner join
(select Symptoms, count(Symptoms) as cnt from [Cases Detection Timeline]
group by Symptoms) c 
on s.symptoms = c.symptoms where s.symptoms is not null
group by s.Symptoms, c.cnt
order by 2 desc

--How many patients had traveled?
select t.country, t.Confirmed_Cases, count(c.[Travel_history (Y/N/NA)])as 'Patients who traveled', 
(count(c.[Travel_history (Y/N/NA)])/t.Confirmed_Cases)*100 as 'Percentage Infected'
from [Total Cases by Country] t
join [Cases Detection Timeline] c
on t.country=c.country
where [Travel_history (Y/N/NA)] = 'Y'
group by t.country, t.Confirmed_Cases
order by 3 desc

--Gender and age of Patients
select country, count(gender) as 'Male Patients'
from [Cases Detection Timeline] a
where gender = 'male'
group by country

select country, count(gender) as 'Female Patients'
from [Cases Detection Timeline]
where gender = 'female'
group by country

select age, count(age) as 'Confirmed cases by age'
from [Cases Detection Timeline]
where age is not null
group by age
order by 1

--Cases by City in the United States Rollup 
select c.date_confirmation, c.city, count(t.Confirmed_Cases) as 'Number of cases Reported', 
sum(count(t.confirmed_cases)) over (partition by c.city order by c.city, c.date_confirmation) as 'Cases by City Rollup'
from [Cases Detection Timeline] c
join 
[Total Cases by Country] t
on c.country=t.country
where c.country = 'United States'
and city is not null
group by c.Date_confirmation,c.City, t.Confirmed_Cases
order by 2, 1

--CTE (Percentage of Cases in City compared to Total Cases in the U.S)
With CasesbyCity(date_confirmation, city, confirmed_cases, [Cases by City Rollup])
as
(
select c.date_confirmation, c.city, count(t.Confirmed_Cases), 
sum(count(t.confirmed_cases)) over (partition by c.city order by c.city, c.date_confirmation) as 'Cases by City Rollup'
from [Cases Detection Timeline] c
join 
[Total Cases by Country] t
on c.country=t.country
where c.country = 'United States'
and city is not null
group by c.Date_confirmation,c.City, t.Confirmed_Cases
)
select *, ([Cases by City Rollup]/ (select Confirmed_Cases from [Total Cases by Country]
where country = 'United States'))*100 as 'Case Percentage by city'
from CasesbyCity

--Creating a Table for future reference
Create Table #Cases_by_city
(
Date_confirmation datetime,
City nvarchar(255),
Cases_Reported numeric,
Cases_by_City_Rollup numeric
)
Insert into #Cases_by_city
select c.date_confirmation, c.city, count(t.Confirmed_Cases), 
sum(count(t.confirmed_cases)) over (partition by c.city order by c.city, c.date_confirmation) as 'Cases by City Rollup'
from [Cases Detection Timeline] c
join 
[Total Cases by Country] t
on c.country=t.country
where c.country = 'United States'
and city is not null
group by c.Date_confirmation,c.City, t.Confirmed_Cases
order by 2, 1



