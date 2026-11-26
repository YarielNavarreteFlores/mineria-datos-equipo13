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

El proyecto cuenta actualmente con seis sistemas de transporte cuyo pipeline individual de datos ha sido validado:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
Tren Ligero
```

Todos siguen el principio general:

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
```

Los archivos RAW permanecen fuera de Git cuando corresponde, mientras que la evidencia reproducible de procedencia, inspección, checksums y manifest se conserva en:

```text
metadata/
```

---

### Metro

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

Fuentes principales:

| Fuente | Registros | Estado |
|---|---:|---|
| Metro Simple | 1,180,920 | Validada |
| Metro Desglosada | 1,192,230 | Validada |

Granularidades:

```text
Simple:
fecha × linea × estacion

Desglosada:
fecha × linea × estacion × tipo_pago
```

Metro constituye el baseline técnico del proyecto.

---

### Metrobús

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

Fuentes:

| Recurso | Registros | Columnas |
|---|---:|---:|
| Simple | 54,159 | 5 |
| Desglosada | 29,386 | 6 |

Granularidades:

```text
Simple:
fecha × linea

Desglosada:
fecha × linea × tipo_pago
```

Pérdida entre STAGING, TYPED y CLEAN:

```text
0
```

Los valores `NaN` del recurso Simple se preservan semánticamente como ausencia de dato y no como cero.

---

### RTP

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

La dimensión operacional respaldada por la fuente es:

```text
servicio
```

Dentro del contrato multisistema:

```text
unidad_operativa = servicio
```

RTP mantiene restricciones de calidad conocidas que no fueron corregidas artificialmente.

En la ventana multisistema común existen:

```text
223 claves con restricción
```

correspondientes a:

```text
92  → COLISION
131 → AFLUENCIA_INCOMPLETA
```

Estas restricciones se mantienen explícitamente para conservar trazabilidad.

---

### Cablebús

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

La dimensión operacional validada es:

```text
linea
```

Dentro del contrato multisistema:

```text
unidad_operativa = linea
```

Cablebús no introduce nuevas restricciones de calidad en el candidato multisistema vigente.

---

### Trolebús

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

Pipeline individual:

```text
STAGING: 65,013
TYPED:   65,013
CLEAN:   65,013
```

Pérdida:

```text
0
```

La dimensión operacional validada es:

```text
linea
```

Dentro del contrato multisistema:

```text
unidad_operativa = linea
```

Trolebús no introduce nuevas restricciones de calidad en el candidato multisistema vigente.

---

### Tren Ligero

Estado:

```text
PIPELINE INDIVIDUAL:
VALIDADO
```

Conteos:

```text
STAGING: 3,530
TYPED:   3,530
CLEAN:   3,530
```

Pérdida:

```text
0
```

Cobertura individual:

```text
2022-01-01 → 2026-10-31
```

Fechas distintas:

```text
1,765
```

Granularidad individual:

```text
fecha × tipo_pago
```

Tipos de pago:

```text
Gratuidad
Prepago
```

La fuente física no contiene:

```text
linea
servicio
unidad_operativa
```

Por tanto, el pipeline individual tampoco crea artificialmente dichos campos.

Para la capa conceptual de integración se validó:

```text
sistema = Tren Ligero
unidad_operativa = Sistema completo
```

con procedencia:

```text
DERIVADA PARA INTEGRACIÓN
```

Esta dimensión no representa una columna publicada por la fuente.

---

## Estado del contrato multisistema

El contrato conceptual vigente es:

```text
fecha × sistema × unidad_operativa
```

Mapeo:

```text
Metro
→ unidad_operativa = linea
→ origen = FUENTE

Metrobús
→ unidad_operativa = linea
→ origen = FUENTE

RTP
→ unidad_operativa = servicio
→ origen = FUENTE

Cablebús
→ unidad_operativa = linea
→ origen = FUENTE

Trolebús
→ unidad_operativa = linea
→ origen = FUENTE

Tren Ligero
→ unidad_operativa = Sistema completo
→ origen = DERIVADA PARA INTEGRACIÓN
```

Ventana temporal estrictamente común:

```text
2022-01-01 → 2026-07-31
```

Fechas:

```text
1,673
```

Candidato conceptual:

```text
Metro:          20,076
Metrobús:       11,711
RTP:            13,382
Cablebús:        3,803
Trolebús:       20,199
Tren Ligero:     1,673
----------------------
Total:          70,844
```

Control global:

```text
Registros:                  70,844
Claves distintas:           70,844
Claves duplicadas:               0
Claves con restricción:        223
```

Las 223 restricciones de calidad pertenecen exclusivamente a RTP.

Estado:

```text
APROBADO CON RESTRICCIONES
```

---

## Estado de `processed/`

La integración de los seis sistemas está materializada en PostgreSQL. Ambas tablas tienen una fila por combinación de `fecha`, `sistema` y `unidad_operativa`.

| Tabla | Uso | Cobertura validada |
|---|---|---|
| `proyecto.afluencia_diaria_multisistema` | Comparar los seis sistemas durante la ventana común del 2022-01-01 al 2026-07-31. | 70,844 claves. |
| `proyecto.afluencia_diaria_historica` | Consultar toda la historia disponible de cada sistema. | 168,053 claves, incluidas las 70,844 de la ventana común. |

En la tabla histórica, 150,572 claves tienen afluencia conocida y 17,481 conservan `NULL`. La columna `estado_calidad` identifica el motivo. Para calcular indicadores o preparar datos de entrenamiento, un `NULL` representa una afluencia desconocida y debe distinguirse de un cero observado.

La carpeta `processed/` queda reservada para archivos derivados cuyo propósito analítico esté documentado. Para consultar las tablas validadas se puede trabajar directamente en PostgreSQL. Las reglas de construcción y la evidencia de conciliación están en la [documentación de la base histórica](../docs/base_historica_multisistema.md).

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