# Contrato de datos — Metrobús

## 1. Propósito

Este documento define el contrato de datos validado para la
iteración de Metrobús del proyecto semestral:

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

El contrato documenta:

- procedencia;
- estructuras recibidas;
- cobertura temporal;
- granularidad;
- tipos físicos;
- dominios;
- tratamiento de valores no disponibles;
- transformaciones CLEAN;
- controles de calidad;
- relación entre los recursos Simple y Desglosado;
- condiciones para su utilización posterior.

La fuente de verdad técnica del pipeline permanece en los scripts SQL
versionados dentro de `proyecto/sql/`.

---

# 2. Sistema

**Sistema de transporte:** Metrobús de la Ciudad de México.

**Conjunto:** Afluencia diaria de Metrobús CDMX.

**Publicador / mantenedor:** Secretaría de Movilidad de la Ciudad de México (SEMOVI).

**Portal:** Portal de Datos Abiertos de la Ciudad de México.

La procedencia completa se mantiene en:

`proyecto/data/metadata/metrobus/procedencia_metrobus.md`

---

# 3. Recursos utilizados

## 3.1 Metrobús Simple

Archivo RAW local:

`proyecto/data/raw/metrobus/datos_metrobus_simple_raw.csv`

Estructura física recibida:

```text
fecha,anio,mes,linea,afluencia
```

Registros:

`54,159`

Columnas:

`5`

Cobertura temporal validada:

`2005-07-26 → 2026-09-30`

Fechas distintas:

`7,737`

Granularidad validada:

`fecha × linea`

Duplicados exactos:

`0`

Colisiones de granularidad:

`0`

---

## 3.2 Metrobús Desglosada

Archivo RAW local:

`proyecto/data/raw/metrobus/datos_metrobus_desglosada_raw.csv`

Estructura física recibida:

```text
fecha,mes,anio,linea,tipo_pago,afluencia
```

Registros:

`29,386`

Columnas:

`6`

Cobertura temporal validada:

`2021-01-01 → 2026-09-30`

Fechas distintas:

`2,099`

Granularidad validada:

`fecha × linea × tipo_pago`

Duplicados exactos:

`0`

Colisiones de granularidad:

`0`

---

# 4. Integridad y trazabilidad

Los archivos RAW permanecen excluidos de Git.

La integridad se controla mediante:

`proyecto/data/metadata/metrobus/checksums_fuentes_metrobus.sha256`

Los hashes SHA-256 de los dos datasets RAW y de los dos
diccionarios oficiales fueron comprobados satisfactoriamente.

La inspección estructural se encuentra en:

`proyecto/data/metadata/metrobus/inspeccion_fuentes_metrobus.json`

El manifest técnico se encuentra en:

`proyecto/data/metadata/metrobus/manifest_fuentes_metrobus.csv`

El estado `INSPECCIONADO_PENDIENTE_VALIDACION` registrado en dicho
manifest corresponde al momento en que fue generado después de la
inspección de fuentes.

La validación posterior del pipeline se documenta mediante SQL,
este contrato y el checkpoint del sistema. No se modifica
retrospectivamente el significado histórico del manifest.

---

# 5. Arquitectura validada

El pipeline implementado es:

```text
RAW
 ↓
STAGING
 ↓
PERFILADO
 ↓
TYPED
 ↓
CLEAN
 ↓
VALIDACIÓN
```

Scripts:

```text
proyecto/sql/ingestion/metrobus/01_stage_metrobus.sql
proyecto/sql/ingestion/metrobus/02_ingesta_metrobus.sql

proyecto/sql/quality/metrobus/03_perfilado_metrobus.sql

proyecto/sql/integration/metrobus/04_typed_metrobus.sql
proyecto/sql/integration/metrobus/05_clean_metrobus.sql

proyecto/sql/quality/metrobus/06_validacion_metrobus.sql
```

---

# 6. STAGING

Tablas:

```text
proyecto.metrobus_simple_stage
proyecto.metrobus_desglosada_stage
```

STAGING recibe todas las columnas como `TEXT`.

Objetivos:

- preservar la representación recibida;
- evitar conversiones prematuras;
- permitir perfilado reproducible;
- conservar literales como `NaN`;
- permitir conciliación directa contra los RAW.

Conteos validados:

| Recurso | STAGING |
|---|---:|
| Simple | 54,159 |
| Desglosada | 29,386 |

Pérdida RAW/manifest → STAGING:

`0 registros`

---

# 7. TYPED

Tablas:

```text
proyecto.metrobus_simple_typed
proyecto.metrobus_desglosada_typed
```

## 7.1 Tipos principales

### Simple

| Campo | Tipo |
|---|---|
| fecha | DATE |
| anio | SMALLINT |
| mes | TEXT |
| linea | TEXT |
| afluencia | NUMERIC |

### Desglosada

| Campo | Tipo |
|---|---|
| fecha | DATE |
| mes | TEXT |
| anio | SMALLINT |
| linea | TEXT |
| tipo_pago | TEXT |
| afluencia | NUMERIC |

`afluencia` utiliza `NUMERIC` y no `INTEGER` porque el perfilado
identificó valores decimales válidos.

Se detectaron:

| Recurso | Valores con componente decimal |
|---|---:|
| Simple | 57 |
| Desglosada | 57 |

Los valores decimales se conservan sin redondeo ni truncamiento.

---

# 8. Tratamiento del literal NaN

Metrobús Simple contiene:

`17,227`

registros cuyo valor RAW de `afluencia` es el literal:

```text
NaN
```

No se convierte a cero.

El perfilado mostró una transición temporal ordenada por línea:

| Línea | Último NaN | Primer valor numérico |
|---|---|---|
| Línea 1 | No presenta NaN | 2005-07-26 |
| Línea 2 | 2008-12-16 | 2008-12-17 |
| Línea 3 | 2011-02-08 | 2011-02-09 |
| Línea 4 | 2012-04-01 | 2012-04-02 |
| Línea 5 | 2013-11-05 | 2013-11-06 |
| Línea 6 | 2016-01-22 | 2016-01-23 |
| Línea 7 | 2018-05-01 | 2018-05-02 |

En TYPED:

```text
NaN RAW/STAGING → NULL
```

La representación original continúa preservada en STAGING.

En CLEAN se agrega:

```text
es_afluencia_no_disponible
```

Por tanto:

```text
NaN ≠ 0
```

y una afluencia no disponible no debe interpretarse como una
medición de cero pasajeros.

Conteos validados:

```text
NaN en STAGING Simple              17,227
NULL en TYPED Simple               17,227
NULL en CLEAN Simple               17,227
es_afluencia_no_disponible = true  17,227
```

Inconsistencias entre `NULL` y la bandera:

`0`

---

# 9. Homologación de línea

El perfilado encontró tres representaciones textuales de las
mismas líneas lógicas:

```text
Linea N
Línea N
linea N
```

Estas variantes corresponden a periodos diferentes de la fuente.

Antes de homologarlas se comprobó que la transformación no genera
colisiones de granularidad.

Resultado:

```text
Simple:       0 colisiones
Desglosada:   0 colisiones
```

CLEAN utiliza como dominio canónico:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
```

Número de líneas lógicas después de CLEAN:

```text
Simple:       7
Desglosada:   7
```

---

# 10. Tipo de pago

El recurso Desglosado contiene dos categorías validadas:

| tipo_pago | Registros |
|---|---:|
| Gratuidad | 14,693 |
| Prepago | 14,693 |

Total:

`29,386`

No se observaron categorías adicionales en el recurso validado.

---

# 11. Variables derivadas CLEAN

CLEAN incorpora variables temporales:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana
```

También incorpora indicadores de calidad:

```text
es_afluencia_no_disponible
es_afluencia_cero
es_colision_clave
es_outlier_iqr_global
es_linea_homologada
```

Estas variables no eliminan ni reemplazan registros originales.

---

# 12. Afluencia

## 12.1 Simple

Valores numéricos disponibles:

`36,932`

Valores no disponibles:

`17,227`

Mínimo numérico observado:

`9`

Máximo numérico observado:

`3,032,667`

Valores negativos:

`0`

Valores iguales a cero:

`0`

## 12.2 Desglosada

Valores numéricos:

`29,386`

Mínimo observado:

`42`

Máximo observado:

`586,643`

Valores negativos:

`0`

Valores iguales a cero:

`0`

---

# 13. Outliers IQR

Los outliers se identifican mediante la regla:

```text
x < Q1 - 1.5 × IQR
o
x > Q3 + 1.5 × IQR
```

Se utilizan todos los valores `NUMERIC` disponibles, incluidos los
valores decimales válidos.

## Simple

```text
Q1 = 84,404.75
Q3 = 206,966
Límite inferior = -99,437.125
Límite superior = 390,807.875
Posibles outliers = 3,000
```

## Desglosada

```text
Q1 = 10,865
Q3 = 148,693.75
Límite inferior = -195,878.125
Límite superior = 355,436.875
Posibles outliers = 1,090
```

Los outliers se conservan.

La bandera:

```text
es_outlier_iqr_global
```

permite analizarlos o filtrarlos posteriormente sin destruir
información.

El valor `3,032,667` observado en Simple se conserva.

---

# 14. Calidad estructural

Resultados finales:

| Control | Simple | Desglosada |
|---|---:|---:|
| Registros | 54,159 | 29,386 |
| Fechas inválidas | 0 | 0 |
| Años inválidos | 0 | 0 |
| Duplicados exactos | 0 | 0 |
| Colisiones de granularidad | 0 | 0 |
| Valores negativos | 0 | 0 |
| Afluencias cero | 0 | 0 |
| Líneas lógicas CLEAN | 7 | 7 |
| Valores decimales | 57 | 57 |
| Outliers IQR | 3,000 | 1,090 |

La coherencia validada entre:

```text
fecha ↔ anio
fecha ↔ mes
fecha ↔ dia_semana
```

presenta:

`0 inconsistencias`

---

# 15. Conciliación entre capas

## Simple

| Capa | Registros |
|---|---:|
| STAGING | 54,159 |
| TYPED | 54,159 |
| CLEAN | 54,159 |

Pérdida:

`0`

## Desglosada

| Capa | Registros |
|---|---:|
| STAGING | 29,386 |
| TYPED | 29,386 |
| CLEAN | 29,386 |

Pérdida:

`0`

---

# 16. Relación Simple ↔ Desglosada

El periodo común validado es:

`2021-01-01 → 2026-09-30`

Fechas comunes:

`2,099`

Para comparar los recursos, Desglosada se agrega por:

```text
fecha × linea
```

mediante:

```text
SUM(afluencia)
```

Resultado:

```text
Claves comparables:       14,693
Coincidencias exactas:    14,693
Diferencias:                   0
Diferencia mínima:             0
Diferencia media:              0
Diferencia máxima:             0
```

Por tanto, para todas las claves comparables del periodo común:

```text
Simple.afluencia
=
SUM(Desglosada.afluencia)
```

Esta evidencia valida la compatibilidad de la medida de afluencia
entre ambos recursos en el periodo comprobado.

Esto no implica que ambos archivos deban concatenarse.

Simple y Desglosada mantienen granularidades distintas.

---

# 17. Diccionarios oficiales

Los diccionarios originales se conservan en:

```text
proyecto/data/metadata/metrobus/
```

Se identificaron discrepancias entre los diccionarios y los CSV
recibidos.

Entre ellas:

- el diccionario Simple utiliza `ano` mientras el CSV utiliza `anio`;
- el diccionario Desglosado describe campos como `estacion`,
  `afluencia_prepago`, `afluencia_gratuidad` y `afluencia_total`,
  que no corresponden directamente con el CSV recibido;
- el diccionario Desglosado presenta mojibake visible en parte del texto.

Los diccionarios se conservan como evidencia oficial, pero no se
utilizan como sustituto de la estructura física observada y validada
de los CSV.

---

# 18. Reglas de uso

1. No modificar RAW.

2. No convertir `NaN` histórico a cero.

3. En TYPED/CLEAN, `NULL` en `afluencia` Simple representa
   información no disponible según la interpretación validada
   del pipeline.

4. No eliminar outliers únicamente por su magnitud.

5. No redondear los 57 valores decimales sin justificación analítica.

6. Utilizar el dominio CLEAN de líneas para análisis comparables.

7. Respetar las granularidades:

```text
Simple:
fecha × linea

Desglosada:
fecha × linea × tipo_pago
```

8. No concatenar Simple y Desglosada como si fueran observaciones
   independientes del mismo nivel de detalle.

9. Para el periodo común, la suma de Desglosada por
   `fecha × linea` puede contrastarse con Simple.

10. Cualquier transformación posterior debe mantener trazabilidad
    hacia CLEAN, TYPED, STAGING y RAW.

---

# 19. Estado de validación

Pipeline:

```text
RAW
  ✅
STAGING
  ✅
PERFILADO
  ✅
TYPED
  ✅
CLEAN
  ✅
VALIDACIÓN
  ✅
```

Resultado:

**PIPELINE METROBÚS VALIDADO**

Script principal de validación:

`proyecto/sql/quality/metrobus/06_validacion_metrobus.sql`

Metrobús queda habilitado para el siguiente checkpoint:

**evaluación de compatibilidad analítica con Metro y diseño posterior de integración multisistema.**