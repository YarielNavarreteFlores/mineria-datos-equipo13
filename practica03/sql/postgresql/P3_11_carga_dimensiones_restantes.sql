-- Práctica 3. Carga y conciliación de cinco dimensiones.
-- Ejecutar como script completo en covid20a23sedi, después de P3_10.
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- dim_unidad_medica: una fila por combinación observada, incluidos los NULL.
CREATE TEMP TABLE p11_unidad_medica ON COMMIT DROP AS
SELECT DISTINCT entidad_um, municipio_um, clues, sector, origen
FROM public.covid_historica;

INSERT INTO p3_covid.dim_unidad_medica (entidad_um, municipio_um, clues, sector, origen)
SELECT entidad_um, municipio_um, clues, sector, origen
FROM pg_temp.p11_unidad_medica
ON CONFLICT (entidad_um, municipio_um, clues, sector, origen) DO NOTHING;

-- dim_perfil_demografico: una fila por combinación observada, incluidos los NULL.
CREATE TEMP TABLE p11_perfil_demografico ON COMMIT DROP AS
SELECT DISTINCT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen
FROM public.covid_historica;

INSERT INTO p3_covid.dim_perfil_demografico (sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen)
SELECT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen
FROM pg_temp.p11_perfil_demografico
ON CONFLICT (sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen) DO NOTHING;

-- dim_comorbilidad: una fila por combinación observada, incluidos los NULL.
CREATE TEMP TABLE p11_comorbilidad ON COMMIT DROP AS
SELECT DISTINCT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo
FROM public.covid_historica;

INSERT INTO p3_covid.dim_comorbilidad (diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo)
SELECT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo
FROM pg_temp.p11_comorbilidad
ON CONFLICT (diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo) DO NOTHING;

-- dim_atencion_clinica: una fila por combinación observada, incluidos los NULL.
CREATE TEMP TABLE p11_atencion_clinica ON COMMIT DROP AS
SELECT DISTINCT tipo_paciente, intubado, neumonia, uci
FROM public.covid_historica;

INSERT INTO p3_covid.dim_atencion_clinica (tipo_paciente, intubado, neumonia, uci)
SELECT tipo_paciente, intubado, neumonia, uci
FROM pg_temp.p11_atencion_clinica
ON CONFLICT (tipo_paciente, intubado, neumonia, uci) DO NOTHING;

-- dim_diagnostico: una fila por combinación observada, incluidos los NULL.
CREATE TEMP TABLE p11_diagnostico ON COMMIT DROP AS
SELECT DISTINCT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final
FROM public.covid_historica;

INSERT INTO p3_covid.dim_diagnostico (otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final)
SELECT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final
FROM pg_temp.p11_diagnostico
ON CONFLICT (otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final) DO NOTHING;

-- EXCEPT compara las combinaciones completas y conserva la semántica de NULL.
SELECT 'dim_unidad_medica' AS dimension,
       (SELECT COUNT(*) FROM pg_temp.p11_unidad_medica) AS combinaciones_origen,
       (SELECT COUNT(*) FROM p3_covid.dim_unidad_medica) AS filas_dimension,
       (SELECT COUNT(*) FROM (
           SELECT entidad_um, municipio_um, clues, sector, origen FROM pg_temp.p11_unidad_medica
           EXCEPT
           SELECT entidad_um, municipio_um, clues, sector, origen FROM p3_covid.dim_unidad_medica
       ) AS falta) AS faltantes,
       (SELECT COUNT(*) FROM (
           SELECT entidad_um, municipio_um, clues, sector, origen FROM p3_covid.dim_unidad_medica
           EXCEPT
           SELECT entidad_um, municipio_um, clues, sector, origen FROM pg_temp.p11_unidad_medica
       ) AS sobra) AS sobrantes
UNION ALL
SELECT 'dim_perfil_demografico' AS dimension,
       (SELECT COUNT(*) FROM pg_temp.p11_perfil_demografico) AS combinaciones_origen,
       (SELECT COUNT(*) FROM p3_covid.dim_perfil_demografico) AS filas_dimension,
       (SELECT COUNT(*) FROM (
           SELECT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen FROM pg_temp.p11_perfil_demografico
           EXCEPT
           SELECT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen FROM p3_covid.dim_perfil_demografico
       ) AS falta) AS faltantes,
       (SELECT COUNT(*) FROM (
           SELECT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen FROM p3_covid.dim_perfil_demografico
           EXCEPT
           SELECT sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen FROM pg_temp.p11_perfil_demografico
       ) AS sobra) AS sobrantes
UNION ALL
SELECT 'dim_comorbilidad' AS dimension,
       (SELECT COUNT(*) FROM pg_temp.p11_comorbilidad) AS combinaciones_origen,
       (SELECT COUNT(*) FROM p3_covid.dim_comorbilidad) AS filas_dimension,
       (SELECT COUNT(*) FROM (
           SELECT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo FROM pg_temp.p11_comorbilidad
           EXCEPT
           SELECT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo FROM p3_covid.dim_comorbilidad
       ) AS falta) AS faltantes,
       (SELECT COUNT(*) FROM (
           SELECT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo FROM p3_covid.dim_comorbilidad
           EXCEPT
           SELECT diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo FROM pg_temp.p11_comorbilidad
       ) AS sobra) AS sobrantes
UNION ALL
SELECT 'dim_atencion_clinica' AS dimension,
       (SELECT COUNT(*) FROM pg_temp.p11_atencion_clinica) AS combinaciones_origen,
       (SELECT COUNT(*) FROM p3_covid.dim_atencion_clinica) AS filas_dimension,
       (SELECT COUNT(*) FROM (
           SELECT tipo_paciente, intubado, neumonia, uci FROM pg_temp.p11_atencion_clinica
           EXCEPT
           SELECT tipo_paciente, intubado, neumonia, uci FROM p3_covid.dim_atencion_clinica
       ) AS falta) AS faltantes,
       (SELECT COUNT(*) FROM (
           SELECT tipo_paciente, intubado, neumonia, uci FROM p3_covid.dim_atencion_clinica
           EXCEPT
           SELECT tipo_paciente, intubado, neumonia, uci FROM pg_temp.p11_atencion_clinica
       ) AS sobra) AS sobrantes
UNION ALL
SELECT 'dim_diagnostico' AS dimension,
       (SELECT COUNT(*) FROM pg_temp.p11_diagnostico) AS combinaciones_origen,
       (SELECT COUNT(*) FROM p3_covid.dim_diagnostico) AS filas_dimension,
       (SELECT COUNT(*) FROM (
           SELECT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final FROM pg_temp.p11_diagnostico
           EXCEPT
           SELECT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final FROM p3_covid.dim_diagnostico
       ) AS falta) AS faltantes,
       (SELECT COUNT(*) FROM (
           SELECT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final FROM p3_covid.dim_diagnostico
           EXCEPT
           SELECT otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final FROM pg_temp.p11_diagnostico
       ) AS sobra) AS sobrantes
ORDER BY dimension;

COMMIT;