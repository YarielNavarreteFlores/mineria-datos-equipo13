-- Reproducción de la exploración exportada. Una medida, tres granularidades.
WITH base AS (
    SELECT date_trunc('month', t.fecha)::date AS mes_ingreso, r.entidad_res,
           r.nombre_entidad, d.clasificacion_final, f.cantidad_registros
    FROM p3_covid.fact_registro_covid f
    LEFT JOIN p3_covid.dim_fecha t ON t.id_fecha=f.id_fecha_ingreso
    JOIN p3_covid.dim_residencia r USING (id_residencia)
    JOIN p3_covid.dim_diagnostico d USING (id_diagnostico)
), agregado AS (
    SELECT CASE WHEN GROUPING(entidad_res)=1 THEN '1D'
                WHEN GROUPING(clasificacion_final)=1 THEN '2D' ELSE '3D' END AS nivel,
           mes_ingreso, entidad_res, nombre_entidad, clasificacion_final,
           SUM(cantidad_registros) AS registros
    FROM base GROUP BY GROUPING SETS (
        (mes_ingreso), (mes_ingreso,entidad_res,nombre_entidad),
        (mes_ingreso,entidad_res,nombre_entidad,clasificacion_final))
)
SELECT agregado.*, SUM(registros) OVER (PARTITION BY nivel) AS total_control_nivel
FROM agregado ORDER BY nivel, mes_ingreso, entidad_res, clasificacion_final;
