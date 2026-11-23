/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

    Capa: STAGING

    Objetivo:
    Recibir la representación original del CSV RAW
    utilizando columnas TEXT antes de aplicar tipado,
    homologación, normalización o limpieza.

    Fuente física observada:
    fecha,mes,anio,linea,tipo_pago,afluencia

    Evidencia previa RAW:
    - 65,013 filas.
    - 6 columnas.
    - 0 filas malformadas.
    - Cobertura observada:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 0 fechas inválidas.
    - 0 inconsistencias fecha <-> anio.
    - 0 inconsistencias fecha <-> mes.
    - 3 tipos de pago:
        Boleto
        Prepago
        Gratuidad
    - 21,671 registros por cada tipo de pago.
    - 43 representaciones originales de linea.
    - 17 representaciones después de una
      normalización gráfica exploratoria.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.
    - 20,246 ceros.
    - 0 valores no numéricos / NaN en afluencia.
    - 0 valores negativos.
    - 1,419 valores decimales.

    Granularidad candidata observada:

        fecha × linea × tipo_pago

    IMPORTANTE:
    La normalización exploratoria de linea demostró
    que variantes gráficas como:

        Línea 1
        Linea 1
        linea_1

    pueden compartir una representación gráfica común
    sin generar colisiones.

    Sin embargo, STAGING NO realiza dicha homologación.

    También existen entidades semánticamente específicas,
    por ejemplo:

        Línea 1 Nochebús
        Línea 10 (Trolebús elevado)

    que no deben fusionarse automáticamente con otras líneas.

    AFLUENCIA:
    Se observaron 1,419 valores con componente decimal,
    principalmente durante 2026.

    STAGING debe preservar esos valores exactamente como
    aparecen en RAW. No se redondean ni convierten todavía
    a un tipo numérico.

    PRINCIPIOS:
    - RAW permanece intacto.
    - No se corrigen valores en STAGING.
    - No se eliminan registros.
    - No se homologan representaciones de linea.
    - No se redondean afluencias.
    - Los ceros permanecen como texto "0".
    - No se imponen restricciones UNIQUE.
    - La granularidad sigue siendo candidata hasta
      completar el perfilado SQL.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING TROLEBÚS
-- =========================================================

DROP TABLE IF EXISTS proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 3. STAGING - TROLEBÚS DESGLOSADA
--
-- Estructura RAW observada:
-- fecha,mes,anio,linea,tipo_pago,afluencia
--
-- Todas las columnas se reciben como TEXT.
-- =========================================================

CREATE TABLE proyecto.trolebus_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
    linea       TEXT,
    tipo_pago   TEXT,
    afluencia   TEXT
);


-- =========================================================
-- 4. VALIDACIÓN DE EXISTENCIA Y NÚMERO DE COLUMNAS
-- =========================================================

SELECT
    table_name,
    COUNT(*) AS numero_columnas
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name = 'trolebus_desglosada_stage'
GROUP BY table_name;


-- =========================================================
-- 5. VALIDACIÓN DE ORDEN, NOMBRE Y TIPO
-- =========================================================

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name = 'trolebus_desglosada_stage'
ORDER BY ordinal_position;


-- =========================================================
-- 6. CONTEO INICIAL
--
-- Antes de la ingesta debe ser 0.
-- =========================================================

SELECT
    COUNT(*) AS registros_iniciales
FROM proyecto.trolebus_desglosada_stage;