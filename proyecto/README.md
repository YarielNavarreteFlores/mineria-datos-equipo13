# Proyecto semestral — Minería de Datos

## Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México

Equipo 13 — Licenciatura en Ciencia de Datos, ESCOM-IPN.

---

## Estado actual

El proyecto se encuentra en la fase de **Preparación de Datos de CRISP-DM**, con cuatro sistemas de transporte ya caracterizados mediante pipelines individuales reproducibles:

- Metro;
- Metrobús;
- RTP;
- Cablebús.

También se completaron los siguientes checkpoints de compatibilidad:

- Metro ↔ Metrobús;
- RTP ↔ contrato multisistema preliminar;
- Cablebús ↔ contrato multisistema preliminar.

El contrato analítico multisistema preliminar vigente es:

```text
fecha × sistema × unidad_operativa
```

Mapeo actualmente respaldado por evidencia:

```text
Metro
→ unidad_operativa = linea

Metrobús
→ unidad_operativa = linea

RTP
→ unidad_operativa = servicio

Cablebús
→ unidad_operativa = linea
```

La ventana temporal estrictamente común actualmente validada para los cuatro sistemas es:

```text
2022-01-01 → 2026-07-31
```

con:

```text
1,673 fechas distintas
```

El candidato conceptual de cuatro sistemas contiene:

```text
Metro:       20,076 registros
Metrobús:    11,711 registros
RTP:         13,382 registros
Cablebús:     3,803 registros
```

Resultado global:

```text
Registros totales:        48,972
Claves distintas:         48,972
Claves duplicadas:             0
Afluencias NULL:             223
Claves con restricción:      223
```

Las 223 restricciones pertenecen exclusivamente a RTP:

```text
92  → COLISION
131 → AFLUENCIA_INCOMPLETA
```

Cablebús no introdujo restricciones nuevas.

Por tanto, el estado actual del contrato multisistema es:

```text
APROBADO CON RESTRICCIONES
```

La integración física multisistema continúa pendiente.

El siguiente sistema que debe estudiarse es:

```text
Trolebús
```

### Estado de iteraciones

| Sistema | RAW | Metadata | STAGING | Perfilado | TYPED | CLEAN | Validación | Contrato |
|---|---|---|---|---|---|---|---|---|
| Metro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Metrobús | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RTP | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cablebús | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Trolebús | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| Tren Ligero | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

**Leyenda**

- ✅ Validado.
- ⚪ Pendiente.

### Iteración 1 — STC Metro

Estado:

**VALIDADA**

Metro constituye el baseline técnico del proyecto.

Flujo:

```text
RAW → STAGING → TYPED → CLEAN → VALIDACIÓN
```

Resultados principales:

- Metro Simple: 1,180,920 registros.
- Metro Desglosada: 1,192,230 registros.
- Pérdida entre STAGING, TYPED y CLEAN: 0 registros.
- Metro Simple conserva 31 grupos conocidos de colisión, correspondientes a 62 filas de Línea B — Oceanía durante diciembre de 2020.
- Los ceros, outliers y colisiones se conservan.

### Iteración 2 — Metrobús

Estado:

**VALIDADA**

Flujo:

```text
RAW → STAGING → PERFILADO → TYPED → CLEAN → VALIDACIÓN
```

Resultados principales:

- Simple: 54,159 registros.
- Desglosada: 29,386 registros.
- Pérdida entre STAGING, TYPED y CLEAN: 0 registros.
- Granularidad Simple: `fecha × linea`.
- Granularidad Desglosada: `fecha × linea × tipo_pago`.
- 17,227 `NaN` históricos preservados como `NULL` desde TYPED.
- `NULL ≠ 0`.
- 57 valores decimales preservados mediante `NUMERIC` en cada recurso.
- 0 duplicados exactos.
- 0 colisiones.
- 7 líneas lógicas homologadas.
- 3,000 outliers IQR en Simple.
- 1,090 outliers IQR en Desglosada.
- 14,693 de 14,693 claves comparables Simple ↔ Desglosada coinciden exactamente.

Contrato:

```text
docs/contrato_datos_metrobus.md
```

Checkpoint individual:

```text
docs/checkpoint_metrobus.md
```

### Checkpoint de compatibilidad Metro ↔ Metrobús

Estado:

**APROBADO CON RESTRICCIONES**

Script:

```text
sql/quality/compatibilidad/01_compatibilidad_metro_metrobus.sql
```

Documento:

```text
docs/checkpoint_compatibilidad_metro_metrobus.md
```

Ventana común evaluada:

```text
2021-01-01 → 2026-07-31
```

Granularidad aprobada en ese momento:

```text
fecha × sistema × linea
```

Resultados:

```text
Registros lógicos:       38,722
Claves distintas:        38,722
Claves duplicadas:            0
Fechas distintas:         2,038
Afluencias NULL:               0
```

Esta granularidad se mantiene válida para Metro y Metrobús, pero dejó de ser suficientemente general al incorporar RTP.

### Iteración 3 — RTP

Estado:

**VALIDADA**

Pipeline:

```text
FUENTE OFICIAL
↓
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
↓
CONTRATO DE DATOS
↓
CHECKPOINT INDIVIDUAL
```

Resultados principales:

```text
Registros:                     41,676
Cobertura:        2022-01-01 → 2026-09-30
Fechas distintas:               1,734
Tipos de pago:                      3
Servicios CLEAN:                   21
```

Calidad:

```text
NaN / NULL:                       187
Ceros:                          7,450
Valores decimales:                 53
Grupos duplicados exactos:         81
Filas en duplicados exactos:      162
Grupos con colisión:              276
Filas con colisión:               552
Outliers IQR:                   4,688
```

Pérdida:

```text
STAGING → TYPED → CLEAN = 0
```

RTP utiliza la dimensión:

```text
servicio
```

No se demostró que:

```text
servicio = linea
```

La granularidad:

```text
fecha × servicio × tipo_pago
```

presenta colisiones y no constituye una clave natural única.

Las colisiones se concentran en ATENEA y se preservan.

Contrato:

```text
docs/contrato_datos_rtp.md
```

Checkpoint individual:

```text
docs/checkpoint_rtp.md
```

### Iteración 4 — Cablebús

Estado:

**VALIDADA**

Pipeline:

```text
FUENTE OFICIAL
↓
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
↓
CONTRATO DE DATOS
↓
CHECKPOINT INDIVIDUAL
```

Resultados principales:

```text
Registros:                     7,972
Cobertura:        2022-01-01 → 2026-09-30
Fechas distintas:               1,734
Tipos de pago:                      2
Líneas lógicas CLEAN:               3
```

Calidad:

```text
NULL / NaN:                         0
Ceros:                            207
Valores negativos:                  0
Valores decimales:                  0
Duplicados exactos:                 0
Colisiones:                         0
Outliers IQR:                       0
```

Pérdida:

```text
STAGING → TYPED → CLEAN = 0
```

La granularidad individual validada es:

```text
fecha × linea × tipo_pago
```

Cada clave:

```text
fecha × linea
```

contiene exactamente:

```text
2 filas
2 tipos de pago
```

Los tipos de pago son:

```text
Gratuidad
Prepago
```

Se detectaron cinco representaciones físicas de `linea`:

```text
Línea 1
Línea 2
Linea 1
Linea 2
Linea 3
```

El perfilado demostró una transición de representación:

```text
Línea 1 / Línea 2
2022-01-01 → 2025-04-30

Linea 1 / Linea 2 / Linea 3
2025-05-01 → 2026-09-30
```

Antes de homologar se comprobó que la normalización:

```text
Línea 1 → Linea 1
Línea 2 → Linea 2
```

no generaba colisiones.

Resultado:

```text
Claves con colisión:       0
Filas involucradas:        0
Registros excedentes:      0
```

La homologación se aplicó únicamente en CLEAN.

CLEAN conserva:

```text
linea_original
```

para mantener trazabilidad respecto a la representación publicada por la fuente.

Filas homologadas:

```text
4,864
```

Dominio lógico CLEAN:

```text
Linea 1: 3,468 registros
Linea 2: 3,468 registros
Linea 3: 1,036 registros
```

Contrato:

```text
docs/contrato_datos_cablebus.md
```

Checkpoint individual:

```text
docs/checkpoint_cablebus.md
```

Validación:

```text
sql/quality/cablebus/06_validacion_cablebus.sql
```

Resultado final:

```text
PIPELINE INDIVIDUAL CABLEBÚS: VALIDADO
```

---

### Checkpoint Cablebús ↔ contrato multisistema preliminar

Estado específico de Cablebús:

**APROBADA**

Estado global del contrato:

**APROBADO CON RESTRICCIONES**

Script reproducible:

```text
sql/quality/compatibilidad/03_compatibilidad_cablebus_contrato_preliminar.sql
```

Documento:

```text
docs/checkpoint_compatibilidad_cablebus_multisistema.md
```

La ventana estrictamente común para:

```text
Metro
Metrobús
RTP
Cablebús
```

es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

Cablebús dentro de esta ventana contiene:

```text
Registros detallados:       7,606
Claves fecha × linea:       3,803
Claves seguras:             3,803
Claves con restricción:         0
```

El candidato diario Cablebús utiliza:

```text
unidad_operativa = linea
```

y se obtiene mediante agregación sobre los dos tipos de pago:

```text
SUM(afluencia)
GROUP BY fecha, linea
```

porque las 3,803 claves presentan:

```text
2 filas
2 tipos de pago
0 NULL
0 colisiones
```

Cobertura por unidad operativa:

```text
Linea 1:
1,673 claves seguras
2022-01-01 → 2026-07-31

Linea 2:
1,673 claves seguras
2022-01-01 → 2026-07-31

Linea 3:
457 claves seguras
2025-05-01 → 2026-07-31
```

Resultados del candidato multisistema:

| Sistema | Registros | Claves distintas | Unidades operativas | Afluencia NULL | Claves con restricción |
|---|---:|---:|---:|---:|---:|
| Metro | 20,076 | 20,076 | 12 | 0 | 0 |
| Metrobús | 11,711 | 11,711 | 7 | 0 | 0 |
| RTP | 13,382 | 13,382 | 21 | 223 | 223 |
| Cablebús | 3,803 | 3,803 | 3 | 0 | 0 |

Resultado global:

```text
Registros totales:        48,972
Claves distintas:         48,972
Claves duplicadas:             0
Fechas distintas:          1,673
Afluencias NULL:             223
Claves con restricción:      223
```

Las 223 restricciones continúan perteneciendo exclusivamente a RTP:

```text
92  → COLISION
131 → AFLUENCIA_INCOMPLETA
```

Cablebús aporta:

```text
3,803 OK
0 restricciones
```

Por tanto, Cablebús puede incorporarse conceptualmente al contrato:

```text
fecha × sistema × unidad_operativa
```

mediante:

```text
sistema = Cablebús
unidad_operativa = linea
```

sin modificar la estructura del contrato multisistema preliminar.

La integración física continúa pendiente.

---

### Contrato multisistema preliminar vigente

**Estado global: APROBADO CON RESTRICCIONES.**

El contrato analítico preliminar validado actualmente es:

```text
fecha × sistema × unidad_operativa
```

La dimensión:

```text
sistema
```

es obligatoria para preservar la semántica propia de cada red de transporte.

La identidad mínima de una unidad operativa es:

```text
sistema × unidad_operativa
```

No debe utilizarse `unidad_operativa` de manera aislada como identificador global.

Por ejemplo:

```text
Metro / Linea 1
≠
Cablebús / Linea 1
```

aunque ambas unidades puedan compartir una etiqueta textual similar.

---

#### Mapeo actualmente validado

```text
Metro
→ unidad_operativa = linea

Metrobús
→ unidad_operativa = linea

RTP
→ unidad_operativa = servicio

Cablebús
→ unidad_operativa = linea
```

`unidad_operativa` es una abstracción analítica común.

No implica que las entidades nativas de cada sistema sean operacionalmente idénticas.

---

#### Ventana temporal estrictamente común

Para:

```text
Metro
Metrobús
RTP
Cablebús
```

la ventana común validada es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

La incorporación de Cablebús no redujo la ventana común previamente establecida.

---

#### Candidato conceptual multisistema

Dentro de la ventana común:

```text
Metro:
20,076 registros
20,076 claves distintas
12 unidades operativas
0 restricciones

Metrobús:
11,711 registros
11,711 claves distintas
7 unidades operativas
0 restricciones

RTP:
13,382 registros
13,382 claves distintas
21 unidades operativas
223 restricciones

Cablebús:
3,803 registros
3,803 claves distintas
3 unidades operativas
0 restricciones
```

Resultado global:

```text
Registros totales:        48,972
Claves distintas:         48,972
Claves duplicadas:             0
Fechas distintas:          1,673
Afluencias NULL:             223
Claves con restricción:      223
```

Por tanto:

```text
48,972 registros
=
48,972 claves distintas
```

y:

```text
claves duplicadas = 0
```

La granularidad:

```text
fecha × sistema × unidad_operativa
```

continúa funcionando como clave conceptual única para los cuatro sistemas evaluados.

---

#### Restricciones conocidas

Las:

```text
223
```

claves con restricción pertenecen exclusivamente a RTP.

Distribución:

```text
13,159 → OK
92     → COLISION
131    → AFLUENCIA_INCOMPLETA
```

Para las 223 claves RTP problemáticas:

```text
afluencia = NULL
```

en el candidato conceptual agregado.

No se calculan totales parciales.

No se imputan valores faltantes.

No se resuelven colisiones arbitrariamente.

Cablebús aporta:

```text
3,803 OK
0 restricciones
```

y no introduce nuevas restricciones al contrato.

---

#### Medida común

La medida conceptual común continúa siendo:

```text
afluencia reportada
```

Cada sistema conserva primero su granularidad y semántica nativas.

En Cablebús:

```text
fecha × linea × tipo_pago
```

se agrega a:

```text
fecha × linea
```

mediante:

```text
SUM(afluencia)
```

únicamente porque se comprobó que las 3,803 claves dentro de la ventana común contienen:

```text
2 filas
2 tipos de pago
0 NULL
0 colisiones
```

---

#### Tipo físico común

La futura medida multisistema deberá admitir:

```text
NUMERIC
```

Cablebús utiliza individualmente:

```text
BIGINT
```

pero:

```text
BIGINT → NUMERIC
```

es una promoción segura y sin pérdida de información.

---

#### Reglas vigentes

- `sistema` es obligatorio.
- `unidad_operativa` debe interpretarse dentro de su sistema.
- La identidad global mínima es `sistema × unidad_operativa`.
- `NULL ≠ 0`.
- Los ceros se conservan como observaciones válidas.
- Los outliers se preservan.
- Las colisiones no se resuelven sin evidencia.
- No se calculan totales parciales cuando faltan componentes necesarios.
- Las granularidades nativas se conservan.
- `estacion` permanece específica de Metro.
- `tipo_pago` permanece disponible como detalle cuando la fuente lo proporciona.
- Las banderas de calidad conservan trazabilidad hacia el sistema de origen.
- La futura medida común debe admitir `NUMERIC`.

---

#### Estado de integración física

Todavía no existe:

```text
integración física multisistema definitiva
tabla de hechos definitiva
modelo dimensional definitivo
dataset multisistema definitivo en processed/
cubo OLAP definitivo
```

El contrato actual es:

```text
analítico
preliminar
validado
```

y se continuará evaluando con los sistemas restantes antes de materializar una integración física.

---

#### Sistemas incorporados actualmente

```text
Metro       → VALIDADO
Metrobús    → VALIDADO
RTP         → VALIDADO
Cablebús    → VALIDADO
```

Compatibilidad:

```text
Metro ↔ Metrobús
→ APROBADO CON RESTRICCIONES

RTP ↔ contrato multisistema
→ APROBADO CON RESTRICCIONES

Cablebús ↔ contrato multisistema
→ APROBADA
```

Estado global:

```text
APROBADO CON RESTRICCIONES
```

Las restricciones vigentes corresponden exclusivamente a RTP.

---

### Siguiente iteración

El siguiente sistema pendiente es:

**Trolebús**

Trolebús deberá completar individualmente:

```text
FUENTE OFICIAL
↓
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
↓
CONTRATO DE DATOS
↓
CHECKPOINT INDIVIDUAL
```

Antes de proponer transformaciones deberán comprobarse directamente en la fuente:

- estructura física;
- cobertura temporal;
- granularidad;
- dominio de unidades operativas;
- tipos de pago, si existen;
- valores faltantes;
- ceros;
- negativos;
- valores decimales;
- duplicados;
- colisiones;
- outliers;
- consistencia temporal;
- metadatos oficiales.

No debe asumirse previamente qué campo de Trolebús representa:

```text
unidad_operativa
```

La equivalencia deberá demostrarse mediante los datos, el diccionario y los metadatos oficiales.

Después del pipeline individual, Trolebús deberá evaluarse contra el contrato multisistema preliminar vigente:

```text
fecha × sistema × unidad_operativa
```

Actualmente el contrato cuenta con evidencia para:

```text
Metro
→ unidad_operativa = linea

Metrobús
→ unidad_operativa = linea

RTP
→ unidad_operativa = servicio

Cablebús
→ unidad_operativa = linea
```

La incorporación de Trolebús deberá determinar si este contrato sigue siendo suficiente o requiere una nueva generalización semántica.

No debe modificarse artificialmente ningún pipeline previamente validado para adaptar Trolebús.

Todavía no debe construirse:

- integración física multisistema definitiva;
- tabla de hechos definitiva;
- modelo dimensional definitivo;
- dataset multisistema definitivo en `processed/`;
- cubo OLAP definitivo.

La integración física se realizará únicamente después de completar los sistemas pendientes y cerrar el checkpoint multisistema final.

---

## Arquitectura

```text
proyecto/
│
├── data/
│   ├── raw/
│   ├── clean/
│   ├── processed/
│   └── metadata/
│
├── docs/
├── etl/
├── models/
├── notebooks/
│
├── sql/
│   ├── ingestion/
│   ├── integration/
│   ├── quality/
│   └── olap/
│
└── tableau/
```

---

## Pipeline Metro

### 1. Inspección de fuentes

Código:

`etl/inspeccionar_fuentes.py`

Registra:

- tamaño;
- SHA-256;
- encoding;
- delimitador;
- columnas;
- filas;
- filas malformadas;
- ejemplos.

Resultados Metro:

`data/metadata/metro/inspeccion_fuentes_metro.json`

---

### 2. Manifest

Código:

`etl/generar_manifest.py`

Salida:

`data/metadata/metro/manifest_fuentes_metro.csv`

Fuentes registradas:

| Fuente | Registros |
|---|---:|
| Metro Simple | 1,180,920 |
| Metro Desglosada | 1,192,230 |

---

### 3. STAGING

Scripts:

- `sql/ingestion/00_schema_proyecto.sql`
- `sql/ingestion/metro/01_stage_metro.sql`
- `sql/ingestion/metro/02_ingesta_metro.sql`

Las columnas se reciben inicialmente como `TEXT`.

Esto permite inspeccionar y validar los valores antes de aplicar conversiones.

---

### 4. Perfilado

Script:

`sql/quality/metro/03_perfilado_metro.sql`

Se verifican:

- valores vacíos;
- convertibilidad;
- rangos temporales;
- coherencia fecha/año;
- coherencia fecha/mes;
- afluencia;
- longitudes;
- dominios;
- mojibake;
- duplicados;
- colisiones de granularidad.

---

### 5. TYPED

Script:

`sql/integration/metro/04_typed_metro.sql`

Conversión principal:

- `fecha → DATE`
- `anio → SMALLINT`
- `afluencia → INTEGER`

No se aplica todavía limpieza semántica.

---

### 6. CLEAN

Script:

`sql/integration/metro/05_clean_metro.sql`

Incluye:

- corrección de mojibake;
- homologación de líneas;
- variables temporales;
- bandera de afluencia cero;
- bandera de colisión de clave;
- bandera de posibles outliers mediante IQR;
- bandera de texto corregido.

No se eliminan automáticamente ceros, outliers ni colisiones.

---

### 7. Validación

Script:

`sql/quality/metro/06_validacion_metro.sql`

Resultado:

**Todos los controles críticos = OK**

Conteos:

| Capa | Simple | Desglosada |
|---|---:|---:|
| STAGING | 1,180,920 | 1,192,230 |
| TYPED | 1,180,920 | 1,192,230 |
| CLEAN | 1,180,920 | 1,192,230 |

Pérdida de registros:

`0`

Mojibake residual:

`0`

---

## Hallazgo de granularidad — Metro Simple

La granularidad conceptual es:

`fecha × línea × estación`

Se detectaron:

- 31 grupos con colisión;
- 62 filas involucradas;
- máximo 2 registros por combinación;
- 0 duplicados exactos.

Los casos corresponden a:

`Línea B — Oceanía — diciembre de 2020`

En cada día existen dos afluencias distintas.

La colisión ya existe en TYPED, por lo que no fue generada por CLEAN.

### Decisión

Los registros se conservan.

No existe actualmente una variable adicional que permita resolver de forma objetiva cuál registro debería conservarse.

La bandera `es_colision_clave` permite excluir o estudiar estos casos en análisis posteriores sin destruir información.

---

## Contrato de datos Metro

Consultar:

`docs/contrato_datos_metro.md`

---

## Calidad y procedencia

Consultar:

`docs/metro_fuentes_y_calidad.md`

---

## Regla de integración multisistema

Un sistema nuevo no puede integrarse directamente a la base analítica común.

Primero debe completar:

1. procedencia;
2. RAW;
3. SHA-256;
4. manifest;
5. inspección;
6. STAGING;
7. perfilado;
8. TYPED;
9. CLEAN;
10. validación;
11. contrato de datos.

Solo después se evalúa compatibilidad con los sistemas existentes.

---

## Próximo objetivo

### Iteración 5 — Trolebús

El siguiente sistema que debe incorporarse al proceso de preparación de datos es:

```text
Trolebús
```

Los pipelines individuales actualmente validados son:

```text
Metro
Metrobús
RTP
Cablebús
```

El contrato multisistema preliminar vigente es:

```text
fecha × sistema × unidad_operativa
```

con los siguientes mapeos ya respaldados por evidencia:

```text
Metro
→ unidad_operativa = linea

Metrobús
→ unidad_operativa = linea

RTP
→ unidad_operativa = servicio

Cablebús
→ unidad_operativa = linea
```

La ventana temporal estrictamente común actualmente validada es:

```text
2022-01-01 → 2026-07-31
```

con:

```text
1,673 fechas distintas
```

El candidato conceptual actual contiene:

```text
Metro:       20,076 registros
Metrobús:    11,711 registros
RTP:         13,382 registros
Cablebús:     3,803 registros
```

Resultado global:

```text
48,972 registros
48,972 claves distintas
0 claves duplicadas
223 claves con restricción
```

Las 223 restricciones pertenecen exclusivamente a RTP:

```text
92  → COLISION
131 → AFLUENCIA_INCOMPLETA
```

Cablebús aporta:

```text
3,803 claves
3,803 OK
0 restricciones
```

Por tanto, Cablebús queda cerrado como iteración individual y como evaluación de compatibilidad.

---

### Objetivo de la Iteración 5

Trolebús deberá comenzar desde comprensión de la fuente oficial y no desde una adaptación automática del pipeline de Cablebús.

Debe completarse:

```text
FUENTE OFICIAL
↓
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
↓
CONTRATO DE DATOS
↓
CHECKPOINT INDIVIDUAL
```

Antes de proponer cualquier transformación deberán demostrarse directamente desde los datos:

```text
estructura física
cobertura temporal
granularidad
dominio de unidades operativas
tipo de pago
valores faltantes
ceros
negativos
decimales
duplicados
colisiones
outliers
consistencia temporal
```

No debe asumirse todavía qué campo de Trolebús corresponde a:

```text
unidad_operativa
```

La equivalencia deberá justificarse a partir de los datos y metadatos oficiales.

---

### Evaluación posterior

Cuando el pipeline individual de Trolebús quede validado deberá evaluarse contra:

```text
fecha × sistema × unidad_operativa
```

El objetivo será determinar si Trolebús puede incorporarse al contrato actual o si requiere una nueva generalización semántica.

No debe modificarse artificialmente:

```text
Metro
Metrobús
RTP
Cablebús
```

para adaptar Trolebús.

---

### Restricciones vigentes

Todavía no debe construirse:

```text
integración física multisistema definitiva
tabla de hechos definitiva
modelo dimensional definitivo
dataset multisistema definitivo en processed/
cubo OLAP definitivo
```

La integración física deberá realizarse únicamente después de completar los sistemas pendientes y cerrar el checkpoint multisistema final.

---

### Orden de trabajo vigente

```text
Metro
↓
Metrobús
↓
Checkpoint Metro ↔ Metrobús
↓
RTP
↓
Checkpoint RTP ↔ contrato multisistema
↓
Cablebús
↓
Checkpoint Cablebús ↔ contrato multisistema
↓
Trolebús
↓
Checkpoint Trolebús ↔ contrato multisistema
↓
Tren Ligero
↓
Checkpoint multisistema final
↓
Integración física multisistema
↓
Modelo dimensional
↓
OLAP
↓
EDA consolidado
↓
Minería de datos
↓
Evaluación
```

---

## Estado CRISP-DM

| Fase | Estado |
|---|---|
| Comprensión del negocio | Avanzada |
| Comprensión de los datos | Avanzada para Metro, Metrobús, RTP y Cablebús; Trolebús es la siguiente iteración |
| Preparación de datos | Pipelines individuales de Metro, Metrobús, RTP y Cablebús validados |
| Integración multisistema | Contrato conceptual `fecha × sistema × unidad_operativa` validado para cuatro sistemas; estado global APROBADO CON RESTRICCIONES; integración física pendiente |
| Modelado | Pendiente |
| Evaluación | Pendiente |
| Despliegue académico | Pendiente |