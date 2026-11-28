-- Versión de reproducción elaborada a partir del DDL y los controles de carga.
BEGIN;
INSERT INTO p3_covid.dim_fuente(anio_fuente, archivo_fuente)
SELECT DISTINCT anio_fuente, archivo_fuente FROM public.covid_historica
ON CONFLICT DO NOTHING;
INSERT INTO p3_covid.dim_fecha(fecha)
SELECT DISTINCT fechas.fecha
FROM public.covid_historica h
CROSS JOIN LATERAL (VALUES (h.fecha_actualizacion), (h.fecha_ingreso),
    (h.fecha_sintomas), (h.fecha_def), (h.fecha_resultado)) fechas(fecha)
WHERE fechas.fecha IS NOT NULL
ON CONFLICT DO NOTHING;
COMMIT;
