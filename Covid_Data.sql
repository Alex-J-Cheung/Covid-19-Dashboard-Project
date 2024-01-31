-- Intital Data Exploration

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidData..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidData..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage people got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidData..CovidDeaths
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 
as PercentPopulationInfected
FROM CovidData..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidData..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Breaking things down by continent

-- showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidData..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers

Select date, SUM(new_cases) as total_global_cases, SUM(new_deaths) as total_global_deaths,
SUM(new_deaths)/SUM(new_cases)*100 as GlobalDeathPercentage
FROM CovidData..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

Select SUM(new_cases) as total_global_cases, SUM(new_deaths) as total_global_deaths,
SUM(new_deaths)/SUM(new_cases)*100 as GlobalDeathPercentage
FROM CovidData..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using a CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

 -- Temp Table
 DROP TABLE if exists #PercentPopulationVaccinated
 CREATE TABLE #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rollingpeoplevaccinated numeric,
 )

 Insert into #PercentPopulationVaccinated
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for visualizations

USE CovidData
GO
Create View PercentPopulationVaccinated 
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated

/*

Queries used for Tableau Visulizations

*/

-- 1. 

SELECT SUM(dea.new_cases) as TotalCases, SUM(dea.new_deaths) as TotalDeaths, MAX(vac.people_vaccinated) as TotalVaccinations,
SUM(dea.new_deaths)/SUM(dea.new_cases)*100 as DeathPercentage, MAX(vac.people_vaccinated)/SUM(DISTINCT dea.population)*100 as VaccinationPercentage
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is null 
AND (dea.location = 'World')
ORDER BY 1,2

-- 2.

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- We remove income status because they are not locations
-- European Union is part of Europe

SELECT location, SUM(new_deaths) as TotalDeathCount
FROM CovidData..CovidDeaths
WHERE continent is null 
and location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income',
'lower middle income', 'low income')
GROUP BY location
ORDER BY TotalDeathCount desc

-- 3. 
SELECT dea.location, MAX(vac.people_vaccinated) as TotalVaccinationCount
FROM CovidData..CovidDeaths as dea
JOIN CovidData..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is null 
and dea.location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income',
'lower middle income', 'low income')
GROUP BY dea.location
ORDER BY TotalVaccinationCount desc

-- 4. 

SELECT location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidData..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- 5. 

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount,  
MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidData..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected desc

