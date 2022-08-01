--please follow  below link for downloading the covid dataset
--https://ourworldindata.org/covid-deaths
--two tables: coviddeaths and covidvaccinations are created from the original dataset. 

--let's walk through CovidDeaths table---------
--wherever continent is null, the location is continent. Hence we are choosing the locations where continent is not null.

select location, date,total_cases,new_cases,total_deaths,population
from covid_project.dbo.CovidDeaths$
order by 1,2

--death % based on total cases

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from covid_project.dbo.CovidDeaths$
where continent is not null
order by 1,2

--% infected people based on population

select location,date,population,total_Cases,(total_cases/population)*100 as PercentPopulationInfected
from covid_project.dbo.CovidDeaths$
where continent is not null
order by 1,2

---highest infection count for the countries based on population

select location,population,MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from covid_project.dbo.CovidDeaths$
where continent is not null
group by location,population
order by 4 desc

--highest death count for locations based on population
select location,MAX(cast(total_deaths as int)) as HighestDeathCount
from covid_project.dbo.CovidDeaths$
where continent is not null
group by location
order by 2 desc

--highest death count for continents based on population
--to get the result for continents, use locations field, where continent field is null.
select location,MAX(cast(total_deaths as int)) as HighestDeathCount
from covid_project.dbo.CovidDeaths$
where continent is null
group by location
order by 2 desc


---global number for each date

--overall total new cases,new deaths and death % 
select SUM(new_cases) as TotalNewCases,SUM(cast(new_deaths as int)) as TotalNewDeaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as TotalDeathPercentage
from covid_project.dbo.CovidDeaths$
where continent is not null


--total new cases,new deaths and death % for dates
select date,SUM(new_cases) as TotalNewCases,SUM(cast(new_deaths as int)) as TotalNewDeaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as TotalDeathPercentage
from covid_project.dbo.CovidDeaths$
where continent is not null
group by date
order by 1


---lets walk through CovidVaccinations table
select *
from covid_project.dbo.CovidVaccinations


---join two tables through date and location fields
--total population vs vaccinations
--get sum of new vaccinations till that date for location

select de.continent,de.location,de.date,de.population,vc.new_vaccinations,
sum(cast(vc.new_Vaccinations as bigint)) over (partition by de.location order by de.location,de.date) as PeopleVaccinatedTillDate 
from covid_project.dbo.CovidDeaths$ as de
join covid_project.dbo.CovidVaccinations as vc
on de.location=vc.location
and de.date=vc.date
where de.continent is not null
order by 2,3

--we cannot use newly created fields such as PeopleVaccinatedTillDate to create another field from it.
--Hence we need temp tables or cte

--create CTE 
with cte1 (continent,location,date,population,new_Vaccinations,PeopleVaccinatedTillDate)
as 
(
select de.continent,de.location,de.date,de.population,vc.new_vaccinations,
sum(cast(vc.new_Vaccinations as bigint)) over (partition by de.location order by de.location,de.date) as PeopleVaccinatedTillDate
from covid_project.dbo.CovidDeaths$ as de
join covid_project.dbo.CovidVaccinations as vc
on de.location=vc.location
and de.date=vc.date
where de.continent is not null
)

--get % people vaccinated till date from given population

select *,(PeopleVaccinatedTillDate/population)*100 as PercentPeopleVaccinated
from cte1

---lets do similar using temp table
drop table if exists #temp
create table #temp
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
PeopleVaccinatedTillDate numeric
)

insert into #temp 
select de.continent,de.location,de.date,de.population,vc.new_vaccinations,
sum(cast(vc.new_Vaccinations as bigint)) over (partition by de.location order by de.location,de.date) as PeopleVaccinatedTillDate
from covid_project.dbo.CovidDeaths$ as de
join covid_project.dbo.CovidVaccinations as vc
on de.location=vc.location
and de.date=vc.date
where de.continent is not null

select *,(PeopleVaccinatedTillDate/population)*100 as PercentPeopleVaccinated
from #temp

---create final view to store data for later visualisation
create view FinalView
as
select de.continent,de.location,de.date,de.population,vc.new_vaccinations,
sum(cast(vc.new_Vaccinations as bigint)) over (partition by de.location order by de.location,de.date) as PeopleVaccinatedTillDate
from covid_project.dbo.CovidDeaths$ as de
join covid_project.dbo.CovidVaccinations as vc
on de.location=vc.location
and de.date=vc.date
where de.continent is not null

select *
from FinalView

