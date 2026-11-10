/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

    CAPA CLEAN

    Objetivos:
    - conservar el 100 % de los registros;
    - aplicar únicamente homologaciones de servicio
      demostradas como seguras;
    - conservar servicio original para trazabilidad;
    - derivar variables temporales;
    - preservar NULL como afluencia no disponible;
    - conservar ceros, decimales, duplicados y colisiones;
    - marcar posibles outliers sin eliminarlos.

    IMPORTANTE:
    - RAW permanece intacto.
    - STAGING permanece intacto.
    - TYPED permanece intacto.
    - No se elimina ningún registro.
    - NULL != 0.
    - No se eliminan outliers.
    - No se eliminan duplicados exactos.
    - No se resuelven artificialmente las colisiones de ATENEA.
    - No se homologan variantes de Ecobús ni Nochebús
      porque las pruebas demostraron que crearían
      colisiones artificiales.
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
    typed_count     BIGINT;
    null_count      BIGINT;
    zero_count      BIGINT;
    decimal_count   BIGINT;
    pagos_invalidos BIGINT;
BEGIN

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

    SELECT COUNT(*)
    INTO pagos_invalidos
    FROM proyecto.rtp_desglosada_typed
    WHERE tipo_pago NOT IN (
        'Boleto',
        'Gratuidad',
        'Prepago'
    );

    IF typed_count <> 41676 THEN
        RAISE EXCEPTION
            'TYPED cambió. Esperado: 41676. Obtenido: %',
            typed_count;
    END IF;

    IF null_count <> 187 THEN
        RAISE EXCEPTION
            'NULL TYPED cambiaron. Esperado: 187. Obtenido: %',
            null_count;
    END IF;

    IF zero_count <> 7450 THEN
        RAISE EXCEPTION
            'Ceros TYPED cambiaron. Esperado: 7450. Obtenido: %',
            zero_count;
    END IF;

    IF decimal_count <> 53 THEN
        RAISE EXCEPTION
            'Decimales TYPED cambiaron. Esperado: 53. Obtenido: %',
            decimal_count;
    END IF;

    IF pagos_invalidos <> 0 THEN
        RAISE EXCEPTION
            'Existen tipos de pago no contemplados: %',
            pagos_invalidos;
    END IF;

    RAISE NOTICE
        'Precondiciones TYPED RTP correctas. Filas: %, NULL: %, ceros: %, decimales: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count;

END
$$;


-- =========================================================
-- 3. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.rtp_desglosada_clean;


-- =========================================================
-- 5. ESTRUCTURA CLEAN
-- =========================================================

CREATE TABLE proyecto.rtp_desglosada_clean (

    fecha                           DATE,
    anio                            SMALLINT,
    mes                             TEXT,

    mes_num                         SMALLINT,
    dia_semana_num                  SMALLINT,
    dia_semana                      TEXT,
    es_fin_semana                   BOOLEAN,

    servicio_original               TEXT,
    servicio                        TEXT,

    tipo_pago                       TEXT,
    afluencia                       NUMERIC,

    es_afluencia_no_disponible      BOOLEAN,
    es_afluencia_cero               BOOLEAN,

    es_colision_clave_origen        BOOLEAN,
    es_colision_clave               BOOLEAN,

    es_duplicado_exacto             BOOLEAN,
    es_outlier_iqr_global           BOOLEAN,
    es_servicio_homologado          BOOLEAN
);


-- =========================================================
-- 6. NORMALIZACIÓN CONSERVADORA
-- =========================================================

WITH normalizado AS (

    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        BTRIM(servicio) AS servicio_original,

        CASE

            WHEN BTRIM(servicio) IN (
                'Atenea',
                'ATENEA'
            )
                THEN 'Atenea'

            WHEN BTRIM(servicio) IN (
                'Expreso',
                'EXPRESO'
            )
                THEN 'Expreso'

            WHEN BTRIM(servicio) IN (
                'Ordinario',
                'ORDINARIO'
            )
                THEN 'Ordinario'

            WHEN BTRIM(servicio) IN (
                'S/Metro',
                'S/METRO'
            )
                THEN 'S/Metro'

            WHEN BTRIM(servicio) IN (
                'Expdirecto',
                'EXPDIRECTO'
            )
                THEN 'Expdirecto'

            WHEN BTRIM(servicio) IN (
                'Circuito Hospitales',
                'CIRCUITO HOSPITALES'
            )
                THEN 'Circuito Hospitales'

            WHEN BTRIM(servicio) IN (
                'Apoyo Concesionado',
                'Apoyo concesionado',
                'APOYO A CONCESIONADO'
            )
                THEN 'Apoyo Concesionado'

            WHEN BTRIM(servicio) IN (
                'Servicios Temporales',
                'SERVICIOS TEMPORALES'
            )
                THEN 'Servicios Temporales'

            /*
                IMPORTANTE:

                NO homologar todavía:

                Ecobús
                ECOBÚS
                ECOBUS
                ECOB S

                Nochebús
                NOCHEBÚS
                NOCHEBUS
                NOCHEB S

                porque su homologación generó
                153 colisiones adicionales.
            */

            ELSE BTRIM(servicio)

        END AS servicio,

        BTRIM(tipo_pago) AS tipo_pago,

        afluencia

    FROM proyecto.rtp_desglosada_typed
),


-- =========================================================
-- 7. CUARTILES PARA OUTLIERS
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

    WHERE afluencia IS NOT NULL
),


-- =========================================================
-- 8. MARCADORES DE CALIDAD
-- =========================================================

preparado AS (

    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                servicio_original,
                tipo_pago
        ) AS cantidad_clave_origen,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                servicio,
                tipo_pago
        ) AS cantidad_clave_clean,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                anio,
                mes,
                servicio_original,
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

INSERT INTO proyecto.rtp_desglosada_clean (

    fecha,
    anio,
    mes,

    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,

    servicio_original,
    servicio,

    tipo_pago,
    afluencia,

    es_afluencia_no_disponible,
    es_afluencia_cero,

    es_colision_clave_origen,
    es_colision_clave,

    es_duplicado_exacto,
    es_outlier_iqr_global,
    es_servicio_homologado
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

    servicio_original,
    servicio,

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

    CASE
        WHEN afluencia IS NULL
            THEN FALSE

        ELSE (
            afluencia < q1 - 1.5 * iqr
            OR
            afluencia > q3 + 1.5 * iqr
        )
    END,

    servicio_original <> servicio

FROM preparado;


-- =========================================================
-- 10. CONCILIACIÓN TYPED -> CLEAN
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.rtp_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.rtp_desglosada_typed)
    ) AS diferencia;


-- =========================================================
-- 11. DOMINIO DE SERVICIO CLEAN
-- =========================================================

SELECT
    servicio,
    COUNT(*) AS registros

FROM proyecto.rtp_desglosada_clean

GROUP BY servicio
ORDER BY servicio;


SELECT
    COUNT(DISTINCT servicio)
        AS servicios_distintos_clean

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 12. FLAGS DE CALIDAD
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
        WHERE es_servicio_homologado
    ) AS filas_servicio_homologado

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 13. NULL Y BANDERA
-- =========================================================

SELECT

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

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 14. DECIMALES CONSERVADOS
-- =========================================================

SELECT
    COUNT(*) AS valores_decimales

FROM proyecto.rtp_desglosada_clean

WHERE afluencia IS NOT NULL
  AND afluencia <> TRUNC(afluencia);


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

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 16. COLISIONES CLEAN
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        servicio,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_clean

    GROUP BY
        fecha,
        servicio,
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
        servicio_original,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_clean

    GROUP BY
        fecha,
        anio,
        mes,
        servicio_original,
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
-- 18. VALIDACIÓN AUTOMÁTICA CLEAN
-- =========================================================

DO $$
DECLARE

    clean_count          BIGINT;
    null_count           BIGINT;
    zero_count           BIGINT;
    decimal_count        BIGINT;

    colision_origen      BIGINT;
    colision_clean       BIGINT;

    duplicados           BIGINT;
    outliers             BIGINT;

    servicios            BIGINT;
    homologadas          BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.rtp_desglosada_clean;

    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia IS NULL;

    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia = 0;

    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia IS NOT NULL
      AND afluencia <> TRUNC(afluencia);

    SELECT COUNT(*)
    INTO colision_origen
    FROM proyecto.rtp_desglosada_clean
    WHERE es_colision_clave_origen;

    SELECT COUNT(*)
    INTO colision_clean
    FROM proyecto.rtp_desglosada_clean
    WHERE es_colision_clave;

    SELECT COUNT(*)
    INTO duplicados
    FROM proyecto.rtp_desglosada_clean
    WHERE es_duplicado_exacto;

    SELECT COUNT(*)
    INTO outliers
    FROM proyecto.rtp_desglosada_clean
    WHERE es_outlier_iqr_global;

    SELECT COUNT(DISTINCT servicio)
    INTO servicios
    FROM proyecto.rtp_desglosada_clean;

    SELECT COUNT(*)
    INTO homologadas
    FROM proyecto.rtp_desglosada_clean
    WHERE es_servicio_homologado;


    IF clean_count <> 41676 THEN
        RAISE EXCEPTION
            'CLEAN incorrecto. Esperado 41676, obtenido %',
            clean_count;
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

    IF colision_origen <> 552 THEN
        RAISE EXCEPTION
            'Filas con colisión origen inesperadas: %',
            colision_origen;
    END IF;

    IF colision_clean <> 552 THEN
        RAISE EXCEPTION
            'La homologación generó nuevas colisiones. Filas CLEAN: %',
            colision_clean;
    END IF;

    IF duplicados <> 162 THEN
        RAISE EXCEPTION
            'Duplicados exactos inesperados. Esperado 162, obtenido %',
            duplicados;
    END IF;

    IF outliers <> 4688 THEN
        RAISE EXCEPTION
            'Outliers distintos al perfilado. Esperado 4688, obtenido %',
            outliers;
    END IF;

    IF servicios <> 21 THEN
        RAISE EXCEPTION
            'Dominio CLEAN inesperado. Esperado 21 servicios, obtenido %',
            servicios;
    END IF;

    IF homologadas <> 11640 THEN
        RAISE EXCEPTION
            'Filas homologadas inesperadas. Esperado 11640, obtenido %',
            homologadas;
    END IF;


    RAISE NOTICE
        'CLEAN RTP correcto. Filas: %, NULL: %, ceros: %, decimales: %, colisiones: %, duplicados: %, outliers: %, servicios: %, homologadas: %',
        clean_count,
        null_count,
        zero_count,
        decimal_count,
        colision_clean,
        duplicados,
        outliers,
        servicios,
        homologadas;

END
$$;


-- =========================================================
-- 19. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;