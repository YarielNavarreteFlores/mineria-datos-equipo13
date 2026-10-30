# Metro — Fuentes, procedencia y calidad inicial

## 1. Procedencia

Sistema: Sistema de Transporte Colectivo Metro (STC Metro)

Fuente: Portal de Datos Abiertos de la Ciudad de México

Organización reportada en la Práctica 1: Secretaría de Movilidad
(SEMOVI).

Fecha de descarga registrada: 17/09/2026.

Fuentes utilizadas:

- `datos_metro_simple_raw.csv`
- `datos_metro_desglosada_raw.csv`

Los archivos originales se preservan sin modificación.

---

## 2. Fuente Simple

Archivo:

`datos_metro_simple_raw.csv`

Registros:

1,180,920

Columnas:

6

Esquema físico observado:

1. fecha
2. anio
3. mes
4. linea
5. estacion
6. afluencia

Filas estructuralmente malformadas:

0

---

## 3. Fuente Desglosada

Archivo:

`datos_metro_desglosada_raw.csv`

Registros:

1,192,230

Columnas:

7

Esquema físico observado:

1. fecha
2. mes
3. anio
4. linea
5. estacion
6. tipo_pago
7. afluencia

Filas estructuralmente malformadas:

0

---

## 4. Deriva entre fuente y diccionario

Durante la revisión se detectó que los diccionarios históricos
versionados en la Práctica 1 no describen exactamente los esquemas
físicos de los CSV utilizados.

### Simple

El diccionario describe una variable adicional denominada `dia`,
mientras que el archivo físico utilizado contiene 6 columnas y no
incluye dicha variable.

### Desglosada

El diccionario describe una estructura con campos como:

- afluencia_boleto
- afluencia_prepago
- afluencia_gratuidad
- afluencia_total

Sin embargo, la fuente física utilizada presenta un formato largo:

- estacion
- tipo_pago
- afluencia

Por lo tanto, se considera que existe una diferencia de versión o
evolución del recurso entre la documentación disponible y los archivos
empleados.

Para el procesamiento se toma como autoridad estructural el archivo
físico recibido, manteniendo los diccionarios como referencia
semántica.

---

## 5. Problemas de representación de texto

Aunque los archivos son decodificables como UTF-8, se observaron
cadenas con mojibake, por ejemplo:

- `LÃ­nea`
- `CatÃ³lica`

Esto indica que algunos textos pudieron haber sido codificados de forma
incorrecta antes de la publicación del archivo.

Los archivos RAW no se modificarán.

La corrección se realizará únicamente en capas derivadas de limpieza,
preservando siempre la representación original.

---

## 6. Integridad estructural

La inspección automatizada confirmó:

- delimitador coma;
- hashes SHA-256 reproducibles;
- número esperado de registros;
- número esperado de columnas;
- cero filas con cantidad incorrecta de campos.

Los resultados completos se encuentran en:

`data/metadata/metro/inspeccion_fuentes_metro.json`

y:

`data/metadata/metro/manifest_fuentes_metro.csv`