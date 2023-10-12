/*

Analysis of COVID Data and Exploration from 01/01/2020 to 09/27/2023

Skills used:	Joins, 
				CTE's (similiar to Tem table (with as Under standard SQL)), 
				Create Temporary Tables, 
				Windows Functions, 
				Aggregate Functions (sum, max, etc.),
				Creating Views, 
				Converting Data Types (convert, cast),
				Data Types(nvarchar(255), float, int),
				Other function( NULLIF, PARTITION BY, OVER BY, LIKE, DROP TABLE IF etc.)
*/





SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS not NULL
ORDER BY 3,4 



-- When the continent is null, the values of Location are not specific to a geographical location.
-- Here are values of locations ( continent is null)
/*
Lower middle income, North America, Asia, World, Low income, Africa, Oceania,
European Union, South America, Upper middle income, Europe, High income
*/


SELECT DISTINCT LOCATION FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL



--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4



-- Select the columns of interest for exploration.
-- Remember to filter out entries where content is null.


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Comparison of Total Cases and Total Deaths UNDER United State)


SELECT 
	location, date, total_cases, total_deaths, 
	(CONVERT(FLOAT,TOTAL_DEATHS)/ NULLIF(CONVERT(FLOAT,TOTAL_CASES), 0)) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'  --Noitce: 'United States Virgin Islands' is included in the location column
ORDER BY 1,2



-- Comparison of Total Cases and Population: 
-- Illustrating the percentage of the population infected with COVID-19.


SELECT 
	location, date, population, total_cases,
	(NULLIF(CONVERT(FLOAT,TOTAL_CASES), 0)/population) *100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%United States%'
ORDER BY 1,2



-- What contry has the highest infection rate?
-- Identification of Countries with the Highest Infection Rates Relative to Population


SELECT 
	location, population, MAX(total_cases) AS HighestInfectionCount,
	ROUND((MAX(TOTAL_CASES)/population) *100,2) AS InfectedPercentageOfPopulation
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%United States%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectedPercentageOfPopulation DESC



-- Countries with the Highest Death Count By locations


SELECT 
	location, MAX(CAST(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%United States%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC 





-- Analyzing by Continent:
-- North America with the Highest Death Count By locations


SELECT 
	location, MAX(CAST(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%United States%'
WHERE continent = 'North America'
GROUP BY location
ORDER BY TotalDeathCount DESC 



-- Displaying continents with the highest death count per population.


SELECT 
	continent, SUM(CAST(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Statistics:


SELECT 
	SUM(NEW_CASES) as total_cases,
	SUM(NEW_DEATHS) as total_deaths,
	(SUM(NEW_DEATHS)/SUM(NEW_CASES))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null


-- In the beginning of exploration, remember that there is a value "World" under location when continent is null.
-- So, the alternative way to code show as below.
-- Be careful the dtypes of total_cases and total_deaths are nvarchar(255) for sorting.

SELECT
	location,
	MAX(DATE) AS DATE,
	MAX(convert(int,total_cases)) AS Total_Cases,
	MAX(convert(int,total_deaths)) AS Total_Deaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 3 DESC



-- Total Population vs Vaccinations:
-- Displaying the Percentage of the Population that has received at least one COVID-19 Vaccine.


SELECT 
	DEA.CONTINENT, 
	DEA.LOCATION, 
	DEA.DATE, 
	DEA.population, 
	VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS float)) OVER(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,
		DEA.DATE) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
 	ON DEA.LOCATION = VAC.LOCATION AND DEA.DATE = VAC.DATE
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3



-- Utilizing a Common Table Expression (CTE) to Calculate with Partition By in the Earlier Query.
-- # of columns has to be matched with the selected table.

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT 
	DEA.CONTINENT, 
	DEA.LOCATION, 
	DEA.DATE, 
	DEA.population, 
	VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS float)) OVER(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION, DEA.DATE) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
 	ON DEA.LOCATION = VAC.LOCATION AND DEA.DATE = VAC.DATE
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3
)

select 
	* , 
	Round((RollingPeopleVaccinated/population)*100, 2) as VaccinatedPercentage
from PopvsVac

-- Upon careful observation, it has been noticed that the Vaccinated Percentage exceeds 100%. 
-- This could be attributed to either the second or third shot.




-- Utilizing a Temporary Table to Calculate with Partition By in the Earlier Query.
--

DROP TABLE IF EXISTS #PercentPopulationCaccinated

CREATE TABLE #PercentPopulationCaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations NUMERIC,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationCaccinated
SELECT 
	DEA.CONTINENT, 
	DEA.LOCATION, 
	DEA.DATE, 
	DEA.population, 
	VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS float)) OVER(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION, 
		DEA.DATE) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
 	ON DEA.LOCATION = VAC.LOCATION AND DEA.DATE = VAC.DATE
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3

SELECT 
	* , 
	(RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
FROM #PercentPopulationCaccinated




-- Establishing a View to Preserve Data for Future Visualization or looking up data.

Create view PercentPopulationVaccinated as
SELECT DEA.CONTINENT, DEA.LOCATION, DEA.DATE, DEA.population, VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS float)) OVER(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION, DEA.DATE) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
 	ON DEA.LOCATION = VAC.LOCATION
	AND DEA.DATE = VAC.DATE
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3
