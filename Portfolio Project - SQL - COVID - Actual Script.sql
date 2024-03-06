/*
Covid 19 Data Exploration 
DatASet Source Website: https://ourworldindata.org/explorers/coronavirus-data-explorer?facet=none&Metric=Confirmed+deaths&Interval=7-day+rolling+average&Relative+to+Population=true&Color+by+test+positivity=false&country=USA~BRA~JPN~DEU

Skills used: JOINs, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


SELECT *
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


-- 1. SELECT Data that we are going to be starting with
SELECT Location, 
		date, 
		total_cASes, 
		new_cASes, 
		total_deaths, 
		population
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 



-- 2. Total CASes vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, 
		date, 
		total_cASes,
		total_deaths, 
		(total_deaths/total_cASes)*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2



-- 3. Total CASes vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, 
		date, 
		Population, 
		total_cASes,  
		(total_cASes/population)*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
--WHERE location like '%states%'
ORDER BY 1,2



-- 4. Countries with Highest Infection Rate compared to Population
SELECT Location, 
		Population, 
		MAX(total_cASes) AS HighestInfectionCount,  
		MAX((total_cASes/population))*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
--WHERE location like '%states%'
GROUP BY Location, 
		 Population
ORDER BY PercentPopulationInfected DESC



-- 5. Countries with Highest Death Count per Population
SELECT Location, 
		MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC



-- 6. BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, 
		MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- 7. GLOBAL NUMBERS
SELECT SUM(new_cASes) AS total_cASes, 
	   SUM( CAST(new_deaths AS int) ) AS total_deaths, 
	   SUM( CAST(new_deaths AS int) ) / SUM(New_CASes)*100 AS DeathPercentage
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



-- 8. Total Population vs Vaccinations
-- Shows Percentage of Population that hAS recieved at leASt one Covid Vaccine
SELECT  dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM( CONVERT(int,vac.new_vaccinations) ) OVER (PARTITION BY dea.Location 
													   ORDER BY dea.location, 
																dea.Date) AS RollingPeopleVaccinated
		--, (RollingPeopleVaccinated/population)*100
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



-- 9. Using CTE to perform Calculation on PARTITION BY in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
	(SELECT dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations, 
			SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location 
														 ORDER BY dea.location, 
																  dea.Date) AS RollingPeopleVaccinated
			--, (RollingPeopleVaccinated/population)*100
	FROM dbo.CovidDeaths dea
	JOIN dbo.CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3
	)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- 10. Using Temp Table to perform Calculation on PARTITION BY in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(
		Continent nvarchar(255),
		Location nvarchar(255),
		Date datetime,
		Population numeric,
		New_vaccinations numeric,
		RollingPeopleVaccinated numeric
	)

	INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations, 
			SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location 
														 ORDER BY dea.location, 
																  dea.Date) AS RollingPeopleVaccinated
		    --, (RollingPeopleVaccinated/population)*100
	FROM dbo.CovidDeaths dea
	JOIN dbo.CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	--WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3

SELECT *, 
	   (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




-- 11. Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations, 
			SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location 
														 ORDER BY dea.location, 
																  dea.Date) AS RollingPeopleVaccinated
			--, (RollingPeopleVaccinated/population)*100
	FROM dbo.CovidDeaths dea
	JOIN dbo.CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

