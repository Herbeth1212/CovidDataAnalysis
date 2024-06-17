--Selecting the required columns
SELECT 
    location, 
    CONVERT(date, date, 105) AS date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    [Project Portfolio]..CovidDeaths_Final
ORDER BY 
   location, CONVERT(date, date, 105)

--Looking at Total Cases vs Total Deaths
Select location, CONVERT(date, date, 105) AS date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
From [Project Portfolio]..CovidDeaths_Final
order by 1,date

--Looking at Total cases vs Population
--Showing what percentage of population is infected by Covid
Select location, CONVERT(date, date, 105) AS date, total_cases,population, 
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
From [Project Portfolio]..CovidDeaths_Final
order by 1,2

--Finding highest Infection rate compared to population in a Country
Select location,population, MAX(total_cases) as HighestInfectionCount, Max(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
From [Project Portfolio]..CovidDeaths_Final
GROUP BY location, population
order by PercentPopulationInfected desc

--Death count by continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [Project Portfolio]..CovidDeaths_Final
WHERE (continent IS NULL OR continent = '')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing countries with highest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Project Portfolio]..CovidDeaths_Final
WHERE (continent <> '') 
GROUP BY location
order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT

--Showing continents with highest death count per population
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Project Portfolio]..CovidDeaths_Final
where continent = ''
GROUP BY location
order by TotalDeathCount desc


--GLOBAL NUMBERS
SELECT CONVERT(date, date, 105) AS date, 
       SUM(CAST(new_cases AS INT)) AS TotalNewCases, 
       SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths, 
       (SUM(CAST(new_deaths as float))/NULLIF(SUM(CAST(new_cases as float)),0))*100 as DeathPercentage
FROM [Project Portfolio]..CovidDeaths_Final
WHERE continent <> ' '
GROUP BY date
ORDER BY date, TotalNewCases

--Total cases accross the world
SELECT SUM(CAST(new_cases AS INT)) AS TotalNewCases, 
       SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths, 
       (SUM(CAST(new_deaths as float))/NULLIF(SUM(CAST(new_cases as float)),0))*100 as DeathPercentage
FROM [Project Portfolio]..CovidDeaths_Final
WHERE continent <> ' '

--Joining both tables on location and date
Select * 
From [Project Portfolio]..CovidDeaths_Final Death
Join [Project Portfolio]..CovidVaccinations_Final vaccine
ON Death.location = vaccine.location
AND Death.date = vaccine.date

-- Looking at total vaccination vs population
Select Death.continent, Death.location, Death.date, Death.population, vaccine.new_vaccinations
From [Project Portfolio]..CovidDeaths_Final Death
Join [Project Portfolio]..CovidVaccinations_Final vaccine
	ON Death.location = vaccine.location
	AND Death.date = vaccine.date
WHERE Death.continent <> ' '
ORDER BY 2,3


-- Total People vaccinated in a country at a date
Select Death.continent, Death.location, CONVERT(date, Death.date, 105) AS date, Death.population, vaccine.new_vaccinations, SUM(CAST(vaccine.new_vaccinations as INT)) OVER (PARTITION BY Death.location order by Death.location, CONVERT(date, Death.date, 105)) as RollingPeopleVaccinated
From [Project Portfolio]..CovidDeaths_Final Death
Join [Project Portfolio]..CovidVaccinations_Final vaccine
	ON Death.location = vaccine.location
	AND Death.date = vaccine.date
WHERE Death.continent <> ' '
ORDER BY 2,3


--Use CTE
WITH PopVSVac AS (
    SELECT 
        Death.continent, 
        Death.location, 
        CONVERT(date, Death.date, 105) AS date, 
        Death.population, 
        vaccine.new_vaccinations, 
        SUM(CAST(vaccine.new_vaccinations AS INT)) OVER (
            PARTITION BY Death.location 
            ORDER BY CONVERT(date, Death.date, 105)
        ) AS RollingPeopleVaccinated
    FROM 
        [Project Portfolio]..CovidDeaths_Final Death
    JOIN 
        [Project Portfolio]..CovidVaccinations_Final vaccine
    ON 
        Death.location = vaccine.location
        AND Death.date = vaccine.date
    WHERE 
        Death.continent <> ' '
)
SELECT *, (NULLIF(CONVERT(float, RollingPeopleVaccinated), 0)/NULLIF(CONVERT(float, population), 0))*100
FROM PopVSVac
ORDER BY location, date;

--Creating view for making visualizations
Create View PercentPopulationVaccinated as
    SELECT 
        Death.continent, 
        Death.location, 
        CONVERT(date, Death.date, 105) AS date, 
        Death.population, 
        vaccine.new_vaccinations, 
        SUM(CAST(vaccine.new_vaccinations AS INT)) OVER (
            PARTITION BY Death.location 
            ORDER BY CONVERT(date, Death.date, 105)
        ) AS RollingPeopleVaccinated
    FROM 
        [Project Portfolio]..CovidDeaths_Final Death
    JOIN 
        [Project Portfolio]..CovidVaccinations_Final vaccine
    ON 
        Death.location = vaccine.location
        AND Death.date = vaccine.date
    WHERE 
        Death.continent <> ' '