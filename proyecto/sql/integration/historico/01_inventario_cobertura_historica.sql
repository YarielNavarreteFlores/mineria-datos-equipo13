-- Inventario de cobertura histórica por recurso.
-- Grano de comparación: fecha × sistema × unidad operativa.
-- Los recursos complementarios se informan por separado.

WITH ventana_comun AS (
    SELECT
        MIN(fecha) AS inicio,
        MAX(fecha) AS fin
    FROM proyecto.afluencia_diaria_multisistema
),
fuentes (sistema, recurso, fecha, unidad_operativa, afluencia) AS (
    SELECT 'Metro', 'Simple', fecha, linea::text, afluencia::numeric
    FROM proyecto.metro_simple_clean

    UNION ALL
    SELECT 'Metro', 'Desglosada', fecha, linea::text, afluencia::numeric
    FROM proyecto.metro_desglosada_clean

    UNION ALL
    SELECT 'Metrobús', 'Simple', fecha, linea::text, afluencia::numeric
    FROM proyecto.metrobus_simple_clean

    UNION ALL
    SELECT 'Metrobús', 'Desglosada', fecha, linea::text, afluencia::numeric
    FROM proyecto.metrobus_desglosada_clean

    UNION ALL
    SELECT 'RTP', 'Desglosada', fecha, servicio::text, afluencia::numeric
    FROM proyecto.rtp_desglosada_clean

    UNION ALL
    SELECT 'Cablebús', 'Desglosada', fecha, linea::text, afluencia::numeric
    FROM proyecto.cablebus_desglosada_clean

    UNION ALL
    SELECT 'Trolebús', 'Desglosada', fecha, linea::text, afluencia::numeric
    FROM proyecto.trolebus_desglosada_clean

    UNION ALL
    -- Unidad derivada para la integración de Tren Ligero.
    SELECT 'Tren Ligero', 'Desglosada', fecha, 'Sistema completo', afluencia::numeric
    FROM proyecto.tren_ligero_desglosada_clean
),
por_clave AS (
    SELECT
        sistema,
        recurso,
        fecha,
        unidad_operativa,
        COUNT(*) AS filas_fuente,
        COUNT(afluencia) AS filas_con_valor
    FROM fuentes
    GROUP BY sistema, recurso, fecha, unidad_operativa
),
inventario AS (
    SELECT
        p.*,
        CASE
            WHEN p.sistema IN ('Metro', 'Metrobús') AND p.recurso = 'Desglosada'
                THEN 'COMPLEMENTARIA'
            ELSE 'PRINCIPAL'
        END AS uso_en_historico,
        p.fecha < v.inicio OR p.fecha > v.fin AS fuera_de_ventana
    FROM por_clave AS p
    CROSS JOIN ventana_comun AS v
)
SELECT
    sistema,
    recurso,
    uso_en_historico,
    MIN(fecha) AS primera_fecha,
    MAX(fecha) AS ultima_fecha,
    COUNT(DISTINCT fecha) AS dias_observados,
    SUM(filas_fuente) AS filas_clean,
    COUNT(*) AS claves_historicas,
    COUNT(*) FILTER (WHERE NOT fuera_de_ventana) AS claves_en_ventana,
    COUNT(*) FILTER (WHERE fuera_de_ventana) AS claves_fuera,
    COUNT(*) FILTER (
        WHERE fuera_de_ventana AND filas_con_valor = filas_fuente
    ) AS fuera_sin_null,
    COUNT(*) FILTER (
        WHERE fuera_de_ventana AND filas_con_valor BETWEEN 1 AND filas_fuente - 1
    ) AS fuera_con_null_parcial,
    COUNT(*) FILTER (
        WHERE fuera_de_ventana AND filas_con_valor = 0
    ) AS fuera_todo_null
FROM inventario
GROUP BY sistema, recurso, uso_en_historico
ORDER BY sistema, recurso;