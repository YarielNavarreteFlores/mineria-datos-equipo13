-- 4.1 Revisar valores nulos en Metro_simple
SELECT
    COUNT(*) AS total_registros,
    COUNT(*) FILTER (WHERE fecha IS NULL) AS nulos_fecha,
    COUNT(*) FILTER (WHERE anio IS NULL) AS nulos_anio,
    COUNT(*) FILTER (WHERE mes IS NULL) AS nulos_mes,
    COUNT(*) FILTER (WHERE linea IS NULL) AS nulos_linea,
    COUNT(*) FILTER (WHERE estacion IS NULL) AS nulos_estacion,
    COUNT(*) FILTER (WHERE afluencia IS NULL) AS nulos_afluencia
FROM practica01.metro_simple_raw;

-- Revisar valores nulos en Metro_desglosada
SELECT
    COUNT(*) AS total_registros,
    COUNT(*) FILTER (WHERE fecha IS NULL) AS nulos_fecha,
    COUNT(*) FILTER (WHERE anio IS NULL) AS nulos_anio,
    COUNT(*) FILTER (WHERE mes IS NULL) AS nulos_mes,
    COUNT(*) FILTER (WHERE linea IS NULL) AS nulos_linea,
    COUNT(*) FILTER (WHERE estacion IS NULL) AS nulos_estacion,
    COUNT(*) FILTER (WHERE tipo_pago IS NULL) AS nulos_tipo_pago,
    COUNT(*) FILTER (WHERE afluencia IS NULL) AS nulos_afluencia
FROM practica01.metro_desglosada_raw;


-- 4.2 Revisar afluencias cero y negativas para Metro_simple
SELECT
    COUNT(*) FILTER (WHERE afluencia < 0) AS afluencias_negativas,
    COUNT(*) FILTER (WHERE afluencia = 0) AS afluencias_cero,
    MIN(afluencia) AS afluencia_minima,
    MAX(afluencia) AS afluencia_maxima,
    ROUND(AVG(afluencia), 2) AS afluencia_promedio
FROM practica01.metro_simple_raw;

-- Revisar afluencias cero y negativas para metro_desglosada
SELECT
    COUNT(*) FILTER (WHERE afluencia < 0) AS afluencias_negativas,
    COUNT(*) FILTER (WHERE afluencia = 0) AS afluencias_cero,
    MIN(afluencia) AS afluencia_minima,
    MAX(afluencia) AS afluencia_maxima,
    ROUND(AVG(afluencia), 2) AS afluencia_promedio
FROM practica01.metro_desglosada_raw;


-- 4.3 Buscar duplicados exactos en Metro_simple
SELECT COUNT(*) AS duplicados_exactos
FROM (
    SELECT
        fecha,
        anio,
        mes,
        linea,
        estacion,
        afluencia,
        COUNT(*) AS veces
    FROM practica01.metro_simple_raw
    GROUP BY
        fecha,
        anio,
        mes,
        linea,
        estacion,
        afluencia
    HAVING COUNT(*) > 1
) t;

-- Buscar duplicados exactos en Metro_desglosada
SELECT COUNT(*) AS duplicados_exactos
FROM (
    SELECT
        fecha,
        mes,
        anio,
        linea,
        estacion,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces
    FROM practica01.metro_desglosada_raw
    GROUP BY
        fecha,
        mes,
        anio,
        linea,
        estacion,
        tipo_pago,
        afluencia
    HAVING COUNT(*) > 1
) t;


-- 4.4 Buscar duplicados segun la granularidad esperada en Metro_simple
SELECT
    fecha,
    linea,
    estacion,
    COUNT(*) AS cantidad
FROM practica01.metro_simple_raw
GROUP BY fecha, linea, estacion
HAVING COUNT(*) > 1
ORDER BY cantidad DESC, fecha
LIMIT 100;

-- Buscar duplicados segun la granularidad esperada en Metro_desglosada
SELECT
    fecha,
    linea,
    estacion,
    tipo_pago,
    COUNT(*) AS cantidad
FROM practica01.metro_desglosada_raw
GROUP BY fecha, linea, estacion, tipo_pago
HAVING COUNT(*) > 1
ORDER BY cantidad DESC, fecha
LIMIT 100;


-- 4.5 Revisar categorias de lineas en Metro_simple
SELECT
    linea,
    COUNT(*) AS registros
FROM practica01.metro_simple_raw
GROUP BY linea
ORDER BY linea;

-- Revisar categorias de lineas en Metro_desglosada
SELECT
    linea,
    COUNT(*) AS registros
FROM practica01.metro_desglosada_raw
GROUP BY linea
ORDER BY linea;


-- 4.6 Revisar tipo_pago (Solo en Metro desglosada)
SELECT
    tipo_pago,
    COUNT(*) AS registros,
    SUM(afluencia) AS afluencia_total
FROM practica01.metro_desglosada_raw
GROUP BY tipo_pago
ORDER BY tipo_pago;


-- 4.7 Detectar textos posiblemente corruptos en Metro_simple
SELECT DISTINCT linea
FROM practica01.metro_simple_raw
WHERE linea LIKE '%Ã%';

SELECT DISTINCT estacion
FROM practica01.metro_simple_raw
WHERE estacion LIKE '%Ã%'
ORDER BY estacion;

-- Detectar textos posiblemente corruptos en Metro_desglosada
SELECT DISTINCT linea
FROM practica01.metro_desglosada_raw
WHERE linea LIKE '%Ã%';

SELECT DISTINCT estacion
FROM practica01.metro_desglosada_raw
WHERE estacion LIKE '%Ã%'
ORDER BY estacion;


-- Para cuantificar exactamente el fenomeno
SELECT
    COUNT(*) AS grupos_repetidos,
    SUM(cantidad - 1) AS registros_excedentes
FROM (
    SELECT
        fecha,
        linea,
        estacion,
        COUNT(*) AS cantidad
    FROM practica01.metro_simple_raw
    GROUP BY fecha, linea, estacion
    HAVING COUNT(*) > 1
) t;

-- Revisar los valores concretos
SELECT
    COUNT(*) AS grupos_repetidos,
    SUM(cantidad - 1) AS registros_excedentes
FROM (
    SELECT
        fecha,
        linea,
        estacion,
        COUNT(*) AS cantidad
    FROM practica01.metro_simple_raw
    GROUP BY fecha, linea, estacion
    HAVING COUNT(*) > 1
) t;


-- Para detectar nombres distintos de estacion con caracteres
-- potencialmente mal codificados presentes en tales registros.
SELECT COUNT(DISTINCT estacion) AS estaciones_corruptas_distintas
FROM practica01.metro_simple_raw
WHERE estacion LIKE '%Ã%';

SELECT COUNT(DISTINCT estacion) AS estaciones_corruptas_distintas
FROM practica01.metro_simple_raw
WHERE estacion LIKE '%Ã%';

SELECT COUNT(*) AS registros_afectados_estacion
FROM practica01.metro_simple_raw
WHERE estacion LIKE '%Ã%';

SELECT COUNT(*) AS registros_afectados_estacion
FROM practica01.metro_desglosada_raw
WHERE estacion LIKE '%Ã%';

SELECT
    COUNT(DISTINCT linea) AS lineas_corruptas_distintas,
    COUNT(*) AS registros_afectados
FROM practica01.metro_simple_raw
WHERE linea LIKE '%Ã%';

SELECT
    COUNT(DISTINCT linea) AS lineas_corruptas_distintas,
    COUNT(*) AS registros_afectados
FROM practica01.metro_desglosada_raw
WHERE linea LIKE '%Ã%';


-- Valores Atipicos para metro_simple
WITH cuartiles AS (
    SELECT
        percentile_cont(0.25) WITHIN GROUP (ORDER BY afluencia) AS q1,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY afluencia) AS q3
    FROM practica01.metro_simple_raw
),
limites AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q1 - 1.5 * (q3 - q1) AS limite_inferior,
        q3 + 1.5 * (q3 - q1) AS limite_superior
    FROM cuartiles
)
SELECT
    q1,
    q3,
    iqr,
    limite_inferior,
    limite_superior,
    COUNT(*) FILTER (
        WHERE afluencia < limite_inferior
           OR afluencia > limite_superior
    ) AS posibles_outliers
FROM practica01.metro_simple_raw
CROSS JOIN limites
GROUP BY q1, q3, iqr, limite_inferior, limite_superior;

-- Valores Atipicos para metro_desglosada
WITH cuartiles AS (
    SELECT
        percentile_cont(0.25) WITHIN GROUP (ORDER BY afluencia) AS q1,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY afluencia) AS q3
    FROM practica01.metro_desglosada_raw
),
limites AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q1 - 1.5 * (q3 - q1) AS limite_inferior,
        q3 + 1.5 * (q3 - q1) AS limite_superior
    FROM cuartiles
)
SELECT
    q1,
    q3,
    iqr,
    limite_inferior,
    limite_superior,
    COUNT(*) FILTER (
        WHERE afluencia < limite_inferior
           OR afluencia > limite_superior
    ) AS posibles_outliers
FROM practica01.metro_desglosada_raw
CROSS JOIN limites
GROUP BY q1, q3, iqr, limite_inferior, limite_superior;



SELECT COUNT(*) AS inconsistencias_anio
FROM practica01.metro_simple_raw
WHERE anio <> EXTRACT(YEAR FROM fecha);

SELECT COUNT(*) AS inconsistencias_anio
FROM practica01.metro_desglosada_raw
WHERE anio <> EXTRACT(YEAR FROM fecha);

SELECT DISTINCT mes
FROM practica01.metro_simple_raw
ORDER BY mes;



SELECT
    fecha,
    linea,
    estacion,
    ARRAY_AGG(afluencia ORDER BY afluencia) AS valores_afluencia,
    COUNT(*) AS cantidad
FROM practica01.metro_simple_raw
GROUP BY fecha, linea, estacion
HAVING COUNT(*) > 1
ORDER BY fecha;

SELECT COUNT(DISTINCT estacion) AS estaciones_corruptas_distintas
FROM practica01.metro_desglosada_raw
WHERE estacion LIKE '%Ã%';


SELECT DISTINCT mes
FROM practica01.metro_desglosada_raw
ORDER BY mes;