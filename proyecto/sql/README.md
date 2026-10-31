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

# Próxima iteración

Metrobús deberá incorporar su propio pipeline:

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

Solo después se evaluará su compatibilidad semántica con Metro.