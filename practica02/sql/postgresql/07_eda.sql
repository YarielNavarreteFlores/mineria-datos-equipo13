/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 6.1 y 6.2
    Análisis exploratorio de PAIS_NACIONALIDAD
    y campos relacionados.
*/


-- =========================================================
-- PAIS_NACIONALIDAD
-- =========================================================

SELECT
    MIN(pais_nacionalidad) AS minimo,
    MAX(pais_nacionalidad) AS maximo,
    COUNT(DISTINCT pais_nacionalidad) AS valores_distintos,
    COUNT(*) AS registros
FROM covid_historica;

SELECT
    pais_nacionalidad,
    COUNT(*) AS frecuencia,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        4
    ) AS porcentaje
FROM covid_historica
GROUP BY pais_nacionalidad
ORDER BY frecuencia DESC;

-- =========================================================
-- CAMPOS_ASOCIADOS_A_NACIONALIDAD
-- =========================================================
SELECT
    MIN(nacionalidad) AS min_nacionalidad,
    MAX(nacionalidad) AS max_nacionalidad,
    COUNT(DISTINCT nacionalidad) AS distintos_nacionalidad,

    MIN(pais_origen) AS min_pais_origen,
    MAX(pais_origen) AS max_pais_origen,
    COUNT(DISTINCT pais_origen) AS distintos_pais_origen

FROM covid_historica;

SELECT
    nacionalidad,
    pais_nacionalidad,
    COUNT(*) AS frecuencia
FROM covid_historica
GROUP BY
    nacionalidad,
    pais_nacionalidad
ORDER BY frecuencia DESC;

-- =========================================================
-- MUNICIPIO_RES
-- =========================================================
SELECT
    MIN(municipio_res) AS municipio_min,
    MAX(municipio_res) AS municipio_max,
    COUNT(DISTINCT municipio_res) AS municipios_distintos
FROM covid_historica;

SELECT
    MIN(entidad_res) AS entidad_min,
    MAX(entidad_res) AS entidad_max,
    COUNT(DISTINCT entidad_res) AS entidades_distintas,

    COUNT(
        DISTINCT (
            entidad_res,
            municipio_res
        )
    ) AS combinaciones_entidad_municipio

FROM covid_historica;

-- =========================================================
-- FRECUENCIAS_DE_MUNICIPIO_ASOCIADAS_A_ENTIDAD
-- =========================================================
SELECT
    entidad_res,
    municipio_res,
    COUNT(*) AS frecuencia
FROM covid_historica
GROUP BY
    entidad_res,
    municipio_res
ORDER BY frecuencia DESC
LIMIT 50;

-- =========================================================
-- BUSCAR_CODIGOS_ESPECIALES_Y_ANOMALIAS
-- PARA_MUNICIPIOS
-- =========================================================
/*
-- CONSULTA INICIAL DESCARTADA:
-- No se usa porque 97, 98 y 99 pueden ser códigos
-- municipales ordinarios dentro de entidades normales.

SELECT
    entidad_res,
    municipio_res,
    COUNT(*) AS frecuencia
FROM covid_historica
WHERE municipio_res IN (97, 98, 99, 999)
   OR entidad_res IN (97, 98, 99)
GROUP BY
    entidad_res,
    municipio_res
ORDER BY frecuencia DESC;
*/

/* =========================================================
-- REVISIÓN DE CÓDIGOS ESPECIALES EN NACIONALIDAD
-- Y PAÍS DE ORIGEN
   ========================================================= */
SELECT
    nacionalidad,
    pais_nacionalidad,
    pais_origen,
    COUNT(*) AS frecuencia
FROM covid_historica
WHERE nacionalidad IN (97, 98, 99)
   OR pais_nacionalidad IN ('97', '98', '99')
   OR pais_origen IN ('97', '98', '99')
GROUP BY
    nacionalidad,
    pais_nacionalidad,
    pais_origen
ORDER BY frecuencia DESC;


/* =========================================================
-- MUNICIPIO_RES = 999
-- Código NO ESPECIFICADO dentro de entidades normales
   ========================================================= */

SELECT
    entidad_res,
    COUNT(*) AS municipio_no_especificado
FROM covid_historica
WHERE entidad_res BETWEEN 1 AND 32
  AND municipio_res = 999
GROUP BY entidad_res
ORDER BY municipio_no_especificado DESC;

/* =========================================================
   COMBINACIONES ESPECIALES ENTIDAD + MUNICIPIO
   ========================================================= */

SELECT
    entidad_res,
    municipio_res,
    COUNT(*) AS frecuencia
FROM covid_historica
WHERE
       (entidad_res = 97 AND municipio_res = 997)
    OR (entidad_res = 98 AND municipio_res = 998)
    OR (entidad_res = 99 AND municipio_res = 999)
GROUP BY
    entidad_res,
    municipio_res
ORDER BY entidad_res;

/* =========================================================
   POSIBLES INCONSISTENCIAS EN ENTIDADES ESPECIALES
   ========================================================= */

SELECT
    entidad_res,
    municipio_res,
    COUNT(*) AS frecuencia
FROM covid_historica
WHERE entidad_res IN (97, 98, 99)
  AND NOT (
         (entidad_res = 97 AND municipio_res = 997)
      OR (entidad_res = 98 AND municipio_res = 998)
      OR (entidad_res = 99 AND municipio_res = 999)
  )
GROUP BY
    entidad_res,
    municipio_res
ORDER BY frecuencia DESC;

/* =========================================================
   DISTRIBUCIÓN DE NACIONALIDAD
   ========================================================= */

SELECT
    nacionalidad,
    COUNT(*) AS frecuencia
FROM covid_historica
GROUP BY nacionalidad
ORDER BY nacionalidad;


/* =========================================================
   COHERENCIA NACIONALIDAD ↔ PAIS_NACIONALIDAD
   ========================================================= */

SELECT
    nacionalidad,
    pais_nacionalidad,
    COUNT(*) AS frecuencia
FROM covid_historica
WHERE
       (nacionalidad = 1 AND pais_nacionalidad <> 'México')
    OR (nacionalidad = 2 AND pais_nacionalidad = 'México')
GROUP BY
    nacionalidad,
    pais_nacionalidad
ORDER BY frecuencia DESC;