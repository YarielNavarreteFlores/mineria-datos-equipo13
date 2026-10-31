# Proyecto semestral — Minería de Datos

## Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México

Equipo 13 — Licenciatura en Ciencia de Datos, ESCOM-IPN.

---

## Estado actual

El proyecto se encuentra en la fase de **Preparación de Datos de CRISP-DM**.

### Estado de iteraciones

| Sistema | RAW | Metadata | STAGING | Perfilado | TYPED | CLEAN | Validación | Contrato |
|---|---|---|---|---|---|---|---|---|
| Metro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Metrobús | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| RTP | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
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

El sistema Metro constituye el primer pipeline completo y funciona como baseline técnico para incorporar posteriormente otros sistemas de transporte.

Flujo implementado:

`RAW → STAGING → TYPED → CLEAN → VALIDACIÓN`

### Próxima iteración

**Metrobús**

La siguiente fuente será sometida al mismo proceso antes de evaluar su integración con Metro.

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

### Iteración 2 — Metrobús

Antes de integrar Metrobús se deberán determinar:

- fuente oficial;
- cobertura temporal;
- granularidad;
- medida de demanda;
- dimensiones disponibles;
- calidad;
- compatibilidad semántica con Metro.

Después se podrá diseñar una capa analítica multisistema común.

---

## Estado CRISP-DM

| Fase | Estado |
|---|---|
| Comprensión del negocio | Avanzada |
| Comprensión de los datos | Avanzada para Metro |
| Preparación de datos | Metro validado; multisistema en desarrollo |
| Modelado | Pendiente |
| Evaluación | Pendiente |
| Despliegue académico | Pendiente |