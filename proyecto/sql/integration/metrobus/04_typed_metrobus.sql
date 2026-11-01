/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    Capa: TYPED

    Objetivo:
    convertir de manera controlada los tipos físicos
    previamente validados durante el perfilado.

    PRINCIPIOS:
    - STAGING permanece intacto.
    - No se eliminan registros.
    - No se homologan todavía categorías de linea.
    - No se corrigen outliers.
    - No se redondea afluencia.
    - Los valores decimales se conservan exactamente.
    - El literal NaN de Simple se representa como NULL.
    - NaN NO se transforma en cero.

    Evidencia previa:
    - Simple: 54,159 registros.
    - Desglosada: 29,386 registros.
    - 17,227 NaN en Simple.
    - 57 valores decimales en cada recurso.
    - 0 duplicados exactos.
    - 0 colisiones de granularidad.
    - 14,693 / 14,693 claves comparables coincidentes.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. PRECONDICIONES
--
-- Si el contenido de STAGING cambia respecto al perfilado,
-- el proceso debe detenerse.
-- =========================================================

DO $$
DECLARE
    simple_count               BIGINT;
    desglosada_count           BIGINT;

    simple_nan                 BIGINT;

    simple_afluencia_invalida  BIGINT;
    desg_afluencia_invalida    BIGINT;

    simple_fecha_invalida      BIGINT;
    desg_fecha_invalida        BIGINT;

    simple_anio_invalido       BIGINT;
    desg_anio_invalido         BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO simple_count
    FROM proyecto.metrobus_simple_stage;

    SELECT COUNT(*)
    INTO desglosada_count
    FROM proyecto.metrobus_desglosada_stage;


    IF simple_count <> 54159 THEN
        RAISE EXCEPTION
            'STAGING Simple cambió. Esperado: 54159. Obtenido: %',
            simple_count;
    END IF;


    IF desglosada_count <> 29386 THEN
        RAISE EXCEPTION
            'STAGING Desglosada cambió. Esperado: 29386. Obtenido: %',
            desglosada_count;
    END IF;


    -- -----------------------------------------------------
    -- Fechas
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_fecha_invalida
    FROM proyecto.metrobus_simple_stage
    WHERE NULLIF(BTRIM(fecha), '') IS NULL
       OR NOT pg_input_is_valid(BTRIM(fecha), 'date');


    SELECT COUNT(*)
    INTO desg_fecha_invalida
    FROM proyecto.metrobus_desglosada_stage
    WHERE NULLIF(BTRIM(fecha), '') IS NULL
       OR NOT pg_input_is_valid(BTRIM(fecha), 'date');


    IF simple_fecha_invalida <> 0
       OR desg_fecha_invalida <> 0 THEN

        RAISE EXCEPTION
            'Se detectaron fechas no convertibles. Simple: %, Desglosada: %',
            simple_fecha_invalida,
            desg_fecha_invalida;

    END IF;


    -- -----------------------------------------------------
    -- Año
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_anio_invalido
    FROM proyecto.metrobus_simple_stage
    WHERE NULLIF(BTRIM(anio), '') IS NULL
       OR NOT pg_input_is_valid(BTRIM(anio), 'smallint');


    SELECT COUNT(*)
    INTO desg_anio_invalido
    FROM proyecto.metrobus_desglosada_stage
    WHERE NULLIF(BTRIM(anio), '') IS NULL
       OR NOT pg_input_is_valid(BTRIM(anio), 'smallint');


    IF simple_anio_invalido <> 0
       OR desg_anio_invalido <> 0 THEN

        RAISE EXCEPTION
            'Se detectaron años no convertibles. Simple: %, Desglosada: %',
            simple_anio_invalido,
            desg_anio_invalido;

    END IF;


    -- -----------------------------------------------------
    -- NaN de Simple
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_nan
    FROM proyecto.metrobus_simple_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';


    IF simple_nan <> 17227 THEN
        RAISE EXCEPTION
            'El número de NaN cambió. Esperado: 17227. Obtenido: %',
            simple_nan;
    END IF;


    -- -----------------------------------------------------
    -- Afluencia Simple
    --
    -- Solo se permite:
    --   1) NUMERIC válido
    --   2) literal NaN
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_afluencia_invalida
    FROM proyecto.metrobus_simple_stage
    WHERE
        NULLIF(BTRIM(afluencia), '') IS NULL

        OR (
            LOWER(BTRIM(afluencia)) <> 'nan'
            AND NOT pg_input_is_valid(
                BTRIM(afluencia),
                'numeric'
            )
        );


    IF simple_afluencia_invalida <> 0 THEN
        RAISE EXCEPTION
            'Simple contiene afluencias no contempladas: %',
            simple_afluencia_invalida;
    END IF;


    -- -----------------------------------------------------
    -- Afluencia Desglosada
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO desg_afluencia_invalida
    FROM proyecto.metrobus_desglosada_stage
    WHERE
        NULLIF(BTRIM(afluencia), '') IS NULL
        OR NOT pg_input_is_valid(
            BTRIM(afluencia),
            'numeric'
        );


    IF desg_afluencia_invalida <> 0 THEN
        RAISE EXCEPTION
            'Desglosada contiene afluencias no convertibles: %',
            desg_afluencia_invalida;
    END IF;


    RAISE NOTICE
        'Precondiciones TYPED correctas. Simple: %, Desglosada: %, NaN Simple: %',
        simple_count,
        desglosada_count,
        simple_nan;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN DE CONSTRUCCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.metrobus_simple_typed;
DROP TABLE IF EXISTS proyecto.metrobus_desglosada_typed;


-- =========================================================
-- 5. TYPED - SIMPLE
-- =========================================================

CREATE TABLE proyecto.metrobus_simple_typed (
    fecha       DATE,
    anio        SMALLINT,
    mes         TEXT,
    linea       TEXT,

    /*
        NUMERIC se utiliza porque el perfilado detectó
        valores decimales reales.

        No se fija escala para evitar pérdida de precisión.
    */
    afluencia   NUMERIC
);


-- =========================================================
-- 6. TYPED - DESGLOSADA
-- =========================================================

CREATE TABLE proyecto.metrobus_desglosada_typed (
    fecha       DATE,
    mes         TEXT,
    anio        SMALLINT,
    linea       TEXT,
    tipo_pago   TEXT,
    afluencia   NUMERIC
);


-- =========================================================
-- 7. STAGING -> TYPED - SIMPLE
--
-- El literal NaN se transforma a NULL.
--
-- Su representación original continúa disponible
-- en metrobus_simple_stage.
-- =========================================================

INSERT INTO proyecto.metrobus_simple_typed (
    fecha,
    anio,
    mes,
    linea,
    afluencia
)

SELECT
    BTRIM(fecha)::DATE,

    BTRIM(anio)::SMALLINT,

    BTRIM(mes),

    BTRIM(linea),

    CASE
        WHEN LOWER(BTRIM(afluencia)) = 'nan'
        THEN NULL

        ELSE BTRIM(afluencia)::NUMERIC
    END

FROM proyecto.metrobus_simple_stage;


-- =========================================================
-- 8. STAGING -> TYPED - DESGLOSADA
-- =========================================================

INSERT INTO proyecto.metrobus_desglosada_typed (
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia
)

SELECT
    BTRIM(fecha)::DATE,

    BTRIM(mes),

    BTRIM(anio)::SMALLINT,

    BTRIM(linea),

    BTRIM(tipo_pago),

    BTRIM(afluencia)::NUMERIC

FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 9. CONCILIACIÓN STAGING VS TYPED
-- =========================================================

SELECT
    'Metrobús Simple' AS fuente,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_stage) AS stage,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_typed) AS typed,

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_typed)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_stage)
    ) AS diferencia

UNION ALL

SELECT
    'Metrobús Desglosada',

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_stage),

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_typed),

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_typed)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_stage)
    );


-- =========================================================
-- 10. VERIFICACIÓN DE TIPOS
-- =========================================================

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name IN (
      'metrobus_simple_typed',
      'metrobus_desglosada_typed'
  )
ORDER BY
    table_name,
    ordinal_position;


-- =========================================================
-- 11. NULL GENERADOS A PARTIR DE NaN
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.metrobus_simple_typed

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    )

FROM proyecto.metrobus_desglosada_typed;


-- =========================================================
-- 12. VALORES CON COMPONENTE DECIMAL
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    ) AS valores_decimales

FROM proyecto.metrobus_simple_typed

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    )

FROM proyecto.metrobus_desglosada_typed;


-- =========================================================
-- 13. RANGOS POST-TIPADO
-- =========================================================

SELECT
    'Simple' AS fuente,

    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,

    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max,

    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max

FROM proyecto.metrobus_simple_typed

UNION ALL

SELECT
    'Desglosada',

    MIN(fecha),
    MAX(fecha),

    MIN(anio),
    MAX(anio),

    MIN(afluencia),
    MAX(afluencia)

FROM proyecto.metrobus_desglosada_typed;


-- =========================================================
-- 14. COMPROBACIÓN DE CATEGORÍAS DE LINEA
--
-- TYPED todavía NO debe homologarlas.
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(DISTINCT linea) AS categorias_linea
FROM proyecto.metrobus_simple_typed

UNION ALL

SELECT
    'Desglosada',
    COUNT(DISTINCT linea)
FROM proyecto.metrobus_desglosada_typed;


-- =========================================================
-- 15. RECONCILIACIÓN SIMPLE VS DESGLOSADA
-- POST-TIPADO
--
-- Debe conservar la relación demostrada en STAGING.
-- =========================================================

WITH simple AS (

    SELECT
        fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        afluencia AS afluencia_simple

    FROM proyecto.metrobus_simple_typed

    WHERE afluencia IS NOT NULL
),

desglosada AS (

    SELECT
        fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        SUM(afluencia) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_typed

    GROUP BY
        fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        )
),

comparacion AS (

    SELECT
        s.fecha,
        s.linea_num,

        s.afluencia_simple,
        d.afluencia_desglosada,

        s.afluencia_simple
        - d.afluencia_desglosada
            AS diferencia

    FROM simple AS s

    INNER JOIN desglosada AS d
        ON s.fecha = d.fecha
       AND s.linea_num = d.linea_num
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
-- 16. VALIDACIÓN AUTOMÁTICA DE LA CAPA TYPED
-- =========================================================

DO $$
DECLARE
    simple_typed_count       BIGINT;
    desg_typed_count         BIGINT;

    simple_null              BIGINT;
    desg_null                BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO simple_typed_count
    FROM proyecto.metrobus_simple_typed;


    SELECT COUNT(*)
    INTO desg_typed_count
    FROM proyecto.metrobus_desglosada_typed;


    SELECT COUNT(*)
    INTO simple_null
    FROM proyecto.metrobus_simple_typed
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO desg_null
    FROM proyecto.metrobus_desglosada_typed
    WHERE afluencia IS NULL;


    IF simple_typed_count <> 54159 THEN

        RAISE EXCEPTION
            'Conteo TYPED Simple incorrecto: %',
            simple_typed_count;

    END IF;


    IF desg_typed_count <> 29386 THEN

        RAISE EXCEPTION
            'Conteo TYPED Desglosada incorrecto: %',
            desg_typed_count;

    END IF;


    IF simple_null <> 17227 THEN

        RAISE EXCEPTION
            'NULL de afluencia Simple inesperados. Esperado: 17227. Obtenido: %',
            simple_null;

    END IF;


    IF desg_null <> 0 THEN

        RAISE EXCEPTION
            'Se generaron NULL inesperados en Desglosada: %',
            desg_null;

    END IF;


    RAISE NOTICE
        'TYPED validado. Simple: %, Desglosada: %, NULL Simple: %',
        simple_typed_count,
        desg_typed_count,
        simple_null;

END
$$;


-- =========================================================
-- 17. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;