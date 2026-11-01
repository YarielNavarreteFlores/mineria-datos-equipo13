# SQL del proyecto semestral

Esta carpeta contiene la implementación PostgreSQL del pipeline de datos del proyecto.

Base de datos principal:

```text
mineria_datos_2026b
```

Esquema del proyecto:

```text
proyecto
```

La arquitectura SQL sigue:

`STAGING → PERFILADO → TYPED → CLEAN → VALIDACIÓN → INTEGRACIÓN → OLAP`

---

## Estructura

```text
sql/
├── ingestion/
├── quality/
├── integration/
└── olap/
```

---

## `ingestion/`

Contiene la creación del esquema, tablas STAGING y carga de fuentes RAW.

Archivo general:

```text
00_schema_proyecto.sql
```

Cada sistema puede tener su propio subdirectorio.

Ejemplo:

```text
ingestion/
└── metro/
    ├── 01_stage_metro.sql
    └── 02_ingesta_metro.sql
```

STAGING recibe inicialmente los valores con tipos flexibles para evitar conversiones prematuras.

---

## `quality/`

Contiene:

- perfilado;
- auditoría;
- validaciones;
- controles de calidad;
- conciliaciones entre capas.

Metro:

```text
quality/
└── metro/
    ├── 03_perfilado_metro.sql
    └── 06_validacion_metro.sql
```

El perfilado debe ejecutarse antes de construir TYPED.

---

## `integration/`

Contiene transformaciones de tipado, limpieza, homologación e integración.

Metro:

```text
integration/
└── metro/
    ├── 04_typed_metro.sql
    └── 05_clean_metro.sql
```

TYPED convierte tipos físicos.

CLEAN aplica transformaciones semánticas justificadas.

Estas responsabilidades no deben mezclarse innecesariamente.

---

## `olap/`

Reservado para:

- modelo dimensional;
- tablas de hechos;
- dimensiones;
- agregaciones;
- consultas OLAP;
- estructuras analíticas multisistema.

Actualmente permanece pendiente.

No debe diseñarse el modelo dimensional definitivo hasta comprender suficientemente las granularidades de los diferentes sistemas de transporte.

---

# Orden actual de ejecución — Metro

## 1. Crear esquema

```text
ingestion/00_schema_proyecto.sql
```

## 2. Crear STAGING

```text
ingestion/metro/01_stage_metro.sql
```

## 3. Ingestar RAW

```text
ingestion/metro/02_ingesta_metro.sql
```

Este archivo utiliza `psql` y `\copy`.

## 4. Perfilar

```text
quality/metro/03_perfilado_metro.sql
```

## 5. Construir TYPED

```text
integration/metro/04_typed_metro.sql
```

## 6. Construir CLEAN

```text
integration/metro/05_clean_metro.sql
```

## 7. Validar

```text
quality/metro/06_validacion_metro.sql
```

Resultado actual:

**Todos los controles críticos de Metro = OK.**

---

# Conteos Metro

| Capa | Simple | Desglosada |
|---|---:|---:|
| STAGING | 1,180,920 | 1,192,230 |
| TYPED | 1,180,920 | 1,192,230 |
| CLEAN | 1,180,920 | 1,192,230 |

Pérdida de registros:

```text
0
```

---

# Reglas

- RAW nunca se modifica desde SQL.
- STAGING preserva la representación recibida.
- No se construye TYPED sin perfilado previo.
- No se elimina una anomalía únicamente porque sea extrema.
- Los ceros se preservan salvo evidencia que justifique otro tratamiento.
- Las colisiones de granularidad se investigan antes de resolverlas.
- Toda transformación debe permitir conciliación de registros.
- Los scripts deben poder ejecutarse nuevamente.
- No incluir contraseñas ni credenciales.
- No usar rutas personales cuando pueda evitarse.

---

# Pipeline validado — Metrobús

La Iteración 2 de Metrobús completó su pipeline individual:

```text
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

## Orden de ejecución

### 1. Crear STAGING

```text
ingestion/metrobus/01_stage_metrobus.sql
```

Estructuras recibidas:

```text
Simple:
fecha, anio, mes, linea, afluencia

Desglosada:
fecha, mes, anio, linea, tipo_pago, afluencia
```

Todas las columnas se reciben inicialmente como `TEXT`.

### 2. Ingestar RAW

```text
ingestion/metrobus/02_ingesta_metrobus.sql
```

Se ejecuta mediante `psql` y `\copy`.

Conteos:

```text
Simple:       54,159
Desglosada:   29,386
```

Diferencia contra manifest:

`0`

### 3. Perfilar

```text
quality/metrobus/03_perfilado_metrobus.sql
```

El perfilado determinó, entre otros:

- cobertura temporal;
- granularidad;
- convertibilidad;
- dominios;
- valores `NaN`;
- valores decimales;
- duplicados;
- colisiones;
- variantes de línea;
- outliers;
- relación Simple ↔ Desglosada.

Granularidades validadas:

```text
Simple:
fecha × linea

Desglosada:
fecha × linea × tipo_pago
```

### 4. Construir TYPED

```text
integration/metrobus/04_typed_metrobus.sql
```

Conversiones principales:

```text
fecha      → DATE
anio       → SMALLINT
afluencia  → NUMERIC
```

En Simple:

```text
NaN → NULL
```

`NaN` no se transforma a cero.

Se preservan 57 valores decimales válidos en cada recurso.

### 5. Construir CLEAN

```text
integration/metrobus/05_clean_metrobus.sql
```

Incluye:

- homologación de línea;
- variables temporales;
- bandera de afluencia no disponible;
- bandera de afluencia cero;
- bandera de colisión;
- bandera de outlier IQR;
- bandera de línea homologada.

Dominio de líneas:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
```

Outliers IQR preservados:

```text
Simple:       3,000
Desglosada:   1,090
```

### 6. Validar

```text
quality/metrobus/06_validacion_metrobus.sql
```

Resultado:

**VALIDACIÓN METROBÚS OK**

Conteos:

| Capa | Simple | Desglosada |
|---|---:|---:|
| STAGING | 54,159 | 29,386 |
| TYPED | 54,159 | 29,386 |
| CLEAN | 54,159 | 29,386 |

Pérdida:

`0`

Duplicados exactos:

`0 / 0`

Colisiones:

`0 / 0`

Valores `NaN` originales de Simple:

`17,227`

Valores decimales preservados:

`57 / 57`

Líneas lógicas:

`7 / 7`

## Reconciliación Simple ↔ Desglosada

Periodo común:

```text
2021-01-01 → 2026-09-30
```

Para Desglosada se utiliza:

```text
SUM(afluencia)
GROUP BY fecha, linea
```

Resultado:

```text
Claves comparables:       14,693
Coincidencias exactas:    14,693
Diferencias:                   0
```

Por tanto, en las claves comparables:

```text
Simple.afluencia
=
SUM(Desglosada.afluencia)
```

La medida es compatible en el periodo validado, pero los recursos
mantienen granularidades distintas y no deben concatenarse
directamente.

Contrato:

`../docs/contrato_datos_metrobus.md`

Checkpoint:

`../docs/checkpoint_metrobus.md`

---

# Siguiente bloque del proyecto

Con Metro y Metrobús validados individualmente, el siguiente trabajo es:

```text
CHECKPOINT DE COMPATIBILIDAD
Metro ↔ Metrobús
```

Antes de construir una capa multisistema se deberá estudiar:

- granularidad común;
- cobertura temporal;
- dimensiones compartidas;
- definición de afluencia;
- ausencia de estación en Metrobús;
- disponibilidad de `tipo_pago`;
- estructura de líneas;
- nivel de agregación compatible;
- diseño de una futura tabla de hechos y dimensiones.

No debe implementarse una unión física definitiva antes de completar
este análisis.