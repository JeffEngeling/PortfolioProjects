
/*
Covid 19 Data Exploration

Skills used: Joins, Aggregate Functions, Converting Data Types, CTE's, Temp Tables, Windows Functions

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Selecting Data that we will be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows the percentage of cases resulting in death in different countries

Select Location, date, total_cases, total_deaths, 
(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Viewing data for only Location = United States

Select Location, date, total_cases, total_deaths, 
(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states'
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population contracted Covid

Select Location, date, Population, total_cases,  
(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states'
ORDER BY 1,2

-- Countries with highest infection rate compared to population
-- there was an issue with the MAX() fx and data type for total_cases -> cast as int and it resolved the problem

Select Location, Population, MAX(cast(total_cases as int)) AS HighestInfectionCount,
MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population

Select Location,MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Sorting Death Count by Continent

Select continent, SUM(cast(new_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers

Select date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases),0) *100 AS WorldDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Overall Global Totals from start of pandemic to August 2023
Select SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases),0) *100 AS WorldDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT *
FROM PortfolioProject..CovidVaccinations

-- Total Population vs Vaccinations
-- Shows Percent of Population that has received at least one Covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Creating a rolling count of vaccinations administered

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
NULLIF(SUM(cast(vac.new_vaccinations AS BIGint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date),0) AS RollingPopVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using a CTE to perform Calculation on Partition By on the rolling count of population vaccinated

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
NULLIF(SUM(cast(vac.new_vaccinations AS BIGint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date),0) AS RollingPopVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population) *100
FROM PopVsVac

-- Using a Temp Table to perfrom Calculation on Partition By on the rolling count of population vaccinated

DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
NULLIF(SUM(cast(vac.new_vaccinations AS BIGint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date),0) AS RollingPopVaccinated
--, (RollingPeopleVaccinated/population) * 100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopVaccinated


-- Creating View to store data for later visualization

Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
NULLIF(SUM(cast(vac.new_vaccinations AS BIGint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date),0) AS RollingPopVaccinated
--, (RollingPeopleVaccinated/population) * 100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated



