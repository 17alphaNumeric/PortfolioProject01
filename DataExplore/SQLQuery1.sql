SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;


---Select *
---From PortfolioProject..CovidVac
---order by 3,4;

---Selected Data

Select Location,date,total_cases,new_cases,total_deaths,population
From PortfolioProject..CovidDeaths
order by 1,2



--Total Cases vs Total Deaths
--likelihood of covid in my country

Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%bangladesh%'
and continent IS NOT NULL
order by 1,2


--looking at total cases vs population
-- shows what percentage of population has gotten covid

SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%bangladesh%'
and continent IS NOT NULL

ORDER BY 1, 2;


--looking at countries highest infection rate
SELECT Location, Population,Max(total_deaths) As HighestInfectionCount, Max((total_deaths/population))* 100 AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%bangladesh%'
and continent IS NOT NULL
Group by location
ORDER BY DeathCount desc;


--Showing highest death

SELECT Location,Max(cast (total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%bangladesh





where continent IS NOT NULL
Group by location
ORDER BY TotalDeathCount desc;


--- Global Numbers

Select sum(new_cases) as total_cases,Sum(Cast(new_deaths as int)) as total_deaths,
Sum(Cast(new_deaths as int))/Sum(Cast(new_cases as int))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location life'%bangladesh%'
where continent is not null
--Group by date
order by 1,2


--7-Day Rolling Death Percentage

WITH DailyStats AS (
    SELECT 
        date,
        SUM(new_cases) AS total_cases,
        SUM(CAST(new_deaths AS FLOAT)) AS total_deaths
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
  AND NOT (
      new_cases IS NULL AND 
      new_deaths IS NULL AND 
      total_cases IS NULL AND 
      total_deaths IS NULL
  )
    GROUP BY date
)
SELECT 
    date,
    total_cases,
    total_deaths,
    (total_deaths / NULLIF(total_cases, 0)) * 100 AS DailyDeathPercentage,
    AVG((total_deaths / NULLIF(total_cases, 0)) * 100) OVER (
        ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS DeathPercentage_7DayAvg
FROM DailyStats
ORDER BY date;

-- Looking at total population vs vaccinations

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVac  vac
	On dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--To show how many people got vaccinated daily and over time in 
--each location (country or region), using COVID data from two tables

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVac vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3



--CTE(Common Table Expression) to perform calculation on Partition

--With VaccinationData As (

--select 
--	dea.continent,
--	dea.location,
--	dea.date,
--	dea.population,
--	vac.new_vaccinations,

--SUM(CONVERT(int,vac.new_vaccinations))
--		OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
----, (RollingPeopleVaccinated/population)*100
--From PortfolioProject..CovidDeaths dea
--Join PortfolioProject..CovidVac vac
--	On dea.location = vac.location
--	and dea.date = vac.date
--where dea.continent is not null
--)

--Select * From VaccinationData
--Order by 2,3




--CTE 

With Pvac ( Continent, Location, Date,Population,New_Vaccinations,RollingPeopleVaccinated) as

(
select 
	dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations, 
	sum(convert(int,vac.new_vaccinations)) over(partition by dea.Location order by dea.location,dea.Date) as RollingPeopleVaccinated

	From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVac vac
	  ON dea.location = vac.location
		AND dea.date = vac.date

where dea.continent is not null)

Select *,(RollingPeopleVaccinated/Population)*100
From Pvac


--Temp Table

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVac vac
    ON dea.location = vac.location
    AND dea.date = vac.date

	SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS VaccinatedPercentage
FROM #PercentPopulationVaccinated



DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVac vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;


--SELECT * FROM PercentPopulationVaccinated

DROP VIEW IF EXISTS GlobalNum;
GO

CREATE VIEW GlobalNum AS
Select sum(new_cases) as total_cases,Sum(Cast(new_deaths as int)) as total_deaths,
Sum(Cast(new_deaths as int))/Sum(Cast(new_cases as int))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVac vac
    ON dea.location = vac.location
    AND dea.date = vac.date
where dea.continent is not null

SELECT * FROM GlobalNum
