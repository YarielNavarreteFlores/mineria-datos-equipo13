# Checkpoint individual — Trolebús

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Trolebús
**Iteración:** 5
**Estado:** VALIDADO
**Fecha del checkpoint:** 2026-11-22

---

## 2. Objetivo del checkpoint

Este documento consolida la evidencia técnica obtenida durante la Iteración 5 correspondiente a Trolebús.

El objetivo es determinar si el recurso seleccionado puede considerarse suficientemente comprendido, trazable y validado para pasar posteriormente al análisis formal de compatibilidad con el contrato multisistema vigente.

El checkpoint individual no representa todavía una integración física con Metro, Metrobús, RTP o Cablebús.

---

## 3. Fuente oficial

Fuente:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI)**

Recurso principal:

**Afluencia Diaria Trolebus (desglosado)**

Recurso documental:

**Diccionario de Datos**

---

## 4. Fuente física utilizada

Archivo RAW:

```text
proyecto/data/raw/trolebus/afluencia_desglosada_trolebus_10_2026.csv
```

Características:

```text
Registros:            65,013
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
4775b452dc7fa5376581b5dfe4cc9fe3f344552ae48a1dee802cb6124ab81ff4
```

---

## 5. Diccionario oficial

Archivo preservado:

```text
proyecto/data/metadata/trolebus/diccionario_trolebus_original.csv
```

Características:

```text
Registros:             8
Columnas:              9
Encoding:         CP1252
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

La copia preservada fue comprobada byte a byte contra el archivo original.

El diccionario pertenece conceptualmente al conjunto:

```text
Afluencia diaria Servicio de Transportes Eléctricos
```

y no exclusivamente a Trolebús.

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

mientras que el recurso físico utilizado presenta:

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
estructura física actual del recurso Trolebús
```

La implementación del pipeline se construyó sobre la estructura física observada y documentó explícitamente esta diferencia.

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
PIPELINE INDIVIDUAL TROLEBÚS: VALIDADO
```

---

## 7. Conciliación entre capas

Resultados:

```text
STAGING:   65,013
TYPED:     65,013
CLEAN:     65,013
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

No hubo pérdida ni generación artificial de registros durante el pipeline.

---

## 8. Cobertura temporal

Cobertura validada:

```text
2022-01-01 → 2026-10-31
```

Fechas distintas:

```text
1,765
```

Años presentes:

```text
2022 → 2026
```

Controles:

```text
Fechas inválidas:              0
Años inválidos:                0
Meses no reconocidos:          0
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
Registros:                   65,013
Claves distintas:            65,013
Grupos con colisión:              0
Filas involucradas:               0
Registros excedentes:             0
Máximo de repeticiones:           1
```

No existe evidencia de colisiones en la granularidad individual validada.

---

## 10. Estructura fecha × linea

Claves distintas:

```text
21,671
```

Cada clave contiene exactamente:

```text
3 filas
3 tipos_pago
```

Por tanto:

```text
21,671 × 3 = 65,013
```

Los tipos de pago presentes son:

```text
Boleto
Gratuidad
Prepago
```

Esta estructura fue validada sobre la totalidad del recurso.

---

## 11. Tipo de pago

Distribución:

```text
Boleto        21,671
Gratuidad     21,671
Prepago       21,671
```

Tipos distintos:

```text
3
```

Registros fuera del dominio:

```text
0
```

---

## 12. Representaciones originales de linea

Se detectaron:

```text
43 representaciones originales
```

Las diferencias corresponden principalmente a:

```text
acentos
mayúsculas / minúsculas
guiones bajos
espacios
variaciones históricas de escritura
```

Ejemplos observados incluyen representaciones como:

```text
Línea 1
Linea 1
linea_1
```

Además existen categorías con semántica propia, entre ellas:

```text
Línea 1 Nochebús
Línea 10 (Trolebús elevado)
```

Estas categorías no fueron reducidas a:

```text
Línea 1
Línea 10
```

porque representan denominaciones diferenciadas en la fuente.

---

## 13. Evaluación previa de homologación

Antes de modificar las representaciones se aplicó una normalización exclusivamente gráfica mediante:

```text
minúsculas
eliminación de acentos
"_" → espacio
reducción de espacios repetidos
```

Resultado:

```text
Representaciones originales:   43
Representaciones gráficas:     17
```

Se verificó la clave:

```text
fecha × linea_normalizada × tipo_pago
```

Resultados:

```text
Claves normalizadas:          65,013
Grupos con colisión:               0
Filas involucradas:                0
Registros excedentes:              0
Máximo de repeticiones:            1
```

Por tanto, la homologación gráfica fue considerada segura.

---

## 14. Homologación CLEAN

La capa CLEAN conserva:

```text
linea_original
```

y genera:

```text
linea
```

como representación canónica.

El dominio resultante contiene:

```text
17 líneas lógicas
```

Categorías:

```text
Linea 0
Linea 1
Linea 1 Nochebus
Linea 2
Linea 3
Linea 4
Linea 5
Linea 6
Linea 7
Linea 8
Linea 9
Linea 10
Linea 10 (Trolebus elevado)
Linea 11
Linea 12
Linea 13
Linea 14
```

Filas homologadas:

```text
62,268
```

Filas cuya representación ya coincidía con el valor canónico:

```text
2,745
```

Total:

```text
65,013
```

No se generaron colisiones durante esta transformación.

---

## 15. Líneas lógicas CLEAN

Cobertura por unidad:

```text
Linea 0
153 días
2026-06-01 → 2026-10-31

Linea 1
1,765 días
2022-01-01 → 2026-10-31

Linea 1 Nochebus
1,765 días
2022-01-01 → 2026-10-31

Linea 2
1,765 días
2022-01-01 → 2026-10-31

Linea 3
1,765 días
2022-01-01 → 2026-10-31

Linea 4
1,765 días
2022-01-01 → 2026-10-31

Linea 5
1,765 días
2022-01-01 → 2026-10-31

Linea 6
1,765 días
2022-01-01 → 2026-10-31

Linea 7
1,765 días
2022-01-01 → 2026-10-31

Linea 8
1,765 días
2022-01-01 → 2026-10-31

Linea 9
1,765 días
2022-01-01 → 2026-10-31

Linea 10
975 días
2024-03-01 → 2026-10-31

Linea 10 (Trolebus elevado)
790 días
2022-01-01 → 2024-02-29

Linea 11
549 días
2025-05-01 → 2026-10-31

Linea 12
883 días
2024-06-01 → 2026-10-31

Linea 13
518 días
2025-06-01 → 2026-10-31

Linea 14
153 días
2026-06-01 → 2026-10-31
```

Las diferencias de cobertura se preservan como características reales del recurso.

No se imputaron observaciones faltantes para uniformar artificialmente las líneas.

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
afluencia   NUMERIC(19,13)
```

La selección de:

```text
NUMERIC(19,13)
```

se encuentra respaldada por el perfilado:

```text
Valores NUMERIC válidos:       65,013
Valores convertibles BIGINT:   63,594
Valores decimales:              1,419

Máximo dígitos enteros:             6
Máxima escala:                     13
```

Por tanto:

```text
6 dígitos enteros
+
13 dígitos decimales
=
19 dígitos de precisión
```

No se aplicó redondeo durante el tipado.

---

## 17. Calidad de afluencia

Resultados:

```text
Valores:          65,013
NULL:                  0
NaN:                   0
Vacíos:                0
No numéricos:          0
Negativos:             0

Ceros:            20,246
Decimales:         1,419
```

Rango observado:

```text
Mínimo:                 0
Máximo:       160619.3667...
```

Estadísticos descriptivos:

```text
Q1:                 0
Mediana:         2,781
Media:       7,600.24111...
Q3:             7,568
```

Los ceros y los valores decimales fueron preservados.

Regla:

```text
NULL ≠ 0
```

---

## 18. Valores decimales

Registros con componente decimal:

```text
1,419
```

Los valores decimales se concentran en:

```text
2026
```

Distribución por tipo de pago:

```text
Boleto:          0
Gratuidad:   1,148
Prepago:       271
```

La escala observada alcanza un máximo de:

```text
13 dígitos decimales
```

Conciliación:

```text
STAGING: 1,419
TYPED:   1,419
CLEAN:   1,419
```

No se redondeó ninguna observación.

---

## 19. Ceros

Ceros totales:

```text
20,246
```

Distribución por tipo de pago:

```text
Boleto:       15,519
Gratuidad:     2,907
Prepago:       1,820
```

Distribución por año:

```text
2022: 2,482
2023: 2,004
2024: 4,944
2025: 5,533
2026: 5,283
```

Los ceros fueron preservados durante todo el pipeline.

Conciliación:

```text
TYPED: 20,246
CLEAN: 20,246
```

No se interpretaron automáticamente como datos faltantes.

---

## 20. Duplicados exactos

Resultado:

```text
Grupos duplicados exactos:  0
Filas involucradas:         0
Registros excedentes:       0
```

No fue necesario eliminar ni resolver duplicados.

---

## 21. Colisiones

En la granularidad original:

```text
fecha × linea × tipo_pago
```

se detectaron:

```text
0
```

colisiones.

Después de la homologación gráfica:

```text
0
```

colisiones.

Por tanto, la normalización de `linea` no introdujo pérdida de unicidad.

---

## 22. Outliers

Método diagnóstico:

```text
IQR global
```

Resultados:

```text
Q1:                    0
Q3:                7,568
IQR:               7,568
Límite inferior: -11,352
Límite superior:  18,920
```

Posibles outliers:

```text
6,345
```

Los outliers no fueron eliminados ni modificados.

La bandera:

```text
es_outlier_iqr_global
```

se utiliza exclusivamente con fines analíticos y de trazabilidad de calidad.

Un valor extremo no fue considerado automáticamente un error.

---

## 23. Banderas de calidad CLEAN

Resultados:

```text
es_afluencia_no_disponible = TRUE:        0
es_afluencia_cero = TRUE:            20,246
es_afluencia_decimal = TRUE:          1,419

es_colision_clave_origen = TRUE:           0
es_colision_clave = TRUE:                  0

es_duplicado_exacto = TRUE:                0
es_outlier_iqr_global = TRUE:          6,345

es_linea_homologada = TRUE:           62,268
```

---

## 24. Coherencia temporal CLEAN

Resultados:

```text
error_anio:          0
error_mes:           0
error_dia_semana:    0
```

Las variables temporales derivadas son coherentes con `fecha`.

---

## 25. Validación integral final

La validación automática terminó sin excepciones.

Resultado:

```text
VALIDACION TROLEBUS OK
```

Controles finales:

```text
Filas:                   65,013
NULL:                         0
Ceros:                   20,246
Decimales:                1,419
Negativos:                    0

Líneas:                      17
Tipos de pago:                3

Colisiones:                   0
Duplicados:                   0

Outliers:                 6,345
Filas homologadas:       62,268

Fechas:                   1,765
Claves fecha-linea:      21,671

Diferencias afluencia:        0
```

Por tanto, las capas:

```text
STAGING
TYPED
CLEAN
```

se consideran reconciliadas.

---

# 26. CONTRATO INDIVIDUAL

La unidad observacional detallada de Trolebús queda establecida como:

```text
fecha × linea × tipo_pago
```

La medida de demanda es:

```text
afluencia
```

y utiliza físicamente:

```text
NUMERIC(19,13)
```

Cada clave:

```text
fecha × linea
```

contiene exactamente:

```text
3 tipos_pago
```

correspondientes a:

```text
Boleto
Gratuidad
Prepago
```

---

# 27. COMPATIBILIDAD PRELIMINAR CON EL CONTRATO MULTISISTEMA

El contrato multisistema actualmente vigente utiliza:

```text
fecha × sistema × unidad_operativa
```

Los mapeos ya evaluados son:

```text
Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio

Cablebús:
unidad_operativa = linea
```

La hipótesis candidata para Trolebús es:

```text
sistema = Trolebús
unidad_operativa = linea
```

Por tanto, conceptualmente Trolebús podría representarse mediante:

```text
fecha × sistema × unidad_operativa
```

después de agregar los componentes de `tipo_pago`.

Esta hipótesis todavía debe evaluarse formalmente mediante el checkpoint de compatibilidad multisistema.

---

## 28. Agregación candidata para compatibilidad

La granularidad individual de Trolebús es:

```text
fecha × linea × tipo_pago
```

Para obtener la abstracción multisistema candidata se requiere conceptualmente:

```text
GROUP BY fecha, linea
SUM(afluencia)
```

produciendo:

```text
fecha × sistema × unidad_operativa
```

donde:

```text
sistema = Trolebús
unidad_operativa = linea
```

La agregación únicamente deberá considerarse segura cuando para una clave:

```text
fecha × linea
```

se verifique:

```text
3 filas
3 tipos_pago
0 NULL
0 colisiones
```

Esta condición fue demostrada individualmente en el recurso completo, pero deberá volver a comprobarse dentro de la ventana temporal común multisistema.

---

## 29. Medida multisistema

Trolebús utiliza:

```text
NUMERIC(19,13)
```

Por tanto, el tipo común para una futura medida multisistema deberá admitir:

```text
NUMERIC
```

Esto permite incorporar sin pérdida sistemas cuyas medidas originales utilicen:

```text
INTEGER
BIGINT
NUMERIC
```

No deberá imponerse:

```text
BIGINT
```

como tipo común porque Trolebús contiene:

```text
1,419 valores con componente decimal
```

y dicha conversión produciría pérdida de información.

---

## 30. Restricciones

El checkpoint individual NO autoriza todavía:

```text
integración física multisistema
tabla de hechos definitiva
modelo dimensional definitivo
dataset processed multisistema definitivo
cubo OLAP definitivo
```

Tampoco implica que:

```text
linea
```

de Trolebús sea operacionalmente idéntica a:

```text
linea
```

de Metro, Metrobús o Cablebús, ni a:

```text
servicio
```

de RTP.

`unidad_operativa` continúa siendo una abstracción analítica para permitir una comparación multisistema controlada.

No deben modificarse los sistemas previamente validados para adaptar sus estructuras a Trolebús.

---

# 31. DECISIONES DEL CHECKPOINT

1. La fuente oficial fue identificada y preservada.
2. RAW permanece inmutable.
3. SHA-256 y manifest están disponibles.
4. El recurso contiene 65,013 observaciones.
5. No existe pérdida STAGING → TYPED → CLEAN.
6. La cobertura validada es 2022-01-01 → 2026-10-31.
7. Existen 1,765 fechas distintas.
8. La granularidad individual es `fecha × linea × tipo_pago`.
9. Existen 21,671 claves `fecha × linea`.
10. Cada clave contiene exactamente 3 tipos de pago.
11. Los tipos son `Boleto`, `Gratuidad` y `Prepago`.
12. Existen 43 representaciones originales de `linea`.
13. La normalización gráfica genera 17 líneas lógicas.
14. La homologación gráfica fue demostrada como segura.
15. `linea_original` conserva trazabilidad.
16. Se homologaron 62,268 filas.
17. `afluencia` es completamente convertible a `NUMERIC`.
18. Existen 1,419 valores con componente decimal.
19. `afluencia` utiliza `NUMERIC(19,13)`.
20. Los valores decimales se preservan sin redondeo.
21. Existen 20,246 ceros.
22. Los ceros permanecen preservados.
23. No existen NULL de afluencia.
24. No existen valores negativos.
25. No existen duplicados exactos.
26. No existen colisiones.
27. Existen 6,345 posibles outliers IQR.
28. Los posibles outliers únicamente se marcan y no se eliminan.
29. No se eliminó ninguna observación.
30. `unidad_operativa = linea` es una hipótesis de compatibilidad suficientemente sustentada para evaluarse en el siguiente checkpoint.
31. La futura medida multisistema debe admitir `NUMERIC`.
32. No se construye todavía integración física multisistema.
33. No se modifica Metro, Metrobús, RTP ni Cablebús para adaptar Trolebús.

---

# 32. ESTADO

```text
PIPELINE INDIVIDUAL TROLEBÚS: VALIDADO
```

```text
CHECKPOINT INDIVIDUAL TROLEBÚS: APROBADO
```

Siguiente etapa:

```text
COMPATIBILIDAD TROLEBÚS
CON CONTRATO MULTISISTEMA V