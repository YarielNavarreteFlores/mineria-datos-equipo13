-- =========================================================
-- PRÁCTICA 01 - MINERÍA DE DATOS - 2026-B
-- Proyecto:
-- Inteligencia de demanda de los principales sistemas
-- de transporte público de la Ciudad de México
--
-- Este script crea la estructura mínima necesaria para
-- importar los conjuntos RAW utilizados en la práctica.
-- =========================================================

CREATE SCHEMA IF NOT EXISTS practica01;

-- =========================================================
-- TABLA RAW: METRO SIMPLE
-- Granularidad esperada:
-- fecha + linea + estacion
-- =========================================================

DROP TABLE IF EXISTS practica01.metro_simple_raw;

CREATE TABLE practica01.metro_simple_raw (
    fecha       DATE,
    anio        INTEGER,
    mes         VARCHAR(20),
    linea       VARCHAR(100),
    estacion    VARCHAR(200),
    afluencia   INTEGER
);

-- =========================================================
-- TABLA RAW: METRO DESGLOSADA
-- Granularidad:
-- fecha + linea + estacion + tipo_pago
-- =========================================================

DROP TABLE IF EXISTS practica01.metro_desglosada_raw;

CREATE TABLE practica01.metro_desglosada_raw (
    fecha       DATE,
    mes         VARCHAR(20),
    anio        INTEGER,
    linea       VARCHAR(100),
    estacion    VARCHAR(200),
    tipo_pago   VARCHAR(100),
    afluencia   INTEGER
);

-- =========================================================
-- VALIDACIÓN DE ESTRUCTURA
-- =========================================================

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'practica01'
ORDER BY table_name;