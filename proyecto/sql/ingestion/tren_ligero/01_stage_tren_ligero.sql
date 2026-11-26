/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

    Capa: STAGING

    Objetivo:
    Recibir la representación original del CSV RAW
    utilizando columnas TEXT antes de aplicar tipado,
    normalización, limpieza o integración semántica.

    Fuente física observada:
    fecha,mes,anio,tipo_pago,afluencia

    Evidencia previa RAW:
    - 3,530 filas.
    - 5 columnas.
    - 0 filas malformadas.
    - Cobertura observada:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 0 fechas faltantes dentro de la cobertura.
    - 0 fechas inválidas.
    - 0 inconsistencias fecha <-> anio.
    - 0 inconsistencias fecha <-> mes.
    - 2 tipos de pago:
        Gratuidad
        Prepago
    - 1,765 registros por cada tipo de pago.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × tipo_pago.
    - 0 valores vacíos.
    - 0 NaN / valores no numéricos en afluencia.
    - 0 ceros.
    - 0 valores negativos.
    - 516 valores decimales.

    Granularidad candidata observada:

        fecha × tipo_pago

    Estructura observada:

        1,765 fechas
        × 2 tipos de pago
        = 3,530 registros

    IMPORTANTE:
    El recurso RAW de Tren Ligero NO contiene una columna
    denominada linea.

    Por tanto, en esta etapa NO se asume:

        unidad_operativa = linea

    ni se crea artificialmente una unidad operativa.

    La equivalencia con la dimensión conceptual
    unidad_operativa será evaluada posteriormente durante
    el checkpoint de compatibilidad multisistema.

    AFLUENCIA:
    Se observaron 516 valores con componente decimal.

    STAGING debe preservar esos valores exactamente como
    aparecen en RAW. No se redondean ni convierten todavía
    a un tipo numérico.

    PRINCIPIOS:
    - RAW permanece intacto.
    - No se corrigen valores en STAGING.
    - No se eliminan registros.
    - No se inventa una columna linea.
    - No se inventa unidad_operativa.
    - No se redondean afluencias.
    - No se imponen restricciones UNIQUE.
    - Todas las columnas permanecen como TEXT.
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
-- 2. REINICIO CONTROLADO DE STAGING TREN LIGERO
-- =========================================================

DROP TABLE IF EXISTS proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 3. STAGING - TREN LIGERO DESGLOSADA
--
-- Estructura RAW observada:
-- fecha,mes,anio,tipo_pago,afluencia
--
-- Todas las columnas se reciben como TEXT.
-- =========================================================

CREATE TABLE proyecto.tren_ligero_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
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
  AND table_name = 'tren_ligero_desglosada_stage'
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
  AND table_name = 'tren_ligero_desglosada_stage'
ORDER BY ordinal_position;


-- =========================================================
-- 6. CONTEO INICIAL
--
-- Antes de la ingesta debe ser 0.
-- =========================================================

SELECT
    COUNT(*) AS registros_iniciales
FROM proyecto.tren_ligero_desglosada_stage;