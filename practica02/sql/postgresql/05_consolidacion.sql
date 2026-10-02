/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 5 - Consolidación de la tabla histórica

    La tabla histórica utiliza el superset de las 44 variables
    observadas entre 2022 y 2023.

    Para 2022:
    MUNICIPIO_UM, CLUES y FECHA_RESULTADO se asignan como NULL
    porque esas variables no existen en el esquema fuente de 2022.

    Se agregan dos columnas técnicas de trazabilidad:
    anio_fuente y archivo_fuente.
*/


-- =========================================================
-- REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS covid_historica;


-- =========================================================
-- TABLA HISTÓRICA
-- =========================================================

CREATE TABLE covid_historica (
    fecha_actualizacion date,
    id_registro varchar(7),
    origen smallint,
    sector smallint,
    entidad_um smallint,

    municipio_um smallint,
    clues varchar(11),

    sexo smallint,
    entidad_nac smallint,
    entidad_res smallint,
    municipio_res smallint,
    localidad_res smallint,
    tipo_paciente smallint,
    fecha_ingreso date,
    fecha_sintomas date,
    fecha_def date,
    intubado smallint,
    neumonia smallint,
    edad smallint,
    nacionalidad smallint,
    embarazo smallint,
    habla_lengua_indig smallint,
    indigena smallint,
    diabetes smallint,
    epoc smallint,
    asma smallint,
    inmusupr smallint,
    hipertension smallint,
    otra_com smallint,
    cardiovascular smallint,
    obesidad smallint,
    renal_cronica smallint,
    tabaquismo smallint,
    otro_caso smallint,
    toma_muestra_lab smallint,
    resultado_lab smallint,
    toma_muestra_antigeno smallint,
    resultado_antigeno smallint,
    clasificacion_final smallint,

    fecha_resultado date,

    migrante smallint,
    pais_nacionalidad varchar(60),
    pais_origen varchar(60),
    uci smallint,

    -- Metadatos agregados por el ETL
    anio_fuente smallint NOT NULL,
    archivo_fuente varchar(100) NOT NULL
);

-- =========================================================
-- CONSOLIDACIÓN 2022
-- =========================================================

INSERT INTO covid_historica (
    fecha_actualizacion,
    id_registro,
    origen,
    sector,
    entidad_um,
    municipio_um,
    clues,
    sexo,
    entidad_nac,
    entidad_res,
    municipio_res,
    localidad_res,
    tipo_paciente,
    fecha_ingreso,
    fecha_sintomas,
    fecha_def,
    intubado,
    neumonia,
    edad,
    nacionalidad,
    embarazo,
    habla_lengua_indig,
    indigena,
    diabetes,
    epoc,
    asma,
    inmusupr,
    hipertension,
    otra_com,
    cardiovascular,
    obesidad,
    renal_cronica,
    tabaquismo,
    otro_caso,
    toma_muestra_lab,
    resultado_lab,
    toma_muestra_antigeno,
    resultado_antigeno,
    clasificacion_final,
    fecha_resultado,
    migrante,
    pais_nacionalidad,
    pais_origen,
    uci,
    anio_fuente,
    archivo_fuente
)
SELECT
    fecha_actualizacion,
    id_registro,
    origen,
    sector,
    entidad_um,

    NULL::smallint AS municipio_um,
    NULL::varchar(11) AS clues,

    sexo,
    entidad_nac,
    entidad_res,
    municipio_res,
    localidad_res,
    tipo_paciente,
    fecha_ingreso,
    fecha_sintomas,
    fecha_def,
    intubado,
    neumonia,
    edad,
    nacionalidad,
    embarazo,
    habla_lengua_indig,
    indigena,
    diabetes,
    epoc,
    asma,
    inmusupr,
    hipertension,
    otra_com,
    cardiovascular,
    obesidad,
    renal_cronica,
    tabaquismo,
    otro_caso,
    toma_muestra_lab,
    resultado_lab,
    toma_muestra_antigeno,
    resultado_antigeno,
    clasificacion_final,

    NULL::date AS fecha_resultado,

    migrante,
    pais_nacionalidad,
    pais_origen,
    uci,

    2022 AS anio_fuente,
    'muestra200k_COVID19MEXICOLOC2022_trabajo.csv'
        AS archivo_fuente

FROM covid_2022_tipada;

-- =========================================================
-- CONSOLIDACIÓN 2023
-- =========================================================

INSERT INTO covid_historica (
    fecha_actualizacion,
    id_registro,
    origen,
    sector,
    entidad_um,
    municipio_um,
    clues,
    sexo,
    entidad_nac,
    entidad_res,
    municipio_res,
    localidad_res,
    tipo_paciente,
    fecha_ingreso,
    fecha_sintomas,
    fecha_def,
    intubado,
    neumonia,
    edad,
    nacionalidad,
    embarazo,
    habla_lengua_indig,
    indigena,
    diabetes,
    epoc,
    asma,
    inmusupr,
    hipertension,
    otra_com,
    cardiovascular,
    obesidad,
    renal_cronica,
    tabaquismo,
    otro_caso,
    toma_muestra_lab,
    resultado_lab,
    toma_muestra_antigeno,
    resultado_antigeno,
    clasificacion_final,
    fecha_resultado,
    migrante,
    pais_nacionalidad,
    pais_origen,
    uci,
    anio_fuente,
    archivo_fuente
)
SELECT
    fecha_actualizacion,
    id_registro,
    origen,
    sector,
    entidad_um,
    municipio_um,
    clues,
    sexo,
    entidad_nac,
    entidad_res,
    municipio_res,
    localidad_res,
    tipo_paciente,
    fecha_ingreso,
    fecha_sintomas,
    fecha_def,
    intubado,
    neumonia,
    edad,
    nacionalidad,
    embarazo,
    habla_lengua_indig,
    indigena,
    diabetes,
    epoc,
    asma,
    inmusupr,
    hipertension,
    otra_com,
    cardiovascular,
    obesidad,
    renal_cronica,
    tabaquismo,
    otro_caso,
    toma_muestra_lab,
    resultado_lab,
    toma_muestra_antigeno,
    resultado_antigeno,
    clasificacion_final,
    fecha_resultado,
    migrante,
    pais_nacionalidad,
    pais_origen,
    uci,

    2023 AS anio_fuente,
    'muestra100k_COVID19MEXICOLOC2023.csv'
        AS archivo_fuente

FROM covid_2023_tipada;


-- =========================================================
-- VALIDACIÓN DE CONSOLIDACIÓN
-- =========================================================

SELECT
    anio_fuente,
    COUNT(*) AS registros
FROM covid_historica
GROUP BY anio_fuente
ORDER BY anio_fuente;


SELECT
    COUNT(*) AS total_historica
FROM covid_historica;


SELECT
    (SELECT COUNT(*) FROM covid_2022_tipada)
    +
    (SELECT COUNT(*) FROM covid_2023_tipada)
        AS total_fuentes,

    (SELECT COUNT(*) FROM covid_historica)
        AS total_historica,

    (
        (SELECT COUNT(*) FROM covid_historica)
        -
        (
            (SELECT COUNT(*) FROM covid_2022_tipada)
            +
            (SELECT COUNT(*) FROM covid_2023_tipada)
        )
    ) AS diferencia;

/* =========================================================
PUNTO 5.3 - AUDITORÍA DE DUPLICADOS
   ========================================================= */

/*Cuantos ID_REGISTRO estan repetidos*/
WITH ids_repetidos AS (
    SELECT
        id_registro,
        COUNT(*) AS apariciones
    FROM covid_historica
    WHERE id_registro IS NOT NULL
    GROUP BY id_registro
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS cantidad_ids_repetidos,
    SUM(apariciones) AS filas_involucradas,
    SUM(apariciones - 1) AS registros_excedentes,
    MAX(apariciones) AS max_apariciones_id
FROM ids_repetidos;

/*Ver los casos con mayor repeticion*/
SELECT
    id_registro,
    COUNT(*) AS apariciones,
    MIN(fecha_actualizacion) AS primera_actualizacion,
    MAX(fecha_actualizacion) AS ultima_actualizacion,
    ARRAY_AGG(
        DISTINCT anio_fuente
        ORDER BY anio_fuente
    ) AS anios_presentes
FROM covid_historica
WHERE id_registro IS NOT NULL
GROUP BY id_registro
HAVING COUNT(*) > 1
ORDER BY
    apariciones DESC,
    id_registro
LIMIT 20;

/*Seperar repeticiones por periodo*/
WITH resumen AS (
    SELECT
        id_registro,

        COUNT(*) FILTER (
            WHERE anio_fuente = 2022
        ) AS apariciones_2022,

        COUNT(*) FILTER (
            WHERE anio_fuente = 2023
        ) AS apariciones_2023

    FROM covid_historica

    WHERE id_registro IS NOT NULL

    GROUP BY id_registro

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS ids_repetidos_total,

    COUNT(*) FILTER (
        WHERE apariciones_2022 > 1
    ) AS repetidos_dentro_2022,

    COUNT(*) FILTER (
        WHERE apariciones_2023 > 1
    ) AS repetidos_dentro_2023,

    COUNT(*) FILTER (
        WHERE apariciones_2022 > 0
        AND apariciones_2023 > 0
    ) AS presentes_en_ambos_anios

FROM resumen;

/*Usar FECHA_ACTUALIZACION*/
WITH id_fecha_repetidos AS (
    SELECT
        id_registro,
        fecha_actualizacion,
        COUNT(*) AS apariciones
    FROM covid_historica
    WHERE id_registro IS NOT NULL
    GROUP BY
        id_registro,
        fecha_actualizacion
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_id_fecha_repetidos,
    SUM(apariciones) AS filas_involucradas,
    SUM(apariciones - 1) AS registros_excedentes,
    MAX(apariciones) AS max_apariciones
FROM id_fecha_repetidos;


/*Ver ejemplos de ID + fecha repetidos*/
SELECT
    id_registro,
    fecha_actualizacion,
    COUNT(*) AS apariciones,
    ARRAY_AGG(
        DISTINCT anio_fuente
        ORDER BY anio_fuente
    ) AS anios_presentes
FROM covid_historica
WHERE id_registro IS NOT NULL
GROUP BY
    id_registro,
    fecha_actualizacion
HAVING COUNT(*) > 1
ORDER BY
    apariciones DESC,
    id_registro
LIMIT 20;


/*Comprobar duplicados exactos*/
WITH candidatos AS (
    SELECT
        id_registro,
        fecha_actualizacion
    FROM covid_historica
    WHERE id_registro IS NOT NULL
    GROUP BY
        id_registro,
        fecha_actualizacion
    HAVING COUNT(*) > 1
),

filas_firmadas AS (
    SELECT
        h.id_registro,
        h.fecha_actualizacion,

        MD5(
            (
                TO_JSONB(h)
                - 'anio_fuente'
                - 'archivo_fuente'
            )::text
        ) AS firma_fila

    FROM covid_historica AS h

    INNER JOIN candidatos AS c
        ON h.id_registro = c.id_registro
    AND h.fecha_actualizacion = c.fecha_actualizacion
),

duplicados_exactos AS (
    SELECT
        id_registro,
        fecha_actualizacion,
        firma_fila,
        COUNT(*) AS apariciones
    FROM filas_firmadas
    GROUP BY
        id_registro,
        fecha_actualizacion,
        firma_fila
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,
    SUM(apariciones) AS filas_en_grupos_exactos,
    SUM(apariciones - 1) AS duplicados_exactos_excedentes,
    MAX(apariciones) AS max_apariciones_exactas
FROM duplicados_exactos;