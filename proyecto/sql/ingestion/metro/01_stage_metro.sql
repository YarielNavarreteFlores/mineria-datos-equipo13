/*
    PROYECTO SEMESTRAL - METRO

    Capa STAGING

    Principio:
    Todas las columnas se reciben inicialmente como TEXT.

    Esto permite conservar la representación de la fuente
    antes de aplicar tipado, normalización o limpieza.
*/


DROP TABLE IF EXISTS proyecto.metro_simple_stage;

CREATE TABLE proyecto.metro_simple_stage (
    fecha       TEXT,
    anio        TEXT,
    mes         TEXT,
    linea       TEXT,
    estacion    TEXT,
    afluencia   TEXT
);


DROP TABLE IF EXISTS proyecto.metro_desglosada_stage;

CREATE TABLE proyecto.metro_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
    linea       TEXT,
    estacion    TEXT,
    tipo_pago   TEXT,
    afluencia   TEXT
);


-- Validación estructural

SELECT
    table_name,
    COUNT(*) AS numero_columnas
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name IN (
      'metro_simple_stage',
      'metro_desglosada_stage'
  )
GROUP BY table_name
ORDER BY table_name;