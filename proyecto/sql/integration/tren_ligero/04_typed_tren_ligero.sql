/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

    CAPA: TYPED

    Objetivo:
    convertir de forma controlada las representaciones
    TEXT de STAGING a tipos físicos adecuados, sin aplicar
    todavía transformaciones semánticas ni integración
    multisistema.

    Evidencia previa validada:
    - 3,530 registros.
    - 0 NULL / vacíos.
    - 0 fechas inválidas.
    - 0 años inválidos.
    - 3,530 afluencias NUMERIC válidas.
    - 0 ceros.
    - 0 negativos.
    - 516 valores con componente decimal.
    - 0 duplicados exactos.
    - 0 colisiones en:
        fecha × tipo_pago.
    - 2 tipos de pago:
        Gratuidad
        Prepago.
    - 1,765 fechas distintas.
    - Cobertura:
        2022-01-01 -> 2026-10-31.

    Granularidad nativa:

        fecha × tipo_pago

    Precisión observada de afluencia:
    - máximo de dígitos enteros: 6;
    - máxima escala decimal: 12;
    - máxima precisión observada por valor: 17.

    Tipo físico adoptado:

        NUMERIC(18,12)

    Justificación:
    NUMERIC(18,12) permite:
    - 18 dígitos totales;
    - 12 dígitos decimales;
    - 6 dígitos enteros.

    Esto cubre sin pérdida la evidencia observada.

    IMPORTANTE:
    El recurso Tren Ligero NO contiene columna linea.

    Por tanto TYPED:
    - no inventa linea;
    - no inventa unidad_operativa;
    - no fuerza todavía compatibilidad multisistema.

    PRINCIPIOS:
    - STAGING permanece intacto.
    - No se eliminan registros.
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

    pago_count              BIGINT;
    fechas_count            BIGINT;
    collision_count         BIGINT;

    max_digitos_enteros     INTEGER;
    max_escala              INTEGER;

BEGIN

    -- -----------------------------------------------------
    -- Conteo
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.tren_ligero_desglosada_stage;


    IF stage_count <> 3530 THEN
        RAISE EXCEPTION
            'STAGING Tren Ligero cambió. Esperado: 3530. Obtenido: %',
            stage_count;
    END IF;


    -- -----------------------------------------------------
    -- NULL / vacíos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO vacios_count

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE NULLIF(BTRIM(fecha), '') IS NULL
       OR NULLIF(BTRIM(mes), '') IS NULL
       OR NULLIF(BTRIM(anio), '') IS NULL
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

    FROM proyecto.tren_ligero_desglosada_stage

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

    FROM proyecto.tren_ligero_desglosada_stage

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

    FROM proyecto.tren_ligero_desglosada_stage

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

    FROM proyecto.tren_ligero_desglosada_stage

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

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE BTRIM(afluencia)::numeric = 0;


    IF ceros_count <> 0 THEN
        RAISE EXCEPTION
            'Conteo de ceros cambió. Esperado: 0. Obtenido: %',
            ceros_count;
    END IF;


    -- -----------------------------------------------------
    -- Decimales
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO decimales_count

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric);


    IF decimales_count <> 516 THEN
        RAISE EXCEPTION
            'Conteo decimal cambió. Esperado: 516. Obtenido: %',
            decimales_count;
    END IF;


    -- -----------------------------------------------------
    -- Negativos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO negativos_count

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE BTRIM(afluencia)::numeric < 0;


    IF negativos_count <> 0 THEN
        RAISE EXCEPTION
            'Se detectaron valores negativos inesperados: %',
            negativos_count;
    END IF;


    -- -----------------------------------------------------
    -- Tipo de pago
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT BTRIM(tipo_pago))
    INTO pago_count

    FROM proyecto.tren_ligero_desglosada_stage;


    IF pago_count <> 2 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago cambió. Esperado: 2. Obtenido: %',
            pago_count;
    END IF;


    -- -----------------------------------------------------
    -- Fechas
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT BTRIM(fecha))
    INTO fechas_count

    FROM proyecto.tren_ligero_desglosada_stage;


    IF fechas_count <> 1765 THEN
        RAISE EXCEPTION
            'Número de fechas cambió. Esperado: 1765. Obtenido: %',
            fechas_count;
    END IF;


    -- -----------------------------------------------------
    -- Granularidad
    -- fecha × tipo_pago
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_count

    FROM (

        SELECT
            BTRIM(fecha),
            BTRIM(tipo_pago)

        FROM proyecto.tren_ligero_desglosada_stage

        GROUP BY
            BTRIM(fecha),
            BTRIM(tipo_pago)

        HAVING COUNT(*) > 1

    ) AS colisiones;


    IF collision_count <> 0 THEN
        RAISE EXCEPTION
            'STAGING contiene colisiones inesperadas: %',
            collision_count;
    END IF;


    -- -----------------------------------------------------
    -- Precisión necesaria para NUMERIC(18,12)
    -- -----------------------------------------------------

    WITH perfil AS (

        SELECT
            BTRIM(afluencia) AS afluencia_txt

        FROM proyecto.tren_ligero_desglosada_stage
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
            'NUMERIC(18,12) insuficiente: se observaron % dígitos enteros.',
            max_digitos_enteros;
    END IF;


    IF max_escala > 12 THEN
        RAISE EXCEPTION
            'NUMERIC(18,12) insuficiente: se observó escala %.',
            max_escala;
    END IF;


    RAISE NOTICE
        'Precondiciones TYPED Tren Ligero correctas. Filas: %, ceros: %, decimales: %, negativos: %, pagos: %, fechas: %, colisiones: %, max_enteros: %, max_escala: %',
        stage_count,
        ceros_count,
        decimales_count,
        negativos_count,
        pago_count,
        fechas_count,
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

DROP TABLE IF EXISTS proyecto.tren_ligero_desglosada_typed;


-- =========================================================
-- 5. CREAR TYPED
-- =========================================================

CREATE TABLE proyecto.tren_ligero_desglosada_typed (

    fecha       DATE,
    mes         TEXT,
    anio        SMALLINT,
    tipo_pago   TEXT,

    afluencia   NUMERIC(18,12)
);


-- =========================================================
-- 6. STAGING -> TYPED
--
-- Únicamente:
-- - BTRIM;
-- - conversión de tipos físicos.
--
-- NO se crea linea.
-- NO se crea unidad_operativa.
-- =========================================================

INSERT INTO proyecto.tren_ligero_desglosada_typed (
    fecha,
    mes,
    anio,
    tipo_pago,
    afluencia
)

SELECT
    BTRIM(fecha)::DATE,
    BTRIM(mes),
    BTRIM(anio)::SMALLINT,
    BTRIM(tipo_pago),
    BTRIM(afluencia)::NUMERIC(18,12)

FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 7. CONCILIACIÓN STAGING VS TYPED
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.tren_ligero_desglosada_stage
    ) AS staging,

    (
        SELECT COUNT(*)
        FROM proyecto.tren_ligero_desglosada_typed
    ) AS typed,

    (
        (SELECT COUNT(*)
         FROM proyecto.tren_ligero_desglosada_typed)

        -

        (SELECT COUNT(*)
         FROM proyecto.tren_ligero_desglosada_stage)

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
  AND table_name = 'tren_ligero_desglosada_typed'

ORDER BY ordinal_position;


-- =========================================================
-- 9. NULL POST-TIPADO
-- =========================================================

SELECT
    COUNT(*) AS afluencia_null

FROM proyecto.tren_ligero_desglosada_typed

WHERE afluencia IS NULL;


-- =========================================================
-- 10. CEROS PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_stage

        WHERE BTRIM(afluencia)::numeric = 0

    ) AS ceros_stage,

    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_typed

        WHERE afluencia = 0

    ) AS ceros_typed;


-- =========================================================
-- 11. DECIMALES PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_stage

        WHERE BTRIM(afluencia)::numeric
              <> TRUNC(BTRIM(afluencia)::numeric)

    ) AS decimales_stage,

    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_typed

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

FROM proyecto.tren_ligero_desglosada_typed;


-- =========================================================
-- 13. DOMINIO DE TIPO_PAGO PRESERVADO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.tren_ligero_desglosada_typed

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
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_typed

    GROUP BY
        fecha,
        mes,
        anio,
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
--
-- fecha × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_typed

    GROUP BY
        fecha,
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
-- 16. COMPARACIÓN DE AFLUENCIA STAGING VS TYPED
-- =========================================================

SELECT
    COUNT(*) AS diferencias_afluencia

FROM proyecto.tren_ligero_desglosada_stage AS s

JOIN proyecto.tren_ligero_desglosada_typed AS t

  ON t.fecha = BTRIM(s.fecha)::DATE
 AND t.tipo_pago = BTRIM(s.tipo_pago)

WHERE t.afluencia
      <> BTRIM(s.afluencia)::numeric;


-- =========================================================
-- 17. ESTRUCTURA POR FECHA POST-TIPADO
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,

        COUNT(*) AS filas,

        COUNT(
            DISTINCT tipo_pago
        ) AS tipos_pago

    FROM proyecto.tren_ligero_desglosada_typed

    GROUP BY fecha
)

SELECT
    filas,
    tipos_pago,
    COUNT(*) AS numero_fechas

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


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

    payment_count        BIGINT;
    date_count           BIGINT;

    collision_count      BIGINT;
    mismatch_count       BIGINT;
    fechas_estructura_ok BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia < 0;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(DISTINCT fecha)
    INTO date_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(*)
    INTO collision_count

    FROM (

        SELECT
            fecha,
            tipo_pago

        FROM proyecto.tren_ligero_desglosada_typed

        GROUP BY
            fecha,
            tipo_pago

        HAVING COUNT(*) > 1

    ) AS colisiones;


    SELECT COUNT(*)
    INTO mismatch_count

    FROM proyecto.tren_ligero_desglosada_stage AS s

    JOIN proyecto.tren_ligero_desglosada_typed AS t

      ON t.fecha = BTRIM(s.fecha)::DATE
     AND t.tipo_pago = BTRIM(s.tipo_pago)

    WHERE t.afluencia
          <> BTRIM(s.afluencia)::numeric;


    WITH grupos AS (

        SELECT
            fecha,
            COUNT(*) AS filas,
            COUNT(DISTINCT tipo_pago) AS tipos_pago

        FROM proyecto.tren_ligero_desglosada_typed

        GROUP BY fecha
    )

    SELECT COUNT(*)
    INTO fechas_estructura_ok

    FROM grupos

    WHERE filas = 2
      AND tipos_pago = 2;


    IF typed_count <> 3530 THEN
        RAISE EXCEPTION
            'Conteo TYPED incorrecto. Esperado: 3530. Obtenido: %',
            typed_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en afluencia TYPED: %',
            null_count;
    END IF;


    IF zero_count <> 0 THEN
        RAISE EXCEPTION
            'Ceros TYPED incorrectos. Esperado: 0. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 516 THEN
        RAISE EXCEPTION
            'Decimales TYPED incorrectos. Esperado: 516. Obtenido: %',
            decimal_count;
    END IF;


    IF negative_count <> 0 THEN
        RAISE EXCEPTION
            'Negativos inesperados en TYPED: %',
            negative_count;
    END IF;


    IF payment_count <> 2 THEN
        RAISE EXCEPTION
            'Tipos de pago cambiaron. Esperados: 2. Obtenidos: %',
            payment_count;
    END IF;


    IF date_count <> 1765 THEN
        RAISE EXCEPTION
            'Fechas cambiaron. Esperadas: 1765. Obtenidas: %',
            date_count;
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


    IF fechas_estructura_ok <> 1765 THEN
        RAISE EXCEPTION
            'Estructura TYPED incorrecta. Esperadas 1765 fechas con 2 filas y 2 tipos_pago. Obtenidas: %',
            fechas_estructura_ok;
    END IF;


    RAISE NOTICE
        'TYPED Tren Ligero validado. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, pagos: %, fechas: %, colisiones: %, diferencias afluencia: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        payment_count,
        date_count,
        collision_count,
        mismatch_count;

END
$$;


-- =========================================================
-- 19. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;