# Proyecto semestral — Minería de Datos

## Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México

Equipo 13 — Licenciatura en Ciencia de Datos, ESCOM-IPN.

---

## Estado actual

El proyecto se encuentra en la fase de **Preparación de Datos de CRISP-DM**.

Metro y Metrobús completaron sus pipelines individuales y el checkpoint de compatibilidad analítica entre ambos sistemas fue cerrado satisfactoriamente.

La siguiente iteración corresponde a **RTP**.

### Estado de iteraciones

| Sistema | RAW | Metadata | STAGING | Perfilado | TYPED | CLEAN | Validación | Contrato |
|---|---|---|---|---|---|---|---|---|
| Metro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Metrobús | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RTP | ⏳ | ⏳ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| Cablebús | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| Trolebús | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| Tren Ligero | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

**Leyenda**

- ✅ Validado.
- ⏳ Próxima iteración / en preparación.
- ⚪ Pendiente.

### Iteración 1 — STC Metro

Estado:

**VALIDADA**

Metro constituye el primer pipeline completo y permanece como baseline técnico.

Flujo:

```text
RAW → STAGING → TYPED → CLEAN → VALIDACIÓN
```

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
- 57 valores decimales preservados mediante `NUMERIC`.
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

Script reproducible:

```text
sql/quality/compatibilidad/01_compatibilidad_metro_metrobus.sql
```

Documento:

```text
docs/checkpoint_compatibilidad_metro_metrobus.md
```

Ventana común validada:

```text
2021-01-01 → 2026-07-31
```

Granularidad multisistema preliminar:

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

Reconciliación interna de Metro:

```text
Claves comparables:      397,410
Coincidencias exactas:   397,410
Diferencias:                   0
Máxima diferencia:             0
```

Decisiones principales:

- `sistema` es obligatorio para identificar correctamente una línea;
- `estacion` permanece específica de Metro;
- `tipo_pago` permanece como detalle adicional;
- `NULL` y cero conservan significados distintos;
- los outliers no se eliminan;
- las granularidades nativas se conservan;
- no se construye todavía integración física;
- no se construye todavía modelo dimensional definitivo.

### Siguiente iteración

**Iteración 3 — RTP**

RTP deberá completar:

```text
FUENTE
↓
RAW
↓
METADATA
↓
INSPECCIÓN
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
CONTRATO
```

Solo después se evaluará su compatibilidad con el contrato multisistema preliminar.

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

### Iteración 3 — RTP

El checkpoint de compatibilidad analítica Metro ↔ Metrobús se encuentra cerrado con resultado:

**APROBADO CON RESTRICCIONES**

La siguiente etapa del proyecto corresponde a la incorporación de **RTP** como tercer sistema de transporte.

Antes de evaluar cualquier integración multisistema, RTP deberá completar individualmente:

1. identificación de la fuente oficial;
2. preservación de archivos RAW;
3. registro de procedencia;
4. verificación de integridad mediante SHA-256;
5. generación del manifest;
6. inspección estructural;
7. construcción de STAGING;
8. perfilado;
9. construcción de TYPED;
10. construcción de CLEAN;
11. validación integral;
12. contrato de datos;
13. checkpoint individual.

El pipeline esperado será:

```text
FUENTE OFICIAL
      ↓
RAW
      ↓
METADATA / PROCEDENCIA
      ↓
INSPECCIÓN
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

Después de validar RTP se evaluará su compatibilidad contra el contrato multisistema preliminar establecido mediante Metro y Metrobús.

Actualmente se considera como granularidad multisistema preliminar:

```text
fecha × sistema × linea
```

Esta granularidad no debe considerarse definitiva hasta evaluar los sistemas restantes.

No debe construirse todavía:

- una integración física multisistema definitiva;
- una tabla de hechos definitiva;
- un modelo dimensional definitivo;
- estructuras OLAP definitivas.

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
| Comprensión de los datos | Avanzada para Metro y Metrobús; RTP es la siguiente iteración |
| Preparación de datos | Metro y Metrobús validados; checkpoint de compatibilidad aprobado |
| Integración multisistema | Pendiente hasta evaluar los sistemas restantes |
| Modelado | Pendiente |
| Evaluación | Pendiente |
| Despliegue académico | Pendiente |