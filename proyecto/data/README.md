# Datos del proyecto semestral

Esta carpeta contiene la organización de datos utilizada por el proyecto:

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

La estructura sigue el principio de trazabilidad:

`RAW → STAGING → TYPED → CLEAN → PROCESSED`

Las capas STAGING, TYPED y CLEAN se implementan principalmente en PostgreSQL. Las carpetas de este directorio almacenan fuentes físicas, metadatos y, cuando sea necesario, datasets derivados materializados.

---

## `raw/`

Contiene los archivos originales obtenidos de las fuentes oficiales.

Reglas:

- no modificar;
- no corregir;
- no eliminar filas;
- no cambiar valores;
- no utilizar Excel para sobrescribir el archivo;
- verificar integridad mediante SHA-256;
- registrar procedencia y fecha de obtención;
- no versionar archivos RAW grandes en Git.

Los archivos RAW deben permanecer disponibles localmente en las máquinas de trabajo autorizadas.

Ejemplo:

```text
raw/
└── metro/
    ├── datos_metro_simple_raw.csv
    └── datos_metro_desglosada_raw.csv
```

Los archivos anteriores existen localmente, pero están excluidos de Git mediante `.gitignore`.

---

## `metadata/`

Contiene información reproducible sobre las fuentes utilizadas.

Puede incluir:

- manifest de archivos;
- SHA-256;
- tamaño;
- número de registros;
- número de columnas;
- encoding;
- delimitador;
- resultados de inspección;
- procedencia;
- observaciones sobre versiones.

Ejemplo Metro:

```text
metadata/
└── metro/
    ├── inspeccion_fuentes_metro.json
    └── manifest_fuentes_metro.csv
```

Los metadatos sí deben versionarse cuando no contienen información sensible.

---

## `clean/`

Reservado para archivos CLEAN materializados fuera de PostgreSQL cuando exista una razón explícita para hacerlo.

Actualmente la capa CLEAN de Metro reside en PostgreSQL:

```text
proyecto.metro_simple_clean
proyecto.metro_desglosada_clean
```

Por lo tanto, esta carpeta puede permanecer vacía.

No debe generarse una copia CSV únicamente por duplicar información.

---

## `processed/`

Reservado para datasets analíticos derivados y preparados para:

- integración multisistema;
- OLAP;
- análisis exploratorio consolidado;
- feature engineering;
- minería de datos;
- modelado.

Un archivo debe entrar a `processed/` únicamente cuando su propósito analítico esté documentado.

---

## Estado actual

### Metro

Fuentes registradas:

| Fuente | Registros | Estado |
|---|---:|---|
| Metro Simple | 1,180,920 | Validada |
| Metro Desglosada | 1,192,230 | Validada |

Pipeline:

`RAW → STAGING → TYPED → CLEAN → VALIDACIÓN`

Estado:

**Baseline Metro validado.**

### Metrobús

Estado:

**Pipeline individual validado.**

Fuentes:

| Recurso | Registros | Columnas | Cobertura |
|---|---:|---:|---|
| Simple | 54,159 | 5 | 2005-07-26 a 2026-09-30 |
| Desglosada | 29,386 | 6 | 2021-01-01 a 2026-09-30 |

Pipeline:

`RAW → STAGING → PERFILADO → TYPED → CLEAN → VALIDACIÓN`

Conteos por capa:

| Capa | Simple | Desglosada |
|---|---:|---:|
| STAGING | 54,159 | 29,386 |
| TYPED | 54,159 | 29,386 |
| CLEAN | 54,159 | 29,386 |

Pérdida de registros:

`0`

Granularidades validadas:

```text
Simple:
fecha × linea

Desglosada:
fecha × linea × tipo_pago
```

Hallazgos principales:

- 17,227 literales `NaN` en Simple.
- `NaN` no se interpreta como cero.
- En TYPED/CLEAN se representa mediante `NULL`.
- 57 valores decimales válidos preservados en cada recurso mediante `NUMERIC`.
- 0 duplicados exactos.
- 0 colisiones de granularidad.
- 7 líneas lógicas después de homologación.
- `Prepago` y `Gratuidad` como categorías de `tipo_pago`.
- 3,000 posibles outliers IQR en Simple.
- 1,090 posibles outliers IQR en Desglosada.
- Ningún outlier fue eliminado.

En el periodo común:

```text
2021-01-01 → 2026-09-30
```

se validaron:

```text
14,693 claves comparables
14,693 coincidencias exactas
0 diferencias
```

cumpliéndose:

```text
Simple.afluencia
=
SUM(Desglosada.afluencia)
```

para las claves comparables `fecha × linea`.

Los archivos RAW continúan en:

`raw/metrobus/`

y permanecen excluidos de Git.

Metadatos:

`metadata/metrobus/`

Contrato:

`../docs/contrato_datos_metrobus.md`

Checkpoint:

`../docs/checkpoint_metrobus.md`

Metrobús todavía no se encuentra integrado físicamente con Metro.

---

## Principio de trazabilidad

Toda fuente incorporada debe poder responder:

1. ¿Quién la publica?
2. ¿De dónde se descargó?
3. ¿Cuándo se obtuvo?
4. ¿Qué periodo cubre?
5. ¿Qué representa una fila?
6. ¿Cuántas filas y columnas contiene?
7. ¿Cuál es su SHA-256?
8. ¿Qué transformaciones recibió?
9. ¿Qué problemas de calidad se detectaron?
10. ¿Qué versión terminó utilizándose?

Si estas preguntas no pueden responderse, la fuente todavía no está lista para integrarse al proyecto.