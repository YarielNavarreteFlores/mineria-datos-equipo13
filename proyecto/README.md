# Proyecto semestral — Minería de Datos

## Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México

Equipo 13 — Licenciatura en Ciencia de Datos, ESCOM-IPN.

---

## Estado actual

El proyecto se encuentra en la fase de **Preparación de Datos de CRISP-DM**.

Metro, Metrobús y RTP completaron sus pipelines individuales reproducibles.

También se completaron:

- checkpoint de compatibilidad Metro ↔ Metrobús;
- checkpoint de compatibilidad RTP ↔ contrato multisistema preliminar.

La incorporación de RTP obligó a generalizar la granularidad multisistema preliminar.

### Estado de iteraciones

| Sistema | RAW | Metadata | STAGING | Perfilado | TYPED | CLEAN | Validación | Contrato |
|---|---|---|---|---|---|---|---|---|
| Metro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Metrobús | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RTP | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cablebús | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
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

### Checkpoint RTP ↔ contrato multisistema preliminar

Estado:

**APROBADO CON RESTRICCIONES**

Script reproducible:

```text
sql/quality/compatibilidad/02_compatibilidad_rtp_contrato_preliminar.sql
```

Documento:

```text
docs/checkpoint_compatibilidad_rtp_multisistema.md
```

La ventana estrictamente común para Metro, Metrobús y RTP es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

La incorporación de RTP generalizó el contrato anterior:

```text
fecha × sistema × linea
```

hacia:

```text
fecha × sistema × unidad_operativa
```

Mapeo conceptual:

```text
Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio
```

`unidad_operativa` es una abstracción analítica y no implica que `linea` y `servicio` sean conceptos idénticos.

Resultados del candidato conceptual:

| Sistema | Registros | Claves distintas | Unidades operativas | Afluencia NULL | Claves con restricción |
|---|---:|---:|---:|---:|---:|
| Metro | 20,076 | 20,076 | 12 | 0 | 0 |
| Metrobús | 11,711 | 11,711 | 7 | 0 | 0 |
| RTP | 13,382 | 13,382 | 21 | 223 | 223 |

Resultado global:

```text
Registros totales:        45,169
Claves distintas:         45,169
Claves duplicadas:             0
Fechas distintas:          1,673
Afluencias NULL:             223
Claves con restricción:      223
```

Las 223 restricciones RTP corresponden a:

```text
92  → COLISION
131 → AFLUENCIA_INCOMPLETA
```

Para dichas claves no se construye artificialmente una afluencia total:

```text
afluencia = NULL
```

La integración física multisistema continúa pendiente.

### Contrato multisistema preliminar vigente

Granularidad conceptual:

```text
fecha × sistema × unidad_operativa
```

Medida común:

```text
afluencia reportada
```

Tipo físico futuro requerido:

```text
NUMERIC
```

Reglas vigentes:

- `sistema` es obligatorio;
- `unidad_operativa` debe interpretarse dentro de su sistema;
- `NULL ≠ 0`;
- no imputar valores faltantes automáticamente;
- no eliminar outliers únicamente por magnitud;
- no resolver colisiones sin evidencia;
- conservar granularidades nativas;
- conservar trazabilidad hacia CLEAN, TYPED, STAGING y RAW;
- `estacion` permanece específica de Metro;
- `tipo_pago` permanece como nivel adicional;
- no construir todavía una tabla de hechos definitiva;
- no materializar todavía un dataset multisistema definitivo en `processed/`.

### Siguiente iteración

El siguiente sistema pendiente es:

**Cablebús**

Deberá completar individualmente:

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

Después deberá evaluarse contra el contrato multisistema preliminar vigente:

```text
fecha × sistema × unidad_operativa
```

No debe construirse todavía:

- integración física definitiva;
- tabla de hechos definitiva;
- modelo dimensional definitivo;
- dataset multisistema definitivo en `processed/`;
- cubo OLAP definitivo.

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

### Iteración 4 — Cablebús

Metro, Metrobús y RTP cuentan con pipelines individuales validados.

El contrato multisistema preliminar vigente es:

```text
fecha × sistema × unidad_operativa
```

con ventana común actual:

```text
2022-01-01 → 2026-07-31
```

La siguiente etapa corresponde a **Cablebús**.

Cablebús deberá completar individualmente:

1. identificación de la fuente oficial;
2. preservación RAW;
3. metadata y procedencia;
4. SHA-256;
5. inspección reproducible;
6. manifest;
7. STAGING;
8. perfilado;
9. TYPED;
10. CLEAN;
11. validación integral;
12. contrato de datos;
13. checkpoint individual.

Después deberá evaluarse su compatibilidad contra:

```text
fecha × sistema × unidad_operativa
```

La dimensión nativa equivalente a `unidad_operativa` deberá demostrarse a partir de los datos y metadatos de Cablebús.

No debe asumirse de antemano que será:

```text
linea
```

ni modificarse la fuente para adaptarla al contrato.

Todavía no debe construirse:

- una integración física multisistema definitiva;
- una tabla de hechos definitiva;
- un modelo dimensional definitivo;
- estructuras OLAP definitivas;
- un dataset multisistema definitivo en `processed/`.

El orden vigente de trabajo es:

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
Trolebús
↓
Tren Ligero
↓
Checkpoint multisistema final
↓
Integración física
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
| Comprensión de los datos | Avanzada para Metro, Metrobús y RTP; Cablebús es la siguiente iteración |
| Preparación de datos | Metro, Metrobús y RTP validados; checkpoints de compatibilidad aprobados con restricciones |
| Integración multisistema | Compatibilidad conceptual en desarrollo; integración física pendiente |
| Modelado | Pendiente |
| Evaluación | Pendiente |
| Despliegue académico | Pendiente |