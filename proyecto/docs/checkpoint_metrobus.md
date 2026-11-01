# Checkpoint — Iteración 2: Metrobús

Fecha del checkpoint: 2026-11-01.

Rama de trabajo:

`feature/etl-metrobus`

Commit base observado de `main` al iniciar la iteración:

`1e68aadf8a8287be0aca544702f2b51d381d53eb`

El trabajo de esta iteración todavía no debe asumirse integrado en `main`
hasta completar revisión, commit, push y Pull Request.

---

# 1. Proyecto

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

La pregunta de minería, hipótesis, objetivos y alcance continúan siendo
los definidos en el README raíz.

Metro permanece como baseline validado.

La Iteración 2 de Metrobús completó:

```text
RAW
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

Metrobús todavía no se encuentra integrado analíticamente con Metro.

El siguiente checkpoint del proyecto deberá evaluar su compatibilidad
para una futura capa multisistema.

---

# 2. Entorno validado

- Windows.
- Git Bash.
- VS Code.
- Python 3.12.10.
- PostgreSQL 18.3.
- DBeaver.
- `psql` 18.3.
- Base de datos: `mineria_datos_2026b`.
- Esquema: `proyecto`.
- Usuario PostgreSQL utilizado durante la iteración: `postgres`.
- Servidor local observado: `127.0.0.1`.
- Puerto: `5432`.

La ingestión con `\copy` se ejecutó mediante `psql`.

---

# 3. Fuente

Portal:

`https://datos.cdmx.gob.mx/dataset/afluencia-diaria-de-metrobus-cdmx`

Organización y mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI).**

Licencia anunciada:

`CC-BY-4.0-ESP`

Fecha de consulta documentada:

`2026-11-01`

Última actualización mostrada por el portal durante la adquisición:

`2026-10-22 11:50 (UTC-06:00)`

La fecha de actualización de la ficha no se utiliza como sustituto
de la cobertura temporal efectiva de los CSV.

Procedencia detallada:

`proyecto/data/metadata/metrobus/procedencia_metrobus.md`

---

# 4. Archivos fuente

| Archivo | Bytes | Registros | Columnas |
|---|---:|---:|---:|
| `datos_metrobus_simple_raw.csv` | 2,068,083 | 54,159 | 5 |
| `datos_metrobus_desglosada_raw.csv` | 1,388,641 | 29,386 | 6 |
| `diccionario_metrobus_simple_original.csv` | 948 | 5 | 9 |
| `diccionario_metrobus_desglosada_original.csv` | 1,703 | 9 | 9 |

RAW:

`proyecto/data/raw/metrobus/`

Metadatos y diccionarios:

`proyecto/data/metadata/metrobus/`

Los cuatro archivos presentaron:

`0 filas estructuralmente malformadas`

Los SHA-256 están registrados en:

`proyecto/data/metadata/metrobus/checksums_fuentes_metrobus.sha256`

La comprobación de los cuatro hashes devolvió resultado satisfactorio.

Los RAW permanecen excluidos de Git.

---

# 5. Estructura física recibida

## Simple

Orden real de columnas:

```text
fecha,anio,mes,linea,afluencia
```

## Desglosada

Orden real de columnas:

```text
fecha,mes,anio,linea,tipo_pago,afluencia
```

El orden de `anio` y `mes` es diferente entre ambos recursos.

No se modificaron los archivos RAW para igualarlos.

---

# 6. Encoding e inspección

Simple, Desglosada y diccionario Simple:

- lectura estricta exitosa mediante `utf-8-sig`;
- sin BOM UTF-8 detectado durante la inspección.

Diccionario Desglosado:

- lectura estricta mediante `latin-1`;
- contiene mojibake visible en parte del texto original.

No se encontraron caracteres U+FFFD durante la inspección.

El diccionario Desglosado se conserva sin reescribir sus bytes.

---

# 7. Scripts implementados

## Ingestión

```text
proyecto/sql/ingestion/metrobus/01_stage_metrobus.sql
proyecto/sql/ingestion/metrobus/02_ingesta_metrobus.sql
```

## Perfilado y validación

```text
proyecto/sql/quality/metrobus/03_perfilado_metrobus.sql
proyecto/sql/quality/metrobus/06_validacion_metrobus.sql
```

## Tipado y limpieza

```text
proyecto/sql/integration/metrobus/04_typed_metrobus.sql
proyecto/sql/integration/metrobus/05_clean_metrobus.sql
```

---

# 8. STAGING

Tablas creadas:

```text
proyecto.metrobus_simple_stage
proyecto.metrobus_desglosada_stage
```

Todas las columnas se reciben inicialmente como `TEXT`.

Conteos:

| Fuente | STAGING |
|---|---:|
| Simple | 54,159 |
| Desglosada | 29,386 |

Diferencia contra manifest:

`0 registros`

El literal `NaN` permanece como texto en STAGING.

---

# 9. Perfilado

## 9.1 Cobertura temporal

### Simple

```text
2005-07-26 → 2026-09-30
```

Fechas distintas:

`7,737`

### Desglosada

```text
2021-01-01 → 2026-09-30
```

Fechas distintas:

`2,099`

---

## 9.2 Granularidad validada

Simple:

```text
fecha × linea
```

Desglosada:

```text
fecha × linea × tipo_pago
```

Colisiones detectadas antes y después de homologar línea:

```text
Simple:       0
Desglosada:   0
```

Duplicados exactos:

```text
Simple:       0
Desglosada:   0
```

---

## 9.3 Coherencia temporal

Se comprobaron:

```text
fecha ↔ anio
fecha ↔ mes
```

Resultado:

```text
Simple:       0 inconsistencias
Desglosada:   0 inconsistencias
```

---

# 10. NaN de Metrobús Simple

Simple contiene:

`17,227`

registros con el literal:

```text
NaN
```

No se interpreta como cero.

Distribución temporal observada:

| Línea | Último NaN | Primer valor numérico |
|---|---|---|
| Línea 1 | No presenta NaN | 2005-07-26 |
| Línea 2 | 2008-12-16 | 2008-12-17 |
| Línea 3 | 2011-02-08 | 2011-02-09 |
| Línea 4 | 2012-04-01 | 2012-04-02 |
| Línea 5 | 2013-11-05 | 2013-11-06 |
| Línea 6 | 2016-01-22 | 2016-01-23 |
| Línea 7 | 2018-05-01 | 2018-05-02 |

Interpretación operativa adoptada:

```text
NaN en RAW/STAGING
        ↓
NULL en TYPED/CLEAN
```

La representación original permanece disponible en STAGING.

CLEAN incorpora:

```text
es_afluencia_no_disponible
```

Conteos:

```text
NaN STAGING Simple             17,227
NULL TYPED Simple              17,227
NULL CLEAN Simple              17,227
bandera no disponible          17,227
```

Inconsistencias entre `NULL` y la bandera:

`0`

---

# 11. Afluencia y tipos físicos

El perfilado inicial contra `INTEGER` encontró 57 valores no
convertibles distintos de `NaN` en cada recurso.

La inspección posterior demostró que esos valores son números
decimales válidos.

Ejemplo de representación:

```text
105183.5494
```

Decisión:

```text
afluencia → NUMERIC
```

No utilizar `INTEGER` para Metrobús.

Valores con componente decimal conservados:

```text
Simple:       57
Desglosada:   57
```

No se redondean ni truncan.

---

# 12. TYPED

Tablas:

```text
proyecto.metrobus_simple_typed
proyecto.metrobus_desglosada_typed
```

Conversión principal:

```text
fecha      TEXT → DATE
anio       TEXT → SMALLINT
afluencia  TEXT → NUMERIC
```

En Simple:

```text
'NaN' → NULL
```

No se aplica homologación semántica de línea en TYPED.

Conteos:

| Fuente | STAGING | TYPED | Diferencia |
|---|---:|---:|---:|
| Simple | 54,159 | 54,159 | 0 |
| Desglosada | 29,386 | 29,386 | 0 |

---

# 13. Variantes de línea

El perfilado detectó tres representaciones textuales de las mismas
líneas lógicas:

```text
Linea N
Línea N
linea N
```

Las variantes corresponden a diferentes periodos de la fuente.

Se verificó que su homologación no genera colisiones.

CLEAN utiliza el dominio canónico:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
```

Número de líneas lógicas:

```text
Simple:       7
Desglosada:   7
```

---

# 14. Tipo de pago

El recurso Desglosado presenta:

| Tipo de pago | Registros |
|---|---:|
| Gratuidad | 14,693 |
| Prepago | 14,693 |

Total:

`29,386`

No se detectaron categorías adicionales.

---

# 15. CLEAN

Tablas:

```text
proyecto.metrobus_simple_clean
proyecto.metrobus_desglosada_clean
```

CLEAN incorpora:

- homologación de línea;
- `mes_num`;
- `dia_semana_num`;
- `dia_semana`;
- `es_fin_semana`;
- `es_afluencia_no_disponible`;
- `es_afluencia_cero`;
- `es_colision_clave`;
- `es_outlier_iqr_global`;
- `es_linea_homologada`.

No se eliminaron registros.

Conteos:

| Fuente | TYPED | CLEAN | Diferencia |
|---|---:|---:|---:|
| Simple | 54,159 | 54,159 | 0 |
| Desglosada | 29,386 | 29,386 | 0 |

---

# 16. Outliers

El perfilado final utiliza todos los valores `NUMERIC` disponibles,
incluidos los 57 valores decimales.

## Simple

```text
Valores numéricos: 36,932
Q1: 84,404.75
Q3: 206,966
Límite inferior: -99,437.125
Límite superior: 390,807.875
Outliers IQR: 3,000
```

## Desglosada

```text
Valores numéricos: 29,386
Q1: 10,865
Q3: 148,693.75
Límite inferior: -195,878.125
Límite superior: 355,436.875
Outliers IQR: 1,090
```

Los outliers se conservan.

No se elimina el valor Simple:

`3,032,667`

por su magnitud.

---

# 17. Relación Simple ↔ Desglosada

Periodo común:

```text
2021-01-01 → 2026-09-30
```

Fechas comunes:

`2,099`

Desglosada se agrega para la comparación mediante:

```text
fecha × linea
SUM(afluencia)
```

Resultado final utilizando `NUMERIC`:

```text
Claves comparables:       14,693
Coincidencias exactas:    14,693
Diferencias:                   0
Diferencia mínima:             0
Diferencia media:              0
Diferencia máxima:             0
```

Por tanto, en las claves comparables:

```text
Simple.afluencia
=
SUM(Desglosada.afluencia)
```

La compatibilidad de la medida queda validada para el periodo común.

Los recursos no deben concatenarse directamente porque mantienen
granularidades diferentes.

---

# 18. Validación final

Script:

`proyecto/sql/quality/metrobus/06_validacion_metrobus.sql`

Resultado:

**VALIDACIÓN METROBÚS OK**

Conteos finales:

| Capa | Simple | Desglosada |
|---|---:|---:|
| STAGING | 54,159 | 29,386 |
| TYPED | 54,159 | 29,386 |
| CLEAN | 54,159 | 29,386 |

Pérdida de registros:

`0`

Resumen CLEAN:

| Control | Simple | Desglosada |
|---|---:|---:|
| Registros | 54,159 | 29,386 |
| No disponibles | 17,227 | 0 |
| Colisiones | 0 | 0 |
| Outliers IQR | 3,000 | 1,090 |
| Líneas lógicas | 7 | 7 |
| Valores decimales | 57 | 57 |
| Duplicados exactos | 0 | 0 |

---

# 19. Diccionarios oficiales

El diccionario Simple utiliza `ano` mientras el CSV recibido utiliza
`anio`.

El diccionario Desglosado describe otra estructura, incluyendo campos
como:

```text
estacion
afluencia_prepago
afluencia_gratuidad
afluencia_total
```

que no corresponden directamente al encabezado del CSV descargado.

El diccionario Desglosado también contiene mojibake visible.

Decisión:

Los diccionarios se preservan como evidencia oficial, pero la
implementación del pipeline utiliza la estructura física realmente
recibida y validada.

---

# 20. Estado de la iteración

Completado:

- identificación de fuente;
- preservación RAW;
- SHA-256;
- inspección estructural;
- manifest;
- STAGING;
- ingestión reproducible;
- conciliación;
- perfilado;
- validación de granularidad;
- TYPED;
- CLEAN;
- validación integral;
- contrato de datos.

Estado del pipeline:

**PIPELINE METROBÚS VALIDADO**

El manifest conserva el estado:

`INSPECCIONADO_PENDIENTE_VALIDACION`

porque representa el estado técnico al momento en que fue generado.
No se modifica retrospectivamente.

La validación posterior queda registrada mediante:

- scripts SQL;
- `proyecto/docs/contrato_datos_metrobus.md`;
- este checkpoint.

---

# 21. Reglas vigentes

- No modificar RAW.
- No sobrescribir los RAW existentes.
- No convertir `NaN` a cero.
- No redondear valores decimales sin justificación.
- No eliminar outliers automáticamente.
- No crear duplicados artificiales mediante integración.
- Respetar las granularidades validadas.
- Mantener Simple y Desglosada como recursos diferenciados.
- Trabajar mediante ramas y Pull Requests.
- No declarar integrado en `main` hasta completar el Pull Request.

---

# 22. Punto exacto de continuación

Metrobús ya completó su pipeline individual.

El próximo bloque de trabajo es:

```text
CHECKPOINT DE COMPATIBILIDAD
Metro ↔ Metrobús
```

Antes de integrar ambos sistemas se deberán comparar, entre otros:

- granularidad analítica;
- cobertura temporal;
- concepto de afluencia;
- presencia o ausencia de estación;
- dimensiones compartidas;
- dominios de línea;
- campos específicos de cada sistema;
- nivel de detalle de `tipo_pago`;
- posibilidades de modelo dimensional común;
- reglas para una capa analítica multisistema.

No se debe diseñar todavía una unión física definitiva sin completar
ese análisis.

Tampoco se ha definido todavía el modelo final de minería de datos.

---

# 23. Respaldo

Los RAW permanecen excluidos de Git.

El repositorio permite recuperar:

- código;
- scripts SQL;
- metadatos;
- hashes;
- documentación;
- decisiones metodológicas.

No permite recuperar los bytes originales de los datasets RAW.

Se debe conservar una copia externa de dichos archivos y de sus
checksums porque la fuente oficial puede actualizar datos históricos.