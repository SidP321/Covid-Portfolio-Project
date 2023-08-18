SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4


SELECT LOCATION, DATE, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Populations
--Shows what percentage of population got covid

SELECT
    LOCATION,
    DATE,
	POPULATION,
    total_cases,
    (CONVERT(float, total_cases) / CONVERT(float, population)) * 100 AS PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE LOCATION like '%States%'
ORDER BY 1, 2;

 
--SELECT
--    Location,
--    date,
--	population,
--    total_cases,
--    (CONVERT(float, total_cases) / CONVERT(float, population)) * 100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths
--Where location like '%Nepal%'
--ORDER BY 1, 2;


Looking at Countries with highest infection rate compared to population

SELECT
    LOCATION,
    POPULATION,
    MAX(total_cases) as GreatestInfectionCount,
    MAX(CONVERT(float, total_cases) / CONVERT(float, population)) * 100 AS PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%States%'
GROUP BY LOCATION, POPULATION
ORDER BY PercentofPopulationInfected DESC;


--Showing countries with highest death count per population

SELECT
    LOCATION,
    MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
    AND LOCATION NOT IN ('High income', 'Upper middle income','Lower middle income','Low income')
GROUP BY LOCATION
ORDER BY TotalDeathCount DESC;

--Showing continents with the highest death count per population

SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
    AND LOCATION NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY continent
ORDER BY TotalDeathCount DESC;


--Global numbers

SELECT
    DATE,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE
        WHEN SUM(new_cases) <> 0 THEN
            (SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(new_cases))
        ELSE
            NULL
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY DATE
ORDER BY 1, 2;


--Looking at total population vs vaccinations

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated
    FROM
        PortfolioProject..CovidDeaths dea
    JOIN
        PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


--TEMP TABLE

DROP TABLE IF exists #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric -- Specify the appropriate data type here
);

INSERT INTO #percentpopulationvaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated
FROM
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #percentpopulationvaccinated;



--Creating view to store data for tableu

CREATE VIEW percentpopulationvaccinatedtab AS 
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated
FROM
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;
