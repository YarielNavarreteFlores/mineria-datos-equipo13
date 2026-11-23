/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

    CAPA: TYPED

    Objetivo:
    convertir de manera controlada las representaciones
    TEXT de STAGING a tipos físicos adecuados, sin aplicar
    todavía homologaciones semánticas ni eliminar registros.

    Evidencia previa validada:
    - 65,013 registros.
    - 0 NULL / vacíos.
    - 0 fechas inválidas.
    - 0 años inválidos.
    - 65,013 afluencias NUMERIC válidas.
    - 63,594 afluencias convertibles a BIGINT.
    - 1,419 valores con componente decimal.
    - 20,246 ceros.
    - 0 negativos.
    - 0 duplicados exactos.
    - 0 colisiones en:
        fecha × linea × tipo_pago.
    - 43 representaciones originales de linea.
    - 17 representaciones gráficas exploratorias.
    - 3 tipos de pago.
    - Cobertura:
        2022-01-01 -> 2026-10-31.

    Precisión observada de afluencia:
    - máximo de dígitos enteros: 6;
    - máxima escala decimal: 13;
    - máxima precisión observada por valor: 17.

    Tipo físico adoptado:

        NUMERIC(19,13)

    Justificación:
    6 dígitos enteros + 13 dígitos decimales = 19
    posiciones de precisión.

    PRINCIPIOS:
    - STAGING permanece intacto.
    - No se eliminan registros.
    - No se homologa todavía linea.
    - No se eliminan ceros.
    - No se eliminan posibles outliers.
    - No se redondea afluencia.
    - No se generan NULL artificialmente.
    - No se imponen restricciones UNIQUE todavía.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. PRECONDICIONES DE STAGING
--
-- Si STAGING cambia respecto al perfilado validado,
-- el proceso debe detenerse.
-- =========================================================

DO $$
DECLARE
    stage_count             BIGINT;
    vacios_count            BIGINT;
    fecha_invalida          BIGINT;
    anio_invalido           BIGINT;
    afluencia_invalida      BIGINT;
    afluencia_nan           BIGINT;
    ceros_count             BIGINT;
    decimales_count         BIGINT;
    negativos_count         BIGINT;
    linea_count             BIGINT;
    pago_count              BIGINT;
    collision_count         BIGINT;
    max_digitos_enteros     INTEGER;
    max_escala              INTEGER;

BEGIN

    -- -----------------------------------------------------
    -- Conteo
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.trolebus_desglosada_stage;


    IF stage_count <> 65013 THEN
        RAISE EXCEPTION
            'STAGING Trolebus cambió. Esperado: 65013. Obtenido: %',
            stage_count;
    END IF;


    -- -----------------------------------------------------
    -- NULL / vacíos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO vacios_count

    FROM proyecto.trolebus_desglosada_stage

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

    FROM proyecto.trolebus_desglosada_stage

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

    FROM proyecto.trolebus_desglosada_stage

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

    FROM proyecto.trolebus_desglosada_stage

    WHERE LOWER(BTRIM(afluencia)) = 'nan';


    IF afluencia_nan <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron NaN inesperados: %',
            afluencia_nan;
    END IF;


    -- -----------------------------------------------------
    -- Convertibilidad NUMERIC
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO afluencia_invalida

    FROM proyecto.trolebus_desglosada_stage

    WHERE NOT pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    );


    IF afluencia_invalida <> 0 THEN
        RAISE EXCEPTION
            'Afluencias no convertibles a NUMERIC: %',
            afluencia_invalida;
    END IF;


    -- -----------------------------------------------------
    -- Ceros
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO ceros_count

    FROM proyecto.trolebus_desglosada_stage

    WHERE BTRIM(afluencia)::numeric = 0;


    IF ceros_count <> 20246 THEN
        RAISE EXCEPTION
            'Conteo de ceros cambió. Esperado: 20246. Obtenido: %',
            ceros_count;
    END IF;


    -- -----------------------------------------------------
    -- Decimales
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO decimales_count

    FROM proyecto.trolebus_desglosada_stage

    WHERE BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric);


    IF decimales_count <> 1419 THEN
        RAISE EXCEPTION
            'Conteo decimal cambió. Esperado: 1419. Obtenido: %',
            decimales_count;
    END IF;


    -- -----------------------------------------------------
    -- Negativos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO negativos_count

    FROM proyecto.trolebus_desglosada_stage

    WHERE BTRIM(afluencia)::numeric < 0;


    IF negativos_count <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron valores negativos inesperados: %',
            negativos_count;
    END IF;


    -- -----------------------------------------------------
    -- Representaciones originales de linea
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT BTRIM(linea))
    INTO linea_count

    FROM proyecto.trolebus_desglosada_stage;


    IF linea_count <> 43 THEN
        RAISE EXCEPTION
            'Representaciones de linea cambiaron. Esperado: 43. Obtenido: %',
            linea_count;
    END IF;


    -- -----------------------------------------------------
    -- Dominio tipo_pago
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT BTRIM(tipo_pago))
    INTO pago_count

    FROM proyecto.trolebus_desglosada_stage;


    IF pago_count <> 3 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago cambió. Esperado: 3. Obtenido: %',
            pago_count;
    END IF;


    -- -----------------------------------------------------
    -- Granularidad
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_count

    FROM (

        SELECT
            BTRIM(fecha),
            BTRIM(linea),
            BTRIM(tipo_pago)

        FROM proyecto.trolebus_desglosada_stage

        GROUP BY
            BTRIM(fecha),
            BTRIM(linea),
            BTRIM(tipo_pago)

        HAVING COUNT(*) > 1

    ) AS colisiones;


    IF collision_count <> 0 THEN
        RAISE EXCEPTION
            'STAGING contiene colisiones inesperadas: %',
            collision_count;
    END IF;


    -- -----------------------------------------------------
    -- Precisión necesaria para NUMERIC(19,13)
    -- -----------------------------------------------------

    WITH perfil AS (

        SELECT
            BTRIM(afluencia) AS afluencia_txt

        FROM proyecto.trolebus_desglosada_stage
    ),

    medidas AS (

        SELECT
            LENGTH(
                REGEXP_REPLACE(
                    SPLIT_PART(
                        afluencia_txt,
                        '.',
                        1
                    ),
                    '^[+-]',
                    ''
                )
            ) AS digitos_enteros,

            CASE
                WHEN POSITION('.' IN afluencia_txt) > 0
                THEN LENGTH(
                    SPLIT_PART(
                        afluencia_txt,
                        '.',
                        2
                    )
                )
                ELSE 0
            END AS escala

        FROM perfil
    )

    SELECT
        MAX(digitos_enteros),
        MAX(escala)

    INTO
        max_digitos_enteros,
        max_escala

    FROM medidas;


    IF max_digitos_enteros > 6 THEN
        RAISE EXCEPTION
            'NUMERIC(19,13) insuficiente: se observaron % dígitos enteros.',
            max_digitos_enteros;
    END IF;


    IF max_escala > 13 THEN
        RAISE EXCEPTION
            'NUMERIC(19,13) insuficiente: se observó escala %.',
            max_escala;
    END IF;


    RAISE NOTICE
        'Precondiciones TYPED Trolebus correctas. Filas: %, ceros: %, decimales: %, negativos: %, lineas: %, pagos: %, colisiones: %, max_enteros: %, max_escala: %',
        stage_count,
        ceros_count,
        decimales_count,
        negativos_count,
        linea_count,
        pago_count,
        collision_count,
        max_digitos_enteros,
        max_escala;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.trolebus_desglosada_typed;


-- =========================================================
-- 5. CREAR TYPED
-- =========================================================

CREATE TABLE proyecto.trolebus_desglosada_typed (

    fecha       DATE,
    mes         TEXT,
    anio        SMALLINT,
    linea       TEXT,
    tipo_pago   TEXT,

    afluencia   NUMERIC(19,13)
);


-- =========================================================
-- 6. STAGING -> TYPED
--
-- Únicamente:
-- - BTRIM;
-- - conversión de tipos físicos.
--
-- No existe todavía homologación semántica de linea.
-- =========================================================

INSERT INTO proyecto.trolebus_desglosada_typed (
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
    BTRIM(afluencia)::NUMERIC(19,13)

FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 7. CONCILIACIÓN STAGING VS TYPED
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_stage
    ) AS staging,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_typed
    ) AS typed,

    (
        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_typed)

        -

        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_stage)

    ) AS diferencia;


-- =========================================================
-- 8. ESTRUCTURA FÍSICA RESULTANTE
-- =========================================================

SELECT
    ordinal_position,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale

FROM information_schema.columns

WHERE table_schema = 'proyecto'
  AND table_name = 'trolebus_desglosada_typed'

ORDER BY ordinal_position;


-- =========================================================
-- 9. NULL POST-TIPADO
-- =========================================================

SELECT
    COUNT(*) AS afluencia_null

FROM proyecto.trolebus_desglosada_typed

WHERE afluencia IS NULL;


-- =========================================================
-- 10. CEROS PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)

        FROM proyecto.trolebus_desglosada_stage

        WHERE BTRIM(afluencia)::numeric = 0

    ) AS ceros_stage,

    (
        SELECT COUNT(*)

        FROM proyecto.trolebus_desglosada_typed

        WHERE afluencia = 0

    ) AS ceros_typed;


-- =========================================================
-- 11. DECIMALES PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)

        FROM proyecto.trolebus_desglosada_stage

        WHERE BTRIM(afluencia)::numeric
              <> TRUNC(BTRIM(afluencia)::numeric)

    ) AS decimales_stage,

    (
        SELECT COUNT(*)

        FROM proyecto.trolebus_desglosada_typed

        WHERE afluencia
              <> TRUNC(afluencia)

    ) AS decimales_typed;


-- =========================================================
-- 12. RANGOS POST-TIPADO
-- =========================================================

SELECT
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,

    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max,

    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max

FROM proyecto.trolebus_desglosada_typed;


-- =========================================================
-- 13. REPRESENTACIONES DE LINEA PRESERVADAS
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.trolebus_desglosada_typed

GROUP BY linea

ORDER BY
    fecha_min,
    linea;


-- =========================================================
-- 14. DOMINIO DE TIPO_PAGO PRESERVADO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_typed

GROUP BY tipo_pago

ORDER BY tipo_pago;


-- =========================================================
-- 15. DUPLICADOS EXACTOS POST-TIPADO
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

    FROM proyecto.trolebus_desglosada_typed

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
-- 16. GRANULARIDAD POST-TIPADO
--
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.trolebus_desglosada_typed

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
-- 17. COMPARACIÓN DE AFLUENCIA STAGING VS TYPED
--
-- Verifica que la conversión NUMERIC no alteró
-- el valor matemático.
-- =========================================================

SELECT
    COUNT(*) AS diferencias_afluencia

FROM proyecto.trolebus_desglosada_stage AS s

JOIN proyecto.trolebus_desglosada_typed AS t

  ON t.fecha = BTRIM(s.fecha)::DATE
 AND t.linea = BTRIM(s.linea)
 AND t.tipo_pago = BTRIM(s.tipo_pago)

WHERE t.afluencia
      <> BTRIM(s.afluencia)::numeric;


-- =========================================================
-- 18. VALIDACIÓN AUTOMÁTICA TYPED
-- =========================================================

DO $$
DECLARE
    typed_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    decimal_count        BIGINT;
    negative_count       BIGINT;
    distinct_linea_count BIGINT;
    payment_count        BIGINT;
    collision_count      BIGINT;
    mismatch_count       BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO typed_count

    FROM proyecto.trolebus_desglosada_typed;


    SELECT COUNT(*)
    INTO null_count

    FROM proyecto.trolebus_desglosada_typed

    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count

    FROM proyecto.trolebus_desglosada_typed

    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count

    FROM proyecto.trolebus_desglosada_typed

    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count

    FROM proyecto.trolebus_desglosada_typed

    WHERE afluencia < 0;


    SELECT COUNT(DISTINCT linea)
    INTO distinct_linea_count

    FROM proyecto.trolebus_desglosada_typed;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count

    FROM proyecto.trolebus_desglosada_typed;


    SELECT COUNT(*)
    INTO collision_count

    FROM (

        SELECT
            fecha,
            linea,
            tipo_pago

        FROM proyecto.trolebus_desglosada_typed

        GROUP BY
            fecha,
            linea,
            tipo_pago

        HAVING COUNT(*) > 1

    ) AS colisiones;


    SELECT COUNT(*)
    INTO mismatch_count

    FROM proyecto.trolebus_desglosada_stage AS s

    JOIN proyecto.trolebus_desglosada_typed AS t

      ON t.fecha = BTRIM(s.fecha)::DATE
     AND t.linea = BTRIM(s.linea)
     AND t.tipo_pago = BTRIM(s.tipo_pago)

    WHERE t.afluencia
          <> BTRIM(s.afluencia)::numeric;


    IF typed_count <> 65013 THEN
        RAISE EXCEPTION
            'Conteo TYPED incorrecto. Esperado: 65013. Obtenido: %',
            typed_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en afluencia TYPED: %',
            null_count;
    END IF;


    IF zero_count <> 20246 THEN
        RAISE EXCEPTION
            'Ceros TYPED incorrectos. Esperado: 20246. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 1419 THEN
        RAISE EXCEPTION
            'Decimales TYPED incorrectos. Esperado: 1419. Obtenido: %',
            decimal_count;
    END IF;


    IF negative_count <> 0 THEN
        RAISE EXCEPTION
            'Negativos inesperados en TYPED: %',
            negative_count;
    END IF;


    IF distinct_linea_count <> 43 THEN
        RAISE EXCEPTION
            'Representaciones de linea cambiaron. Esperadas: 43. Obtenidas: %',
            distinct_linea_count;
    END IF;


    IF payment_count <> 3 THEN
        RAISE EXCEPTION
            'Tipos de pago cambiaron. Esperados: 3. Obtenidos: %',
            payment_count;
    END IF;


    IF collision_count <> 0 THEN
        RAISE EXCEPTION
            'Se generaron colisiones inesperadas en TYPED: %',
            collision_count;
    END IF;


    IF mismatch_count <> 0 THEN
        RAISE EXCEPTION
            'La conversión de afluencia alteró % valores.',
            mismatch_count;
    END IF;


    RAISE NOTICE
        'TYPED Trolebus validado. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, representaciones linea: %, pagos: %, colisiones: %, diferencias afluencia: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        distinct_linea_count,
        payment_count,
        collision_count,
        mismatch_count;

END
$$;


-- =========================================================
-- 19. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;