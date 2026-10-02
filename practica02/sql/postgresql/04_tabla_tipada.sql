/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 4.2 - Construcción de tablas tipadas

    Flujo:
        STAGE (TEXT)
             ↓
        limpieza controlada
             ↓
        TYPED

    Decisiones principales:
    - Se aplica BTRIM para eliminar espacios y caracteres
      de control antes de las conversiones.
    - 97, 98 y 99 se conservan como códigos categóricos.
    - 9999-99-99 se convierte a NULL únicamente en fechas.
    - Los valores originales permanecen intactos en STAGE.
*/


-- =========================================================
-- REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS covid_2022_tipada;
DROP TABLE IF EXISTS covid_2023_tipada;


-- =========================================================
-- TABLA TIPADA 2022
-- =========================================================

CREATE TABLE covid_2022_tipada (
    fecha_actualizacion date,
    id_registro varchar(7),
    origen smallint,
    sector smallint,
    entidad_um smallint,
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
    migrante smallint,
    pais_nacionalidad varchar(60),
    pais_origen varchar(60),
    uci smallint
);


-- =========================================================
-- TABLA TIPADA 2023
-- =========================================================

CREATE TABLE covid_2023_tipada (
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
    uci smallint
);


-- =========================================================
-- INSERCIÓN TRANSFORMADA 2022
-- =========================================================

INSERT INTO covid_2022_tipada (
    fecha_actualizacion,
    id_registro,
    origen,
    sector,
    entidad_um,
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
    migrante,
    pais_nacionalidad,
    pais_origen,
    uci
)
SELECT
    NULLIF(BTRIM(fecha_actualizacion, E' \t\r\n'), '')::date,
    NULLIF(BTRIM(id_registro, E' \t\r\n'), '')::varchar(7),
    NULLIF(BTRIM(origen, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(sector, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_um, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(sexo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_nac, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(municipio_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(localidad_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(tipo_paciente, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(fecha_ingreso, E' \t\r\n'), '')::date,
    NULLIF(BTRIM(fecha_sintomas, E' \t\r\n'), '')::date,

    CASE
        WHEN BTRIM(fecha_def, E' \t\r\n') IN ('', '9999-99-99')
            THEN NULL
        ELSE BTRIM(fecha_def, E' \t\r\n')::date
    END,

    NULLIF(BTRIM(intubado, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(neumonia, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(edad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(nacionalidad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(embarazo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(habla_lengua_indig, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(indigena, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(diabetes, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(epoc, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(asma, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(inmusupr, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(hipertension, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(otra_com, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(cardiovascular, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(obesidad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(renal_cronica, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(tabaquismo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(otro_caso, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(toma_muestra_lab, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(resultado_lab, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(toma_muestra_antigeno, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(resultado_antigeno, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(clasificacion_final, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(migrante, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(pais_nacionalidad, E' \t\r\n'), '')::varchar(60),
    NULLIF(BTRIM(pais_origen, E' \t\r\n'), '')::varchar(60),
    NULLIF(BTRIM(uci, E' \t\r\n'), '')::smallint

FROM covid_stage_2022;


-- =========================================================
-- INSERCIÓN TRANSFORMADA 2023
-- =========================================================

INSERT INTO covid_2023_tipada (
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
    uci
)
SELECT
    NULLIF(BTRIM(fecha_actualizacion, E' \t\r\n'), '')::date,
    NULLIF(BTRIM(id_registro, E' \t\r\n'), '')::varchar(7),
    NULLIF(BTRIM(origen, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(sector, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_um, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(municipio_um, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(clues, E' \t\r\n'), '')::varchar(11),
    NULLIF(BTRIM(sexo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_nac, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(entidad_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(municipio_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(localidad_res, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(tipo_paciente, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(fecha_ingreso, E' \t\r\n'), '')::date,
    NULLIF(BTRIM(fecha_sintomas, E' \t\r\n'), '')::date,

    CASE
        WHEN BTRIM(fecha_def, E' \t\r\n') IN ('', '9999-99-99')
            THEN NULL
        ELSE BTRIM(fecha_def, E' \t\r\n')::date
    END,

    NULLIF(BTRIM(intubado, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(neumonia, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(edad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(nacionalidad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(embarazo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(habla_lengua_indig, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(indigena, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(diabetes, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(epoc, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(asma, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(inmusupr, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(hipertension, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(otra_com, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(cardiovascular, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(obesidad, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(renal_cronica, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(tabaquismo, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(otro_caso, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(toma_muestra_lab, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(resultado_lab, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(toma_muestra_antigeno, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(resultado_antigeno, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(clasificacion_final, E' \t\r\n'), '')::smallint,

    CASE
        WHEN BTRIM(fecha_resultado, E' \t\r\n') IN ('', '9999-99-99')
            THEN NULL
        ELSE BTRIM(fecha_resultado, E' \t\r\n')::date
    END,

    NULLIF(BTRIM(migrante, E' \t\r\n'), '')::smallint,
    NULLIF(BTRIM(pais_nacionalidad, E' \t\r\n'), '')::varchar(60),
    NULLIF(BTRIM(pais_origen, E' \t\r\n'), '')::varchar(60),
    NULLIF(BTRIM(uci, E' \t\r\n'), '')::smallint

FROM covid_stage_2023;


-- =========================================================
-- VALIDACIÓN INICIAL
-- =========================================================

SELECT
    '2022 stage' AS tabla,
    COUNT(*) AS registros
FROM covid_stage_2022

UNION ALL

SELECT
    '2022 tipada',
    COUNT(*)
FROM covid_2022_tipada

UNION ALL

SELECT
    '2023 stage',
    COUNT(*)
FROM covid_stage_2023

UNION ALL

SELECT
    '2023 tipada',
    COUNT(*)
FROM covid_2023_tipada;