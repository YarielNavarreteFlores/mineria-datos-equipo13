\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

    Capa: INGESTA RAW -> STAGING

    OBJETIVO:
    Cargar el CSV RAW de Trolebús preservando su
    representación original mediante columnas TEXT.

    Fuente física:
    fecha,mes,anio,linea,tipo_pago,afluencia

    Perfilado RAW previo:
    - 65,013 registros.
    - 6 columnas.
    - 0 filas malformadas.
    - Cobertura:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 0 fechas inválidas.
    - 0 inconsistencias fecha <-> anio.
    - 0 inconsistencias fecha <-> mes.
    - 3 tipos de pago:
        Boleto
        Prepago
        Gratuidad
    - 21,671 registros por tipo de pago.
    - 43 representaciones originales de linea.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.
    - 0 NaN / valores no numéricos.
    - 20,246 ceros.
    - 0 negativos.
    - 1,419 valores decimales.

    IMPORTANTE:
    - Ejecutar mediante psql.
    - Ejecutar desde la raíz del repositorio.
    - RAW permanece intacto.
    - No se aplica limpieza.
    - No se aplica tipado.
    - No se homologan valores de linea.
    - No se redondean valores de afluencia.
    - Los ceros permanecen como texto.
    - No se imponen restricciones UNIQUE.
*/


-- =========================================================
-- 1. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 3. INGESTA TROLEBÚS DESGLOSADA
--
-- RAW:
-- fecha,mes,anio,linea,tipo_pago,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de Trolebus Desglosada...
\echo ==========================================

\copy proyecto.trolebus_desglosada_stage (fecha, mes, anio, linea, tipo_pago, afluencia) FROM 'proyecto/data/raw/trolebus/afluencia_desglosada_trolebus_10_2026.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Trolebus Desglosada terminada.


-- =========================================================
-- 4. CONTEO POST-INGESTA
-- =========================================================

\echo
\echo ==========================================
\echo Conteo STAGING Trolebus
\echo ==========================================

SELECT
    COUNT(*) AS registros_stage
FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 5. CONCILIACIÓN CONTRA MANIFEST
-- =========================================================

\echo
\echo ==========================================
\echo Conciliacion contra manifest
\echo ==========================================

SELECT
    'Trolebus Desglosada' AS fuente,
    65013::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 65013::bigint AS diferencia
FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 6. COMPROBACIÓN DE NaN
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de NaN
\echo ==========================================

SELECT
    COUNT(*) AS registros_nan
FROM proyecto.trolebus_desglosada_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


-- =========================================================
-- 7. COMPROBACIÓN DE VALORES NO NUMÉRICOS
--
-- Se admite:
-- entero
-- decimal positivo o negativo
--
-- No se convierte todavía.
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de valores no numericos
\echo ==========================================

SELECT
    COUNT(*) AS afluencias_no_numericas
FROM proyecto.trolebus_desglosada_stage
WHERE BTRIM(afluencia) !~ '^[+-]?[0-9]+([.][0-9]+)?$';


-- =========================================================
-- 8. COMPROBACIÓN DE CEROS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de ceros
\echo ==========================================

SELECT
    COUNT(*) AS registros_cero
FROM proyecto.trolebus_desglosada_stage
WHERE BTRIM(afluencia) ~ '^[+-]?[0-9]+([.][0-9]+)?$'
  AND BTRIM(afluencia)::numeric = 0;


-- =========================================================
-- 9. COMPROBACIÓN DE VALORES DECIMALES
--
-- Valores numéricos cuya parte decimal no es cero.
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de valores decimales
\echo ==========================================

SELECT
    COUNT(*) AS registros_decimales
FROM proyecto.trolebus_desglosada_stage
WHERE BTRIM(afluencia) ~ '^[+-]?[0-9]+[.][0-9]+$'
  AND BTRIM(afluencia)::numeric
        <> TRUNC(BTRIM(afluencia)::numeric);


-- =========================================================
-- 10. COMPROBACIÓN DE NEGATIVOS
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de negativos
\echo ==========================================

SELECT
    COUNT(*) AS registros_negativos
FROM proyecto.trolebus_desglosada_stage
WHERE BTRIM(afluencia) ~ '^[+-]?[0-9]+([.][0-9]+)?$'
  AND BTRIM(afluencia)::numeric < 0;


-- =========================================================
-- 11. DOMINIO ORIGINAL DE TIPO_PAGO
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de tipo_pago
\echo ==========================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros
FROM proyecto.trolebus_desglosada_stage
GROUP BY BTRIM(tipo_pago)
ORDER BY BTRIM(tipo_pago);


-- =========================================================
-- 12. NÚMERO DE REPRESENTACIONES ORIGINALES DE LINEA
-- =========================================================

\echo
\echo ==========================================
\echo Representaciones originales de linea
\echo ==========================================

SELECT
    COUNT(DISTINCT BTRIM(linea)) AS representaciones_linea
FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 13. DOMINIO ORIGINAL DE LINEA
--
-- No se aplica homologación.
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de linea
\echo ==========================================

SELECT
    BTRIM(linea) AS linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT BTRIM(fecha)) AS dias_con_registro,
    MIN(BTRIM(fecha)) AS fecha_min,
    MAX(BTRIM(fecha)) AS fecha_max
FROM proyecto.trolebus_desglosada_stage
GROUP BY BTRIM(linea)
ORDER BY BTRIM(linea);


-- =========================================================
-- 14. GRANULARIDAD CANDIDATA
--
-- fecha × linea × tipo_pago
-- =========================================================

\echo
\echo ==========================================
\echo Granularidad candidata
\echo ==========================================

WITH grupos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(linea) AS linea,
        BTRIM(tipo_pago) AS tipo_pago,
        COUNT(*) AS repeticiones
    FROM proyecto.trolebus_desglosada_stage
    GROUP BY
        BTRIM(fecha),
        BTRIM(linea),
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
-- 15. ESTRUCTURA fecha × linea
--
-- Esperado:
-- 3 filas y 3 tipos de pago por clave.
-- =========================================================

\echo
\echo ==========================================
\echo Estructura fecha x linea
\echo ==========================================

WITH grupos AS (
    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(linea) AS linea,
        COUNT(*) AS filas,
        COUNT(DISTINCT BTRIM(tipo_pago)) AS tipos_pago
    FROM proyecto.trolebus_desglosada_stage
    GROUP BY
        BTRIM(fecha),
        BTRIM(linea)
)
SELECT
    filas,
    tipos_pago,
    COUNT(*) AS claves_fecha_linea
FROM grupos
GROUP BY
    filas,
    tipos_pago
ORDER BY
    filas,
    tipos_pago;


-- =========================================================
-- 16. MUESTRA RAW PRESERVADA EN STAGING
-- =========================================================

\echo
\echo ==========================================
\echo Muestra RAW preservada en STAGING
\echo ==========================================

SELECT
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia
FROM proyecto.trolebus_desglosada_stage
ORDER BY
    fecha,
    linea,
    tipo_pago
LIMIT 15;


-- =========================================================
-- 17. CONTROL AUTOMÁTICO DE INTEGRIDAD
-- =========================================================

DO $$
DECLARE
    total_stage           BIGINT;
    total_nan             BIGINT;
    total_no_numericos    BIGINT;
    total_ceros           BIGINT;
    total_decimales       BIGINT;
    total_negativos       BIGINT;
    total_tipos_pago      BIGINT;
    total_lineas_original BIGINT;
    total_claves          BIGINT;
    total_colisiones      BIGINT;
BEGIN

    SELECT COUNT(*)
    INTO total_stage
    FROM proyecto.trolebus_desglosada_stage;


    SELECT COUNT(*)
    INTO total_nan
    FROM proyecto.trolebus_desglosada_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';


    SELECT COUNT(*)
    INTO total_no_numericos
    FROM proyecto.trolebus_desglosada_stage
    WHERE BTRIM(afluencia)
          !~ '^[+-]?[0-9]+([.][0-9]+)?$';


    SELECT COUNT(*)
    INTO total_ceros
    FROM proyecto.trolebus_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+([.][0-9]+)?$'
      AND BTRIM(afluencia)::numeric = 0;


    SELECT COUNT(*)
    INTO total_decimales
    FROM proyecto.trolebus_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+[.][0-9]+$'
      AND BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric);


    SELECT COUNT(*)
    INTO total_negativos
    FROM proyecto.trolebus_desglosada_stage
    WHERE BTRIM(afluencia)
          ~ '^[+-]?[0-9]+([.][0-9]+)?$'
      AND BTRIM(afluencia)::numeric < 0;


    SELECT COUNT(DISTINCT BTRIM(tipo_pago))
    INTO total_tipos_pago
    FROM proyecto.trolebus_desglosada_stage;


    SELECT COUNT(DISTINCT BTRIM(linea))
    INTO total_lineas_original
    FROM proyecto.trolebus_desglosada_stage;


    WITH grupos AS (
        SELECT
            BTRIM(fecha),
            BTRIM(linea),
            BTRIM(tipo_pago),
            COUNT(*) AS repeticiones
        FROM proyecto.trolebus_desglosada_stage
        GROUP BY
            BTRIM(fecha),
            BTRIM(linea),
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


    IF total_stage <> 65013 THEN
        RAISE EXCEPTION
            'Conteo Trolebus incorrecto. Esperado: 65013. Obtenido: %',
            total_stage;
    END IF;


    IF total_nan <> 0 THEN
        RAISE EXCEPTION
            'Conteo NaN Trolebus incorrecto. Esperado: 0. Obtenido: %',
            total_nan;
    END IF;


    IF total_no_numericos <> 0 THEN
        RAISE EXCEPTION
            'Afluencias no numericas Trolebus. Esperado: 0. Obtenido: %',
            total_no_numericos;
    END IF;


    IF total_ceros <> 20246 THEN
        RAISE EXCEPTION
            'Conteo de ceros Trolebus incorrecto. Esperado: 20246. Obtenido: %',
            total_ceros;
    END IF;


    IF total_decimales <> 1419 THEN
        RAISE EXCEPTION
            'Conteo decimal Trolebus incorrecto. Esperado: 1419. Obtenido: %',
            total_decimales;
    END IF;


    IF total_negativos <> 0 THEN
        RAISE EXCEPTION
            'Conteo negativos Trolebus incorrecto. Esperado: 0. Obtenido: %',
            total_negativos;
    END IF;


    IF total_tipos_pago <> 3 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago Trolebus incorrecto. Esperado: 3. Obtenido: %',
            total_tipos_pago;
    END IF;


    IF total_lineas_original <> 43 THEN
        RAISE EXCEPTION
            'Representaciones linea Trolebus incorrectas. Esperado: 43. Obtenido: %',
            total_lineas_original;
    END IF;


    IF total_claves <> 65013 THEN
        RAISE EXCEPTION
            'Granularidad Trolebus inconsistente. Esperado: 65013 claves. Obtenido: %',
            total_claves;
    END IF;


    IF total_colisiones <> 0 THEN
        RAISE EXCEPTION
            'Colisiones Trolebus inesperadas. Esperado: 0. Obtenido: %',
            total_colisiones;
    END IF;


    RAISE NOTICE
        'Integridad STAGING Trolebus correcta. Registros: %, NaN: %, no numericos: %, ceros: %, decimales: %, negativos: %, tipos_pago: %, representaciones_linea: %, claves: %, colisiones: %',
        total_stage,
        total_nan,
        total_no_numericos,
        total_ceros,
        total_decimales,
        total_negativos,
        total_tipos_pago,
        total_lineas_original,
        total_claves,
        total_colisiones;

END
$$;


-- =========================================================
-- 18. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;


\echo
\echo ==========================================
\echo INGESTA TROLEBUS COMPLETADA
\echo ==========================================