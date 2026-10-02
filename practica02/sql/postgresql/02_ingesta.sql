\encoding UTF8
\set ON_ERROR_STOP on

/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 3 - Ingesta de archivos CSV

    Este script debe ejecutarse mediante psql porque utiliza \copy.

    2022:
    Se utiliza la copia de trabajo generada mediante
    scripts/preparar_2022.py. El archivo RAW permanece intacto.

    2023:
    Se utiliza directamente el archivo RAW previamente verificado.

    Si cambia la ubicación del repositorio, deben ajustarse las rutas.
*/


-- =========================================================
-- REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE covid_stage_2022;
TRUNCATE TABLE covid_stage_2023;


-- =========================================================
-- INGESTA 2022
-- =========================================================

\echo Iniciando carga de COVID 2022...

\copy covid_stage_2022 FROM 'C:/Users/yari_/Documents/mineria-datos-equipo13/practica02/data/working/muestra200k_COVID19MEXICOLOC2022_trabajo.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga 2022 terminada.


-- =========================================================
-- INGESTA 2023
-- =========================================================

\echo Iniciando carga de COVID 2023...

\copy covid_stage_2023 FROM 'C:/Users/yari_/Documents/mineria-datos-equipo13/practica02/data/raw/muestra100k_COVID19MEXICOLOC2023.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga 2023 terminada.


-- =========================================================
-- VALIDACIÓN DE CONTEOS
-- =========================================================

SELECT
    'covid_stage_2022' AS tabla,
    COUNT(*) AS registros
FROM covid_stage_2022

UNION ALL

SELECT
    'covid_stage_2023',
    COUNT(*)
FROM covid_stage_2023;


SELECT
    (
        SELECT COUNT(*)
        FROM covid_stage_2022
    )
    +
    (
        SELECT COUNT(*)
        FROM covid_stage_2023
    ) AS total_registros_stage;