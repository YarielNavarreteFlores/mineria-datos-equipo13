/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

    Capa: TYPED

    Objetivo:
    convertir de manera controlada las representaciones
    TEXT de STAGING a tipos físicos adecuados, sin aplicar
    todavía homologaciones semánticas ni eliminar registros.

    Evidencia previa:
    - 7,972 registros.
    - 0 NULL / vacíos.
    - 0 fechas inválidas.
    - 0 años inválidos.
    - 7,972 afluencias numéricas.
    - 7,972 afluencias enteras.
    - 0 NaN.
    - 0 valores decimales.
    - 207 ceros.
    - 0 negativos.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.
    - Cobertura:
      2022-01-01 -> 2026-09-30.

    Representaciones originales de linea:

        Línea 1
        Línea 2
        Linea 1
        Linea 2
        Linea 3

    PRINCIPIOS:
    - STAGING permanece intacto.
    - No se eliminan registros.
    - No se homologan todavía categorías de linea.
    - No se eliminan ceros.
    - No se eliminan posibles outliers.
    - No se generan NULL artificialmente.
    - afluencia se representa como BIGINT porque todas
      las observaciones son enteras válidas.
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
-- Si STAGING cambia respecto al perfilado validado,
-- el proceso se detiene.
-- =========================================================

DO $$
DECLARE
    stage_count            BIGINT;
    vacios_count           BIGINT;
    fecha_invalida         BIGINT;
    anio_invalido          BIGINT;
    afluencia_invalida     BIGINT;
    afluencia_nan          BIGINT;
    ceros_count            BIGINT;
    decimales_count        BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.cablebus_desglosada_stage;


    IF stage_count <> 7972 THEN
        RAISE EXCEPTION
            'STAGING Cablebus cambió. Esperado: 7972. Obtenido: %',
            stage_count;
    END IF;


    -- -----------------------------------------------------
    -- NULL / vacíos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO vacios_count
    FROM proyecto.cablebus_desglosada_stage
    WHERE NULLIF(BTRIM(fecha), '') IS NULL
       OR NULLIF(BTRIM(mes), '') IS NULL
       OR NULLIF(BTRIM(anio), '') IS NULL
       OR NULLIF(BTRIM(linea), '') IS NULL
       OR NULLIF(BTRIM(tipo_pago), '') IS NULL
       OR NULLIF(BTRIM(afluencia), '') IS NULL;


    IF vacios_count <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron filas con campos vacíos: %',
            vacios_count;
    END IF;


    -- -----------------------------------------------------
    -- Fecha
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO fecha_invalida
    FROM proyecto.cablebus_desglosada_stage
    WHERE NOT pg_input_is_valid(
        BTRIM(fecha),
        'date'
    );


    IF fecha_invalida <> 0 THEN
        RAISE EXCEPTION
            'Fechas no convertibles detectadas: %',
            fecha_invalida;
    END IF;


    -- -----------------------------------------------------
    -- Año
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO anio_invalido
    FROM proyecto.cablebus_desglosada_stage
    WHERE NOT pg_input_is_valid(
        BTRIM(anio),
        'smallint'
    );


    IF anio_invalido <> 0 THEN
        RAISE EXCEPTION
            'Años no convertibles detectados: %',
            anio_invalido;
    END IF;


    -- -----------------------------------------------------
    -- NaN
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO afluencia_nan
    FROM proyecto.cablebus_desglosada_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';


    IF afluencia_nan <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron NaN inesperados: %',
            afluencia_nan;
    END IF;


    -- -----------------------------------------------------
    -- Afluencia
    --
    -- El perfilado demostró que todas las observaciones
    -- son enteros válidos.
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO afluencia_invalida
    FROM proyecto.cablebus_desglosada_stage
    WHERE NOT pg_input_is_valid(
        BTRIM(afluencia),
        'bigint'
    );


    IF afluencia_invalida <> 0 THEN
        RAISE EXCEPTION
            'Afluencias no convertibles a BIGINT: %',
            afluencia_invalida;
    END IF;


    -- -----------------------------------------------------
    -- Ceros
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO ceros_count
    FROM proyecto.cablebus_desglosada_stage
    WHERE BTRIM(afluencia)::BIGINT = 0;


    IF ceros_count <> 207 THEN
        RAISE EXCEPTION
            'Conteo de ceros cambió. Esperado: 207. Obtenido: %',
            ceros_count;
    END IF;


    -- -----------------------------------------------------
    -- Decimales
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO decimales_count
    FROM proyecto.cablebus_desglosada_stage
    WHERE pg_input_is_valid(
            BTRIM(afluencia),
            'numeric'
          )
      AND BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric);


    IF decimales_count <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron valores decimales inesperados: %',
            decimales_count;
    END IF;


    RAISE NOTICE
        'Precondiciones TYPED Cablebus correctas. Filas: %, ceros: %, NaN: %, decimales: %',
        stage_count,
        ceros_count,
        afluencia_nan,
        decimales_count;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.cablebus_desglosada_typed;


-- =========================================================
-- 5. CREAR TYPED
-- =========================================================

CREATE TABLE proyecto.cablebus_desglosada_typed (
    fecha       DATE,
    mes         TEXT,
    anio        SMALLINT,
    linea       TEXT,
    tipo_pago   TEXT,
    afluencia   BIGINT
);


-- =========================================================
-- 6. STAGING -> TYPED
--
-- Únicamente:
-- - BTRIM
-- - conversión de tipos físicos
--
-- No existe homologación semántica de linea.
-- =========================================================

INSERT INTO proyecto.cablebus_desglosada_typed (
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
    BTRIM(afluencia)::BIGINT

FROM proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 7. CONCILIACIÓN STAGING VS TYPED
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_stage)
        AS staging,

    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_typed)
        AS typed,

    (
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_typed)
        -
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_stage)
    ) AS diferencia;


-- =========================================================
-- 8. ESTRUCTURA FÍSICA RESULTANTE
-- =========================================================

SELECT
    ordinal_position,
    column_name,
    data_type

FROM information_schema.columns

WHERE table_schema = 'proyecto'
  AND table_name = 'cablebus_desglosada_typed'

ORDER BY ordinal_position;


-- =========================================================
-- 9. NULL POST-TIPADO
-- =========================================================

SELECT
    COUNT(*) AS afluencia_null
FROM proyecto.cablebus_desglosada_typed
WHERE afluencia IS NULL;


-- =========================================================
-- 10. CEROS PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.cablebus_desglosada_stage
        WHERE BTRIM(afluencia)::BIGINT = 0
    ) AS ceros_stage,

    (
        SELECT COUNT(*)
        FROM proyecto.cablebus_desglosada_typed
        WHERE afluencia = 0
    ) AS ceros_typed;


-- =========================================================
-- 11. RANGOS POST-TIPADO
-- =========================================================

SELECT
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,

    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max,

    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max

FROM proyecto.cablebus_desglosada_typed;


-- =========================================================
-- 12. REPRESENTACIONES DE LINEA PRESERVADAS
--
-- TYPED todavía debe conservar las 5 categorías.
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.cablebus_desglosada_typed

GROUP BY linea
ORDER BY fecha_min, linea;


-- =========================================================
-- 13. DOMINIO DE TIPO DE PAGO PRESERVADO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_typed

GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 14. DUPLICADOS EXACTOS POST-TIPADO
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        mes,
        anio,
        linea,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_typed

    GROUP BY
        fecha,
        mes,
        anio,
        linea,
        tipo_pago,
        afluencia

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,

    COALESCE(
        SUM(veces),
        0
    ) AS filas_involucradas

FROM grupos;


-- =========================================================
-- 15. GRANULARIDAD POST-TIPADO
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_typed

    GROUP BY
        fecha,
        linea,
        tipo_pago

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,

    COALESCE(
        SUM(veces),
        0
    ) AS filas_involucradas

FROM grupos;


-- =========================================================
-- 16. VALIDACIÓN AUTOMÁTICA TYPED
-- =========================================================

DO $$
DECLARE
    typed_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    distinct_linea_count BIGINT;
    collision_count      BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.cablebus_desglosada_typed;


    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.cablebus_desglosada_typed
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.cablebus_desglosada_typed
    WHERE afluencia = 0;


    SELECT COUNT(DISTINCT linea)
    INTO distinct_linea_count
    FROM proyecto.cablebus_desglosada_typed;


    SELECT COUNT(*)
    INTO collision_count
    FROM (
        SELECT
            fecha,
            linea,
            tipo_pago
        FROM proyecto.cablebus_desglosada_typed
        GROUP BY
            fecha,
            linea,
            tipo_pago
        HAVING COUNT(*) > 1
    ) AS colisiones;


    IF typed_count <> 7972 THEN
        RAISE EXCEPTION
            'Conteo TYPED incorrecto. Esperado: 7972. Obtenido: %',
            typed_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en afluencia TYPED: %',
            null_count;
    END IF;


    IF zero_count <> 207 THEN
        RAISE EXCEPTION
            'Ceros TYPED incorrectos. Esperado: 207. Obtenido: %',
            zero_count;
    END IF;


    IF distinct_linea_count <> 5 THEN
        RAISE EXCEPTION
            'Representaciones de linea cambiaron. Esperadas: 5. Obtenidas: %',
            distinct_linea_count;
    END IF;


    IF collision_count <> 0 THEN
        RAISE EXCEPTION
            'Se generaron colisiones inesperadas en TYPED: %',
            collision_count;
    END IF;


    RAISE NOTICE
        'TYPED Cablebus validado. Filas: %, NULL: %, ceros: %, representaciones linea: %, colisiones: %',
        typed_count,
        null_count,
        zero_count,
        distinct_linea_count,
        collision_count;

END
$$;


-- =========================================================
-- 17. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;