# Checkpoint individual — Cablebús

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Cablebús
**Iteración:** 4
**Estado:** VALIDADO
**Fecha del checkpoint:** 2026-11-12

---

## 2. Objetivo del checkpoint

Este documento consolida la evidencia técnica obtenida durante la Iteración 4 correspondiente a Cablebús.

El objetivo es determinar si el recurso seleccionado puede considerarse suficientemente comprendido, trazable y validado para pasar posteriormente al análisis de compatibilidad con el contrato multisistema preliminar.

El checkpoint individual no representa todavía una integración física con Metro, Metrobús o RTP.

---

## 3. Fuente oficial

Fuente:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI)**

Recurso principal:

**Afluencia Diaria Cablebus (Desglosada)**

Recurso documental:

**Diccionario de Datos**

---

## 4. Fuente física utilizada

Archivo RAW:

```text
proyecto/data/raw/cablebus/afluencia_desglosada_cb_09_2026.csv
```

Características:

```text
Registros:             7,972
Columnas:                  6
Filas malformadas:         0
Encoding:          UTF-8-SIG
Delimitador:               ,
```

Columnas:

```text
fecha
mes
anio
linea
tipo_pago
afluencia
```

SHA-256:

```text
d5761d27f0d12198f434d569713b34cec5ffa61c84f28fe66a294b536a67624c
```

---

## 5. Diccionario oficial

Archivo preservado:

```text
proyecto/data/metadata/cablebus/diccionario_cablebus_original.csv
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

El diccionario oficial pertenece conceptualmente al conjunto:

```text
Afluencia diaria Servicio de Transportes Eléctricos
```

y no exclusivamente a Cablebús.

El diccionario describe:

```text
fecha
ano
mes
linea
afluencia_boleto
afluencia_prepago
afluencia_gratuidad
afluencia_total
```

mientras que el CSV físico de Cablebús utiliza:

```text
fecha
mes
anio
linea
tipo_pago
afluencia
```

Por tanto:

```text
diccionario conceptual STE
≠
estructura física actual del recurso Cablebús
```

La implementación del pipeline se basó en la estructura física observada y documentó explícitamente esta diferencia.

---

# 6. PIPELINE INDIVIDUAL

Pipeline aplicado:

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

Estado:

```text
PIPELINE INDIVIDUAL CABLEBÚS: VALIDADO
```

---

## 7. Conciliación entre capas

Resultados:

```text
STAGING:    7,972
TYPED:      7,972
CLEAN:      7,972
```

Diferencia:

```text
0
```

Por tanto:

```text
STAGING = TYPED = CLEAN
```

en número de observaciones.

No hubo pérdida de registros durante el pipeline.

---

## 8. Cobertura temporal

Cobertura validada:

```text
2022-01-01 → 2026-09-30
```

Fechas distintas:

```text
1,734
```

Años presentes:

```text
2022 → 2026
```

Controles:

```text
Fechas inválidas:              0
Inconsistencias fecha ↔ año:   0
Inconsistencias fecha ↔ mes:   0
```

---

## 9. Granularidad individual

Granularidad validada:

```text
fecha × linea × tipo_pago
```

Resultados:

```text
Registros:                    7,972
Claves distintas:             7,972
Grupos con colisión:              0
Filas involucradas:               0
Registros excedentes:             0
```

No existe evidencia de colisiones en la granularidad individual validada.

---

## 10. Estructura fecha × linea

Claves:

```text
3,986
```

Cada clave contiene:

```text
2 filas
2 tipos_pago
```

Por tanto:

```text
3,986 × 2 = 7,972
```

Los tipos de pago son:

```text
Gratuidad
Prepago
```

---

## 11. Tipo de pago

Distribución:

```text
Gratuidad    3,986
Prepago      3,986
```

Tipos distintos:

```text
2
```

Fuera del dominio:

```text
0
```

---

## 12. Representaciones originales de linea

Se detectaron cinco representaciones:

```text
Línea 1
Línea 2
Linea 1
Linea 2
Linea 3
```

Cobertura:

```text
Línea 1
2022-01-01 → 2025-04-30

Línea 2
2022-01-01 → 2025-04-30

Linea 1
2025-05-01 → 2026-09-30

Linea 2
2025-05-01 → 2026-09-30

Linea 3
2025-05-01 → 2026-09-30
```

La diferencia entre `Línea` y `Linea` fue comprobada también a nivel de bytes.

---

## 13. Evaluación previa de homologación

Antes de modificar las representaciones se evaluó:

```text
fecha × linea_lógica × tipo_pago
```

Resultado:

```text
Claves con colisión:       0
Filas involucradas:        0
Registros excedentes:      0
Máximo de repeticiones:    0
```

Por tanto, la homologación fue considerada segura.

---

## 14. Homologación CLEAN

Reglas aplicadas:

```text
Línea 1 → Linea 1
Linea 1 → Linea 1

Línea 2 → Linea 2
Linea 2 → Linea 2

Linea 3 → Linea 3
```

CLEAN conserva:

```text
linea_original
```

para asegurar trazabilidad.

Filas homologadas:

```text
4,864
```

Filas cuya representación permaneció igual:

```text
3,108
```

Total:

```text
7,972
```

---

## 15. Líneas lógicas CLEAN

Dominio final:

```text
Linea 1
Linea 2
Linea 3
```

Distribución:

```text
Linea 1: 3,468 registros
Linea 2: 3,468 registros
Linea 3: 1,036 registros
```

Cobertura:

```text
Linea 1
1,734 días
2022-01-01 → 2026-09-30

Linea 2
1,734 días
2022-01-01 → 2026-09-30

Linea 3
518 días
2025-05-01 → 2026-09-30
```

---

## 16. Tipado

### STAGING

```text
fecha       TEXT
mes         TEXT
anio        TEXT
linea       TEXT
tipo_pago   TEXT
afluencia   TEXT
```

### TYPED

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
linea       TEXT
tipo_pago   TEXT
afluencia   BIGINT
```

La elección de `BIGINT` para `afluencia` está respaldada por:

```text
7,972 valores numéricos
7,972 valores enteros
0 valores decimales
0 NaN
0 valores no numéricos
```

---

## 17. Calidad de afluencia

Resultados:

```text
Valores:       7,972
NULL:              0
NaN:               0
Vacíos:            0
No numéricos:      0
Negativos:         0
Decimales:         0
Ceros:           207
```

Rango:

```text
Mínimo:       0
Máximo:  80,727
```

Los ceros fueron preservados.

Regla:

```text
NULL ≠ 0
```

---

## 18. Ceros

Ceros totales:

```text
207
```

Distribución:

```text
Gratuidad: 137
Prepago:    70
```

Conciliación:

```text
STAGING: 207
TYPED:   207
CLEAN:   207
```

No se eliminaron ni reemplazaron.

---

## 19. Duplicados exactos

Resultado:

```text
Grupos duplicados exactos:  0
Filas involucradas:         0
Registros excedentes:       0
```

---

## 20. Colisiones

Antes de homologación:

```text
0
```

Después de homologación:

```text
0
```

La normalización de `linea` no introdujo pérdida de unicidad.

---

## 21. Outliers

Método diagnóstico:

```text
IQR global
```

Resultados:

```text
Q1:                6,163.75
Q3:               50,634.25
Límite inferior: -60,542
Límite superior: 117,340
Máximo observado: 80,727
```

Posibles outliers:

```text
0
```

No se eliminaron observaciones por magnitud.

---

## 22. Banderas de calidad CLEAN

Resultados:

```text
es_afluencia_no_disponible = TRUE:     0
es_afluencia_cero = TRUE:            207

es_colision_clave_origen = TRUE:       0
es_colision_clave = TRUE:              0

es_duplicado_exacto = TRUE:            0
es_outlier_iqr_global = TRUE:           0

es_linea_homologada = TRUE:         4,864
```

---

## 23. Coherencia temporal CLEAN

Resultados:

```text
error_anio:          0
error_mes:           0
error_dia_semana:    0
```

Las variables temporales derivadas son coherentes con `fecha`.

---

## 24. Validación integral final

La validación automática terminó sin excepciones.

Resultado:

```text
VALIDACIÓN CABLEBUS OK
```

Controles finales:

```text
Filas:                7,972
NULL:                      0
Ceros:                   207
Líneas:                    3
Tipos de pago:             2
Colisiones:                0
Duplicados:                0
Outliers:                  0
Filas homologadas:     4,864
Fechas:                1,734
Claves fecha-linea:    3,986
```

---

# 25. CONTRATO INDIVIDUAL

La unidad observacional detallada de Cablebús queda establecida como:

```text
fecha × linea × tipo_pago
```

La medida de demanda es:

```text
afluencia
```

y utiliza físicamente:

```text
BIGINT
```

---

# 26. COMPATIBILIDAD PRELIMINAR CON EL CONTRATO MULTISISTEMA

El contrato multisistema vigente después de RTP utiliza:

```text
fecha × sistema × unidad_operativa
```

Mapeo candidato de Cablebús:

```text
sistema = Cablebús
unidad_operativa = linea
```

Por tanto:

```text
fecha × sistema × unidad_operativa
```

puede representar conceptualmente Cablebús al agregar sobre `tipo_pago`.

Sin embargo, esta conclusión todavía debe validarse mediante un checkpoint multisistema específico.

---

## 27. Agregación candidata para compatibilidad

La granularidad individual es:

```text
fecha × linea × tipo_pago
```

Para obtener la abstracción multisistema candidata se requeriría:

```text
GROUP BY fecha, linea
SUM(afluencia)
```

produciendo conceptualmente:

```text
fecha × sistema × unidad_operativa
```

con:

```text
sistema = Cablebús
unidad_operativa = linea
```

Esta agregación todavía no se materializa como dataset definitivo.

---

## 28. Medida multisistema

Cablebús utiliza:

```text
BIGINT
```

Otros sistemas previamente validados pueden utilizar valores decimales.

Por tanto, una futura medida común debe admitir:

```text
NUMERIC
```

La promoción:

```text
BIGINT → NUMERIC
```

es segura para Cablebús.

---

## 29. Restricciones

El checkpoint individual NO autoriza todavía:

```text
integración física multisistema
tabla de hechos definitiva
modelo dimensional definitivo
dataset processed multisistema definitivo
```

Tampoco implica que:

```text
linea
```

de Cablebús sea operacionalmente idéntica a:

```text
linea
```

de Metro o Metrobús ni a:

```text
servicio
```

de RTP.

`unidad_operativa` continúa siendo una abstracción analítica.

---

# 30. DECISIONES DEL CHECKPOINT

1. La fuente oficial fue identificada y preservada.
2. RAW permanece inmutable.
3. SHA-256 y manifest están disponibles.
4. El recurso contiene 7,972 observaciones válidas.
5. No existe pérdida STAGING → TYPED → CLEAN.
6. La cobertura validada es 2022-01-01 → 2026-09-30.
7. La granularidad individual es `fecha × linea × tipo_pago`.
8. Existen 3,986 claves `fecha × linea`.
9. Cada clave contiene exactamente 2 tipos de pago.
10. Existen tres líneas lógicas.
11. La homologación `Línea → Linea` fue demostrada como segura.
12. `linea_original` conserva trazabilidad.
13. Los 207 ceros permanecen preservados.
14. No existen NULL de afluencia.
15. No existen valores negativos.
16. No existen valores decimales.
17. No existen duplicados exactos.
18. No existen colisiones.
19. No existen outliers IQR globales.
20. `unidad_operativa = linea` es una hipótesis de compatibilidad suficientemente sustentada para ser evaluada en el siguiente checkpoint.
21. No se construye todavía integración física multisistema.
22. No se modifica Metro, Metrobús ni RTP para adaptar Cablebús.

---

# 31. ESTADO

```text
PIPELINE INDIVIDUAL CABLEBÚS: VALIDADO
```

```text
CHECKPOINT INDIVIDUAL CABLEBÚS: APROBADO
```

Siguiente etapa:

```text
COMPATIBILIDAD CABLEBÚS
CON CONTRATO MULTISISTEMA PRELIMINAR
```