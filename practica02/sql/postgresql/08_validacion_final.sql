/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    VALIDACIÓN FINAL

    Objetivo:
    Verificar de forma integral que la ingesta,
    transformación, consolidación y limpieza
    produjeron los resultados esperados.

    Este script NO modifica datos.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario,
    version() AS version_postgresql;


-- =========================================================
-- 2. CONTEOS POR CAPA
-- =========================================================

SELECT
    'covid_stage_2022' AS tabla,
    COUNT(*) AS registros
FROM covid_stage_2022

UNION ALL

SELECT
    'covid_2022_tipada',
    COUNT(*)
FROM covid_2022_tipada

UNION ALL

SELECT
    'covid_stage_2023',
    COUNT(*)
FROM covid_stage_2023

UNION ALL

SELECT
    'covid_2023_tipada',
    COUNT(*)
FROM covid_2023_tipada

UNION ALL

SELECT
    'covid_historica',
    COUNT(*)
FROM covid_historica;


-- =========================================================
-- 3. CONCILIACIÓN HISTÓRICA
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM covid_2022_tipada)
        AS registros_2022,

    (SELECT COUNT(*) FROM covid_2023_tipada)
        AS registros_2023,

    (
        (SELECT COUNT(*) FROM covid_2022_tipada)
        +
        (SELECT COUNT(*) FROM covid_2023_tipada)
    ) AS suma_fuentes,

    (SELECT COUNT(*) FROM covid_historica)
        AS historica,

    (
        (SELECT COUNT(*) FROM covid_historica)
        -
        (
            (SELECT COUNT(*) FROM covid_2022_tipada)
            +
            (SELECT COUNT(*) FROM covid_2023_tipada)
        )
    ) AS diferencia;


-- =========================================================
-- 4. UNICIDAD DE ID_REGISTRO
-- =========================================================

SELECT
    COUNT(*) AS total_registros,

    COUNT(*) FILTER (
        WHERE id_registro IS NULL
    ) AS id_null,

    COUNT(DISTINCT id_registro)
        AS ids_distintos,

    COUNT(*) - COUNT(DISTINCT id_registro)
        AS diferencia_total_distintos

FROM covid_historica;


-- =========================================================
-- 5. DUPLICADOS
-- =========================================================

WITH repetidos AS (
    SELECT
        id_registro
    FROM covid_historica
    GROUP BY id_registro
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS ids_repetidos
FROM repetidos;


-- =========================================================
-- 6. NULL PRINCIPALES TRAS LA TRANSFORMACIÓN
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE fecha_def IS NULL
    ) AS fecha_def_null,

    COUNT(*) FILTER (
        WHERE fecha_resultado IS NULL
    ) AS fecha_resultado_null,

    COUNT(*) FILTER (
        WHERE municipio_um IS NULL
    ) AS municipio_um_null,

    COUNT(*) FILTER (
        WHERE clues IS NULL
    ) AS clues_null

FROM covid_historica;


-- =========================================================
-- 7. TRAZABILIDAD POR AÑO
-- =========================================================

SELECT
    anio_fuente,
    COUNT(*) AS registros
FROM covid_historica
GROUP BY anio_fuente
ORDER BY anio_fuente;


-- =========================================================
-- 8. NACIONALIDAD
-- =========================================================

SELECT
    nacionalidad,
    COUNT(*) AS frecuencia
FROM covid_historica
GROUP BY nacionalidad
ORDER BY nacionalidad;


-- =========================================================
-- 9. POSIBLES INCONSISTENCIAS
--    NACIONALIDAD vs PAIS_NACIONALIDAD
-- =========================================================

SELECT
    COUNT(*) AS inconsistencias_nacionalidad
FROM covid_historica
WHERE
       (nacionalidad = 1 AND pais_nacionalidad <> 'México')
    OR (nacionalidad = 2 AND pais_nacionalidad = 'México');


-- =========================================================
-- 10. VALIDAR CASO MIGRANTE NORMALIZADO
-- =========================================================

SELECT
    id_registro,
    migrante
FROM covid_2022_tipada
WHERE id_registro = '15ec76';


-- =========================================================
-- 11. MUNICIPIO NO ESPECIFICADO
--     Resultado informativo, no es error.
-- =========================================================

SELECT
    COUNT(*) AS municipio_999
FROM covid_historica
WHERE entidad_res BETWEEN 1 AND 32
  AND municipio_res = 999;


-- =========================================================
-- 12. RESUMEN AUTOMÁTICO DE CONTROLES
-- =========================================================

SELECT
    'STAGE 2022' AS prueba,
    (SELECT COUNT(*) FROM covid_stage_2022)::text AS resultado,
    '1999998' AS esperado,
    CASE
        WHEN (SELECT COUNT(*) FROM covid_stage_2022) = 1999998
            THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

UNION ALL

SELECT
    'TIPADA 2022',
    (SELECT COUNT(*) FROM covid_2022_tipada)::text,
    '1999998',
    CASE
        WHEN (SELECT COUNT(*) FROM covid_2022_tipada) = 1999998
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'STAGE 2023',
    (SELECT COUNT(*) FROM covid_stage_2023)::text,
    '99999',
    CASE
        WHEN (SELECT COUNT(*) FROM covid_stage_2023) = 99999
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'TIPADA 2023',
    (SELECT COUNT(*) FROM covid_2023_tipada)::text,
    '99999',
    CASE
        WHEN (SELECT COUNT(*) FROM covid_2023_tipada) = 99999
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'HISTORICA',
    (SELECT COUNT(*) FROM covid_historica)::text,
    '2099997',
    CASE
        WHEN (SELECT COUNT(*) FROM covid_historica) = 2099997
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'ID NULL',
    (
        SELECT COUNT(*)
        FROM covid_historica
        WHERE id_registro IS NULL
    )::text,
    '0',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM covid_historica
            WHERE id_registro IS NULL
        ) = 0
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'ID REPETIDOS',
    (
        SELECT COUNT(*)
        FROM (
            SELECT id_registro
            FROM covid_historica
            GROUP BY id_registro
            HAVING COUNT(*) > 1
        ) AS x
    )::text,
    '0',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM (
                SELECT id_registro
                FROM covid_historica
                GROUP BY id_registro
                HAVING COUNT(*) > 1
            ) AS y
        ) = 0
            THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'INCONSISTENCIA NACIONALIDAD',
    (
        SELECT COUNT(*)
        FROM covid_historica
        WHERE
               (nacionalidad = 1
                AND pais_nacionalidad <> 'México')
            OR (nacionalidad = 2
                AND pais_nacionalidad = 'México')
    )::text,
    '0',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM covid_historica
            WHERE
                   (nacionalidad = 1
                    AND pais_nacionalidad <> 'México')
                OR (nacionalidad = 2
                    AND pais_nacionalidad = 'México')
        ) = 0
            THEN 'OK'
        ELSE 'REVISAR'
    END;