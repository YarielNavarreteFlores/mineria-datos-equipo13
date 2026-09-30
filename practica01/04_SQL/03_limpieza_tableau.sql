-- 6.2 Crear metro_simple_clean
CREATE TABLE practica01.metro_simple_clean AS
WITH encoding_corregido AS (
    SELECT
        fecha,
        anio,
        mes,
        CASE
            WHEN linea LIKE '%Ã%'
            THEN convert_from(convert_to(linea, 'LATIN1'), 'UTF8')
            ELSE linea
        END AS linea_tmp,
        CASE
            WHEN estacion LIKE '%Ã%'
            THEN convert_from(convert_to(estacion, 'LATIN1'), 'UTF8')
            ELSE estacion
        END AS estacion,
        afluencia
    FROM practica01.metro_simple_raw
),
normalizado AS (
    SELECT
        fecha,
        anio,
        mes,
        -- Homologamos:
        -- "Linea 1" y "Línea 1"
        -- a una sola categoría: "Línea 1"
        regexp_replace(
            linea_tmp,
            '^L[ií]nea\s*',
            'Línea ',
            'i'
        ) AS linea,
        estacion,
        afluencia
    FROM encoding_corregido
),
cuartiles AS (
    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,
        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3
    FROM normalizado
),
preparado AS (
    SELECT
        n.*,
        COUNT(*) OVER (
            PARTITION BY fecha, linea, estacion
        ) AS cantidad_clave,
        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr
    FROM normalizado n
    CROSS JOIN cuartiles c
)
SELECT
    fecha,
    anio,
    mes,
    EXTRACT(MONTH FROM fecha)::INTEGER AS mes_num,
    EXTRACT(ISODOW FROM fecha)::INTEGER AS dia_semana_num,
    CASE EXTRACT(ISODOW FROM fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana,
    CASE
        WHEN EXTRACT(ISODOW FROM fecha) IN (6,7)
        THEN TRUE
        ELSE FALSE
    END AS es_fin_semana,
    linea,
    estacion,
    afluencia,
    CASE
        WHEN afluencia = 0 THEN TRUE
        ELSE FALSE
    END AS es_afluencia_cero,
    CASE
        WHEN cantidad_clave > 1 THEN TRUE
        ELSE FALSE
    END AS es_colision_clave,
    CASE
        WHEN afluencia < q1 - 1.5 * iqr
          OR afluencia > q3 + 1.5 * iqr
        THEN TRUE
        ELSE FALSE
    END AS es_outlier_iqr
FROM preparado;

-- Parece bastante codigo, pero conceptualmente hace solo cuatro cosas:
-- arreglar caracteres
--         ↓
-- homologar línea
--        ↓
-- crear variables temporales
--       ↓
-- marcar casos especiales



-- 6.3 Porque agregamos esas columnas?
-- Ahora cada fila tendra, ademas de los datos originales:
-- mes_num
-- dia_semana_num
-- dia_semana
-- es_fin_semana
-- es_afluencia_cero
-- es_colision_clave
-- es_outlier_iqr

-- Por ejemplo:
-- fecha             2025-09-22
-- anio              2025
-- mes               Septiembre
-- mes_num           9
-- dia_semana_num    1
-- dia_semana        Lunes
-- es_fin_semana     false

-- linea             Línea 3
-- estacion          Hidalgo
-- afluencia         43892

-- es_afluencia_cero false
-- es_colision_clave false
-- es_outlier_iqr    false

-- Especialmente mes_num, porque si utilizaramos solamente los nombres:
-- Abril
-- Agosto
-- Diciembre
-- Enero
-- ...
-- Tableau podria ordenarlos alfabeticamente.
-- Con: mes_num = 1 ... 12 impone el orden cronologico correcto.



-- 6.4 Crear metro_desglosada_clean
CREATE TABLE practica01.metro_desglosada_clean AS
WITH encoding_corregido AS (

    SELECT
        fecha,
        anio,
        mes,

        CASE
            WHEN linea LIKE '%Ã%'
            THEN convert_from(convert_to(linea, 'LATIN1'), 'UTF8')
            ELSE linea
        END AS linea_tmp,

        CASE
            WHEN estacion LIKE '%Ã%'
            THEN convert_from(convert_to(estacion, 'LATIN1'), 'UTF8')
            ELSE estacion
        END AS estacion,

        tipo_pago,
        afluencia

    FROM practica01.metro_desglosada_raw
),
normalizado AS (

    SELECT
        fecha,
        anio,
        mes,

        regexp_replace(
            linea_tmp,
            '^L[ií]nea\s*',
            'Línea ',
            'i'
        ) AS linea,

        estacion,
        tipo_pago,
        afluencia

    FROM encoding_corregido
),
cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3

    FROM normalizado
),
preparado AS (

    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY fecha,
                         linea,
                         estacion,
                         tipo_pago
        ) AS cantidad_clave,

        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM normalizado n
    CROSS JOIN cuartiles c
)
SELECT
    fecha,
    anio,
    mes,
    EXTRACT(MONTH FROM fecha)::INTEGER AS mes_num,
    EXTRACT(ISODOW FROM fecha)::INTEGER AS dia_semana_num,
    CASE EXTRACT(ISODOW FROM fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana,
    CASE
        WHEN EXTRACT(ISODOW FROM fecha) IN (6,7)
        THEN TRUE
        ELSE FALSE
    END AS es_fin_semana,
    linea,
    estacion,
    tipo_pago,
    afluencia,
    CASE
        WHEN afluencia = 0 THEN TRUE
        ELSE FALSE
    END AS es_afluencia_cero,
    CASE
        WHEN cantidad_clave > 1 THEN TRUE
        ELSE FALSE
    END AS es_colision_clave,
    CASE
        WHEN afluencia < q1 - 1.5 * iqr
          OR afluencia > q3 + 1.5 * iqr
        THEN TRUE
        ELSE FALSE
    END AS es_outlier_iqr
FROM preparado;



-- 6.5 Validamos que NO destruimos informacion
SELECT COUNT(*)
FROM practica01.metro_simple_clean;

SELECT COUNT(*)
FROM practica01.metro_desglosada_clean;

-- Debemos seguir teniendo:
-- metro_simple_clean
-- 1,180,920

-- metro_desglosada_clean
-- 1,192,230



-- 6.6 Comprobar el encoding
SELECT COUNT(*)
FROM practica01.metro_simple_clean
WHERE linea LIKE '%Ã%'
   OR estacion LIKE '%Ã%';

SELECT COUNT(*)
FROM practica01.metro_desglosada_clean
WHERE linea LIKE '%Ã%'
   OR estacion LIKE '%Ã%';
--Lo ideal es:
-- 0
-- 0

SELECT DISTINCT linea
FROM practica01.metro_simple_clean
ORDER BY linea;
-- Deberiamos tener 12 lineas, no 24.



-- 6.7 Comprobar las banderas
SELECT
    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,
    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS registros_en_colision,
    COUNT(*) FILTER (
        WHERE es_outlier_iqr
    ) AS outliers
FROM practica01.metro_simple_clean;

-- Esperamos aproximadamente:
-- ceros
-- 62,025

-- registros_en_colision
-- 62

-- outliers
-- 66,361


SELECT
    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,
    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS registros_en_colision,
    COUNT(*) FILTER (
        WHERE es_outlier_iqr
    ) AS outliers
FROM practica01.metro_desglosada_clean;

-- Esperamos aproximadamente:
-- ceros
-- 291,457

-- registros_en_colision
-- 0

-- outliers
-- 103,485



-- Crear indices para una consulta mas comoda desde Tableau.
-- Despues de validar las tablas:
CREATE INDEX idx_simple_clean_fecha
ON practica01.metro_simple_clean(fecha);
CREATE INDEX idx_simple_clean_linea
ON practica01.metro_simple_clean(linea);
CREATE INDEX idx_simple_clean_estacion
ON practica01.metro_simple_clean(estacion);
-- y luego
CREATE INDEX idx_desglosada_clean_fecha
ON practica01.metro_desglosada_clean(fecha);
CREATE INDEX idx_desglosada_clean_linea
ON practica01.metro_desglosada_clean(linea);
CREATE INDEX idx_desglosada_clean_estacion
ON practica01.metro_desglosada_clean(estacion);
CREATE INDEX idx_desglosada_clean_tipo_pago
ON practica01.metro_desglosada_clean(tipo_pago);