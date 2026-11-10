/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

    Capa: TYPED

    Objetivo:
    Convertir las representaciones TEXT de STAGING a tipos
    físicos adecuados sin aplicar todavía homologaciones
    semánticas ni eliminación de observaciones.

    PRINCIPIOS:
    - STAGING permanece intacto.
    - TYPED conserva las 41,676 filas.
    - NaN representa información no disponible y pasa a NULL.
    - NaN NO se convierte a cero.
    - Afluencia utiliza NUMERIC para preservar 53 decimales.
    - No se homologan variantes de servicio.
    - No se eliminan duplicados exactos.
    - No se eliminan colisiones.
    - No se eliminan ceros.
    - No se eliminan outliers.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.rtp_desglosada_typed;


-- =========================================================
-- 3. CREAR TYPED
-- =========================================================

CREATE TABLE proyecto.rtp_desglosada_typed AS

SELECT
    BTRIM(fecha)::date AS fecha,

    BTRIM(mes) AS mes,

    BTRIM(anio)::smallint AS anio,

    BTRIM(servicio) AS servicio,

    BTRIM(tipo_pago) AS tipo_pago,

    CASE
        WHEN LOWER(BTRIM(afluencia)) = 'nan'
            THEN NULL

        WHEN pg_input_is_valid(
            BTRIM(afluencia),
            'numeric'
        )
            THEN BTRIM(afluencia)::numeric

        ELSE NULL
    END AS afluencia

FROM proyecto.rtp_desglosada_stage;


-- =========================================================
-- 4. ESTRUCTURA FÍSICA RESULTANTE
-- =========================================================

SELECT
    ordinal_position,
    column_name,
    data_type

FROM information_schema.columns

WHERE table_schema = 'proyecto'
  AND table_name = 'rtp_desglosada_typed'

ORDER BY ordinal_position;


-- =========================================================
-- 5. CONCILIACIÓN DE FILAS
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_stage)
        AS staging,

    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_typed)
    -
    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_stage)
        AS diferencia;


-- =========================================================
-- 6. NaN STAGING -> NULL TYPED
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_stage
        WHERE LOWER(BTRIM(afluencia)) = 'nan'
    ) AS nan_stage,

    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_typed
        WHERE afluencia IS NULL
    ) AS null_typed;


-- =========================================================
-- 7. CEROS PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_stage
        WHERE LOWER(BTRIM(afluencia)) <> 'nan'
          AND pg_input_is_valid(
              BTRIM(afluencia),
              'numeric'
          )
          AND BTRIM(afluencia)::numeric = 0
    ) AS ceros_stage,

    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_typed
        WHERE afluencia = 0
    ) AS ceros_typed;


-- =========================================================
-- 8. DECIMALES PRESERVADOS
-- =========================================================

SELECT
    COUNT(*) AS valores_decimales_typed

FROM proyecto.rtp_desglosada_typed

WHERE afluencia IS NOT NULL
  AND afluencia <> TRUNC(afluencia);


-- =========================================================
-- 9. COLISIONES PRESERVADAS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        servicio,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_typed

    GROUP BY
        fecha,
        servicio,
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
-- 10. DUPLICADOS EXACTOS PRESERVADOS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        mes,
        anio,
        servicio,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_typed

    GROUP BY
        fecha,
        mes,
        anio,
        servicio,
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
-- 11. CONTROL AUTOMÁTICO
-- =========================================================

DO $$
DECLARE
    stage_count   BIGINT;
    typed_count   BIGINT;
    null_count    BIGINT;
    zero_count    BIGINT;
    decimal_count BIGINT;
BEGIN

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.rtp_desglosada_stage;

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.rtp_desglosada_typed;

    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.rtp_desglosada_typed
    WHERE afluencia IS NULL;

    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.rtp_desglosada_typed
    WHERE afluencia = 0;

    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.rtp_desglosada_typed
    WHERE afluencia IS NOT NULL
      AND afluencia <> TRUNC(afluencia);

    IF stage_count <> 41676 THEN
        RAISE EXCEPTION
            'STAGING incorrecto. Esperado 41676, obtenido %',
            stage_count;
    END IF;

    IF typed_count <> 41676 THEN
        RAISE EXCEPTION
            'TYPED incorrecto. Esperado 41676, obtenido %',
            typed_count;
    END IF;

    IF null_count <> 187 THEN
        RAISE EXCEPTION
            'NULL incorrectos. Esperado 187, obtenido %',
            null_count;
    END IF;

    IF zero_count <> 7450 THEN
        RAISE EXCEPTION
            'Ceros incorrectos. Esperado 7450, obtenido %',
            zero_count;
    END IF;

    IF decimal_count <> 53 THEN
        RAISE EXCEPTION
            'Decimales incorrectos. Esperado 53, obtenido %',
            decimal_count;
    END IF;

    RAISE NOTICE
        'TYPED RTP correcto. Filas: %, NULL: %, ceros: %, decimales: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count;

END
$$;