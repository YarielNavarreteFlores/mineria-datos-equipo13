# Inspección inicial de fuentes — Práctica 2

Este documento fue generado a partir de los archivos utilizados en la Práctica 2.

## 1. Archivos

| Archivo | Capa | Registros | Columnas | Tamaño MiB |
|---|---|---:|---:|---:|
| muestra200k_COVID19MEXICOLOC2022.csv | RAW | 3,999,996 | 41 | 654.56 |
| muestra200k_COVID19MEXICOLOC2022_trabajo.csv | WORKING | 1,999,998 | 41 | 327.28 |
| muestra100k_COVID19MEXICOLOC2023.csv | RAW | 99,999 | 44 | 19.32 |

## 2. Integridad estructural

- 2022 WORKING: 0 filas con número incorrecto de columnas.
- 2023 RAW: 0 filas con número incorrecto de columnas.

## 3. Diferencias de esquema

Campos presentes solamente en 2022:

- Ninguno.

Campos presentes solamente en 2023:

- `CLUES`
- `FECHA_RESULTADO`
- `MUNICIPIO_UM`

## 4. Perfil 2022

### Celdas vacías

No se detectaron casos.

### Centinelas de fecha 9999-99-99

| Campo | Cantidad |
|---|---:|
| `FECHA_DEF` | 1,983,215 |

### Fechas inválidas adicionales

No se detectaron casos.

### Campos que contienen tabulación

| Campo | Cantidad |
|---|---:|
| `MIGRANTE` | 1 |

## 5. Perfil 2023

### Celdas vacías

No se detectaron casos.

### Centinelas de fecha 9999-99-99

| Campo | Cantidad |
|---|---:|
| `FECHA_DEF` | 99,223 |
| `FECHA_RESULTADO` | 82,283 |

### Fechas inválidas adicionales

No se detectaron casos.

### Campos que contienen tabulación

No se detectaron casos.

## 6. Longitudes máximas relevantes

| Campo | 2022 | 2023 |
|---|---:|---:|
| `ID_REGISTRO` | 7 | 7 |
| `PAIS_NACIONALIDAD` | 54 | 36 |
| `PAIS_ORIGEN` | 54 | 25 |
| `CLUES` | N/A | 11 |

## 7. Formato, codificación y delimitadores

Los archivos fueron inspeccionados antes de la ingesta a PostgreSQL.

| Característica | 2022 | 2023 |
|---|---|---|
| Codificación | UTF-8 válida | UTF-8 válida |
| Delimitador de campos | Coma (`,`) | Coma (`,`) |
| Calificador de texto | Comillas dobles (`"`) | Comillas dobles (`"`) |
| Delimitador de filas observado | CRLF (`\r\n`) | CRLF (`\r\n`) |
| Formato de fechas ordinarias | `AAAA-MM-DD` | `AAAA-MM-DD` |
| Cadenas vacías detectadas | 0 | 0 |
| Filas malformadas en archivo utilizable | 0 | 0 |

La ausencia de cadenas vacías no implica ausencia de valores semánticamente
especiales. El conjunto utiliza códigos de catálogo como 97, 98 y 99, además
del valor centinela `9999-99-99` en determinados campos de fecha. Estos valores
se analizarán de acuerdo con el diccionario y no se sustituirán
automáticamente.

## 8. Anomalía física del archivo 2022

El archivo RAW de 2022 tiene un tamaño de 686,356,922 bytes y puede dividirse
exactamente en dos segmentos de 343,178,461 bytes. Ambos segmentos producen el
mismo SHA-256:

`9192b9abe85267252cb8ebaf0b2f6b3ea6e36bf0617eb70c3637a85d5946c782`

Esto demuestra que el archivo recibido contiene dos copias byte a byte
idénticas.

Cada segmento representa un encabezado y 1,999,998 registros de datos. Por
tanto, el archivo RAW representa 3,999,996 registros duplicados por
concatenación, mientras que la fuente útil contiene 1,999,998 registros.

El RAW se conserva intacto. Para la ingesta se genera mediante
`scripts/preparar_2022.py` una copia de trabajo que conserva exclusivamente el
primer segmento. La copia resultante contiene 1,999,998 registros, 41 columnas,
cero filas malformadas y conserva trazabilidad mediante SHA-256.

## 9. Consistencia de encabezados

Los encabezados fueron comparados entre ambos periodos.

- El esquema utilizable de 2022 contiene 41 columnas.
- El esquema de 2023 contiene 44 columnas.
- Las 41 columnas de 2022 están presentes también en 2023.
- En 2023 se incorporan tres variables adicionales:
  - `MUNICIPIO_UM`
  - `CLUES`
  - `FECHA_RESULTADO`

Debido a esta evolución de esquema no es seguro realizar una carga posicional
de ambos archivos sobre una misma tabla de etapa. Se utilizarán tablas
`stage` separadas por versión y posteriormente una estructura histórica
homologada.