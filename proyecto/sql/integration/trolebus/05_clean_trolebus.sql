/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

    CAPA CLEAN

    Objetivos:
    - conservar el 100 % de los registros;
    - homologar únicamente variantes gráficas de linea
      cuya equivalencia fue demostrada;
    - conservar linea_original para trazabilidad;
    - derivar variables temporales;
    - conservar ceros;
    - conservar decimales;
    - conservar posibles outliers;
    - marcar indicadores de calidad sin eliminar filas.

    Evidencia previa:

    TYPED:
    - 65,013 registros.
    - 0 NULL en afluencia.
    - 20,246 ceros.
    - 1,419 valores decimales.
    - 0 negativos.
    - 0 duplicados exactos.
    - 0 colisiones en:
        fecha × linea × tipo_pago.
    - 43 representaciones originales de linea.
    - 3 tipos de pago.

    Perfilado:
    - normalización gráfica:
        43 representaciones originales
        -> 17 categorías gráficas.
    - 65,013 claves después de normalización.
    - 0 colisiones después de normalización.
    - 6,345 posibles outliers IQR globales.

    Granularidad validada:
        fecha × linea × tipo_pago

    PRINCIPIOS:
    - RAW permanece intacto.
    - STAGING permanece intacto.
    - TYPED permanece intacto.
    - no se elimina ningún registro.
    - no se agregan registros.
    - no se redondea afluencia.
    - no se eliminan ceros.
    - no se eliminan outliers.
    - no se fusionan servicios semánticamente distintos.
    - no se imponen restricciones UNIQUE todavía.

    Categorías CLEAN esperadas:

        Linea 0
        Linea 1
        Linea 1 Nochebus
        Linea 2
        Linea 3
        Linea 4
        Linea 5
        Linea 6
        Linea 7
        Linea 8
        Linea 9
        Linea 10
        Linea 10 (Trolebus elevado)
        Linea 11
        Linea 12
        Linea 13
        Linea 14
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. PRECONDICIONES TYPED
-- =========================================================

DO $$
DECLARE

    typed_count         BIGINT;
    null_count          BIGINT;
    zero_count          BIGINT;
    decimal_count       BIGINT;
    negative_count      BIGINT;
    linea_count         BIGINT;
    pago_count          BIGINT;
    collision_count     BIGINT;

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
    INTO linea_count
    FROM proyecto.trolebus_desglosada_typed;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO pago_count
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

    ) AS x;


    IF typed_count <> 65013 THEN
        RAISE EXCEPTION
            'TYPED Trolebus cambió. Esperado: 65013. Obtenido: %',
            typed_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en TYPED: %',
            null_count;
    END IF;


    IF zero_count <> 20246 THEN
        RAISE EXCEPTION
            'Ceros TYPED cambiaron. Esperado: 20246. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 1419 THEN
        RAISE EXCEPTION
            'Decimales TYPED cambiaron. Esperado: 1419. Obtenido: %',
            decimal_count;
    END IF;


    IF negative_count <> 0 THEN
        RAISE EXCEPTION
            'Negativos inesperados en TYPED: %',
            negative_count;
    END IF;


    IF linea_count <> 43 THEN
        RAISE EXCEPTION
            'Representaciones de linea cambiaron. Esperadas: 43. Obtenidas: %',
            linea_count;
    END IF;


    IF pago_count <> 3 THEN
        RAISE EXCEPTION
            'Tipos de pago cambiaron. Esperados: 3. Obtenidos: %',
            pago_count;
    END IF;


    IF collision_count <> 0 THEN
        RAISE EXCEPTION
            'TYPED contiene colisiones inesperadas: %',
            collision_count;
    END IF;


    RAISE NOTICE
        'Precondiciones CLEAN Trolebus correctas. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, lineas: %, pagos: %, colisiones: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        linea_count,
        pago_count,
        collision_count;

END
$$;


-- =========================================================
-- 3. TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 5. ESTRUCTURA CLEAN
-- =========================================================

CREATE TABLE proyecto.trolebus_desglosada_clean (

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
    afluencia                   NUMERIC(19,13),

    es_afluencia_no_disponible  BOOLEAN,
    es_afluencia_cero           BOOLEAN,
    es_afluencia_decimal        BOOLEAN,

    es_colision_clave_origen    BOOLEAN,
    es_colision_clave           BOOLEAN,

    es_duplicado_exacto         BOOLEAN,
    es_outlier_iqr_global       BOOLEAN,
    es_linea_homologada         BOOLEAN
);


-- =========================================================
-- 6. NORMALIZACIÓN GRÁFICA
--
-- Solo se eliminan diferencias de:
-- - mayúsculas / minúsculas;
-- - acentos;
-- - guiones bajos;
-- - espacios repetidos.
--
-- No se eliminan términos semánticos como:
-- - Nochebus
-- - Trolebus elevado
-- =========================================================

WITH base AS (

    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        BTRIM(linea) AS linea_original,

        BTRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    REPLACE(
                        LOWER(BTRIM(linea)),
                        '_',
                        ' '
                    ),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) AS linea_grafica,

        BTRIM(tipo_pago) AS tipo_pago,

        afluencia

    FROM proyecto.trolebus_desglosada_typed
),


-- =========================================================
-- 7. ASIGNACIÓN DE CATEGORÍAS CANÓNICAS
-- =========================================================

normalizado AS (

    SELECT
        fecha,
        anio,
        mes,

        linea_original,

        CASE linea_grafica

            WHEN 'linea 0'
                THEN 'Linea 0'

            WHEN 'linea 1'
                THEN 'Linea 1'

            WHEN 'linea 1 nochebus'
                THEN 'Linea 1 Nochebus'

            WHEN 'linea 2'
                THEN 'Linea 2'

            WHEN 'linea 3'
                THEN 'Linea 3'

            WHEN 'linea 4'
                THEN 'Linea 4'

            WHEN 'linea 5'
                THEN 'Linea 5'

            WHEN 'linea 6'
                THEN 'Linea 6'

            WHEN 'linea 7'
                THEN 'Linea 7'

            WHEN 'linea 8'
                THEN 'Linea 8'

            WHEN 'linea 9'
                THEN 'Linea 9'

            WHEN 'linea 10'
                THEN 'Linea 10'

            WHEN 'linea 10 (trolebus elevado)'
                THEN 'Linea 10 (Trolebus elevado)'

            WHEN 'linea 11'
                THEN 'Linea 11'

            WHEN 'linea 12'
                THEN 'Linea 12'

            WHEN 'linea 13'
                THEN 'Linea 13'

            WHEN 'linea 14'
                THEN 'Linea 14'

            ELSE NULL

        END AS linea,

        tipo_pago,
        afluencia

    FROM base
),


-- =========================================================
-- 8. CUARTILES PARA MARCADOR IQR
-- =========================================================

cuartiles AS (

    SELECT

        percentile_cont(0.25)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q3

    FROM normalizado
),


-- =========================================================
-- 9. PREPARAR INDICADORES
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
-- 10. INSERTAR CLEAN
-- =========================================================

INSERT INTO proyecto.trolebus_desglosada_clean (

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
    es_afluencia_decimal,

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

    COALESCE(
        afluencia <> TRUNC(afluencia),
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
-- 11. CONCILIACIÓN TYPED -> CLEAN
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_typed
    ) AS typed,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_clean
    ) AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_clean)

        -

        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_typed)

    ) AS diferencia;


-- =========================================================
-- 12. DOMINIO CLEAN
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS dias_con_registro,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.trolebus_desglosada_clean

GROUP BY linea

ORDER BY linea;


SELECT
    COUNT(DISTINCT linea)
        AS lineas_distintas_clean

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 13. TRAZABILIDAD DE HOMOLOGACIÓN
-- =========================================================

SELECT
    linea_original,
    linea,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_clean

GROUP BY
    linea_original,
    linea

ORDER BY
    linea,
    linea_original;


-- =========================================================
-- 14. DOMINIO DE TIPO_PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_clean

GROUP BY tipo_pago

ORDER BY tipo_pago;


-- =========================================================
-- 15. FLAGS DE CALIDAD
-- =========================================================

SELECT

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS no_disponibles,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_afluencia_decimal
    ) AS decimales,

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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 16. COHERENCIA TEMPORAL
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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 17. COLISIONES CLEAN
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.trolebus_desglosada_clean

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
-- 18. DUPLICADOS EXACTOS CLEAN
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

    FROM proyecto.trolebus_desglosada_clean

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
-- 19. CEROS Y DECIMALES PRESERVADOS
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_typed
        WHERE afluencia = 0
    ) AS ceros_typed,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_clean
        WHERE afluencia = 0
    ) AS ceros_clean,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_typed
        WHERE afluencia <> TRUNC(afluencia)
    ) AS decimales_typed,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_clean
        WHERE afluencia <> TRUNC(afluencia)
    ) AS decimales_clean;


-- =========================================================
-- 20. ESTRUCTURA fecha × linea
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        COUNT(*) AS filas,
        COUNT(DISTINCT tipo_pago)
            AS tipos_pago

    FROM proyecto.trolebus_desglosada_clean

    GROUP BY
        fecha,
        linea
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
-- 21. CONTEO DE CLAVES fecha × linea
-- =========================================================

SELECT
    COUNT(*) AS claves_fecha_linea

FROM (

    SELECT
        fecha,
        linea

    FROM proyecto.trolebus_desglosada_clean

    GROUP BY
        fecha,
        linea

) AS claves;


-- =========================================================
-- 22. VALIDACIÓN AUTOMÁTICA CLEAN
-- =========================================================

DO $$
DECLARE

    clean_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    decimal_count        BIGINT;
    negative_count       BIGINT;

    colision_count       BIGINT;
    duplicado_count      BIGINT;
    outlier_count        BIGINT;

    lineas_count         BIGINT;
    payment_count        BIGINT;

    homologadas_count    BIGINT;

    temporal_errors      BIGINT;
    fecha_count          BIGINT;
    fecha_linea_count    BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia IS NULL
       OR linea IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia < 0;


    SELECT COUNT(*)
    INTO colision_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE es_colision_clave;


    SELECT COUNT(*)
    INTO duplicado_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE es_duplicado_exacto;


    SELECT COUNT(*)
    INTO outlier_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE es_outlier_iqr_global;


    SELECT COUNT(DISTINCT linea)
    INTO lineas_count
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(*)
    INTO homologadas_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE es_linea_homologada;


    SELECT

        COUNT(*) FILTER (
            WHERE anio <>
                  EXTRACT(YEAR FROM fecha)::SMALLINT
        )

        +

        COUNT(*) FILTER (
            WHERE mes_num <>
                  EXTRACT(MONTH FROM fecha)::SMALLINT
        )

        +

        COUNT(*) FILTER (
            WHERE dia_semana_num <>
                  EXTRACT(ISODOW FROM fecha)::SMALLINT
        )

    INTO temporal_errors

    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(DISTINCT fecha)
    INTO fecha_count
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(*)
    INTO fecha_linea_count

    FROM (

        SELECT
            fecha,
            linea

        FROM proyecto.trolebus_desglosada_clean

        GROUP BY
            fecha,
            linea

    ) AS x;


    IF clean_count <> 65013 THEN
        RAISE EXCEPTION
            'CLEAN incorrecto. Esperado: 65013. Obtenido: %',
            clean_count;
    END IF;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en CLEAN: %',
            null_count;
    END IF;


    IF zero_count <> 20246 THEN
        RAISE EXCEPTION
            'Ceros CLEAN incorrectos. Esperado: 20246. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 1419 THEN
        RAISE EXCEPTION
            'Decimales CLEAN incorrectos. Esperado: 1419. Obtenido: %',
            decimal_count;
    END IF;


    IF negative_count <> 0 THEN
        RAISE EXCEPTION
            'Negativos inesperados en CLEAN: %',
            negative_count;
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


    IF outlier_count <> 6345 THEN
        RAISE EXCEPTION
            'Outliers distintos al perfilado. Esperado: 6345. Obtenido: %',
            outlier_count;
    END IF;


    IF lineas_count <> 17 THEN
        RAISE EXCEPTION
            'Dominio CLEAN inesperado. Esperadas: 17 lineas. Obtenidas: %',
            lineas_count;
    END IF;


    IF payment_count <> 3 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago inesperado. Esperados: 3. Obtenidos: %',
            payment_count;
    END IF;


    /*
        Solo las 2,745 filas ya publicadas exactamente
        con las etiquetas canónicas "Linea N" permanecen
        textualmente iguales.

        65,013 - 2,745 = 62,268
    */

    IF homologadas_count <> 62268 THEN
        RAISE EXCEPTION
            'Filas homologadas inesperadas. Esperado: 62268. Obtenido: %',
            homologadas_count;
    END IF;


    IF temporal_errors <> 0 THEN
        RAISE EXCEPTION
            'Errores temporales CLEAN: %',
            temporal_errors;
    END IF;


    IF fecha_count <> 1765 THEN
        RAISE EXCEPTION
            'Fechas distintas incorrectas. Esperado: 1765. Obtenido: %',
            fecha_count;
    END IF;


    IF fecha_linea_count <> 21671 THEN
        RAISE EXCEPTION
            'Claves fecha x linea incorrectas. Esperado: 21671. Obtenido: %',
            fecha_linea_count;
    END IF;


    RAISE NOTICE
        'CLEAN Trolebus validado. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, colisiones: %, duplicados: %, outliers: %, lineas: %, pagos: %, homologadas: %, fechas: %, claves fecha-linea: %',
        clean_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        colision_count,
        duplicado_count,
        outlier_count,
        lineas_count,
        payment_count,
        homologadas_count,
        fecha_count,
        fecha_linea_count;

END
$$;


-- =========================================================
-- 23. COMMIT
-- =========================================================

COMMIT;