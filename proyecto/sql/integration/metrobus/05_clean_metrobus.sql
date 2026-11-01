/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    CAPA CLEAN

    Objetivos:
    - conservar el 100 % de los registros;
    - homologar las variantes textuales de linea;
    - derivar variables temporales;
    - preservar NULL como afluencia no disponible;
    - generar indicadores de calidad;
    - conservar valores decimales de afluencia;
    - marcar posibles outliers sin eliminarlos.

    IMPORTANTE:
    - RAW permanece intacto.
    - STAGING permanece intacto.
    - TYPED permanece intacto.
    - No se eliminan NaN/NULL.
    - No se reemplazan NULL por cero.
    - No se eliminan outliers.
    - No se eliminan registros.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. PRECONDICIONES DE TYPED
-- =========================================================

DO $$
DECLARE
    simple_count       BIGINT;
    desglosada_count   BIGINT;

    simple_null        BIGINT;
    desglosada_null    BIGINT;

    lineas_invalidas_simple BIGINT;
    lineas_invalidas_desg   BIGINT;

    tipos_pago_invalidos BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO simple_count
    FROM proyecto.metrobus_simple_typed;

    SELECT COUNT(*)
    INTO desglosada_count
    FROM proyecto.metrobus_desglosada_typed;


    IF simple_count <> 54159 THEN
        RAISE EXCEPTION
            'TYPED Simple cambió. Esperado: 54159. Obtenido: %',
            simple_count;
    END IF;


    IF desglosada_count <> 29386 THEN
        RAISE EXCEPTION
            'TYPED Desglosada cambió. Esperado: 29386. Obtenido: %',
            desglosada_count;
    END IF;


    SELECT COUNT(*)
    INTO simple_null
    FROM proyecto.metrobus_simple_typed
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO desglosada_null
    FROM proyecto.metrobus_desglosada_typed
    WHERE afluencia IS NULL;


    IF simple_null <> 17227 THEN
        RAISE EXCEPTION
            'NULL Simple cambió. Esperado: 17227. Obtenido: %',
            simple_null;
    END IF;


    IF desglosada_null <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en Desglosada: %',
            desglosada_null;
    END IF;


    -- Solo se aceptan líneas lógicas 1 a 7.

    SELECT COUNT(*)
    INTO lineas_invalidas_simple
    FROM proyecto.metrobus_simple_typed
    WHERE regexp_replace(
              BTRIM(linea),
              '[^0-9]',
              '',
              'g'
          ) NOT IN ('1','2','3','4','5','6','7');


    SELECT COUNT(*)
    INTO lineas_invalidas_desg
    FROM proyecto.metrobus_desglosada_typed
    WHERE regexp_replace(
              BTRIM(linea),
              '[^0-9]',
              '',
              'g'
          ) NOT IN ('1','2','3','4','5','6','7');


    IF lineas_invalidas_simple <> 0
       OR lineas_invalidas_desg <> 0 THEN

        RAISE EXCEPTION
            'Se detectaron líneas no contempladas. Simple: %, Desglosada: %',
            lineas_invalidas_simple,
            lineas_invalidas_desg;

    END IF;


    -- El perfilado encontró únicamente Prepago y Gratuidad.

    SELECT COUNT(*)
    INTO tipos_pago_invalidos
    FROM proyecto.metrobus_desglosada_typed
    WHERE BTRIM(tipo_pago) NOT IN (
        'Prepago',
        'Gratuidad'
    );


    IF tipos_pago_invalidos <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron tipos de pago no contemplados: %',
            tipos_pago_invalidos;
    END IF;


    RAISE NOTICE
        'Precondiciones CLEAN correctas. Simple: %, Desglosada: %, NULL Simple: %',
        simple_count,
        desglosada_count,
        simple_null;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.metrobus_simple_clean;
DROP TABLE IF EXISTS proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 5. ESTRUCTURA CLEAN - SIMPLE
-- =========================================================

CREATE TABLE proyecto.metrobus_simple_clean (
    fecha                          DATE,
    anio                           SMALLINT,
    mes                            TEXT,

    mes_num                        SMALLINT,
    dia_semana_num                 SMALLINT,
    dia_semana                     TEXT,
    es_fin_semana                  BOOLEAN,

    linea                          TEXT,

    afluencia                      NUMERIC,

    es_afluencia_no_disponible     BOOLEAN,
    es_afluencia_cero              BOOLEAN,
    es_colision_clave              BOOLEAN,
    es_outlier_iqr_global          BOOLEAN,
    es_linea_homologada            BOOLEAN
);


-- =========================================================
-- 6. ESTRUCTURA CLEAN - DESGLOSADA
-- =========================================================

CREATE TABLE proyecto.metrobus_desglosada_clean (
    fecha                          DATE,
    anio                           SMALLINT,
    mes                            TEXT,

    mes_num                        SMALLINT,
    dia_semana_num                 SMALLINT,
    dia_semana                     TEXT,
    es_fin_semana                  BOOLEAN,

    linea                          TEXT,
    tipo_pago                      TEXT,

    afluencia                      NUMERIC,

    es_afluencia_no_disponible     BOOLEAN,
    es_afluencia_cero              BOOLEAN,
    es_colision_clave              BOOLEAN,
    es_outlier_iqr_global          BOOLEAN,
    es_linea_homologada            BOOLEAN
);


-- =========================================================
-- 7. CLEAN - SIMPLE
-- =========================================================

WITH normalizado AS (

    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        BTRIM(linea) AS linea_original,

        'Línea ' ||
        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea,

        afluencia

    FROM proyecto.metrobus_simple_typed
),

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia)
            AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia)
            AS q3

    FROM normalizado

    WHERE afluencia IS NOT NULL
),

preparado AS (

    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea
        ) AS cantidad_clave,

        c.q1,
        c.q3,

        c.q3 - c.q1 AS iqr

    FROM normalizado AS n

    CROSS JOIN cuartiles AS c
)

INSERT INTO proyecto.metrobus_simple_clean (
    fecha,
    anio,
    mes,
    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,
    linea,
    afluencia,
    es_afluencia_no_disponible,
    es_afluencia_cero,
    es_colision_clave,
    es_outlier_iqr_global,
    es_linea_homologada
)

SELECT
    fecha,

    anio,

    mes,

    EXTRACT(MONTH FROM fecha)::SMALLINT,

    EXTRACT(ISODOW FROM fecha)::SMALLINT,

    CASE EXTRACT(ISODOW FROM fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END,

    EXTRACT(ISODOW FROM fecha) IN (6, 7),

    linea,

    afluencia,

    afluencia IS NULL,

    COALESCE(
        afluencia = 0,
        FALSE
    ),

    cantidad_clave > 1,

    CASE
        WHEN afluencia IS NULL
        THEN FALSE

        ELSE (
            afluencia < q1 - 1.5 * iqr
            OR
            afluencia > q3 + 1.5 * iqr
        )
    END,

    linea_original <> linea

FROM preparado;


-- =========================================================
-- 8. CLEAN - DESGLOSADA
-- =========================================================

WITH normalizado AS (

    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        BTRIM(linea) AS linea_original,

        'Línea ' ||
        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea,

        BTRIM(tipo_pago) AS tipo_pago,

        afluencia

    FROM proyecto.metrobus_desglosada_typed
),

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia)
            AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia)
            AS q3

    FROM normalizado

    WHERE afluencia IS NOT NULL
),

preparado AS (

    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea,
                tipo_pago
        ) AS cantidad_clave,

        c.q1,
        c.q3,

        c.q3 - c.q1 AS iqr

    FROM normalizado AS n

    CROSS JOIN cuartiles AS c
)

INSERT INTO proyecto.metrobus_desglosada_clean (
    fecha,
    anio,
    mes,
    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,
    linea,
    tipo_pago,
    afluencia,
    es_afluencia_no_disponible,
    es_afluencia_cero,
    es_colision_clave,
    es_outlier_iqr_global,
    es_linea_homologada
)

SELECT
    fecha,

    anio,

    mes,

    EXTRACT(MONTH FROM fecha)::SMALLINT,

    EXTRACT(ISODOW FROM fecha)::SMALLINT,

    CASE EXTRACT(ISODOW FROM fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END,

    EXTRACT(ISODOW FROM fecha) IN (6, 7),

    linea,

    tipo_pago,

    afluencia,

    afluencia IS NULL,

    COALESCE(
        afluencia = 0,
        FALSE
    ),

    cantidad_clave > 1,

    CASE
        WHEN afluencia IS NULL
        THEN FALSE

        ELSE (
            afluencia < q1 - 1.5 * iqr
            OR
            afluencia > q3 + 1.5 * iqr
        )
    END,

    linea_original <> linea

FROM preparado;


-- =========================================================
-- 9. CONCILIACIÓN TYPED VS CLEAN
-- =========================================================

SELECT
    'Metrobús Simple' AS fuente,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_typed)
    ) AS diferencia

UNION ALL

SELECT
    'Metrobús Desglosada',

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_typed),

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_clean),

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_typed)
    );


-- =========================================================
-- 10. DOMINIO DE LÍNEA DESPUÉS DE HOMOLOGAR
-- =========================================================

SELECT
    'Simple' AS fuente,
    linea,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_clean
GROUP BY linea

UNION ALL

SELECT
    'Desglosada',
    linea,
    COUNT(*)
FROM proyecto.metrobus_desglosada_clean
GROUP BY linea

ORDER BY
    fuente,
    linea;


-- =========================================================
-- 11. CANTIDAD DE LÍNEAS LÓGICAS
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(DISTINCT linea) AS lineas_distintas
FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',
    COUNT(DISTINCT linea)
FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 12. TIPO DE PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros
FROM proyecto.metrobus_desglosada_clean
GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 13. FLAGS DE CALIDAD
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS afluencia_no_disponible,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers,

    COUNT(*) FILTER (
        WHERE es_linea_homologada
    ) AS lineas_homologadas

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ),

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ),

    COUNT(*) FILTER (
        WHERE es_linea_homologada
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 14. NULL Y BANDERA DE NO DISPONIBILIDAD
--
-- Ambas expresiones deben coincidir exactamente.
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS bandera_no_disponible,

    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    ) AS inconsistencias

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ),

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ),

    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 15. VALORES DECIMALES CONSERVADOS
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    ) AS valores_decimales

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 16. COHERENCIA TEMPORAL CLEAN
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE anio <>
              EXTRACT(YEAR FROM fecha)::SMALLINT
    ) AS error_anio,

    COUNT(*) FILTER (
        WHERE mes_num <>
              EXTRACT(MONTH FROM fecha)::SMALLINT
    ) AS error_mes,

    COUNT(*) FILTER (
        WHERE dia_semana_num <>
              EXTRACT(ISODOW FROM fecha)::SMALLINT
    ) AS error_dia_semana

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE anio <>
              EXTRACT(YEAR FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE mes_num <>
              EXTRACT(MONTH FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE dia_semana_num <>
              EXTRACT(ISODOW FROM fecha)::SMALLINT
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 17. RECONCILIACIÓN SIMPLE VS DESGLOSADA EN CLEAN
-- =========================================================

WITH simple AS (

    SELECT
        fecha,
        linea,
        afluencia AS afluencia_simple

    FROM proyecto.metrobus_simple_clean

    WHERE afluencia IS NOT NULL
),

desglosada AS (

    SELECT
        fecha,
        linea,
        SUM(afluencia) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_clean

    GROUP BY
        fecha,
        linea
),

comparacion AS (

    SELECT
        s.fecha,
        s.linea,

        s.afluencia_simple,
        d.afluencia_desglosada,

        s.afluencia_simple
        - d.afluencia_desglosada
            AS diferencia

    FROM simple AS s

    INNER JOIN desglosada AS d
        ON s.fecha = d.fecha
       AND s.linea = d.linea
)

SELECT
    COUNT(*) AS claves_comparables,

    COUNT(*) FILTER (
        WHERE diferencia = 0
    ) AS coincidencias_exactas,

    COUNT(*) FILTER (
        WHERE diferencia <> 0
    ) AS diferencias,

    MIN(diferencia) AS diferencia_min,

    AVG(diferencia)::numeric(20,6)
        AS diferencia_media,

    MAX(diferencia) AS diferencia_max

FROM comparacion;


-- =========================================================
-- 18. VALIDACIÓN AUTOMÁTICA CLEAN
-- =========================================================

DO $$
DECLARE
    simple_count       BIGINT;
    desglosada_count   BIGINT;

    simple_null        BIGINT;
    desglosada_null    BIGINT;

    simple_colisiones  BIGINT;
    desg_colisiones    BIGINT;

    simple_lineas      BIGINT;
    desg_lineas        BIGINT;

    simple_outliers    BIGINT;
    desg_outliers      BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO simple_count
    FROM proyecto.metrobus_simple_clean;


    SELECT COUNT(*)
    INTO desglosada_count
    FROM proyecto.metrobus_desglosada_clean;


    IF simple_count <> 54159 THEN
        RAISE EXCEPTION
            'CLEAN Simple incorrecto. Esperado: 54159. Obtenido: %',
            simple_count;
    END IF;


    IF desglosada_count <> 29386 THEN
        RAISE EXCEPTION
            'CLEAN Desglosada incorrecto. Esperado: 29386. Obtenido: %',
            desglosada_count;
    END IF;


    SELECT COUNT(*)
    INTO simple_null
    FROM proyecto.metrobus_simple_clean
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO desglosada_null
    FROM proyecto.metrobus_desglosada_clean
    WHERE afluencia IS NULL;


    IF simple_null <> 17227 THEN
        RAISE EXCEPTION
            'NULL Simple inesperados: %',
            simple_null;
    END IF;


    IF desglosada_null <> 0 THEN
        RAISE EXCEPTION
            'NULL Desglosada inesperados: %',
            desglosada_null;
    END IF;


    SELECT COUNT(*)
    INTO simple_colisiones
    FROM proyecto.metrobus_simple_clean
    WHERE es_colision_clave;


    SELECT COUNT(*)
    INTO desg_colisiones
    FROM proyecto.metrobus_desglosada_clean
    WHERE es_colision_clave;


    IF simple_colisiones <> 0
       OR desg_colisiones <> 0 THEN

        RAISE EXCEPTION
            'Se generaron colisiones después de CLEAN. Simple: %, Desglosada: %',
            simple_colisiones,
            desg_colisiones;

    END IF;


    SELECT COUNT(DISTINCT linea)
    INTO simple_lineas
    FROM proyecto.metrobus_simple_clean;


    SELECT COUNT(DISTINCT linea)
    INTO desg_lineas
    FROM proyecto.metrobus_desglosada_clean;


    IF simple_lineas <> 7
       OR desg_lineas <> 7 THEN

        RAISE EXCEPTION
            'Dominio de líneas inesperado. Simple: %, Desglosada: %',
            simple_lineas,
            desg_lineas;

    END IF;


    SELECT COUNT(*)
    INTO simple_outliers
    FROM proyecto.metrobus_simple_clean
    WHERE es_outlier_iqr_global;


    SELECT COUNT(*)
    INTO desg_outliers
    FROM proyecto.metrobus_desglosada_clean
    WHERE es_outlier_iqr_global;


    IF simple_outliers <> 3000 THEN
        RAISE EXCEPTION
            'Outliers Simple distintos al perfilado. Esperado: 3000. Obtenido: %',
            simple_outliers;
    END IF;


    IF desg_outliers <> 1090 THEN
        RAISE EXCEPTION
            'Outliers Desglosada distintos al perfilado. Esperado: 1090. Obtenido: %',
            desg_outliers;
    END IF;


    RAISE NOTICE
        'CLEAN validado. Simple: %, Desglosada: %, NULL Simple: %, Outliers Simple: %, Outliers Desglosada: %',
        simple_count,
        desglosada_count,
        simple_null,
        simple_outliers,
        desg_outliers;

END
$$;


-- =========================================================
-- 19. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;