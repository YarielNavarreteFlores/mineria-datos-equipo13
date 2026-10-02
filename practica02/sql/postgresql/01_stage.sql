/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 2.2 - Tablas temporales de staging

    Objetivo:
    Conservar los valores originales de los CSV antes
    de aplicar conversiones de tipos o reglas de limpieza.

    Por esta razón las columnas se mantienen como TEXT.
*/


-- =========================================================
-- STAGING 2022
-- Fuente con 41 columnas
-- =========================================================

CREATE TABLE covid_stage_2022 (
    fecha_actualizacion text,
    id_registro text,
    origen text,
    sector text,
    entidad_um text,
    sexo text,
    entidad_nac text,
    entidad_res text,
    municipio_res text,
    localidad_res text,
    tipo_paciente text,
    fecha_ingreso text,
    fecha_sintomas text,
    fecha_def text,
    intubado text,
    neumonia text,
    edad text,
    nacionalidad text,
    embarazo text,
    habla_lengua_indig text,
    indigena text,
    diabetes text,
    epoc text,
    asma text,
    inmusupr text,
    hipertension text,
    otra_com text,
    cardiovascular text,
    obesidad text,
    renal_cronica text,
    tabaquismo text,
    otro_caso text,
    toma_muestra_lab text,
    resultado_lab text,
    toma_muestra_antigeno text,
    resultado_antigeno text,
    clasificacion_final text,
    migrante text,
    pais_nacionalidad text,
    pais_origen text,
    uci text
);


-- =========================================================
-- STAGING 2023
-- Fuente con 44 columnas
-- =========================================================

CREATE TABLE covid_stage_2023 (
    fecha_actualizacion text,
    id_registro text,
    origen text,
    sector text,
    entidad_um text,
    municipio_um text,
    clues text,
    sexo text,
    entidad_nac text,
    entidad_res text,
    municipio_res text,
    localidad_res text,
    tipo_paciente text,
    fecha_ingreso text,
    fecha_sintomas text,
    fecha_def text,
    intubado text,
    neumonia text,
    edad text,
    nacionalidad text,
    embarazo text,
    habla_lengua_indig text,
    indigena text,
    diabetes text,
    epoc text,
    asma text,
    inmusupr text,
    hipertension text,
    otra_com text,
    cardiovascular text,
    obesidad text,
    renal_cronica text,
    tabaquismo text,
    otro_caso text,
    toma_muestra_lab text,
    resultado_lab text,
    toma_muestra_antigeno text,
    resultado_antigeno text,
    clasificacion_final text,
    fecha_resultado text,
    migrante text,
    pais_nacionalidad text,
    pais_origen text,
    uci text
);