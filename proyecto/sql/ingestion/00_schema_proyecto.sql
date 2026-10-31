/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Inteligencia de demanda de los principales sistemas
    de transporte público de la Ciudad de México

    Capa: inicialización del esquema
*/

CREATE SCHEMA IF NOT EXISTS proyecto;

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name = 'proyecto';