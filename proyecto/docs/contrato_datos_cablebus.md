# Contrato de Datos — Cablebús

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Cablebús
**Iteración:** 4
**Estado del pipeline individual:** VALIDADO
**Fecha de validación:** 2026-11-12

---

## 2. Fuente oficial

La fuente utilizada corresponde al:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI)**

Recurso utilizado:

**Afluencia Diaria Cablebus (Desglosada)**

Recurso documental:

**Diccionario de Datos**

El recurso de Cablebús declara información de afluencia diaria desde el 1 de enero de 2022.

El conjunto de Servicio de Transportes Eléctricos agrupa recursos correspondientes a:

- Cablebús;
- Tren Ligero;
- Trolebús.

Para esta iteración únicamente se incorporó el recurso específico de Cablebús y el diccionario oficial asociado al conjunto.

---

## 3. Archivos fuente

### 3.1 Afluencia

Archivo RAW:

```text
proyecto/data/raw/cablebus/afluencia_desglosada_cb_09_2026.csv
```

Características verificadas:

```text
Filas de datos:       7,972
Columnas:                 6
Filas malformadas:        0
Encoding:         UTF-8-SIG
Delimitador:              ,
```

SHA-256:

```text
d5761d27f0d12198f434d569713b34cec5ffa61c84f28fe66a294b536a67624c
```

---

### 3.2 Diccionario

Archivo preservado:

```text
proyecto/data/metadata/cablebus/diccionario_cablebus_original.csv
```

Características verificadas:

```text
Filas de datos:        8
Columnas:              9
Filas malformadas:     0
Encoding:         CP1252
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

La copia preservada en `metadata/` fue comprobada byte a byte contra el archivo RAW.

---

## 4. Estructura física de la fuente

El archivo de afluencia contiene las columnas:

```text
fecha
mes
anio
linea
tipo_pago
afluencia
```

La estructura física del CSV fue tomada como autoridad operacional para el pipeline.

El diccionario oficial describe conceptualmente una estructura distinta:

```text
fecha
ano
mes
linea
afluencia_boleto
afluencia_prepago
afluencia_gratuidad
afluencia_total
```

Por tanto:

```text
diccionario conceptual STE
≠
estructura física actual del CSV Cablebús
```

El pipeline no transforma artificialmente el CSV para ajustarlo al formato conceptual del diccionario.

---

## 5. Cobertura temporal validada

Cobertura física:

```text
Fecha mínima:      2022-01-01
Fecha máxima:      2026-09-30
Fechas distintas:       1,734
```

No existen fechas inválidas.

No existen inconsistencias entre:

```text
fecha ↔ anio
fecha ↔ mes
```

Las 1,734 fechas corresponden a la cobertura diaria observada del periodo validado.

---

## 6. Granularidad

La granularidad individual validada de Cablebús es:

```text
fecha × linea × tipo_pago
```

Resultados:

```text
Registros:                    7,972
Claves distintas:             7,972
Grupos con colisión:              0
Filas involucradas:               0
Registros excedentes:             0
```

Por tanto, dentro del recurso analizado:

```text
fecha × linea × tipo_pago
```

identifica de manera única cada observación.

No se impuso físicamente una restricción `UNIQUE` durante esta iteración.

---

## 7. Estructura fecha × linea

Existen:

```text
3,986
```

claves distintas:

```text
fecha × linea
```

Cada una posee exactamente:

```text
2 filas
2 tipos de pago
```

Los dos tipos son:

```text
Gratuidad
Prepago
```

Por tanto:

```text
3,986 claves fecha × linea
×
2 tipos_pago
=
7,972 observaciones
```

---

## 8. Dominio de tipo_pago

Dominio observado y validado:

| tipo_pago | Registros |
|---|---:|
| Gratuidad | 3,986 |
| Prepago | 3,986 |

Total:

```text
7,972
```

No se detectaron categorías fuera de este dominio.

---

## 9. Representaciones originales de linea

En STAGING y TYPED se preservaron cinco representaciones físicas:

```text
Línea 1
Línea 2
Linea 1
Linea 2
Linea 3
```

Cobertura observada:

```text
Línea 1
2022-01-01 → 2025-04-30

Línea 2
2022-01-01 → 2025-04-30

Linea 1
2025-05-01 → 2026-09-30

Linea 2
2025-05-01 → 2026-09-30

Linea 3
2025-05-01 → 2026-09-30
```

La auditoría de caracteres y bytes confirmó que:

```text
Línea
```

y:

```text
Linea
```

son representaciones físicamente diferentes.

---

## 10. Homologación de linea

Antes de modificar las representaciones se comprobó si la homologación generaría colisiones en:

```text
fecha × linea_lógica × tipo_pago
```

Resultado:

```text
Claves con colisión:     0
Filas involucradas:      0
Registros excedentes:    0
```

Por tanto se aprobó la homologación:

```text
Línea 1 → Linea 1
Linea 1 → Linea 1

Línea 2 → Linea 2
Linea 2 → Linea 2

Linea 3 → Linea 3
```

La capa CLEAN conserva:

```text
linea_original
```

y:

```text
linea
```

para mantener trazabilidad.

---

## 11. Dominio lógico CLEAN

Después de la homologación existen exactamente tres líneas lógicas:

| linea | Registros | Días con registro | Fecha mínima | Fecha máxima |
|---|---:|---:|---|---|
| Linea 1 | 3,468 | 1,734 | 2022-01-01 | 2026-09-30 |
| Linea 2 | 3,468 | 1,734 | 2022-01-01 | 2026-09-30 |
| Linea 3 | 1,036 | 518 | 2025-05-01 | 2026-09-30 |

Total:

```text
7,972
```

Filas donde la representación fue modificada:

```text
4,864
```

Filas donde la representación ya coincidía con el valor CLEAN:

```text
3,108
```

---

## 12. Tipos de datos por capa

### STAGING

```text
fecha       TEXT
mes         TEXT
anio        TEXT
linea       TEXT
tipo_pago   TEXT
afluencia   TEXT
```

STAGING conserva la representación textual de la fuente.

---

### TYPED

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
linea       TEXT
tipo_pago   TEXT
afluencia   BIGINT
```

`afluencia` utiliza `BIGINT` porque:

```text
7,972 / 7,972 valores son enteros válidos
0 valores decimales
0 valores no numéricos
0 NaN
```

---

### CLEAN

CLEAN conserva los tipos físicos de TYPED y agrega:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana
linea_original
linea
es_afluencia_no_disponible
es_afluencia_cero
es_colision_clave_origen
es_colision_clave
es_duplicado_exacto
es_outlier_iqr_global
es_linea_homologada
```

---

## 13. Afluencia

Resultados validados:

```text
Valores:             7,972
NULL:                    0
NaN:                     0
Vacíos:                  0
No numéricos:            0
Negativos:               0
Decimales:               0
Ceros:                 207
Mínimo:                  0
Máximo:             80,727
```

Los ceros se consideran observaciones válidas y fueron preservados.

Regla:

```text
0 ≠ NULL
```

No se generaron valores faltantes artificialmente.

---

## 14. Ceros

Ceros totales:

```text
207
```

Distribución observada:

```text
Gratuidad: 137
Prepago:    70
```

Los 207 ceros se conservan desde STAGING hasta CLEAN.

Conciliación:

```text
TYPED: 207
CLEAN: 207
```

No se reemplazan ni eliminan.

---

## 15. Duplicados

Duplicados exactos detectados:

```text
Grupos:               0
Filas involucradas:   0
Registros excedentes: 0
```

No fue necesario eliminar ni resolver duplicados.

---

## 16. Colisiones

En la granularidad original:

```text
fecha × linea × tipo_pago
```

se detectaron:

```text
0 grupos con colisión
```

Después de homologar las representaciones de línea:

```text
0 grupos con colisión
```

Por tanto, la normalización de `linea` no produjo pérdida de unicidad.

---

## 17. Outliers

Se utilizó diagnóstico IQR global exclusivamente como bandera de calidad.

Resultados:

```text
Q1:               6,163.75
Q3:              50,634.25
Límite inferior: -60,542
Límite superior: 117,340
Máximo observado: 80,727

Posibles outliers IQR: 0
```

No se eliminaron observaciones por magnitud.

---

## 18. Reglas de transformación

El pipeline permite únicamente transformaciones reproducibles.

### RAW → STAGING

Permitido:

```text
Carga textual exacta del CSV
```

No permitido:

```text
corrección
homologación
tipado
eliminación
imputación
```

---

### STAGING → TYPED

Permitido:

```text
BTRIM
TEXT → DATE
TEXT → SMALLINT
TEXT → BIGINT
```

No se modifica la semántica de `linea`.

---

### TYPED → CLEAN

Permitido:

```text
derivación temporal
homologación segura de linea
banderas de calidad
preservación de linea_original
```

No permitido:

```text
eliminar ceros
eliminar filas
eliminar valores extremos
crear afluencia inexistente
resolver observaciones artificialmente
```

---

## 19. Conciliación entre capas

Resultado definitivo:

```text
STAGING: 7,972
TYPED:   7,972
CLEAN:   7,972
```

Pérdida:

```text
0
```

Formalmente:

```text
STAGING = TYPED = CLEAN
```

en cantidad de observaciones.

---

## 20. Banderas de calidad CLEAN

Resultados:

```text
es_afluencia_no_disponible = TRUE:    0
es_afluencia_cero = TRUE:           207

es_colision_clave_origen = TRUE:      0
es_colision_clave = TRUE:             0

es_duplicado_exacto = TRUE:           0
es_outlier_iqr_global = TRUE:          0

es_linea_homologada = TRUE:        4,864
```

---

## 21. Coherencia temporal

Después de CLEAN:

```text
error_anio:        0
error_mes:         0
error_dia_semana:  0
```

Las variables derivadas son coherentes con `fecha`.

---

## 22. Compatibilidad con el contrato multisistema preliminar

El contrato multisistema vigente antes de Cablebús utiliza como abstracción:

```text
fecha × sistema × unidad_operativa
```

Para Cablebús existe evidencia suficiente para proponer:

```text
sistema = Cablebús
unidad_operativa = linea
```

porque `linea` representa la unidad operacional publicada por la fuente y se obtuvieron tres entidades lógicas:

```text
Linea 1
Linea 2
Linea 3
```

Por tanto, Cablebús es conceptualmente compatible con:

```text
fecha × sistema × unidad_operativa
```

mediante:

```text
unidad_operativa = linea
```

Esta equivalencia es una abstracción analítica.

No implica que `linea`, `servicio` y otros campos de sistemas diferentes sean conceptos operacionalmente idénticos.

---

## 23. Medida común multisistema

En Cablebús:

```text
afluencia = BIGINT
```

Sin embargo, otros sistemas previamente validados contienen valores decimales.

Por tanto, una futura capa común multisistema deberá admitir al menos:

```text
NUMERIC
```

Cablebús puede promoverse de:

```text
BIGINT → NUMERIC
```

sin pérdida de información.

Esta promoción no se materializa todavía.

---

## 24. Restricciones para integración futura

No debe asumirse todavía que:

```text
fecha × sistema × unidad_operativa
```

puede materializarse directamente como dataset definitivo.

Antes se requiere completar el checkpoint de compatibilidad multisistema incluyendo Cablebús.

No se construye todavía:

```text
tabla de hechos definitiva
modelo dimensional definitivo
dataset processed multisistema definitivo
```

---

## 25. Decisiones definitivas de la Iteración 4

1. RAW permanece inmutable.
2. El recurso principal contiene 7,972 observaciones.
3. La cobertura validada es 2022-01-01 → 2026-09-30.
4. La granularidad individual es `fecha × linea × tipo_pago`.
5. Existen 3 líneas lógicas.
6. Existen 2 tipos de pago.
7. `afluencia` es enteramente numérica.
8. Los 207 ceros se preservan.
9. No existen NULL de afluencia.
10. No existen valores negativos.
11. No existen valores decimales.
12. No existen duplicados exactos.
13. No existen colisiones.
14. No existen outliers según IQR global.
15. Las variantes `Línea` / `Linea` se homologan únicamente en CLEAN.
16. `linea_original` conserva trazabilidad.
17. La homologación no genera colisiones.
18. No se elimina ninguna observación.
19. Cablebús propone `unidad_operativa = linea` para el contrato multisistema preliminar.
20. No se materializa todavía integración multisistema.

---

## 26. Estado del pipeline individual

```text
RAW
↓
METADATA / PROCEDENCIA
↓
INSPECCIÓN
↓
SHA-256
↓
MANIFEST
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

Estado:

```text
PIPELINE INDIVIDUAL CABLEBÚS: VALIDADO
```

Registros:

```text
STAGING    7,972
TYPED      7,972
CLEAN      7,972
```

Pérdida:

```text
0
```

Granularidad individual:

```text
fecha × linea × tipo_pago
```

Abstracción multisistema candidata:

```text
fecha × sistema × unidad_operativa

Cablebús:
unidad_operativa = linea
```

El siguiente paso es realizar el checkpoint individual y posteriormente evaluar formalmente la compatibilidad de Cablebús con el contrato multisistema vigente.