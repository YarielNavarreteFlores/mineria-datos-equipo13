# Contrato de Datos — Tren Ligero

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Tren Ligero
**Iteración:** 6
**Estado del pipeline individual:** VALIDADO

---

## 2. Fuente oficial

La fuente utilizada corresponde al:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI) / Servicio de Transportes Eléctricos (STE)**

Recurso utilizado:

**Afluencia Diaria Tren Ligero (desglosada)**

Recurso documental:

**Diccionario de Datos**

El recurso contiene información diaria de afluencia de Tren Ligero desde el 1 de enero de 2022.

El conjunto del Servicio de Transportes Eléctricos agrupa recursos correspondientes a:

- Cablebús;
- Tren Ligero;
- Trolebús.

Para esta iteración se incorporaron exclusivamente el recurso correspondiente a Tren Ligero y el diccionario oficial asociado al conjunto.

---

## 3. Archivos fuente

### 3.1 Afluencia

Archivo RAW:

```text
proyecto/data/raw/tren_ligero/afluencia_desglosada_tl_10_2026.csv
```

Características verificadas:

```text
Filas de datos:       3,530
Columnas:                 5
Filas malformadas:        0
Encoding:         UTF-8-SIG
Delimitador:              ,
```

SHA-256:

```text
20f7ce65a095a58306b788070f93d882f0d23885345f7add2954f0e8a2ccc15f
```

---

### 3.2 Diccionario

Archivo preservado:

```text
proyecto/data/metadata/tren_ligero/diccionario_tren_ligero_original.csv
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

La copia preservada en `metadata/` fue comprobada byte a byte contra el archivo RAW correspondiente.

---

## 4. Estructura física de la fuente

El archivo de afluencia de Tren Ligero contiene:

```text
fecha
mes
anio
tipo_pago
afluencia
```

El recurso físico no contiene:

```text
linea
```

ni:

```text
unidad_operativa
```

La estructura física del CSV fue tomada como autoridad operacional para construir el pipeline individual.

El diccionario oficial del conjunto STE describe conceptualmente:

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
estructura física actual del CSV Tren Ligero
```

Además, el recurso físico utiliza una representación larga:

```text
tipo_pago
afluencia
```

en lugar de mantener las medidas de afluencia en columnas independientes.

El pipeline no modifica artificialmente el CSV para ajustarlo a la estructura conceptual del diccionario.

---

## 5. Ausencia de linea

Durante la inspección, STAGING, TYPED, CLEAN y validación integral se comprobó que Tren Ligero no contiene una variable física:

```text
linea
```

Tampoco se creó artificialmente:

```text
linea
linea_original
unidad_operativa
```

La auditoría final confirmó:

```text
columnas linea/unidad_operativa artificiales: 0
```

Por tanto, el pipeline individual conserva estrictamente la semántica publicada por la fuente.

---

## 6. Cobertura temporal validada

Cobertura física:

```text
Fecha mínima:      2022-01-01
Fecha máxima:      2026-10-31
Fechas distintas:       1,765
Días calendario:        1,765
Fechas faltantes:           0
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
Fechas inválidas:              0
Años inválidos:                0
Meses no reconocidos:          0
Inconsistencias fecha ↔ año:   0
Inconsistencias fecha ↔ mes:   0
```

La cobertura observada es continua dentro del periodo analizado.

---

## 7. Granularidad individual

La granularidad individual validada de Tren Ligero es:

```text
fecha × tipo_pago
```

Resultados:

```text
Registros:                    3,530
Claves distintas:             3,530
Grupos con colisión:              0
Filas involucradas:               0
Registros excedentes:             0
Máximo de repeticiones:           1
```

Por tanto:

```text
fecha × tipo_pago
```

identifica de manera única cada observación del recurso analizado.

No fue necesario imponer físicamente una restricción `UNIQUE` durante esta iteración.

---

## 8. Estructura por fecha

Existen exactamente:

```text
1,765
```

fechas distintas.

Cada fecha contiene:

```text
2 filas
2 tipos de pago
```

Por tanto:

```text
1,765 fechas
×
2 tipos_pago
=
3,530 observaciones
```

La estructura fue comprobada para la totalidad del recurso.

---

## 9. Dominio de tipo_pago

Dominio observado:

| tipo_pago | Registros | Fechas |
|---|---:|---:|
| Gratuidad | 1,765 | 1,765 |
| Prepago | 1,765 | 1,765 |

Total:

```text
3,530
```

Tipos distintos:

```text
2
```

Categorías fuera del dominio:

```text
0
```

Cada fecha contiene ambas categorías.

---

## 10. Tipos de datos por capa

### STAGING

```text
fecha       TEXT
mes         TEXT
anio        TEXT
tipo_pago   TEXT
afluencia   TEXT
```

STAGING conserva la representación textual de la fuente sin corrección semántica.

---

### TYPED

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
tipo_pago   TEXT
afluencia   NUMERIC(18,12)
```

El tipo:

```text
NUMERIC(18,12)
```

fue seleccionado a partir del perfilado real de la fuente.

Resultados:

```text
Valores NUMERIC válidos:        3,530
Valores con componente decimal:   516

Máximo de dígitos enteros:          6
Máxima escala observada:           12
Máxima precisión observada:        17
```

Para preservar simultáneamente:

```text
6 dígitos enteros
+
12 dígitos decimales
```

se requiere una capacidad mínima de:

```text
NUMERIC(18,12)
```

No se aplicó redondeo durante el tipado.

---

### CLEAN

CLEAN conserva los tipos físicos de TYPED y agrega:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana

es_afluencia_no_disponible
es_afluencia_cero
es_afluencia_decimal

es_colision_clave
es_duplicado_exacto
es_outlier_iqr_global
```

CLEAN no incorpora:

```text
linea
unidad_operativa
```

porque esas variables no existen en la fuente individual.

---

## 11. Calidad de afluencia

Resultados validados:

```text
Valores:          3,530
NULL:                 0
NaN:                  0
Vacíos:               0
No numéricos:         0
Negativos:            0
Ceros:                0
Decimales:          516
```

Rango observado:

```text
Mínimo:                619
Máximo:            146,779
```

Estadísticos descriptivos:

```text
Q1:          5,992.87266575
Mediana:       19,730.910355
Media:         39,569.028847...
Q3:                72,567.75
```

Los valores decimales se consideran observaciones válidas y se preservan sin redondeo.

---

## 12. Valores decimales

Registros con componente decimal:

```text
516
```

Distribución por año:

```text
2025: 212
2026: 304
```

Total:

```text
516
```

Distribución por tipo de pago:

```text
Gratuidad: 516
Prepago:     0
```

Distribución por escala decimal:

```text
Escala 3:       4
Escala 4:      29
Escala 5:     349
Escala 6:     132
Escala 12:      2
```

Total:

```text
516
```

La escala máxima observada fue:

```text
12
```

No se redondeó ningún valor.

Conciliación:

```text
STAGING: 516
TYPED:   516
CLEAN:   516
```

---

## 13. Ceros

Ceros detectados:

```text
0
```

Conciliación:

```text
STAGING: 0
TYPED:   0
CLEAN:   0
```

No fue necesario aplicar ninguna regla de tratamiento de ceros.

---

## 14. Valores negativos

Valores negativos:

```text
0
```

No se detectó ninguna observación con afluencia menor que cero.

---

## 15. Duplicados

Duplicados exactos detectados:

```text
Grupos:               0
Filas involucradas:   0
Registros excedentes: 0
```

No fue necesario eliminar ni resolver duplicados.

---

## 16. Colisiones

Para la granularidad:

```text
fecha × tipo_pago
```

se detectaron:

```text
0 grupos con colisión
```

Por tanto, la clave individual validada conserva unicidad completa.

---

## 17. Outliers

Se utilizó el criterio IQR global exclusivamente como diagnóstico.

Resultados:

```text
Q1:                 5,992.87266575
Q3:                    72,567.75

Límite inferior:
-93,869.443335625

Límite superior:
172,430.066001375
```

Posibles outliers IQR:

```text
0
```

Máximo observado:

```text
146,779
```

Por tanto, ningún valor fue marcado como outlier mediante el criterio IQR global utilizado.

La ausencia de outliers bajo este criterio no implica que la fuente sea libre de cualquier posible anomalía; únicamente expresa el resultado de la regla diagnóstica utilizada.

---

## 18. Coherencia temporal

Después de CLEAN:

```text
error_anio:        0
error_mes:         0
error_dia_semana:  0
```

Las variables temporales derivadas son coherentes con `fecha`.

---

## 19. Reglas de transformación

### RAW → STAGING

Permitido:

```text
Carga textual del CSV
```

No permitido:

```text
corrección
tipado
eliminación
imputación
redondeo
invención de linea
invención de unidad_operativa
```

---

### STAGING → TYPED

Permitido:

```text
BTRIM
TEXT → DATE
TEXT → SMALLINT
TEXT → NUMERIC(18,12)
```

No se modifica la semántica del recurso.

No se redondea `afluencia`.

No se crea `linea`.

---

### TYPED → CLEAN

Permitido:

```text
derivación temporal
banderas de calidad
preservación de granularidad
```

No permitido:

```text
eliminar decimales
eliminar filas
crear afluencia inexistente
inventar lineas
inventar unidades operativas
forzar integración multisistema
```

---

## 20. Conciliación entre capas

Resultado definitivo:

```text
STAGING: 3,530
TYPED:   3,530
CLEAN:   3,530
```

Pérdida:

```text
0
```

Formalmente:

```text
STAGING = TYPED = CLEAN
```

en número de observaciones.

Comparación:

```text
STAGING → TYPED:
diferencias_afluencia = 0

TYPED → CLEAN:
diferencias_core = 0
```

Por tanto, el pipeline no alteró la medida de afluencia.

---

## 21. Banderas de calidad CLEAN

Resultados:

```text
es_afluencia_no_disponible = TRUE:     0
es_afluencia_cero = TRUE:              0
es_afluencia_decimal = TRUE:         516

es_colision_clave = TRUE:              0
es_duplicado_exacto = TRUE:            0
es_outlier_iqr_global = TRUE:          0
```

---

## 22. Contrato individual validado

La estructura individual validada de Tren Ligero es:

```text
fecha × tipo_pago
```

con medida:

```text
afluencia
```

y dominio:

```text
tipo_pago:
Gratuidad
Prepago
```

Cada fecha contiene exactamente:

```text
2 observaciones
```

correspondientes a:

```text
Gratuidad
Prepago
```

---

## 23. Candidato diario de Tren Ligero

La estructura individual permite evaluar una agregación diaria mediante:

```text
SUM(afluencia)
```

sobre:

```text
Gratuidad
+
Prepago
```

para cada:

```text
fecha
```

Dado que existen:

```text
1,765 fechas
```

y cada fecha contiene exactamente:

```text
2 filas
2 tipos de pago
0 NULL
0 colisiones
```

la agregación candidata produciría:

```text
1,765 observaciones diarias
```

La medida debe permanecer en dominio:

```text
NUMERIC
```

para preservar los valores decimales existentes.

Esta agregación todavía debe evaluarse formalmente en el checkpoint de compatibilidad multisistema.

---

## 24. Candidato para contrato multisistema

El contrato multisistema preliminar vigente utiliza:

```text
fecha × sistema × unidad_operativa
```

Los sistemas ya evaluados utilizan:

```text
Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio

Cablebús:
unidad_operativa = linea

Trolebús:
unidad_operativa = linea
```

Tren Ligero presenta una situación diferente.

La fuente individual no contiene una dimensión equivalente explícita a:

```text
linea
servicio
unidad_operativa
```

Por tanto, durante el pipeline individual no se realizó ningún mapeo artificial.

La compatibilidad multisistema deberá evaluar formalmente si es metodológicamente válido representar Tren Ligero mediante una única unidad analítica constante correspondiente al sistema completo.

Una representación candidata a evaluar es conceptualmente:

```text
sistema = Tren Ligero
unidad_operativa = unidad única del sistema
```

pero esta representación:

```text
NO se considera todavía aprobada
```

hasta demostrar que:

1. no altera la granularidad de origen;
2. preserva la demanda diaria agregada;
3. produce una clave única;
4. es compatible con el significado abstracto de `unidad_operativa`;
5. no se presenta falsamente como una variable publicada por la fuente.

---

## 25. Regla semántica importante

Si el checkpoint multisistema aprobara una unidad constante para Tren Ligero, deberá quedar explícitamente documentado que:

```text
unidad_operativa
```

sería una dimensión derivada exclusivamente para la capa de integración.

No sería una columna original de la fuente.

Por tanto:

```text
unidad_operativa derivada
≠
atributo físico publicado
```

El pipeline individual deberá permanecer sin modificaciones.

---

## 26. Medida común multisistema

Tren Ligero utiliza:

```text
afluencia NUMERIC(18,12)
```

La futura capa multisistema debe mantener una medida común:

```text
NUMERIC
```

para evitar pérdida de información.

No debe realizarse una conversión a `BIGINT`, porque Tren Ligero contiene:

```text
516 valores con componente decimal
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

Primero debe evaluarse formalmente Tren Ligero contra:

```text
fecha × sistema × unidad_operativa
```

y comprobar:

- ventana temporal estrictamente común;
- estructura `fecha × tipo_pago`;
- completitud de Gratuidad y Prepago;
- ausencia de NULL;
- ausencia de colisiones;
- unicidad de la agregación diaria;
- preservación de afluencia;
- compatibilidad semántica de una unidad operativa constante;
- compatibilidad con Metro, Metrobús, RTP, Cablebús y Trolebús;
- unicidad global de `fecha × sistema × unidad_operativa`.

---

## 28. Decisiones definitivas de la Iteración 6 hasta el pipeline individual

1. RAW permanece inmutable.
2. El recurso principal contiene 3,530 observaciones.
3. La fuente contiene 5 columnas.
4. La cobertura validada es 2022-01-01 → 2026-10-31.
5. Existen 1,765 fechas distintas.
6. No existen fechas faltantes dentro de la cobertura.
7. La granularidad individual es `fecha × tipo_pago`.
8. Existen 3,530 claves únicas `fecha × tipo_pago`.
9. Cada fecha contiene exactamente 2 tipos de pago.
10. Los tipos son `Gratuidad` y `Prepago`.
11. La fuente no contiene `linea`.
12. El pipeline individual no crea `linea`.
13. El pipeline individual no crea `unidad_operativa`.
14. `afluencia` es completamente convertible a `NUMERIC`.
15. Existen 516 valores con componente decimal.
16. `afluencia` se almacena como `NUMERIC(18,12)`.
17. Los valores decimales no se redondean.
18. No existen ceros.
19. No existen valores negativos.
20. No existen NULL de afluencia.
21. No existen duplicados exactos.
22. No existen colisiones de granularidad.
23. El criterio IQR global identifica 0 posibles outliers.
24. No se eliminó ninguna observación.
25. STAGING, TYPED y CLEAN contienen 3,530 filas.
26. La pérdida de registros es 0.
27. STAGING → TYPED conserva afluencia sin diferencias.
28. TYPED → CLEAN conserva el núcleo del registro sin diferencias.
29. La compatibilidad multisistema todavía debe evaluarse.
30. No se materializa todavía una integración multisistema.

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
PIPELINE INDIVIDUAL TREN LIGERO: VALIDADO
```

Registros:

```text
STAGING    3,530
TYPED      3,530
CLEAN      3,530
```

Pérdida:

```text
0
```

Granularidad individual:

```text
fecha × tipo_pago
```

Situación respecto del contrato multisistema:

```text
fecha × sistema × unidad_operativa
```

Tren Ligero:

```text
unidad_operativa = PENDIENTE DE EVALUACIÓN FORMAL
```

El siguiente paso es elaborar el checkpoint individual y posteriormente evaluar formalmente la compatibilidad de Tren Ligero con el contrato multisistema vigente.