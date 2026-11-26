\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

    Capa: INGESTA RAW -> STAGING

    OBJETIVO:
    Cargar el CSV RAW de Tren Ligero preservando su
    representación original mediante columnas TEXT.

    Fuente física observada:

        fecha,mes,anio,tipo_pago,afluencia

    Perfilado RAW previo:
    - 3,530 registros.
    - 5 columnas.
    - 0 filas malformadas.
    - Cobertura:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 0 fechas faltantes.
    - 0 fechas inválidas.
    - 0 inconsistencias fecha <-> anio.
    - 0 inconsistencias fecha <-> mes.
    - 2 tipos de pago:
        Gratuidad
        Prepago
    - 1,765 registros por tipo de pago.
    - 0 valores vacíos.
    - 0 NaN / valores no numéricos.
    - 0 ceros.
    - 0 negativos.
    - 516 valores decimales.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × tipo_pago.

    Granularidad candidata:

        fecha × tipo_pago

    Estructura esperada:

        1,765 fechas
        × 2 tipos de pago
        = 3,530 registros

    IMPORTANTE:
    El recurso NO contiene columna linea.

    Por tanto:
    - no se crea linea;
    - no se crea unidad_operativa;
    - no se fuerza todavía compatibilidad multisistema.

    STAGING conserva exclusivamente la estructura física
    publicada por la fuente.

    PRINCIPIOS:
    - Ejecutar mediante psql.
    - Ejecutar desde la raíz del repositorio.
    - RAW permanece intacto.
    - No se aplica limpieza.
    - No se aplica tipado.
    - No se redondea afluencia.
    - No se eliminan registros.
    - No se imponen restricciones UNIQUE.
*/


-- =========================================================
-- 1. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 3. INGESTA TREN LIGERO DESGLOSADA
--
-- RAW:
-- fecha,mes,anio,tipo_pago,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de Tren Ligero Desglosada...
\echo ==========================================

\copy proyecto.tren_ligero_desglosada_stage (fecha, mes, anio, tipo_pago, afluencia) FROM 'proyecto/data/raw/tren_ligero/afluencia_desglosada_tl_10_2026.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Tren Ligero Desglosada terminada.


-- =========================================================
-- 4. CONTEO POST-INGESTA
-- =========================================================

\echo
\echo ==========================================
\echo Conteo STAGING Tren Ligero
\echo ==========================================

SELECT
    COUNT(*) AS registros_stage
FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 5. CONCILIACIÓN CONTRA MANIFEST
-- =========================================================

\echo
\echo ==========================================
\echo Conciliacion contra manifest
\echo ==========================================

SELECT
    'Tren Ligero Desglosada' AS fuente,
    3530::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 3530::bigint AS diferencia
FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 6. COMPROBACIÓN DE VACÍOS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de vacios
\echo ==========================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NULL
    ) AS vacios_fecha,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(mes), '') IS NULL
    ) AS vacios_mes,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NULL
    ) AS vacios_anio,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_pago), '') IS NULL
    ) AS vacios_tipo_pago,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 7. COMPROBACIÓN DE NaN
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de NaN
\echo ==========================================

SELECT
    COUNT(*) AS registros_nan
FROM proyecto.tren_ligero_desglosada_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


-- =========================================================
-- 8. COMPROBACIÓN DE VALORES NO NUMÉRICOS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de valores no numericos
\echo ==========================================

SELECT
    COUNT(*) AS afluencias_no_numericas
FROM proyecto.tren_ligero_desglosada_stage
WHERE BTRIM(afluencia)
      !~ '^[+-]?[0-9]+([.][0-9]+)?$';


-- =========================================================
-- 9. COMPROBACIÓN DE CEROS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de ceros
\echo ==========================================

SELECT
    COUNT(*) AS registros_cero
FROM proyecto.tren_ligero_desglosada_stage
WHERE BTRIM(afluencia)
      ~ '^[+-]?[0-9]+([.][0-9]+)?$'
  AND BTRIM(afluencia)::numeric = 0;


-- =========================================================
-- 10. COMPROBACIÓN DE VALORES DECIMALES
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de valores decimales
\echo ==========================================

SELECT
    COUNT(*) AS registros_decimales
FROM proyecto.tren_ligero_desglosada_stage
WHERE BTRIM(afluencia)
      ~ '^[+-]?[0-9]+[.][0-9]+$'
  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric);


-- =========================================================
-- 11. COMPROBACIÓN DE NEGATIVOS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de negativos
\echo ==========================================

SELECT
    COUNT(*) AS registros_negativos
FROM proyecto.tren_ligero_desglosada_stage
WHERE BTRIM(afluencia)
      ~ '^[+-]?[0-9]+([.][0-9]+)?$'
  AND BTRIM(afluencia)::numeric < 0;


-- =========================================================
-- 12. DOMINIO ORIGINAL DE TIPO_PAGO
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de tipo_pago
\echo ==========================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros
FROM proyecto.tren_ligero_desglosada_stage
GROUP BY BTRIM(tipo_pago)
ORDER BY BTRIM(tipo_pago);


-- =========================================================
-- 13. COBERTURA TEMPORAL
-- =========================================================

\echo
\echo ==========================================
\echo Cobertura temporal
\echo ==========================================

SELECT
    COUNT(DISTINCT BTRIM(fecha)) AS fechas_distintas,
    MIN(BTRIM(fecha)) AS fecha_min,
    MAX(BTRIM(fecha)) AS fecha_max
FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 14. CONSISTENCIA FECHA - AÑO
-- =========================================================

\echo
\echo ==========================================
\echo Consistencia fecha - anio
\echo ==========================================

SELECT
    COUNT(*) AS inconsistencias_fecha_anio
FROM proyecto.tren_ligero_desglosada_stage
WHERE BTRIM(fecha) !~ '^\d{4}-\d{2}-\d{2}$'
   OR BTRIM(anio) !~ '^\d{4}$'
   OR SUBSTRING(BTRIM(fecha), 1, 4) <> BTRIM(anio);


-- =========================================================
-- 15. CONSISTENCIA FECHA - MES
-- =========================================================

\echo
\echo ==========================================
\echo Consistencia fecha - mes
\echo ==========================================

WITH datos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        LOWER(BTRIM(mes)) AS mes
    FROM proyecto.tren_ligero_desglosada_stage
)
SELECT
    COUNT(*) AS inconsistencias_fecha_mes
FROM datos
WHERE CASE mes
          WHEN 'enero'      THEN 1
          WHEN 'febrero'    THEN 2
          WHEN 'marzo'      THEN 3
          WHEN 'abril'      THEN 4
          WHEN 'mayo'       THEN 5
          WHEN 'junio'      THEN 6
          WHEN 'julio'      THEN 7
          WHEN 'agosto'     THEN 8
          WHEN 'septiembre' THEN 9
          WHEN 'setiembre'  THEN 9
          WHEN 'octubre'    THEN 10
          WHEN 'noviembre'  THEN 11
          WHEN 'diciembre'  THEN 12
          ELSE NULL
      END IS DISTINCT FROM
      EXTRACT(
          MONTH FROM BTRIM(fecha)::date
      )::integer;


-- =========================================================
-- 16. DUPLICADOS EXACTOS
-- =========================================================

\echo
\echo ==========================================
\echo Duplicados exactos
\echo ==========================================

WITH grupos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(mes) AS mes,
        BTRIM(anio) AS anio,
        BTRIM(tipo_pago) AS tipo_pago,
        BTRIM(afluencia) AS afluencia,
        COUNT(*) AS repeticiones
    FROM proyecto.tren_ligero_desglosada_stage
    GROUP BY
        BTRIM(fecha),
        BTRIM(mes),
        BTRIM(anio),
        BTRIM(tipo_pago),
        BTRIM(afluencia)
)
SELECT
    COUNT(*) FILTER (
        WHERE repeticiones > 1
    ) AS grupos_duplicados_exactos,

    COALESCE(
        SUM(repeticiones) FILTER (
            WHERE repeticiones > 1
        ),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(repeticiones - 1) FILTER (
            WHERE repeticiones > 1
        ),
        0
    ) AS registros_excedentes,

    MAX(repeticiones) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 17. GRANULARIDAD CANDIDATA
--
-- fecha × tipo_pago
-- =========================================================

\echo
\echo ==========================================
\echo Granularidad candidata
\echo ==========================================

WITH grupos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(tipo_pago) AS tipo_pago,
        COUNT(*) AS repeticiones
    FROM proyecto.tren_ligero_desglosada_stage
    GROUP BY
        BTRIM(fecha),
        BTRIM(tipo_pago)
)
SELECT
    COUNT(*) AS claves_distintas,

    COUNT(*) FILTER (
        WHERE repeticiones > 1
    ) AS grupos_con_colision,

    COALESCE(
        SUM(repeticiones) FILTER (
            WHERE repeticiones > 1
        ),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(repeticiones - 1) FILTER (
            WHERE repeticiones > 1
        ),
        0
    ) AS registros_excedentes,

    MAX(repeticiones) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 18. ESTRUCTURA POR FECHA
--
-- Esperado:
-- 2 filas y 2 tipos de pago para cada fecha.
-- =========================================================

\echo
\echo ==========================================
\echo Estructura por fecha
\echo ==========================================

WITH grupos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        COUNT(*) AS filas,
        COUNT(DISTINCT BTRIM(tipo_pago)) AS tipos_pago
    FROM proyecto.tren_ligero_desglosada_stage
    GROUP BY BTRIM(fecha)
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
-- 19. MUESTRA RAW PRESERVADA EN STAGING
-- =========================================================

\echo
\echo ==========================================
\echo Muestra RAW preservada en STAGING
\echo ==========================================

SELECT
    fecha,
    mes,
    anio,
    tipo_pago,
    afluencia
FROM proyecto.tren_ligero_desglosada_stage
ORDER BY
    fecha,
    tipo_pago
LIMIT 15;


-- =========================================================
-- 20. CONTROL AUTOMÁTICO DE INTEGRIDAD
-- =========================================================

DO $$
DECLARE

    total_stage                BIGINT;
    total_vacios               BIGINT;
    total_nan                  BIGINT;
    total_no_numericos         BIGINT;
    total_ceros                BIGINT;
    total_decimales            BIGINT;
    total_negativos            BIGINT;

    total_tipos_pago           BIGINT;
    total_gratuidad            BIGINT;
    total_prepago              BIGINT;

    total_fechas               BIGINT;
    total_inconsistencias_anio BIGINT;
    total_inconsistencias_mes  BIGINT;

    total_claves               BIGINT;
    total_colisiones           BIGINT;

    fechas_estructura_ok       BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO total_stage
    FROM proyecto.tren_ligero_desglosada_stage;


    SELECT COUNT(*)
    INTO total_vacios
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE NULLIF(BTRIM(fecha), '') IS NULL
       OR NULLIF(BTRIM(mes), '') IS NULL
       OR NULLIF(BTRIM(anio), '') IS NULL
       OR NULLIF(BTRIM(tipo_pago), '') IS NULL
       OR NULLIF(BTRIM(afluencia), '') IS NULL;


    SELECT COUNT(*)
    INTO total_nan
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';


    SELECT COUNT(*)
    INTO total_no_numericos
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(afluencia)
          !~ '^[+-]?[0-9]+([.][0-9]+)?$';


    SELECT COUNT(*)
    INTO total_ceros
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+([.][0-9]+)?$'
      AND BTRIM(afluencia)::numeric = 0;


    SELECT COUNT(*)
    INTO total_decimales
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+[.][0-9]+$'
      AND BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric);


    SELECT COUNT(*)
    INTO total_negativos
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+([.][0-9]+)?$'
      AND BTRIM(afluencia)::numeric < 0;


    SELECT COUNT(DISTINCT BTRIM(tipo_pago))
    INTO total_tipos_pago
    FROM proyecto.tren_ligero_desglosada_stage;


    SELECT COUNT(*)
    INTO total_gratuidad
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(tipo_pago) = 'Gratuidad';


    SELECT COUNT(*)
    INTO total_prepago
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(tipo_pago) = 'Prepago';


    SELECT COUNT(DISTINCT BTRIM(fecha))
    INTO total_fechas
    FROM proyecto.tren_ligero_desglosada_stage;


    SELECT COUNT(*)
    INTO total_inconsistencias_anio
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE BTRIM(fecha) !~ '^\d{4}-\d{2}-\d{2}$'
       OR BTRIM(anio) !~ '^\d{4}$'
       OR SUBSTRING(BTRIM(fecha), 1, 4) <> BTRIM(anio);


    SELECT COUNT(*)
    INTO total_inconsistencias_mes
    FROM proyecto.tren_ligero_desglosada_stage
    WHERE CASE LOWER(BTRIM(mes))
              WHEN 'enero'      THEN 1
              WHEN 'febrero'    THEN 2
              WHEN 'marzo'      THEN 3
              WHEN 'abril'      THEN 4
              WHEN 'mayo'       THEN 5
              WHEN 'junio'      THEN 6
              WHEN 'julio'      THEN 7
              WHEN 'agosto'     THEN 8
              WHEN 'septiembre' THEN 9
              WHEN 'setiembre'  THEN 9
              WHEN 'octubre'    THEN 10
              WHEN 'noviembre'  THEN 11
              WHEN 'diciembre'  THEN 12
              ELSE NULL
          END IS DISTINCT FROM
          EXTRACT(
              MONTH FROM BTRIM(fecha)::date
          )::integer;


    WITH grupos AS (
        SELECT
            BTRIM(fecha),
            BTRIM(tipo_pago),
            COUNT(*) AS repeticiones
        FROM proyecto.tren_ligero_desglosada_stage
        GROUP BY
            BTRIM(fecha),
            BTRIM(tipo_pago)
    )
    SELECT
        COUNT(*),
        COUNT(*) FILTER (
            WHERE repeticiones > 1
        )
    INTO
        total_claves,
        total_colisiones
    FROM grupos;


    WITH grupos AS (
        SELECT
            BTRIM(fecha) AS fecha,
            COUNT(*) AS filas,
            COUNT(DISTINCT BTRIM(tipo_pago)) AS tipos_pago
        FROM proyecto.tren_ligero_desglosada_stage
        GROUP BY BTRIM(fecha)
    )
    SELECT COUNT(*)
    INTO fechas_estructura_ok
    FROM grupos
    WHERE filas = 2
      AND tipos_pago = 2;


    IF total_stage <> 3530 THEN
        RAISE EXCEPTION
            'Conteo Tren Ligero incorrecto. Esperado: 3530. Obtenido: %',
            total_stage;
    END IF;


    IF total_vacios <> 0 THEN
        RAISE EXCEPTION
            'Valores vacios Tren Ligero inesperados. Esperado: 0. Obtenido: %',
            total_vacios;
    END IF;


    IF total_nan <> 0 THEN
        RAISE EXCEPTION
            'Conteo NaN Tren Ligero incorrecto. Esperado: 0. Obtenido: %',
            total_nan;
    END IF;


    IF total_no_numericos <> 0 THEN
        RAISE EXCEPTION
            'Afluencias no numericas Tren Ligero. Esperado: 0. Obtenido: %',
            total_no_numericos;
    END IF;


    IF total_ceros <> 0 THEN
        RAISE EXCEPTION
            'Conteo de ceros Tren Ligero incorrecto. Esperado: 0. Obtenido: %',
            total_ceros;
    END IF;


    IF total_decimales <> 516 THEN
        RAISE EXCEPTION
            'Conteo decimal Tren Ligero incorrecto. Esperado: 516. Obtenido: %',
            total_decimales;
    END IF;


    IF total_negativos <> 0 THEN
        RAISE EXCEPTION
            'Conteo negativos Tren Ligero incorrecto. Esperado: 0. Obtenido: %',
            total_negativos;
    END IF;


    IF total_tipos_pago <> 2 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago Tren Ligero incorrecto. Esperado: 2. Obtenido: %',
            total_tipos_pago;
    END IF;


    IF total_gratuidad <> 1765 THEN
        RAISE EXCEPTION
            'Conteo Gratuidad Tren Ligero incorrecto. Esperado: 1765. Obtenido: %',
            total_gratuidad;
    END IF;


    IF total_prepago <> 1765 THEN
        RAISE EXCEPTION
            'Conteo Prepago Tren Ligero incorrecto. Esperado: 1765. Obtenido: %',
            total_prepago;
    END IF;


    IF total_fechas <> 1765 THEN
        RAISE EXCEPTION
            'Fechas Tren Ligero incorrectas. Esperado: 1765. Obtenido: %',
            total_fechas;
    END IF;


    IF total_inconsistencias_anio <> 0 THEN
        RAISE EXCEPTION
            'Inconsistencias fecha-anio Tren Ligero. Esperado: 0. Obtenido: %',
            total_inconsistencias_anio;
    END IF;


    IF total_inconsistencias_mes <> 0 THEN
        RAISE EXCEPTION
            'Inconsistencias fecha-mes Tren Ligero. Esperado: 0. Obtenido: %',
            total_inconsistencias_mes;
    END IF;


    IF total_claves <> 3530 THEN
        RAISE EXCEPTION
            'Granularidad Tren Ligero inconsistente. Esperado: 3530 claves. Obtenido: %',
            total_claves;
    END IF;


    IF total_colisiones <> 0 THEN
        RAISE EXCEPTION
            'Colisiones Tren Ligero inesperadas. Esperado: 0. Obtenido: %',
            total_colisiones;
    END IF;


    IF fechas_estructura_ok <> 1765 THEN
        RAISE EXCEPTION
            'Estructura por fecha Tren Ligero incorrecta. Esperado: 1765 fechas con 2 filas y 2 tipos_pago. Obtenido: %',
            fechas_estructura_ok;
    END IF;


    RAISE NOTICE
        'Integridad STAGING Tren Ligero correcta. Registros: %, vacios: %, NaN: %, no numericos: %, ceros: %, decimales: %, negativos: %, tipos_pago: %, gratuidad: %, prepago: %, fechas: %, claves: %, colisiones: %',
        total_stage,
        total_vacios,
        total_nan,
        total_no_numericos,
        total_ceros,
        total_decimales,
        total_negativos,
        total_tipos_pago,
        total_gratuidad,
        total_prepago,
        total_fechas,
        total_claves,
        total_colisiones;

END
$$;


-- =========================================================
-- 21. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;


\echo
\echo ==========================================
\echo INGESTA TREN LIGERO COMPLETADA
\echo ==========================================