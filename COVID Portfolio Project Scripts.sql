SELECT *
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProjectCOVID..CovidVaccinations
--ORDER BY 3,4

--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
ORDER BY 1,2


--Look at Total Cases vs Total Deaths
--Shows likelihood of dying from contracting covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location LIKE '%states%' AND continent IS not null
ORDER BY 1,2


--Looking at total cases vs population
--Shows what percentage of population got COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location LIKE '%states%' AND continent IS not null
ORDER BY 1,2


--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
GROUP BY location
ORDER BY HighestDeathCount DESC


--Lets break things down by continent

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathCount DESC


--Showing Continents with highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC


--Global Numbers

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, 
	ROUND((SUM(cast(new_deaths as int))/SUM(new_cases)*100),2) AS DeathPercentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
GROUP BY date
ORDER BY 1,2


--Join tables together

SELECT *
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date


--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS not null
ORDER BY 2,3


--USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS not null
)
SELECT *, ROUND((RollingPeopleVaccinated/population*100),2) AS PercentageVaccinated
FROM PopvsVac


--Create Temp Table

DROP TABLE if EXISTS #PerceptPopulationVaccinated
CREATE Table #PerceptPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PerceptPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS not null

SELECT *, ROUND((RollingPeopleVaccinated/population*100),2) AS PercentageVaccinated
FROM #PerceptPopulationVaccinated


--Creating views to store data for later visualizations

CREATE VIEW PerceptPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS not null


CREATE VIEW ContinentsWithHighestDeathRate AS
SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY continent


CREATE VIEW GlobalNumbers AS
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, 
	ROUND((SUM(cast(new_deaths as int))/SUM(new_cases)*100),2) AS DeathPercentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
GROUP BY date


CREATE VIEW HighestInfectionRate AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent IS not null
GROUP BY location, population
