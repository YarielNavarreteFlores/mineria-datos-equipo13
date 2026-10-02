/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 4.1 - Perfilado previo al refinamiento de tipos

    Objetivo:
    Identificar valores problemáticos ANTES de convertir
    las tablas STAGE a tipos definitivos.

    PostgreSQL utilizado en la máquina de referencia:
    PostgreSQL 18.3
*/


-- =========================================================
-- 1. CONTEOS BASE
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


/* =========================================================
   2. LONGITUDES MÁXIMAS DE CAMPOS DE TEXTO
   ========================================================= */

SELECT
    '2022' AS periodo,
    MAX(LENGTH(BTRIM(id_registro, E' \t\r\n'))) AS max_id_registro,
    MAX(LENGTH(BTRIM(pais_nacionalidad, E' \t\r\n'))) AS max_pais_nacionalidad,
    MAX(LENGTH(BTRIM(pais_origen, E' \t\r\n'))) AS max_pais_origen
FROM covid_stage_2022

UNION ALL

SELECT
    '2023',
    MAX(LENGTH(BTRIM(id_registro, E' \t\r\n'))),
    MAX(LENGTH(BTRIM(pais_nacionalidad, E' \t\r\n'))),
    MAX(LENGTH(BTRIM(pais_origen, E' \t\r\n')))
FROM covid_stage_2023;


SELECT
    MAX(LENGTH(BTRIM(clues, E' \t\r\n'))) AS max_clues_2023
FROM covid_stage_2023;


/* =========================================================
   3. VALIDACIÓN DE FECHAS — 2022
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_actualizacion, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_actualizacion, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_actualizacion,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_ingreso, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_ingreso, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_ingreso,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_sintomas, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_sintomas, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_sintomas,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_def, E' \t\r\n') NOT IN ('', '9999-99-99')
          AND NOT pg_input_is_valid(
              BTRIM(fecha_def, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_def

FROM covid_stage_2022;


/* =========================================================
   4. VALIDACIÓN DE FECHAS — 2023
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_actualizacion, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_actualizacion, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_actualizacion,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_ingreso, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_ingreso, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_ingreso,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha_sintomas, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(
              BTRIM(fecha_sintomas, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_sintomas,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_def, E' \t\r\n') NOT IN ('', '9999-99-99')
          AND NOT pg_input_is_valid(
              BTRIM(fecha_def, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_def,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_resultado, E' \t\r\n') NOT IN ('', '9999-99-99')
          AND NOT pg_input_is_valid(
              BTRIM(fecha_resultado, E' \t\r\n'),
              'date'
          )
    ) AS invalidas_fecha_resultado

FROM covid_stage_2023;


/* =========================================================
   5. CENTINELAS DE FECHA
   ========================================================= */

SELECT
    '2022' AS periodo,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_def, E' \t\r\n') = '9999-99-99'
    ) AS fecha_def_9999

FROM covid_stage_2022;


SELECT
    '2023' AS periodo,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_def, E' \t\r\n') = '9999-99-99'
    ) AS fecha_def_9999,

    COUNT(*) FILTER (
        WHERE BTRIM(fecha_resultado, E' \t\r\n') = '9999-99-99'
    ) AS fecha_resultado_9999

FROM covid_stage_2023;


/* =========================================================
   6. VALIDACIÓN DE VARIABLES NUMÉRICAS — 2022
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(origen, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(origen, E' \t\r\n'),
            'smallint'
        )
    ) AS origen_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(sector, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(sector, E' \t\r\n'),
            'smallint'
        )
    ) AS sector_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_um, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_um, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_um_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(sexo, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(sexo, E' \t\r\n'),
            'smallint'
        )
    ) AS sexo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_nac, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_nac, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_nac_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_res, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(municipio_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(municipio_res, E' \t\r\n'),
            'smallint'
        )
    ) AS municipio_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(localidad_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(localidad_res, E' \t\r\n'),
            'smallint'
        )
    ) AS localidad_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_paciente, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(tipo_paciente, E' \t\r\n'),
            'smallint'
        )
    ) AS tipo_paciente_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(edad, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(edad, E' \t\r\n'),
            'smallint'
        )
    ) AS edad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(migrante, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(migrante, E' \t\r\n'),
            'smallint'
        )
    ) AS migrante_invalidos

FROM covid_stage_2022;


/* =========================================================
   7. VALIDACIÓN DE VARIABLES NUMÉRICAS — 2023
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(origen, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(origen, E' \t\r\n'),
            'smallint'
        )
    ) AS origen_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(sector, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(sector, E' \t\r\n'),
            'smallint'
        )
    ) AS sector_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_um, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_um, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_um_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(municipio_um, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(municipio_um, E' \t\r\n'),
            'smallint'
        )
    ) AS municipio_um_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(sexo, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(sexo, E' \t\r\n'),
            'smallint'
        )
    ) AS sexo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_nac, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_nac, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_nac_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(entidad_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(entidad_res, E' \t\r\n'),
            'smallint'
        )
    ) AS entidad_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(municipio_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(municipio_res, E' \t\r\n'),
            'smallint'
        )
    ) AS municipio_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(localidad_res, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(localidad_res, E' \t\r\n'),
            'smallint'
        )
    ) AS localidad_res_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_paciente, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(tipo_paciente, E' \t\r\n'),
            'smallint'
        )
    ) AS tipo_paciente_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(edad, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(edad, E' \t\r\n'),
            'smallint'
        )
    ) AS edad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(migrante, E' \t\r\n'), '') IS NOT NULL
        AND NOT pg_input_is_valid(
            BTRIM(migrante, E' \t\r\n'),
            'smallint'
        )
    ) AS migrante_invalidos

FROM covid_stage_2023;


/* =========================================================
   8. RANGO DE EDAD
   Solo después de comprobar que puede convertirse.
   ========================================================= */

SELECT
    '2022' AS periodo,
    MIN(BTRIM(edad, E' \t\r\n')::smallint) AS edad_min,
    MAX(BTRIM(edad, E' \t\r\n')::smallint) AS edad_max
FROM covid_stage_2022
WHERE pg_input_is_valid(
    BTRIM(edad, E' \t\r\n'),
    'smallint'
)

UNION ALL

SELECT
    '2023',
    MIN(BTRIM(edad, E' \t\r\n')::smallint),
    MAX(BTRIM(edad, E' \t\r\n')::smallint)
FROM covid_stage_2023
WHERE pg_input_is_valid(
    BTRIM(edad, E' \t\r\n'),
    'smallint'
);


/* =========================================================
   9. ESPACIOS / CARACTERES DE CONTROL
   ========================================================= */

SELECT
    id_registro,
    migrante AS valor_original,
    REGEXP_REPLACE(
        migrante,
        E'\t',
        '<TAB>',
        'g'
    ) AS valor_visible,
    BTRIM(
        migrante,
        E' \t\r\n'
    ) AS valor_normalizado
FROM covid_stage_2022
WHERE migrante <>
      BTRIM(migrante, E' \t\r\n')
LIMIT 20;


/* =========================================================
   10. VALORES DISTINTOS DEL CAMPO MIGRANTE
   Antes y después de BTRIM
   ========================================================= */

SELECT
    migrante AS valor_original,
    BTRIM(
        migrante,
        E' \t\r\n'
    ) AS valor_normalizado,
    COUNT(*) AS frecuencia
FROM covid_stage_2022
GROUP BY
    migrante,
    BTRIM(migrante, E' \t\r\n')
ORDER BY frecuencia DESC;

/* =========================================================
   11. VALIDACIÓN NUMÉRICA COMPLETA — 2022
   Campos que posteriormente serán SMALLINT
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(intubado, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(intubado, E' \t\r\n'), 'smallint')
    ) AS intubado_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(neumonia, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(neumonia, E' \t\r\n'), 'smallint')
    ) AS neumonia_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(nacionalidad, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(nacionalidad, E' \t\r\n'), 'smallint')
    ) AS nacionalidad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(embarazo, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(embarazo, E' \t\r\n'), 'smallint')
    ) AS embarazo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(habla_lengua_indig, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(habla_lengua_indig, E' \t\r\n'), 'smallint')
    ) AS habla_lengua_indig_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(indigena, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(indigena, E' \t\r\n'), 'smallint')
    ) AS indigena_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(diabetes, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(diabetes, E' \t\r\n'), 'smallint')
    ) AS diabetes_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(epoc, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(epoc, E' \t\r\n'), 'smallint')
    ) AS epoc_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(asma, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(asma, E' \t\r\n'), 'smallint')
    ) AS asma_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(inmusupr, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(inmusupr, E' \t\r\n'), 'smallint')
    ) AS inmusupr_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(hipertension, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(hipertension, E' \t\r\n'), 'smallint')
    ) AS hipertension_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(otra_com, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(otra_com, E' \t\r\n'), 'smallint')
    ) AS otra_com_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(cardiovascular, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(cardiovascular, E' \t\r\n'), 'smallint')
    ) AS cardiovascular_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(obesidad, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(obesidad, E' \t\r\n'), 'smallint')
    ) AS obesidad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(renal_cronica, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(renal_cronica, E' \t\r\n'), 'smallint')
    ) AS renal_cronica_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tabaquismo, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(tabaquismo, E' \t\r\n'), 'smallint')
    ) AS tabaquismo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(otro_caso, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(otro_caso, E' \t\r\n'), 'smallint')
    ) AS otro_caso_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(toma_muestra_lab, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(toma_muestra_lab, E' \t\r\n'), 'smallint')
    ) AS toma_muestra_lab_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(resultado_lab, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(resultado_lab, E' \t\r\n'), 'smallint')
    ) AS resultado_lab_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(toma_muestra_antigeno, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(toma_muestra_antigeno, E' \t\r\n'), 'smallint')
    ) AS toma_muestra_antigeno_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(resultado_antigeno, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(resultado_antigeno, E' \t\r\n'), 'smallint')
    ) AS resultado_antigeno_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(clasificacion_final, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(clasificacion_final, E' \t\r\n'), 'smallint')
    ) AS clasificacion_final_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(uci, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(uci, E' \t\r\n'), 'smallint')
    ) AS uci_invalidos

FROM covid_stage_2022;


/* =========================================================
   12. VALIDACIÓN NUMÉRICA COMPLETA — 2023
   ========================================================= */

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(intubado, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(intubado, E' \t\r\n'), 'smallint')
    ) AS intubado_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(neumonia, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(neumonia, E' \t\r\n'), 'smallint')
    ) AS neumonia_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(nacionalidad, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(nacionalidad, E' \t\r\n'), 'smallint')
    ) AS nacionalidad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(embarazo, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(embarazo, E' \t\r\n'), 'smallint')
    ) AS embarazo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(habla_lengua_indig, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(habla_lengua_indig, E' \t\r\n'), 'smallint')
    ) AS habla_lengua_indig_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(indigena, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(indigena, E' \t\r\n'), 'smallint')
    ) AS indigena_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(diabetes, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(diabetes, E' \t\r\n'), 'smallint')
    ) AS diabetes_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(epoc, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(epoc, E' \t\r\n'), 'smallint')
    ) AS epoc_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(asma, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(asma, E' \t\r\n'), 'smallint')
    ) AS asma_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(inmusupr, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(inmusupr, E' \t\r\n'), 'smallint')
    ) AS inmusupr_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(hipertension, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(hipertension, E' \t\r\n'), 'smallint')
    ) AS hipertension_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(otra_com, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(otra_com, E' \t\r\n'), 'smallint')
    ) AS otra_com_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(cardiovascular, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(cardiovascular, E' \t\r\n'), 'smallint')
    ) AS cardiovascular_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(obesidad, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(obesidad, E' \t\r\n'), 'smallint')
    ) AS obesidad_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(renal_cronica, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(renal_cronica, E' \t\r\n'), 'smallint')
    ) AS renal_cronica_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tabaquismo, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(tabaquismo, E' \t\r\n'), 'smallint')
    ) AS tabaquismo_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(otro_caso, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(otro_caso, E' \t\r\n'), 'smallint')
    ) AS otro_caso_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(toma_muestra_lab, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(toma_muestra_lab, E' \t\r\n'), 'smallint')
    ) AS toma_muestra_lab_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(resultado_lab, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(resultado_lab, E' \t\r\n'), 'smallint')
    ) AS resultado_lab_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(toma_muestra_antigeno, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(toma_muestra_antigeno, E' \t\r\n'), 'smallint')
    ) AS toma_muestra_antigeno_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(resultado_antigeno, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(resultado_antigeno, E' \t\r\n'), 'smallint')
    ) AS resultado_antigeno_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(clasificacion_final, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(clasificacion_final, E' \t\r\n'), 'smallint')
    ) AS clasificacion_final_invalidos,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(uci, E' \t\r\n'), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(uci, E' \t\r\n'), 'smallint')
    ) AS uci_invalidos

FROM covid_stage_2023;