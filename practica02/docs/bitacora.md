# Bitácora técnica — Práctica 2

## Equipo 13

- Navarrete Flores Yariel — Coordinador / Analista de datos
- Nava Villar Eric — Ingeniero de datos / Arquitecto
- Uribe Sánchez Edén — Machine Learning / Visualizador

## Flujo ejecutado

### 1. Inspección de fuentes
Se verificaron los archivos CSV proporcionados por el profesor.

2022:
- Archivo RAW: muestra200k_COVID19MEXICOLOC2022.csv
- Tamaño: 686,356,922 bytes
- 41 columnas
- UTF-8
- Se detectaron dos mitades byte a byte idénticas.
- Cada mitad contiene 1,999,998 registros de datos.

2023:
- Archivo RAW: muestra100k_COVID19MEXICOLOC2023.csv
- Tamaño: 20,258,324 bytes
- 44 columnas
- 99,999 registros
- UTF-8

### 2. Preparación 2022
Se generó de forma reproducible una copia de trabajo de la primera mitad válida mediante:

scripts/preparar_2022.py

El archivo RAW original permaneció intacto.

### 3. PostgreSQL
Base utilizada:

covid20a23sedi

Se crearon tablas STAGE con todas las columnas en TEXT.

### 4. Ingesta

Resultados:

- covid_stage_2022: 1,999,998 registros
- covid_stage_2023: 99,999 registros

Durante la primera ejecución de psql se presentó un problema de client_encoding WIN1252.
Se corrigió estableciendo UTF8 y la carga posterior terminó correctamente.

### 5. Perfilado y tipado

Se validaron fechas, variables numéricas y longitudes antes de ejecutar conversiones.

No se detectaron valores no convertibles en las columnas destinadas a DATE o SMALLINT.

Se detectó una tabulación en MIGRANTE para ID_REGISTRO = 15ec76.
Después de BTRIM el valor quedó normalizado a 99.

Los valores 9999-99-99 de fechas se transformaron a NULL.

### 6. Tablas tipadas

- covid_2022_tipada: 1,999,998 registros
- covid_2023_tipada: 99,999 registros

No hubo pérdida de registros.

### 7. Consolidación histórica

covid_historica:

2,099,997 registros.

Diferencia contra la suma de las fuentes:

0 registros.

### 8. Duplicados

- ID_REGISTRO NULL: 0
- ID_REGISTRO distintos: 2,099,997
- ID_REGISTRO repetidos: 0
- Duplicados exactos: 0

No se aplicó deduplicación.

### 9. Calidad y EDA

Se analizaron:
- PAIS_NACIONALIDAD
- NACIONALIDAD
- PAIS_ORIGEN
- MUNICIPIO_RES
- ENTIDAD_RES
- valores especiales de catálogo
- valores NULL de todas las columnas

Los códigos especiales se conservaron conforme a los catálogos.

### 10. Validación final

Todos los controles definidos en 08_validacion_final.sql terminaron con estado OK.