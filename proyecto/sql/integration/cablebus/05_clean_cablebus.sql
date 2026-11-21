/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

    CAPA CLEAN

    Objetivos:
    - conservar el 100 % de los registros;
    - homologar únicamente las variantes de linea
      demostradas como equivalentes y seguras;
    - conservar linea_original para trazabilidad;
    - derivar variables temporales;
    - conservar los ceros;
    - conservar valores extremos;
    - marcar indicadores de calidad sin eliminar filas.

    Evidencia previa:
    - 7,972 registros TYPED.
    - 0 NULL de afluencia.
    - 207 ceros.
    - 0 negativos.
    - 0 valores decimales.
    - 0 duplicados exactos.
    - 0 colisiones en fecha × linea × tipo_pago.
    - 0 colisiones después de homologar linea.
    - 0 outliers IQR globales.
    - 5 representaciones originales de linea.
    - 3 líneas lógicas.

    Homologación aprobada:

        Línea 1 -> Linea 1
        Linea 1 -> Linea 1

        Línea 2 -> Linea 2
        Linea 2 -> Linea 2

        Linea 3 -> Linea 3

    IMPORTANTE:
    - RAW permanece intacto.
    - STAGING permanece intacto.
    - TYPED permanece intacto.
    - No se elimina ningún registro.
    - No se reemplazan valores por cero.
    - No se eliminan ceros.
    - No se eliminan outliers.
    - No se agregan filas.
    - No se imponen restricciones UNIQUE todavía.
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
    typed_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    linea_invalida       BIGINT;
    pago_invalido        BIGINT;
    colisiones_origen    BIGINT;

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


    SELECT COUNT(*)
    INTO linea_invalida
    FROM proyecto.cablebus_desglosada_typed
    WHERE BTRIM(linea) NOT IN (
        'Línea 1',
        'Línea 2',
        'Linea 1',
        'Linea 2',
        'Linea 3'
    );


    SELECT COUNT(*)
    INTO pago_invalido
    FROM proyecto.cablebus_desglosada_typed
    WHERE BTRIM(tipo_pago) NOT IN (
        'Prepago',
        'Gratuidad'
    );


    SELECT COUNT(*)
    INTO colisiones_origen
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
    ) AS x;


    IF typed_count <> 7972 THEN
        RAISE EXCEPTION
            'TYPED Cablebus cambió. Esperado: 7972. Obtenido: %',
            typed_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en TYPED: %',
            null_count;
    END IF;


    IF zero_count <> 207 THEN
        RAISE EXCEPTION
            'Ceros TYPED cambiaron. Esperado: 207. Obtenido: %',
            zero_count;
    END IF;


    IF linea_invalida <> 0 THEN
        RAISE EXCEPTION
            'Representaciones de linea no contempladas: %',
            linea_invalida;
    END IF;


    IF pago_invalido <> 0 THEN
        RAISE EXCEPTION
            'Tipos de pago no contemplados: %',
            pago_invalido;
    END IF;


    IF colisiones_origen <> 0 THEN
        RAISE EXCEPTION
            'TYPED contiene colisiones inesperadas: %',
            colisiones_origen;
    END IF;


    RAISE NOTICE
        'Precondiciones CLEAN Cablebus correctas. Filas: %, NULL: %, ceros: %, colisiones: %',
        typed_count,
        null_count,
        zero_count,
        colisiones_origen;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 5. ESTRUCTURA CLEAN
-- =========================================================

CREATE TABLE proyecto.cablebus_desglosada_clean (

    fecha                       DATE,
    anio                        SMALLINT,
    mes                         TEXT,

    mes_num                     SMALLINT,
    dia_semana_num              SMALLINT,
    dia_semana                  TEXT,
    es_fin_semana               BOOLEAN,

    linea_original              TEXT,
    linea                       TEXT,

    tipo_pago                   TEXT,
    afluencia                   BIGINT,

    es_afluencia_no_disponible  BOOLEAN,
    es_afluencia_cero           BOOLEAN,

    es_colision_clave_origen    BOOLEAN,
    es_colision_clave           BOOLEAN,

    es_duplicado_exacto         BOOLEAN,
    es_outlier_iqr_global       BOOLEAN,
    es_linea_homologada         BOOLEAN
);


-- =========================================================
-- 6. HOMOLOGACIÓN CONSERVADORA DE LINEA
-- =========================================================

WITH normalizado AS (

    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        BTRIM(linea) AS linea_original,

        CASE
            WHEN BTRIM(linea) IN (
                'Línea 1',
                'Linea 1'
            )
                THEN 'Linea 1'

            WHEN BTRIM(linea) IN (
                'Línea 2',
                'Linea 2'
            )
                THEN 'Linea 2'

            WHEN BTRIM(linea) = 'Linea 3'
                THEN 'Linea 3'

            ELSE BTRIM(linea)

        END AS linea,

        BTRIM(tipo_pago) AS tipo_pago,

        afluencia

    FROM proyecto.cablebus_desglosada_typed
),


-- =========================================================
-- 7. CUARTILES PARA MARCADOR IQR
-- =========================================================

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia)
            AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia)
            AS q3

    FROM normalizado
),


-- =========================================================
-- 8. PREPARAR INDICADORES DE CALIDAD
-- =========================================================

preparado AS (

    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea_original,
                tipo_pago
        ) AS cantidad_clave_origen,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea,
                tipo_pago
        ) AS cantidad_clave_clean,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                anio,
                mes,
                linea_original,
                tipo_pago,
                afluencia
        ) AS cantidad_duplicado_exacto,

        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM normalizado AS n

    CROSS JOIN cuartiles AS c
)


-- =========================================================
-- 9. INSERTAR CLEAN
-- =========================================================

INSERT INTO proyecto.cablebus_desglosada_clean (

    fecha,
    anio,
    mes,

    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,

    linea_original,
    linea,

    tipo_pago,
    afluencia,

    es_afluencia_no_disponible,
    es_afluencia_cero,

    es_colision_clave_origen,
    es_colision_clave,

    es_duplicado_exacto,
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

    linea_original,
    linea,

    tipo_pago,
    afluencia,

    afluencia IS NULL,

    COALESCE(
        afluencia = 0,
        FALSE
    ),

    cantidad_clave_origen > 1,

    cantidad_clave_clean > 1,

    cantidad_duplicado_exacto > 1,

    (
        afluencia < q1 - 1.5 * iqr
        OR
        afluencia > q3 + 1.5 * iqr
    ),

    linea_original <> linea

FROM preparado;


-- =========================================================
-- 10. CONCILIACIÓN TYPED -> CLEAN
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_typed)
    ) AS diferencia;


-- =========================================================
-- 11. DOMINIO DE LINEA CLEAN
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS dias_con_registro,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.cablebus_desglosada_clean

GROUP BY linea
ORDER BY linea;


SELECT
    COUNT(DISTINCT linea)
        AS lineas_distintas_clean

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 12. TRAZABILIDAD DE HOMOLOGACIÓN
-- =========================================================

SELECT
    linea_original,
    linea,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_clean

GROUP BY
    linea_original,
    linea

ORDER BY
    linea,
    linea_original;


-- =========================================================
-- 13. TIPO DE PAGO CLEAN
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_clean

GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 14. FLAGS DE CALIDAD
-- =========================================================

SELECT

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS no_disponibles,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_colision_clave_origen
    ) AS filas_colision_origen,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_colision_clean,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers,

    COUNT(*) FILTER (
        WHERE es_linea_homologada
    ) AS filas_linea_homologada

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 15. COHERENCIA TEMPORAL
-- =========================================================

SELECT

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

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 16. COLISIONES CLEAN
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        linea,
        tipo_pago

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_colision,

    COALESCE(
        SUM(veces),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(veces - 1),
        0
    ) AS registros_excedentes,

    COALESCE(
        MAX(veces),
        0
    ) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 17. DUPLICADOS EXACTOS CLEAN
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        anio,
        mes,
        linea_original,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        anio,
        mes,
        linea_original,
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
-- 18. CEROS PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.cablebus_desglosada_typed
        WHERE afluencia = 0
    ) AS ceros_typed,

    (
        SELECT COUNT(*)
        FROM proyecto.cablebus_desglosada_clean
        WHERE afluencia = 0
    ) AS ceros_clean;


-- =========================================================
-- 19. VALIDACIÓN AUTOMÁTICA CLEAN
-- =========================================================

DO $$
DECLARE

    clean_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    colision_count       BIGINT;
    duplicado_count      BIGINT;
    outlier_count        BIGINT;
    lineas_count         BIGINT;
    homologadas_count    BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.cablebus_desglosada_clean;


    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO colision_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_colision_clave;


    SELECT COUNT(*)
    INTO duplicado_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_duplicado_exacto;


    SELECT COUNT(*)
    INTO outlier_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_outlier_iqr_global;


    SELECT COUNT(DISTINCT linea)
    INTO lineas_count
    FROM proyecto.cablebus_desglosada_clean;


    SELECT COUNT(*)
    INTO homologadas_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_linea_homologada;


    IF clean_count <> 7972 THEN
        RAISE EXCEPTION
            'CLEAN incorrecto. Esperado: 7972. Obtenido: %',
            clean_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en CLEAN: %',
            null_count;
    END IF;


    IF zero_count <> 207 THEN
        RAISE EXCEPTION
            'Ceros CLEAN incorrectos. Esperado: 207. Obtenido: %',
            zero_count;
    END IF;


    IF colision_count <> 0 THEN
        RAISE EXCEPTION
            'La homologación generó colisiones: %',
            colision_count;
    END IF;


    IF duplicado_count <> 0 THEN
        RAISE EXCEPTION
            'Duplicados exactos inesperados: %',
            duplicado_count;
    END IF;


    IF outlier_count <> 0 THEN
        RAISE EXCEPTION
            'Outliers distintos al perfilado. Esperado: 0. Obtenido: %',
            outlier_count;
    END IF;


    IF lineas_count <> 3 THEN
        RAISE EXCEPTION
            'Dominio CLEAN inesperado. Esperadas: 3 lineas. Obtenidas: %',
            lineas_count;
    END IF;


    IF homologadas_count <> 4864 THEN
        RAISE EXCEPTION
            'Filas homologadas inesperadas. Esperado: 4864. Obtenido: %',
            homologadas_count;
    END IF;


    RAISE NOTICE
        'CLEAN Cablebus validado. Filas: %, NULL: %, ceros: %, colisiones: %, duplicados: %, outliers: %, lineas: %, homologadas: %',
        clean_count,
        null_count,
        zero_count,
        colision_count,
        duplicado_count,
        outlier_count,
        lineas_count,
        homologadas_count;

END
$$;


-- =========================================================
-- 20. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;