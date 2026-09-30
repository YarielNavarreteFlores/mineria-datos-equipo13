DROP TABLE IF EXISTS practica01.resumen_procesamiento;

CREATE TABLE practica01.resumen_procesamiento AS
SELECT
    1 AS orden,
    'RAW - Original' AS etapa,
    COUNT(*)::BIGINT AS registros
FROM practica01.metro_simple_raw
UNION ALL
SELECT
    2 AS orden,
    'CLEAN - Limpieza' AS etapa,
    COUNT(*)::BIGINT AS registros
FROM practica01.metro_simple_clean
UNION ALL
SELECT
    3 AS orden,
    'ANÁLISIS - Sin colisiones' AS etapa,
    COUNT(*)::BIGINT AS registros
FROM practica01.metro_simple_clean
WHERE es_colision_clave = FALSE;


-- Despues verifica
SELECT *
FROM practica01.resumen_procesamiento
ORDER BY orden;

--Debe obtener
-- 1 | RAW - Original             | 1,180,920
-- 2 | CLEAN - Limpieza           | 1,180,920
-- 3 | ANÁLISIS - Sin colisiones  | 1,180,858