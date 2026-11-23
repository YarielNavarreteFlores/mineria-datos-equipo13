# Contrato de Datos — Trolebús

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Trolebús
**Iteración:** 5
**Estado del pipeline individual:** VALIDADO

---

## 2. Fuente oficial

La fuente utilizada corresponde al:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI)**

Recurso utilizado:

**Afluencia Diaria Trolebus (desglosado)**

Recurso documental:

**Diccionario de Datos**

El recurso utilizado contiene información diaria de afluencia de Trolebús desde el 1 de enero de 2022.

El conjunto del Servicio de Transportes Eléctricos agrupa recursos correspondientes a:

- Cablebús;
- Tren Ligero;
- Trolebús.

Para esta iteración se incorporaron exclusivamente el recurso de Trolebús y el diccionario oficial asociado al conjunto.

---

## 3. Archivos fuente

### 3.1 Afluencia

Archivo RAW:

```text
proyecto/data/raw/trolebus/afluencia_desglosada_trolebus_10_2026.csv
```

Características verificadas:

```text
Filas de datos:      65,013
Columnas:                 6
Filas malformadas:        0
Encoding:         UTF-8-SIG
Delimitador:              ,
```

SHA-256:

```text
4775b452dc7fa5376581b5dfe4cc9fe3f344552ae48a1dee802cb6124ab81ff4
```

---

### 3.2 Diccionario

Archivo preservado:

```text
proyecto/data/metadata/trolebus/diccionario_trolebus_original.csv
```

Características verificadas:

```text
Filas de datos:        8
Columnas:              9
Filas malformadas:     0
Encoding:         CP1252
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

La copia preservada en `metadata/` fue comprobada byte a byte contra el archivo RAW.

---

## 4. Estructura física de la fuente

El archivo de afluencia contiene las columnas:

```text
fecha
mes
anio
linea
tipo_pago
afluencia
```

La estructura física del CSV fue tomada como autoridad operacional para el pipeline.

El diccionario oficial describe conceptualmente:

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

Por tanto:

```text
diccionario conceptual STE
≠
estructura física actual del CSV Trolebús
```

El diccionario representa conceptualmente las medidas de afluencia mediante columnas separadas, mientras que el recurso físico desglosado utiliza una representación larga mediante:

```text
tipo_pago
afluencia
```

El pipeline no modifica artificialmente el CSV para ajustarlo a la representación conceptual del diccionario.

---

## 5. Cobertura temporal validada

Cobertura física:

```text
Fecha mínima:      2022-01-01
Fecha máxima:      2026-10-31
Fechas distintas:       1,765
```

Años presentes:

```text
2022
2023
2024
2025
2026
```

Controles:

```text
Fechas inválidas:             0
Años inválidos:               0
Meses no reconocidos:         0
Inconsistencias fecha ↔ año:  0
Inconsistencias fecha ↔ mes:  0
```

---

## 6. Granularidad individual

La granularidad individual validada de Trolebús es:

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

Por tanto:

```text
fecha × linea × tipo_pago
```

identifica de manera única cada observación del recurso analizado.

No se impuso físicamente una restricción `UNIQUE` durante esta iteración.

---

## 7. Estructura fecha × linea

Existen exactamente:

```text
21,671
```

claves distintas:

```text
fecha × linea
```

Cada una contiene:

```text
3 filas
3 tipos de pago
```

Por tanto:

```text
21,671 claves fecha × linea
×
3 tipos_pago
=
65,013 observaciones
```

La estructura es consistente en todo el recurso validado.

---

## 8. Dominio de tipo_pago

Dominio observado:

| tipo_pago | Registros |
|---|---:|
| Boleto | 21,671 |
| Gratuidad | 21,671 |
| Prepago | 21,671 |

Total:

```text
65,013
```

Tipos distintos:

```text
3
```

Categorías fuera del dominio:

```text
0
```

---

## 9. Representaciones originales de linea

En STAGING y TYPED se preservaron:

```text
43 representaciones originales
```

Estas representaciones incluyen diferencias asociadas a:

- acentos;
- mayúsculas y minúsculas;
- uso de guion bajo;
- espacios;
- cambios históricos de representación textual.

También existen categorías con significado propio, entre ellas:

```text
Línea 1 Nochebús
Línea 10 (Trolebús elevado)
```

Estas categorías no fueron fusionadas con:

```text
Línea 1
Línea 10
```

respectivamente.

La auditoría de caracteres y bytes permitió comprobar que las diferencias físicas de representación existían realmente en la fuente.

---

## 10. Normalización gráfica exploratoria

Se evaluó una normalización exclusivamente gráfica mediante:

```text
minúsculas
eliminación de acentos
"_" → espacio
reducción de espacios repetidos
```

Resultado:

```text
Representaciones originales: 43
Representaciones gráficas:   17
```

La prueba se realizó sobre:

```text
fecha × linea_normalizada × tipo_pago
```

Resultados:

```text
Claves normalizadas:         65,013
Grupos con colisión:              0
Filas involucradas:               0
Registros excedentes:             0
Máximo de repeticiones:           1
```

Por tanto, la normalización gráfica propuesta no altera la unicidad del recurso.

---

## 11. Homologación CLEAN de linea

La capa CLEAN reduce las 43 representaciones originales a 17 categorías canónicas:

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

La homologación únicamente corrige diferencias gráficas demostradas.

No se eliminan conceptos semánticos como:

```text
Nochebus
Trolebus elevado
```

CLEAN conserva:

```text
linea_original
```

junto con:

```text
linea
```

para mantener trazabilidad completa.

Filas cuya representación fue homologada:

```text
62,268
```

Filas cuya representación ya coincidía con la forma canónica:

```text
2,745
```

Total:

```text
65,013
```

---

## 12. Dominio lógico CLEAN

Después de la homologación existen exactamente:

```text
17 líneas lógicas
```

Cobertura observada:

| linea | Días con registro | Fecha mínima | Fecha máxima |
|---|---:|---|---|
| Linea 0 | 153 | 2026-06-01 | 2026-10-31 |
| Linea 1 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 1 Nochebus | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 2 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 3 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 4 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 5 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 6 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 7 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 8 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 9 | 1,765 | 2022-01-01 | 2026-10-31 |
| Linea 10 | 975 | 2024-03-01 | 2026-10-31 |
| Linea 10 (Trolebus elevado) | 790 | 2022-01-01 | 2024-02-29 |
| Linea 11 | 549 | 2025-05-01 | 2026-10-31 |
| Linea 12 | 883 | 2024-06-01 | 2026-10-31 |
| Linea 13 | 518 | 2025-06-01 | 2026-10-31 |
| Linea 14 | 153 | 2026-06-01 | 2026-10-31 |

La diferencia de cobertura entre líneas se conserva como característica de la fuente.

No se imputaron fechas ni observaciones inexistentes.

---

## 13. Tipos de datos por capa

### STAGING

```text
fecha       TEXT
mes         TEXT
anio        TEXT
linea       TEXT
tipo_pago   TEXT
afluencia   TEXT
```

STAGING conserva la representación textual de la fuente.

---

### TYPED

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
linea       TEXT
tipo_pago   TEXT
afluencia   NUMERIC(19,13)
```

La elección de:

```text
NUMERIC(19,13)
```

está respaldada por el perfilado:

```text
65,013 valores NUMERIC válidos
63,594 valores convertibles a BIGINT
1,419 valores con componente decimal

máximo de dígitos enteros: 6
máxima escala observada:   13
```

Por tanto:

```text
6 + 13 = 19
```

y se utiliza:

```text
NUMERIC(19,13)
```

para evitar pérdida de precisión.

---

### CLEAN

CLEAN conserva los tipos físicos de TYPED y agrega:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana

linea_original
linea

es_afluencia_no_disponible
es_afluencia_cero
es_afluencia_decimal

es_colision_clave_origen
es_colision_clave

es_duplicado_exacto
es_outlier_iqr_global
es_linea_homologada
```

---

## 14. Afluencia

Resultados validados:

```text
Valores:          65,013
NULL:                  0
NaN:                   0
Vacíos:                0
No numéricos:          0
Negativos:             0

Ceros:            20,246
Decimales:         1,419

Mínimo:                0
Máximo:      160619.3667...
Mediana:           2,781
Media:        7,600.24111...
Q1:                    0
Q3:                7,568
```

Los valores decimales se consideran observaciones válidas y se preservan sin redondeo.

Los ceros también se preservan.

Regla:

```text
0 ≠ NULL
```

---

## 15. Valores decimales

Valores con componente decimal:

```text
1,419
```

Los 1,419 registros se concentran en:

```text
2026
```

Distribución por tipo de pago:

```text
Gratuidad: 1,148
Prepago:      271
Boleto:         0
```

Se observaron escalas entre:

```text
3 y 13 dígitos decimales
```

con máximo:

```text
13
```

No se redondeó ningún valor.

Conciliación:

```text
STAGING: 1,419
TYPED:   1,419
CLEAN:   1,419
```

---

## 16. Ceros

Ceros totales:

```text
20,246
```

Distribución por tipo de pago:

```text
Boleto:     15,519
Gratuidad:   2,907
Prepago:     1,820
```

Distribución por año:

```text
2022: 2,482
2023: 2,004
2024: 4,944
2025: 5,533
2026: 5,283
```

Los ceros se consideran valores válidos de la fuente.

Conciliación:

```text
TYPED: 20,246
CLEAN: 20,246
```

No se sustituyen por `NULL`.

---

## 17. Duplicados

Duplicados exactos detectados:

```text
Grupos:               0
Filas involucradas:   0
Registros excedentes: 0
```

No fue necesario eliminar ni resolver duplicados.

---

## 18. Colisiones

En la granularidad original:

```text
fecha × linea × tipo_pago
```

se detectaron:

```text
0 grupos con colisión
```

Después de homologar gráficamente las representaciones de línea:

```text
0 grupos con colisión
```

Por tanto, la homologación CLEAN no produjo pérdida de unicidad.

---

## 19. Outliers

Se utilizó el criterio IQR global exclusivamente como diagnóstico.

Resultados:

```text
Q1:                0
Q3:            7,568
IQR:           7,568

Límite inferior:
-11,352

Límite superior:
18,920
```

Posibles outliers IQR:

```text
6,345
```

Máximo observado:

```text
160619.3667...
```

Una observación fuera de los límites IQR no implica por sí misma un error.

Por tanto:

```text
es_outlier_iqr_global = TRUE
```

es únicamente una bandera analítica.

No se eliminó ninguna observación por magnitud.

---

## 20. Reglas de transformación

### RAW → STAGING

Permitido:

```text
Carga textual del CSV
```

No permitido:

```text
corrección
homologación
tipado
eliminación
imputación
redondeo
```

---

### STAGING → TYPED

Permitido:

```text
BTRIM
TEXT → DATE
TEXT → SMALLINT
TEXT → NUMERIC(19,13)
```

No se modifica la semántica de `linea`.

No se redondea `afluencia`.

---

### TYPED → CLEAN

Permitido:

```text
derivación temporal
homologación gráfica segura de linea
preservación de linea_original
banderas de calidad
```

No permitido:

```text
eliminar ceros
eliminar decimales
eliminar outliers
eliminar filas
crear afluencia inexistente
fusionar servicios semánticamente distintos
```

---

## 21. Conciliación entre capas

Resultado definitivo:

```text
STAGING: 65,013
TYPED:   65,013
CLEAN:   65,013
```

Pérdida:

```text
0
```

Formalmente:

```text
STAGING = TYPED = CLEAN
```

en cantidad de observaciones.

La comparación TYPED → CLEAN produjo:

```text
diferencias_afluencia = 0
```

Por tanto, CLEAN no modificó los valores de afluencia.

---

## 22. Banderas de calidad CLEAN

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

## 23. Coherencia temporal

Después de CLEAN:

```text
error_anio:        0
error_mes:         0
error_dia_semana:  0
```

Las variables temporales derivadas son coherentes con `fecha`.

---

## 24. Contrato individual validado

La estructura individual validada de Trolebús es:

```text
fecha × linea × tipo_pago
```

con medida:

```text
afluencia
```

y dominio:

```text
linea: 17 categorías CLEAN
tipo_pago: 3 categorías
```

Cada clave:

```text
fecha × linea
```

contiene exactamente:

```text
3 observaciones
```

correspondientes a:

```text
Boleto
Gratuidad
Prepago
```

---

## 25. Candidato para contrato multisistema

El contrato multisistema preliminar vigente utiliza la abstracción:

```text
fecha × sistema × unidad_operativa
```

Para Trolebús existe evidencia suficiente para proponer:

```text
sistema = Trolebús
unidad_operativa = linea
```

porque `linea` representa la unidad operacional publicada por la fuente y el dominio CLEAN contiene 17 categorías diferenciadas.

Por tanto, la agregación candidata para integrar Trolebús al contrato multisistema es:

```text
fecha
×
sistema = Trolebús
×
unidad_operativa = linea
```

La medida diaria candidata se obtiene mediante:

```text
SUM(afluencia)
```

sobre las tres observaciones de:

```text
tipo_pago
```

de cada:

```text
fecha × linea
```

Esta agregación deberá evaluarse formalmente en el checkpoint de compatibilidad multisistema antes de aprobar cualquier integración física.

---

## 26. Medida común multisistema

Trolebús utiliza:

```text
afluencia NUMERIC(19,13)
```

La futura capa multisistema deberá admitir una medida común:

```text
NUMERIC
```

para evitar pérdida de información.

Los sistemas cuyas afluencias individuales sean enteras pueden promoverse a:

```text
NUMERIC
```

sin pérdida.

No debe realizarse una conversión multisistema a `BIGINT`, porque Trolebús contiene:

```text
1,419 valores con componente decimal
```

---

## 27. Restricciones para integración futura

Todavía no debe construirse:

```text
tabla de hechos multisistema definitiva
modelo dimensional definitivo
dataset processed multisistema definitivo
cubo OLAP definitivo
```

Primero debe evaluarse formalmente Trolebús contra el contrato multisistema vigente:

```text
fecha × sistema × unidad_operativa
```

y comprobar:

- ventana temporal común;
- estructura `fecha × linea`;
- completitud de los tres tipos de pago;
- ausencia de colisiones;
- unicidad después de agregación;
- preservación de la afluencia;
- compatibilidad con Metro, Metrobús, RTP y Cablebús;
- unicidad global de `fecha × sistema × unidad_operativa`.

---

## 28. Decisiones definitivas de la Iteración 5

1. RAW permanece inmutable.
2. El recurso principal contiene 65,013 observaciones.
3. La cobertura validada es 2022-01-01 → 2026-10-31.
4. Existen 1,765 fechas distintas.
5. La granularidad individual es `fecha × linea × tipo_pago`.
6. Existen 21,671 claves `fecha × linea`.
7. Cada clave contiene exactamente 3 tipos de pago.
8. Los tipos son `Boleto`, `Gratuidad` y `Prepago`.
9. Existen 43 representaciones originales de `linea`.
10. La normalización gráfica produce 17 categorías CLEAN.
11. La normalización gráfica genera 0 colisiones.
12. `linea_original` conserva la trazabilidad.
13. Se homologaron 62,268 filas.
14. `afluencia` es completamente convertible a `NUMERIC`.
15. Existen 1,419 valores con componente decimal.
16. `afluencia` se almacena como `NUMERIC(19,13)`.
17. Los valores decimales no se redondean.
18. Existen 20,246 ceros válidos.
19. Los ceros se preservan.
20. No existen valores negativos.
21. No existen NULL de afluencia.
22. No existen duplicados exactos.
23. No existen colisiones de granularidad.
24. Se identificaron 6,345 posibles outliers IQR.
25. Los outliers se conservan y únicamente se marcan.
26. No se eliminó ninguna observación.
27. Trolebús propone `unidad_operativa = linea`.
28. La medida multisistema deberá admitir `NUMERIC`.
29. No se materializa todavía integración multisistema.

---

## 29. Estado del pipeline individual

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

Registros:

```text
STAGING    65,013
TYPED      65,013
CLEAN      65,013
```

Pérdida:

```text
0
```

Granularidad individual:

```text
fecha × linea × tipo_pago
```

Abstracción multisistema candidata:

```text
fecha × sistema × unidad_operativa

Trolebús:
unidad_operativa = linea
```

El siguiente paso es elaborar el checkpoint individual y posteriormente evaluar formalmente la compatibilidad de Trolebús con el contrato multisistema vigente.