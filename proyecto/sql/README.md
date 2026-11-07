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
↓
COMPATIBILIDAD
↓
INTEGRACIÓN
↓
OLAP
```

Las etapas de integración y OLAP todavía no se encuentran implementadas de forma definitiva.

---

## Estructura

```text
sql/
├── ingestion/
├── quality/
│   ├── metro/
│   ├── metrobus/
│   └── compatibilidad/
├── integration/
└── olap/
```

---

## `ingestion/`

Contiene la creación del esquema, tablas STAGING y carga de fuentes RAW.

Archivo general:

```text
ingestion/00_schema_proyecto.sql
```

Cada sistema dispone de su propio subdirectorio cuando comienza formalmente su iteración.

Metro:

```text
ingestion/
└── metro/
    ├── 01_stage_metro.sql
    └── 02_ingesta_metro.sql
```

Metrobús:

```text
ingestion/
└── metrobus/
    ├── 01_stage_metrobus.sql
    └── 02_ingesta_metrobus.sql
```

STAGING recibe inicialmente los valores con tipos flexibles para evitar conversiones prematuras y preservar la representación recibida desde RAW.

---

## `quality/`

Contiene:

- perfilado;
- auditoría;
- validaciones;
- controles de calidad;
- conciliaciones entre capas;
- conciliaciones entre recursos;
- checkpoints de compatibilidad analítica.

Estructura actual:

```text
quality/
├── metro/
│   ├── 03_perfilado_metro.sql
│   └── 06_validacion_metro.sql
│
├── metrobus/
│   ├── 03_perfilado_metrobus.sql
│   └── 06_validacion_metrobus.sql
│
└── compatibilidad/
    └── 01_compatibilidad_metro_metrobus.sql
```

El perfilado individual debe ejecutarse antes de construir TYPED.

Los scripts de `compatibilidad/` no modifican los pipelines individuales validados.

Su función es comprobar:

- compatibilidad semántica;
- granularidad;
- cobertura temporal;
- dimensiones compartidas;
- dimensiones específicas;
- calidad de las medidas;
- niveles de agregación;
- condiciones necesarias para una futura integración multisistema.

---

## `integration/`

Contiene transformaciones de tipado, limpieza y homologación de cada sistema.

Metro:

```text
integration/
└── metro/
    ├── 04_typed_metro.sql
    └── 05_clean_metro.sql
```

Metrobús:

```text
integration/
└── metrobus/
    ├── 04_typed_metrobus.sql
    └── 05_clean_metrobus.sql
```

TYPED convierte tipos físicos de forma controlada.

CLEAN aplica transformaciones semánticas justificadas.

Estas responsabilidades no deben mezclarse innecesariamente.

La existencia del directorio `integration/` no significa que ya exista una integración física multisistema.

Actualmente contiene principalmente las transformaciones individuales de TYPED y CLEAN.

La integración física definitiva permanece pendiente.

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

No debe diseñarse ni implementarse el modelo dimensional definitivo hasta comprender suficientemente las granularidades de todos los sistemas de transporte seleccionados.

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

Granularidades validadas:

```text
Simple:
fecha × linea × estacion

Desglosada:
fecha × linea × estacion × tipo_pago
```

Metro Simple conserva:

```text
31 grupos conocidos de colisión
62 filas involucradas
```

correspondientes a:

```text
Línea B
Oceanía
diciembre de 2020
```

Las colisiones no fueron eliminadas.

Metro permanece como baseline validado.

---

# Reglas generales SQL

- RAW nunca se modifica desde SQL.
- STAGING preserva la representación recibida.
- No se construye TYPED sin perfilado previo.
- No se elimina una anomalía únicamente porque sea extrema.
- Los ceros se preservan salvo evidencia que justifique otro tratamiento.
- Los valores faltantes no se convierten automáticamente a cero.
- Las colisiones de granularidad se investigan antes de resolverlas.
- Toda transformación debe permitir conciliación de registros.
- Los scripts deben poder ejecutarse nuevamente.
- No incluir contraseñas ni credenciales.
- No usar rutas personales cuando pueda evitarse.
- Una integración física no debe realizarse antes de comprobar compatibilidad semántica y de granularidad.

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

```text
0
```

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

```text
0
```

Duplicados exactos:

```text
0 / 0
```

Colisiones:

```text
0 / 0
```

Valores `NaN` originales de Simple:

```text
17,227
```

Valores decimales preservados:

```text
57 / 57
```

Líneas lógicas:

```text
7 / 7
```

---

# Reconciliación Metrobús Simple ↔ Desglosada

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

Por tanto, para las claves comparables:

```text
Simple.afluencia
=
SUM(Desglosada.afluencia)
```

La medida es compatible en el periodo validado.

Los recursos mantienen granularidades distintas y no deben concatenarse directamente.

Contrato:

```text
../docs/contrato_datos_metrobus.md
```

Checkpoint individual:

```text
../docs/checkpoint_metrobus.md
```

---

# Checkpoint de compatibilidad Metro ↔ Metrobús

Estado:

**APROBADO CON RESTRICCIONES**

El checkpoint se implementa mediante:

```text
quality/compatibilidad/01_compatibilidad_metro_metrobus.sql
```

Las consultas se ejecutan mediante transacciones de solo lectura:

```sql
BEGIN TRANSACTION READ ONLY;
```

El script no:

- crea tablas;
- inserta registros;
- actualiza registros;
- elimina registros;
- modifica RAW;
- modifica Metro;
- modifica Metrobús.

---

## 1. Cobertura general validada

| Recurso | Fecha mínima | Fecha máxima | Registros | Fechas | Líneas | Afluencia NULL |
|---|---|---|---:|---:|---:|---:|
| Metro Simple | 2010-01-01 | 2026-07-31 | 1,180,920 | 6,056 | 12 | 0 |
| Metro Desglosada | 2021-01-01 | 2026-07-31 | 1,192,230 | 2,038 | 12 | 0 |
| Metrobús Simple | 2005-07-26 | 2026-09-30 | 54,159 | 7,737 | 7 | 17,227 |
| Metrobús Desglosada | 2021-01-01 | 2026-09-30 | 29,386 | 2,099 | 7 | 0 |

Los conteos coinciden con los pipelines individuales previamente validados.

---

## 2. Líneas

Metro contiene:

```text
12 líneas lógicas
```

Metrobús contiene:

```text
7 líneas lógicas
```

Ambos sistemas presentan etiquetas textuales como:

```text
Línea 1
Línea 2
...
Línea 7
```

La coincidencia textual no representa identidad operacional.

Por tanto:

```text
linea
```

no puede funcionar como identificador global independiente.

La identificación analítica requiere al menos:

```text
sistema × linea
```

---

## 3. Tipo de pago

Metro presenta:

```text
Boleto
Gratuidad
Prepago
```

Metrobús presenta:

```text
Gratuidad
Prepago
```

`tipo_pago` es compatible parcialmente.

No forma parte obligatoria de la granularidad multisistema principal y deberá conservarse como detalle adicional cuando corresponda.

---

## 4. Calidad comparada

| Recurso | Nulos | Ceros | Outliers IQR | Filas con colisión |
|---|---:|---:|---:|---:|
| Metro Simple | 0 | 62,025 | 66,361 | 62 |
| Metro Desglosada | 0 | 291,457 | 103,485 | 0 |
| Metrobús Simple | 17,227 | 0 | 3,000 | 0 |
| Metrobús Desglosada | 0 | 0 | 1,090 | 0 |

Los valores nulos, ceros, outliers y colisiones mantienen su semántica y trazabilidad de origen.

---

# Reconciliación interna de Metro

Para determinar si Metro puede agregarse de estación a línea sin alterar la medida, se compararon Metro Simple y Metro Desglosada.

Periodo:

```text
2021-01-01 → 2026-07-31
```

Granularidad de comparación:

```text
fecha × linea × estacion
```

Metro Desglosada se agregó mediante:

```text
SUM(afluencia)
GROUP BY fecha, linea, estacion
```

Resultado:

```text
Claves en la unión:       397,410
Claves comparables:       397,410
Solo Simple:                    0
Solo Desglosada:                0
Coincidencias exactas:    397,410
Diferencias:                    0
Máxima diferencia:              0
```

Por tanto:

```text
Metro Simple.afluencia
=
SUM(Metro Desglosada.afluencia)
```

para las 397,410 claves comparables.

---

# Granularidad multisistema preliminar

Se evaluó como nivel común:

```text
fecha × sistema × linea
```

Ventana temporal:

```text
2021-01-01 → 2026-07-31
```

Metro se agrega desde:

```text
fecha × linea × estacion
```

hacia:

```text
fecha × linea
```

mediante:

```text
SUM(afluencia)
GROUP BY fecha, linea
```

Metrobús Simple ya se encuentra naturalmente en:

```text
fecha × linea
```

Resultados:

| Sistema | Registros | Claves `fecha × linea` | Fecha mínima | Fecha máxima | Líneas | NULL | Ceros | Colisión origen |
|---|---:|---:|---|---|---:|---:|---:|---:|
| Metro | 24,456 | 24,456 | 2021-01-01 | 2026-07-31 | 12 | 0 | 699 | 0 |
| Metrobús | 14,266 | 14,266 | 2021-01-01 | 2026-07-31 | 7 | 0 | 0 | 0 |

En ambos sistemas:

```text
registros = claves fecha × linea
```

por lo que no existen colisiones en el nivel analítico evaluado.

---

# Validación de clave multisistema

La representación lógica combinada produjo:

```text
Registros totales:       38,722
Claves distintas:        38,722
Claves duplicadas:            0
Fechas distintas:         2,038
Fecha mínima:        2021-01-01
Fecha máxima:        2026-07-31
Afluencia NULL:                0
```

Por tanto:

```text
fecha × sistema × linea
```

funciona como clave única en la ventana evaluada.

Estado:

**GRANULARIDAD MULTISISTEMA PRELIMINAR APROBADA**

---

# Restricciones del checkpoint

La aprobación de compatibilidad no significa que exista todavía una integración física definitiva.

Se mantienen las siguientes reglas:

- `sistema` es obligatorio.
- `linea` no identifica globalmente una entidad por sí sola.
- `estacion` permanece como dimensión específica de Metro.
- `tipo_pago` permanece como nivel de detalle adicional.
- `NULL` no debe convertirse a cero.
- Los ceros se conservan.
- Los outliers no se eliminan automáticamente.
- Las colisiones mantienen trazabilidad.
- Las granularidades nativas se preservan.
- La futura medida común debe admitir `NUMERIC`.
- Las banderas de calidad actuales no deben interpretarse automáticamente como indicadores comparables entre sistemas.
- No se construye todavía una tabla de hechos definitiva.
- No se construye todavía el modelo dimensional definitivo.
- No se materializa todavía un dataset multisistema en `processed/`.

Documento completo:

```text
../docs/checkpoint_compatibilidad_metro_metrobus.md
```

---

# Estado actual

```text
Metro
Pipeline individual:
VALIDADO

Metrobús
Pipeline individual:
VALIDADO

Checkpoint Metro ↔ Metrobús:
APROBADO CON RESTRICCIONES

Granularidad multisistema preliminar:
fecha × sistema × linea

Ventana temporal preliminar:
2021-01-01 → 2026-07-31

Integración física:
PENDIENTE

Modelo dimensional:
PENDIENTE
```

---

# Siguiente bloque del proyecto

El siguiente trabajo corresponde a:

```text
ITERACIÓN 3 — RTP
```

RTP deberá completar individualmente:

```text
FUENTE
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

Después se evaluará su compatibilidad con el contrato multisistema preliminar.

El orden vigente continúa:

```text
RTP
↓
Cablebús
↓
Trolebús
↓
Tren Ligero
↓
CHECKPOINT MULTISISTEMA FINAL
↓
INTEGRACIÓN FÍSICA
↓
MODELO DIMENSIONAL
↓
OLAP
↓
EDA CONSOLIDADO
↓
MINERÍA
↓
EVALUACIÓN
```

No debe implementarse una integración física multisistema definitiva antes de completar las iteraciones restantes y el checkpoint multisistema final.