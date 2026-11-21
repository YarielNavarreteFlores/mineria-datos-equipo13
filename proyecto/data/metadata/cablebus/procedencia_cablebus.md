# Procedencia de datos — Cablebús

## 1. Proyecto

**Proyecto semestral:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.

**Unidad de aprendizaje:** Minería de Datos.

**Iteración:** 4 — Cablebús.

**Sistema:** Cablebús de la Ciudad de México.

---

## 2. Fuente oficial

Los datos utilizados en esta iteración fueron obtenidos del:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto de datos:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI)**

Página oficial del conjunto:

```text
https://www.datos.cdmx.gob.mx/dataset/afluencia-diaria-servicio-de-transportes-electricos
```

Fecha de consulta y adquisición:

```text
2026-11-12
```

---

## 3. Descripción general del conjunto

La ficha oficial indica que las bases muestran la afluencia diaria del Servicio de Transportes Eléctricos de la Ciudad de México, compuesto por:

- Cablebús;
- Tren Ligero;
- Trolebús.

La descripción del portal señala también que la información de afluencia desglosada se encuentra separada por medio de acceso.

Entre los medios mencionados se encuentran:

- Tarjeta Única de Movilidad Integrada;
- boleto;
- gratuidad.

La gratuidad se refiere al acceso gratuito de personas contempladas por los requisitos establecidos por el organismo.

La descripción textual del conjunto indica que la base se actualiza mensualmente.

Sin embargo, en la ficha de información adicional del portal se observa:

```text
Frecuencia de actualización: no_aplica
```

Esta discrepancia se conserva como parte de los metadatos publicados y no se corrige artificialmente.

---

## 4. Recursos disponibles en el conjunto

Durante la consulta del portal se observaron los siguientes recursos:

```text
Diccionario de Datos
Afluencia Diaria Tren Ligero (desglosada)
Afluencia Diaria Cablebus (Desglosada)
Afluencia Diaria Trolebus (desglosado)
```

Para la Iteración 4 se seleccionaron únicamente:

```text
Afluencia Diaria Cablebus (Desglosada)
Diccionario de Datos
```

Los recursos de Tren Ligero y Trolebús no forman parte del RAW de esta iteración.

---

## 5. Recurso principal seleccionado

Nombre publicado:

**Afluencia Diaria Cablebus (Desglosada)**

Descripción observada en el portal:

```text
Afluencia Diaria Cablebus desde el 1 de enero de 2022.
```

La ficha del recurso describe a Cablebús como un proyecto de transporte que atiende zonas de alta densidad poblacional y señala actualmente tres líneas:

```text
Línea 1:
Cuautepec ↔ Indios Verdes

Línea 2:
Santa Marta ↔ Constitución de 1917

Línea 3:
Los Pinos / Constituyentes ↔ Vasco de Quiroga
```

Esta descripción corresponde a los metadatos publicados por el portal.

La existencia física y los valores de las líneas deberán verificarse posteriormente directamente contra el CSV.

---

## 6. Estructura mostrada por el portal

La ficha del recurso de Cablebús muestra seis campos:

```text
fecha
mes
anio
linea
tipo_pago
afluencia
```

Todos aparecen inicialmente descritos por el portal como:

```text
text
```

Esto corresponde únicamente a la representación publicada en la ficha.

Los tipos físicos definitivos no se asumirán hasta realizar:

```text
INSPECCIÓN
↓
PERFILADO
↓
TYPED
```

---

## 7. Recurso descargado de afluencia

Archivo recibido:

```text
afluencia_desglosada_cb_09_2026.csv
```

Ubicación:

```text
proyecto/data/raw/cablebus/afluencia_desglosada_cb_09_2026.csv
```

Tamaño observado en el sistema de archivos:

```text
aproximadamente 361 KiB
```

Detección preliminar mediante `file`:

```text
CSV Unicode text, UTF-8 text
```

El archivo RAW no fue:

- renombrado;
- editado;
- abierto y guardado en Excel;
- recodificado;
- corregido manualmente;
- transformado.

---

## 8. Diccionario oficial

Recurso publicado:

**Diccionario de Datos**

Archivo descargado:

```text
1fd34251-b1e7-4a00-ba07-5d3b9d8701e9.csv
```

Ubicación RAW:

```text
proyecto/data/raw/cablebus/1fd34251-b1e7-4a00-ba07-5d3b9d8701e9.csv
```

Tamaño observado:

```text
aproximadamente 1.6 KiB
```

Detección preliminar mediante `file`:

```text
CSV ISO-8859 text
```

Se preservó una copia byte a byte en:

```text
proyecto/data/metadata/cablebus/diccionario_cablebus_original.csv
```

La igualdad entre RAW y la copia de metadata fue comprobada mediante:

```text
cmp
```

Resultado:

```text
sin diferencias
```

Por tanto:

```text
diccionario RAW
=
diccionario preservado en metadata
```

a nivel de bytes.

---

## 9. Naturaleza del diccionario

La ficha del recurso denominado `Diccionario de Datos` muestra nueve columnas correspondientes a la estructura del propio diccionario:

```text
No.
Nombre de la base y/o conjunto de datos
Nombre de la columna
Etiqueta
Descripción
Tipo de dato
Formato
Rango o valores que permite el campo
Registro de campos vacíos
```

En esta etapa todavía no se asume que todas las filas del diccionario correspondan exclusivamente a Cablebús.

Debe comprobarse mediante inspección física si el recurso documenta:

- solamente Cablebús;
- Cablebús + Tren Ligero;
- Cablebús + Trolebús;
- los tres sistemas del Servicio de Transportes Eléctricos.

Esta decisión se tomará a partir del contenido real del CSV.

---

## 10. Metadatos observados en el portal

Conjunto:

```text
Afluencia diaria Servicio de Transportes Eléctricos
```

Mantenedor:

```text
SEMOVI
```

Última actualización mostrada en la ficha general durante la consulta:

```text
2026-10-27 17:32 (UTC-06:00)
```

Recurso Cablebús:

```text
Formato: CSV
Fecha de creación mostrada: 2026-10-27
Tamaño mostrado: aproximadamente 360.8 KiB
```

Diccionario:

```text
Formato: CSV
Fecha de creación mostrada: 2026-08-28
Tamaño mostrado: aproximadamente 1.5 KiB
```

El portal advierte que, debido a procesos de migración, algunas fechas de creación o actualización mostradas pueden corresponder a la migración y no necesariamente a la fecha original de publicación.

Por tanto, estas fechas se conservan como metadatos del portal y no se utilizan por sí solas para determinar cobertura histórica.

---

## 11. Cobertura temporal

La descripción del recurso afirma disponibilidad desde:

```text
2022-01-01
```

Sin embargo, la cobertura temporal efectiva todavía no se declara validada.

Debe obtenerse directamente del CSV mediante:

```text
MIN(fecha)
MAX(fecha)
COUNT(DISTINCT fecha)
```

durante el perfilado.

Regla:

```text
Descripción del portal
≠
evidencia física suficiente de cobertura
```

---

## 12. Granularidad

La presencia de las columnas:

```text
fecha
linea
tipo_pago
```

sugiere como primera hipótesis:

```text
fecha × linea × tipo_pago
```

pero esta granularidad todavía NO está validada.

Antes de aceptarla deben comprobarse:

- duplicados exactos;
- colisiones;
- cantidad de filas por clave;
- dominio de `linea`;
- dominio de `tipo_pago`;
- cambios históricos de representación;
- valores faltantes;
- posibles dimensiones no visibles.

No debe imponerse ninguna restricción `UNIQUE` durante esta etapa.

---

## 13. Relación con el contrato multisistema

El contrato multisistema preliminar vigente después de RTP es:

```text
fecha × sistema × unidad_operativa
```

Actualmente:

```text
Metro
→ unidad_operativa = linea

Metrobús
→ unidad_operativa = linea

RTP
→ unidad_operativa = servicio
```

Cablebús publica un campo denominado:

```text
linea
```

pero todavía no se declara formalmente:

```text
unidad_operativa = linea
```

hasta comprobar su semántica y comportamiento real.

Cablebús no será modificado para adaptarse al contrato existente.

El contrato podrá volver a evaluarse si los datos lo requieren.

---

## 14. Reglas de preservación

Durante la Iteración 4 se aplican las siguientes reglas:

1. RAW es inmutable.
2. No modificar archivos originales.
3. No sobrescribir RAW.
4. No corregir manualmente CSV.
5. No eliminar observaciones sin evidencia.
6. No convertir valores faltantes a cero.
7. `NULL ≠ 0`.
8. No eliminar outliers únicamente por ser extremos.
9. Toda transformación debe ser reproducible.
10. Toda fuente debe disponer de procedencia.
11. Toda fuente deberá disponer de SHA-256.
12. Toda fuente deberá incorporarse al manifest.
13. Primero se inspecciona y perfila.
14. Después se deciden transformaciones.
15. No copiar mecánicamente el pipeline de RTP.
16. No asumir que Cablebús posee la misma granularidad que Metro o Metrobús.
17. No modificar otros sistemas para adaptar Cablebús.
18. No construir todavía integración física multisistema.
19. No construir todavía modelo dimensional definitivo.
20. Toda decisión debe poder defenderse técnicamente.

---

## 15. Estado actual

Completado:

```text
FUENTE OFICIAL             ✅
SELECCIÓN DE RECURSOS      ✅
RAW                        ✅
COPIA DICCIONARIO METADATA ✅
PROCEDENCIA                ✅
```

Pendiente:

```text
INSPECCIÓN
SHA-256
MANIFEST
STAGING
PERFILADO
TYPED
CLEAN
VALIDACIÓN
CONTRATO DE DATOS
CHECKPOINT INDIVIDUAL
COMPATIBILIDAD MULTISISTEMA
```

No existe todavía ninguna transformación aplicada al recurso Cablebús.