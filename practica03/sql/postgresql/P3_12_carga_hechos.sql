-- P3_12. Ejecutar completo en covid20a23sedi después de P3_11.
-- La transacción concilia las claves antes de confirmar la carga.
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Las claves naturales incluyen indicadores y textos que pueden ser NULL.
-- La igualdad de arreglos respeta orden, tipos y posiciones NULL, y admite hash join.
CREATE TEMP TABLE p12_resueltos ON COMMIT DROP AS
SELECT h.id_registro,
       actualizacion.id_fecha AS id_fecha_actualizacion,
       ingreso.id_fecha AS id_fecha_ingreso,
       sintomas.id_fecha AS id_fecha_sintomas,
       def.id_fecha AS id_fecha_def,
       resultado.id_fecha AS id_fecha_resultado,
       residencia.id_residencia,
       unidad_medica.id_unidad_medica,
       perfil_demografico.id_perfil,
       comorbilidad.id_comorbilidad,
       atencion_clinica.id_atencion,
       diagnostico.id_diagnostico,
       fuente.id_fuente,
       (h.fecha_actualizacion IS NULL OR actualizacion.id_fecha IS NOT NULL)
       AND (h.fecha_ingreso IS NULL OR ingreso.id_fecha IS NOT NULL)
       AND (h.fecha_sintomas IS NULL OR sintomas.id_fecha IS NOT NULL)
       AND (h.fecha_def IS NULL OR def.id_fecha IS NOT NULL)
       AND (h.fecha_resultado IS NULL OR resultado.id_fecha IS NOT NULL)
       AND residencia.id_residencia IS NOT NULL
       AND unidad_medica.id_unidad_medica IS NOT NULL
       AND perfil_demografico.id_perfil IS NOT NULL
       AND comorbilidad.id_comorbilidad IS NOT NULL
       AND atencion_clinica.id_atencion IS NOT NULL
       AND diagnostico.id_diagnostico IS NOT NULL
       AND fuente.id_fuente IS NOT NULL AS enlaces_completos
FROM public.covid_historica AS h
LEFT JOIN p3_covid.dim_fecha AS actualizacion ON actualizacion.fecha = h.fecha_actualizacion
LEFT JOIN p3_covid.dim_fecha AS ingreso ON ingreso.fecha = h.fecha_ingreso
LEFT JOIN p3_covid.dim_fecha AS sintomas ON sintomas.fecha = h.fecha_sintomas
LEFT JOIN p3_covid.dim_fecha AS def ON def.fecha = h.fecha_def
LEFT JOIN p3_covid.dim_fecha AS resultado ON resultado.fecha = h.fecha_resultado
LEFT JOIN p3_covid.dim_residencia AS residencia
    ON ARRAY[residencia.entidad_res, residencia.municipio_res]
       = ARRAY[h.entidad_res, h.municipio_res]
LEFT JOIN p3_covid.dim_unidad_medica AS unidad_medica
    ON ARRAY[unidad_medica.entidad_um, unidad_medica.municipio_um, unidad_medica.sector, unidad_medica.origen]
       = ARRAY[h.entidad_um, h.municipio_um, h.sector, h.origen]
   AND ARRAY[unidad_medica.clues]
       = ARRAY[h.clues]
LEFT JOIN p3_covid.dim_perfil_demografico AS perfil_demografico
    ON ARRAY[perfil_demografico.sexo, perfil_demografico.edad, perfil_demografico.entidad_nac, perfil_demografico.nacionalidad, perfil_demografico.embarazo, perfil_demografico.habla_lengua_indig, perfil_demografico.indigena, perfil_demografico.migrante]
       = ARRAY[h.sexo, h.edad, h.entidad_nac, h.nacionalidad, h.embarazo, h.habla_lengua_indig, h.indigena, h.migrante]
   AND ARRAY[perfil_demografico.pais_nacionalidad, perfil_demografico.pais_origen]
       = ARRAY[h.pais_nacionalidad, h.pais_origen]
LEFT JOIN p3_covid.dim_comorbilidad AS comorbilidad
    ON ARRAY[comorbilidad.diabetes, comorbilidad.epoc, comorbilidad.asma, comorbilidad.inmusupr, comorbilidad.hipertension, comorbilidad.otra_com, comorbilidad.cardiovascular, comorbilidad.obesidad, comorbilidad.renal_cronica, comorbilidad.tabaquismo]
       = ARRAY[h.diabetes, h.epoc, h.asma, h.inmusupr, h.hipertension, h.otra_com, h.cardiovascular, h.obesidad, h.renal_cronica, h.tabaquismo]
LEFT JOIN p3_covid.dim_atencion_clinica AS atencion_clinica
    ON ARRAY[atencion_clinica.tipo_paciente, atencion_clinica.intubado, atencion_clinica.neumonia, atencion_clinica.uci]
       = ARRAY[h.tipo_paciente, h.intubado, h.neumonia, h.uci]
LEFT JOIN p3_covid.dim_diagnostico AS diagnostico
    ON ARRAY[diagnostico.otro_caso, diagnostico.toma_muestra_lab, diagnostico.resultado_lab, diagnostico.toma_muestra_antigeno, diagnostico.resultado_antigeno, diagnostico.clasificacion_final]
       = ARRAY[h.otro_caso, h.toma_muestra_lab, h.resultado_lab, h.toma_muestra_antigeno, h.resultado_antigeno, h.clasificacion_final]
LEFT JOIN p3_covid.dim_fuente AS fuente
    ON ARRAY[fuente.anio_fuente]
       = ARRAY[h.anio_fuente]
   AND ARRAY[fuente.archivo_fuente]
       = ARRAY[h.archivo_fuente];

ALTER TABLE pg_temp.p12_resueltos ADD PRIMARY KEY (id_registro);

DO $validacion$
DECLARE
    sin_enlace bigint;
BEGIN
    SELECT COUNT(*) INTO sin_enlace FROM pg_temp.p12_resueltos WHERE NOT enlaces_completos;
    IF sin_enlace > 0 THEN
        RAISE EXCEPTION '% registros tienen un valor sin correspondencia. Revise las dimensiones.', sin_enlace;
    END IF;
    IF EXISTS (
        SELECT 1 FROM p3_covid.fact_registro_covid AS f
        WHERE NOT EXISTS (SELECT 1 FROM pg_temp.p12_resueltos AS r WHERE r.id_registro = f.id_registro)
    ) THEN
        RAISE EXCEPTION 'Hay hechos previos cuyos identificadores están ausentes en el origen.';
    END IF;
END;
$validacion$;

INSERT INTO p3_covid.fact_registro_covid AS f (
    id_registro, id_fecha_actualizacion,
    id_fecha_ingreso,
    id_fecha_sintomas,
    id_fecha_def,
    id_fecha_resultado,
    id_residencia,
    id_unidad_medica,
    id_perfil,
    id_comorbilidad,
    id_atencion,
    id_diagnostico,
    id_fuente
)
SELECT id_registro, id_fecha_actualizacion,
       id_fecha_ingreso,
       id_fecha_sintomas,
       id_fecha_def,
       id_fecha_resultado,
       id_residencia,
       id_unidad_medica,
       id_perfil,
       id_comorbilidad,
       id_atencion,
       id_diagnostico,
       id_fuente
FROM pg_temp.p12_resueltos
ON CONFLICT (id_registro) DO UPDATE
SET id_fecha_actualizacion = EXCLUDED.id_fecha_actualizacion,
    id_fecha_ingreso = EXCLUDED.id_fecha_ingreso,
    id_fecha_sintomas = EXCLUDED.id_fecha_sintomas,
    id_fecha_def = EXCLUDED.id_fecha_def,
    id_fecha_resultado = EXCLUDED.id_fecha_resultado,
    id_residencia = EXCLUDED.id_residencia,
    id_unidad_medica = EXCLUDED.id_unidad_medica,
    id_perfil = EXCLUDED.id_perfil,
    id_comorbilidad = EXCLUDED.id_comorbilidad,
    id_atencion = EXCLUDED.id_atencion,
    id_diagnostico = EXCLUDED.id_diagnostico,
    id_fuente = EXCLUDED.id_fuente
WHERE ROW(f.id_fecha_actualizacion, f.id_fecha_ingreso, f.id_fecha_sintomas, f.id_fecha_def, f.id_fecha_resultado, f.id_residencia, f.id_unidad_medica, f.id_perfil, f.id_comorbilidad, f.id_atencion, f.id_diagnostico, f.id_fuente)
      IS DISTINCT FROM ROW(EXCLUDED.id_fecha_actualizacion, EXCLUDED.id_fecha_ingreso, EXCLUDED.id_fecha_sintomas, EXCLUDED.id_fecha_def, EXCLUDED.id_fecha_resultado, EXCLUDED.id_residencia, EXCLUDED.id_unidad_medica, EXCLUDED.id_perfil, EXCLUDED.id_comorbilidad, EXCLUDED.id_atencion, EXCLUDED.id_diagnostico, EXCLUDED.id_fuente);

-- Conteos de IDs, medida, fechas de resultado ausentes y municipios por año.
WITH origen AS (
    SELECT anio_fuente, COUNT(*) AS registros_origen
    FROM public.covid_historica GROUP BY anio_fuente
),
destino AS (
    SELECT s.anio_fuente, COUNT(*) AS hechos,
           COUNT(DISTINCT f.id_registro) AS ids_distintos,
           SUM(f.cantidad_registros) AS suma_medida,
           COUNT(*) FILTER (WHERE f.id_fecha_resultado IS NULL) AS sin_fecha_resultado,
           COUNT(*) FILTER (WHERE r.municipio_res = 999) AS municipio_999,
           COUNT(*) FILTER (WHERE r.entidad_res = 8 AND r.municipio_res = 113) AS pareja_08_113
    FROM p3_covid.fact_registro_covid AS f
    JOIN p3_covid.dim_fuente AS s USING (id_fuente)
    JOIN p3_covid.dim_residencia AS r USING (id_residencia)
    GROUP BY s.anio_fuente
)
SELECT anio_fuente, registros_origen, hechos, ids_distintos, suma_medida,
       COALESCE(hechos, 0) - COALESCE(registros_origen, 0) AS diferencia,
       sin_fecha_resultado, municipio_999, pareja_08_113
FROM origen FULL JOIN destino USING (anio_fuente)
ORDER BY anio_fuente;

COMMIT;