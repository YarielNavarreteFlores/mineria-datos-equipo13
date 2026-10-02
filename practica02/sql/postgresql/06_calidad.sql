/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 6.3 - Perfil completo de valores NULL

    Se contabilizan todas las columnas de covid_historica
    y se calcula el porcentaje respecto de los 2,099,997
    registros históricos.
*/

WITH conteos AS (
    SELECT
        COUNT(*) AS total,

        COUNT(*) FILTER (WHERE fecha_actualizacion IS NULL) AS n_fecha_actualizacion,
        COUNT(*) FILTER (WHERE id_registro IS NULL) AS n_id_registro,
        COUNT(*) FILTER (WHERE origen IS NULL) AS n_origen,
        COUNT(*) FILTER (WHERE sector IS NULL) AS n_sector,
        COUNT(*) FILTER (WHERE entidad_um IS NULL) AS n_entidad_um,
        COUNT(*) FILTER (WHERE municipio_um IS NULL) AS n_municipio_um,
        COUNT(*) FILTER (WHERE clues IS NULL) AS n_clues,
        COUNT(*) FILTER (WHERE sexo IS NULL) AS n_sexo,
        COUNT(*) FILTER (WHERE entidad_nac IS NULL) AS n_entidad_nac,
        COUNT(*) FILTER (WHERE entidad_res IS NULL) AS n_entidad_res,
        COUNT(*) FILTER (WHERE municipio_res IS NULL) AS n_municipio_res,
        COUNT(*) FILTER (WHERE localidad_res IS NULL) AS n_localidad_res,
        COUNT(*) FILTER (WHERE tipo_paciente IS NULL) AS n_tipo_paciente,
        COUNT(*) FILTER (WHERE fecha_ingreso IS NULL) AS n_fecha_ingreso,
        COUNT(*) FILTER (WHERE fecha_sintomas IS NULL) AS n_fecha_sintomas,
        COUNT(*) FILTER (WHERE fecha_def IS NULL) AS n_fecha_def,
        COUNT(*) FILTER (WHERE intubado IS NULL) AS n_intubado,
        COUNT(*) FILTER (WHERE neumonia IS NULL) AS n_neumonia,
        COUNT(*) FILTER (WHERE edad IS NULL) AS n_edad,
        COUNT(*) FILTER (WHERE nacionalidad IS NULL) AS n_nacionalidad,
        COUNT(*) FILTER (WHERE embarazo IS NULL) AS n_embarazo,
        COUNT(*) FILTER (WHERE habla_lengua_indig IS NULL) AS n_habla_lengua_indig,
        COUNT(*) FILTER (WHERE indigena IS NULL) AS n_indigena,
        COUNT(*) FILTER (WHERE diabetes IS NULL) AS n_diabetes,
        COUNT(*) FILTER (WHERE epoc IS NULL) AS n_epoc,
        COUNT(*) FILTER (WHERE asma IS NULL) AS n_asma,
        COUNT(*) FILTER (WHERE inmusupr IS NULL) AS n_inmusupr,
        COUNT(*) FILTER (WHERE hipertension IS NULL) AS n_hipertension,
        COUNT(*) FILTER (WHERE otra_com IS NULL) AS n_otra_com,
        COUNT(*) FILTER (WHERE cardiovascular IS NULL) AS n_cardiovascular,
        COUNT(*) FILTER (WHERE obesidad IS NULL) AS n_obesidad,
        COUNT(*) FILTER (WHERE renal_cronica IS NULL) AS n_renal_cronica,
        COUNT(*) FILTER (WHERE tabaquismo IS NULL) AS n_tabaquismo,
        COUNT(*) FILTER (WHERE otro_caso IS NULL) AS n_otro_caso,
        COUNT(*) FILTER (WHERE toma_muestra_lab IS NULL) AS n_toma_muestra_lab,
        COUNT(*) FILTER (WHERE resultado_lab IS NULL) AS n_resultado_lab,
        COUNT(*) FILTER (WHERE toma_muestra_antigeno IS NULL) AS n_toma_muestra_antigeno,
        COUNT(*) FILTER (WHERE resultado_antigeno IS NULL) AS n_resultado_antigeno,
        COUNT(*) FILTER (WHERE clasificacion_final IS NULL) AS n_clasificacion_final,
        COUNT(*) FILTER (WHERE fecha_resultado IS NULL) AS n_fecha_resultado,
        COUNT(*) FILTER (WHERE migrante IS NULL) AS n_migrante,
        COUNT(*) FILTER (WHERE pais_nacionalidad IS NULL) AS n_pais_nacionalidad,
        COUNT(*) FILTER (WHERE pais_origen IS NULL) AS n_pais_origen,
        COUNT(*) FILTER (WHERE uci IS NULL) AS n_uci,
        COUNT(*) FILTER (WHERE anio_fuente IS NULL) AS n_anio_fuente,
        COUNT(*) FILTER (WHERE archivo_fuente IS NULL) AS n_archivo_fuente

    FROM covid_historica
)

SELECT
    v.columna,
    v.nulos,
    c.total,
    ROUND(
        100.0 * v.nulos / NULLIF(c.total, 0),
        4
    ) AS porcentaje_nulos

FROM conteos AS c

CROSS JOIN LATERAL (
    VALUES
        ('fecha_actualizacion', c.n_fecha_actualizacion),
        ('id_registro', c.n_id_registro),
        ('origen', c.n_origen),
        ('sector', c.n_sector),
        ('entidad_um', c.n_entidad_um),
        ('municipio_um', c.n_municipio_um),
        ('clues', c.n_clues),
        ('sexo', c.n_sexo),
        ('entidad_nac', c.n_entidad_nac),
        ('entidad_res', c.n_entidad_res),
        ('municipio_res', c.n_municipio_res),
        ('localidad_res', c.n_localidad_res),
        ('tipo_paciente', c.n_tipo_paciente),
        ('fecha_ingreso', c.n_fecha_ingreso),
        ('fecha_sintomas', c.n_fecha_sintomas),
        ('fecha_def', c.n_fecha_def),
        ('intubado', c.n_intubado),
        ('neumonia', c.n_neumonia),
        ('edad', c.n_edad),
        ('nacionalidad', c.n_nacionalidad),
        ('embarazo', c.n_embarazo),
        ('habla_lengua_indig', c.n_habla_lengua_indig),
        ('indigena', c.n_indigena),
        ('diabetes', c.n_diabetes),
        ('epoc', c.n_epoc),
        ('asma', c.n_asma),
        ('inmusupr', c.n_inmusupr),
        ('hipertension', c.n_hipertension),
        ('otra_com', c.n_otra_com),
        ('cardiovascular', c.n_cardiovascular),
        ('obesidad', c.n_obesidad),
        ('renal_cronica', c.n_renal_cronica),
        ('tabaquismo', c.n_tabaquismo),
        ('otro_caso', c.n_otro_caso),
        ('toma_muestra_lab', c.n_toma_muestra_lab),
        ('resultado_lab', c.n_resultado_lab),
        ('toma_muestra_antigeno', c.n_toma_muestra_antigeno),
        ('resultado_antigeno', c.n_resultado_antigeno),
        ('clasificacion_final', c.n_clasificacion_final),
        ('fecha_resultado', c.n_fecha_resultado),
        ('migrante', c.n_migrante),
        ('pais_nacionalidad', c.n_pais_nacionalidad),
        ('pais_origen', c.n_pais_origen),
        ('uci', c.n_uci),
        ('anio_fuente', c.n_anio_fuente),
        ('archivo_fuente', c.n_archivo_fuente)
) AS v(columna, nulos)

ORDER BY porcentaje_nulos DESC, columna;