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

## 7. Resultado del pipeline Metro

El procesamiento del STC Metro quedó implementado mediante una arquitectura de cuatro capas:

`RAW → STAGING → TYPED → CLEAN`

Los archivos RAW originales se conservaron sin modificación y su identidad se verificó mediante SHA-256.

### 7.1 Conciliación de registros

Metro Simple:

- RAW/manifest: 1,180,920 registros.
- STAGING: 1,180,920 registros.
- TYPED: 1,180,920 registros.
- CLEAN: 1,180,920 registros.
- Diferencia final: 0 registros.

Metro Desglosada:

- RAW/manifest: 1,192,230 registros.
- STAGING: 1,192,230 registros.
- TYPED: 1,192,230 registros.
- CLEAN: 1,192,230 registros.
- Diferencia final: 0 registros.

Por lo tanto, las transformaciones realizadas no produjeron pérdida ni generación artificial de filas.

---

## 8. Corrección de representación textual

Se detectó mojibake en variables como `linea` y `estacion`.

La representación original se conservó en RAW, STAGING y TYPED. La corrección se aplicó únicamente en CLEAN.

Registros donde fue necesario corregir texto:

- Metro Simple: 495,537.
- Metro Desglosada: 727,209.

Después de la limpieza:

- ocurrencias residuales de mojibake en `linea`: 0;
- ocurrencias residuales de mojibake en `estacion`: 0.

Las categorías de línea quedaron homologadas en 12 valores:

- Línea 1
- Línea 2
- Línea 3
- Línea 4
- Línea 5
- Línea 6
- Línea 7
- Línea 8
- Línea 9
- Línea 12
- Línea A
- Línea B

---

## 9. Modalidades de pago

Metro Desglosada contiene tres modalidades:

- Boleto
- Gratuidad
- Prepago

Cada modalidad contiene 397,410 registros.

No se detectaron categorías adicionales después de la limpieza.

---

## 10. Indicadores de calidad preservados

Las anomalías estadísticas no fueron eliminadas. Se conservaron mediante banderas de calidad.

### Metro Simple

- afluencias iguales a cero: 62,025;
- filas involucradas en colisiones de clave: 62;
- posibles outliers globales mediante IQR: 66,361;
- registros con texto corregido: 495,537.

### Metro Desglosada

- afluencias iguales a cero: 291,457;
- filas involucradas en colisiones de clave: 0;
- posibles outliers globales mediante IQR: 103,485;
- registros con texto corregido: 727,209.

Los valores cero y los posibles outliers se conservan porque su presencia no demuestra por sí misma un error de captura.

---

## 11. Investigación de colisiones de granularidad en Metro Simple

La granularidad inicialmente esperada para Metro Simple es:

`fecha + linea + estacion`

Al auditar esta combinación se identificaron:

- 31 grupos con colisión;
- 62 filas involucradas;
- 31 registros excedentes respecto de una fila por clave;
- máximo de 2 filas por combinación.

Los 31 grupos corresponden a:

- Línea B;
- estación Oceanía;
- periodo del 1 al 31 de diciembre de 2020.

Cada grupo contiene dos registros y ambos presentan valores de afluencia distintos.

La comparación entre capas mostró:

- TYPED: 31 grupos / 62 filas;
- CLEAN: 31 grupos / 62 filas.

Por lo tanto, las colisiones ya existían antes de la normalización textual y no fueron generadas por la capa CLEAN.

Adicionalmente:

- grupos de duplicados exactos: 0;
- filas en duplicados exactos: 0;
- duplicados exactos excedentes: 0.

### Decisión

No se eliminan ni fusionan estos registros.

Con la información disponible no existe una variable adicional que permita determinar cuál de las dos afluencias representa el valor correcto o si ambas corresponden a una granularidad operativa no publicada en el archivo.

Los registros se conservan y se identifican mediante `es_colision_clave = TRUE`.

Esta decisión preserva la información original y evita introducir una deduplicación arbitraria.

---

## 12. Validación integral

El script:

`sql/quality/metro/06_validacion_metro.sql`

verifica de forma automática:

- conteos STAGING, TYPED y CLEAN;
- conciliación de registros;
- mojibake residual;
- valores NULL en campos críticos;
- coherencia temporal;
- dominios principales;
- indicadores de calidad.

Todos los controles críticos terminaron con estado `OK`.

Metro queda establecido como el primer pipeline de referencia del proyecto semestral.