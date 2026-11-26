# Checkpoint individual — Tren Ligero

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema:** Tren Ligero
**Iteración:** 6
**Estado:** VALIDADO
**Fecha del checkpoint:** 2026-11-25

---

## 2. Objetivo del checkpoint

Este documento consolida la evidencia técnica obtenida durante la Iteración 6 correspondiente a Tren Ligero.

El objetivo es determinar si el recurso seleccionado puede considerarse suficientemente:

- comprendido;
- trazable;
- reproducible;
- tipado correctamente;
- validado estructuralmente;
- preservado sin pérdida;

para pasar posteriormente al análisis formal de compatibilidad con el contrato multisistema vigente.

Este checkpoint corresponde exclusivamente al pipeline individual.

No representa todavía una integración física con:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
```

---

## 3. Fuente oficial

Fuente:

**Portal de Datos Abiertos de la Ciudad de México**

Conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI) / Servicio de Transportes Eléctricos (STE)**

Recurso principal:

**Afluencia Diaria Tren Ligero (desglosada)**

Recurso documental:

**Diccionario de Datos**

---

## 4. Fuente física utilizada

Archivo RAW:

```text
proyecto/data/raw/tren_ligero/afluencia_desglosada_tl_10_2026.csv
```

Características verificadas:

```text
Registros:             3,530
Columnas:                  5
Filas malformadas:         0
Encoding:          UTF-8-SIG
Delimitador:               ,
```

Columnas:

```text
fecha
mes
anio
tipo_pago
afluencia
```

SHA-256:

```text
20f7ce65a095a58306b788070f93d882f0d23885345f7add2954f0e8a2ccc15f
```

---

## 5. Diccionario oficial

Archivo preservado:

```text
proyecto/data/metadata/tren_ligero/diccionario_tren_ligero_original.csv
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

y no exclusivamente a Tren Ligero.

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
tipo_pago
afluencia
```

Por tanto:

```text
diccionario conceptual STE
≠
estructura física actual del recurso Tren Ligero
```

La implementación del pipeline se construyó a partir de la estructura física observada.

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
PIPELINE INDIVIDUAL TREN LIGERO: VALIDADO
```

---

## 7. Conciliación entre capas

Resultados:

```text
STAGING:   3,530
TYPED:     3,530
CLEAN:     3,530
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

No hubo:

```text
pérdida de registros
generación artificial de registros
eliminación de registros
```

durante el pipeline.

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

Días calendario dentro del intervalo:

```text
1,765
```

Fechas faltantes:

```text
0
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

---

## 9. Granularidad individual

Granularidad validada:

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

identifica de manera única cada observación física del recurso.

---

## 10. Estructura por fecha

Existen:

```text
1,765 fechas
```

Para cada fecha existen exactamente:

```text
2 filas
2 tipos de pago
```

Formalmente:

```text
1,765 × 2 = 3,530
```

observaciones.

No se detectaron fechas con estructura incompleta.

---

## 11. Dominio de tipo_pago

Tipos observados:

```text
Gratuidad
Prepago
```

Distribución:

```text
Gratuidad:   1,765
Prepago:     1,765
```

Total:

```text
3,530
```

Tipos distintos:

```text
2
```

Valores fuera del dominio:

```text
0
```

Cada una de las 1,765 fechas contiene ambos tipos de pago.

---

## 12. Ausencia de linea

El archivo físico de Tren Ligero no contiene:

```text
linea
```

Durante todo el pipeline se verificó que tampoco fueran creadas artificialmente las columnas:

```text
linea
linea_original
unidad_operativa
```

Auditoría final:

```text
linea/unidad_operativa artificiales: 0
```

Por tanto:

```text
PIPELINE INDIVIDUAL
```

preserva estrictamente la estructura publicada por la fuente.

No se asumió que Tren Ligero tuviera una dimensión operacional equivalente a las líneas utilizadas por otros sistemas.

---

## 13. STAGING

Tabla:

```text
proyecto.tren_ligero_desglosada_stage
```

Estructura:

```text
fecha       TEXT
mes         TEXT
anio        TEXT
tipo_pago   TEXT
afluencia   TEXT
```

Registros:

```text
3,530
```

STAGING conserva la representación textual del recurso.

No se realizan transformaciones semánticas en esta capa.

---

## 14. Perfilado

El perfilado formal confirmó:

```text
Registros:                3,530
Fechas distintas:         1,765
Tipos de pago:                2

Vacíos:                       0
NaN:                          0
No numéricos:                 0
Negativos:                    0
Ceros:                        0
Decimales:                  516

Duplicados exactos:           0
Colisiones:                   0
```

Granularidad candidata comprobada:

```text
fecha × tipo_pago
```

Resultado:

```text
VALIDADA
```

---

## 15. Tipado de afluencia

Se observaron:

```text
Máximo de dígitos enteros:       6
Máxima escala:                  12
Máxima precisión observada:     17
```

Para preservar:

```text
6 dígitos enteros
+
12 dígitos decimales
```

se adoptó:

```text
NUMERIC(18,12)
```

El tipo seleccionado permite preservar completamente la precisión observada en la fuente.

No se realizó redondeo.

---

## 16. TYPED

Tabla:

```text
proyecto.tren_ligero_desglosada_typed
```

Estructura:

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
tipo_pago   TEXT
afluencia   NUMERIC(18,12)
```

Conciliación:

```text
STAGING: 3,530
TYPED:   3,530

Diferencia: 0
```

Validación:

```text
NULL:                    0
Ceros:                   0
Decimales:             516
Negativos:               0
Tipos de pago:           2
Fechas:               1,765
Colisiones:              0
Diferencias afluencia:   0
```

Resultado:

```text
TYPED TREN LIGERO: VALIDADO
```

---

## 17. CLEAN

Tabla:

```text
proyecto.tren_ligero_desglosada_clean
```

CLEAN conserva:

```text
fecha
anio
mes
tipo_pago
afluencia
```

y agrega exclusivamente variables derivadas y banderas de calidad:

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

No se crea:

```text
linea
unidad_operativa
```

---

## 18. Derivación temporal

Variables derivadas:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana
```

Controles:

```text
error_anio:        0
error_mes:         0
error_dia_semana:  0
```

Por tanto, las variables derivadas son coherentes con:

```text
fecha
```

---

## 19. Calidad de afluencia

Valores analizados:

```text
3,530
```

Calidad:

```text
NULL:             0
NaN:              0
Vacíos:           0
No numéricos:     0
Negativos:        0
Ceros:            0
Decimales:      516
```

Rango:

```text
Mínimo:       619
Máximo:   146,779
```

Estadísticos descriptivos:

```text
Q1:          5,992.87266575
Mediana:       19,730.910355
Media:         39,569.028847...
Q3:                72,567.75
```

---

## 20. Valores decimales

Valores con componente decimal:

```text
516
```

Distribución por año:

```text
2025: 212
2026: 304
```

Distribución por tipo de pago:

```text
Gratuidad: 516
Prepago:     0
```

Distribución por escala:

```text
3 dígitos:      4
4 dígitos:     29
5 dígitos:    349
6 dígitos:    132
12 dígitos:     2
```

Total:

```text
516
```

Conciliación:

```text
STAGING: 516
TYPED:   516
CLEAN:   516
```

No se perdió precisión.

---

## 21. Ceros

Ceros observados:

```text
0
```

Conciliación:

```text
STAGING: 0
TYPED:   0
CLEAN:   0
```

---

## 22. Duplicados

Duplicados exactos:

```text
Grupos:               0
Filas involucradas:   0
Registros excedentes: 0
```

No fue necesario eliminar registros.

---

## 23. Colisiones

En la granularidad:

```text
fecha × tipo_pago
```

se detectaron:

```text
Grupos con colisión:      0
Filas involucradas:       0
Registros excedentes:     0
```

Por tanto, la granularidad permanece única durante todo el pipeline.

---

## 24. Outliers

Se utilizó el criterio IQR global exclusivamente con fines diagnósticos.

Resultados:

```text
Q1:                  5,992.87266575
Q3:                     72,567.75

Límite inferior:
-93,869.443335625

Límite superior:
172,430.066001375
```

Posibles outliers:

```text
0
```

Máximo observado:

```text
146,779
```

No se eliminó ninguna observación por magnitud.

---

## 25. Banderas CLEAN

Resultados:

```text
es_afluencia_no_disponible = TRUE:     0
es_afluencia_cero = TRUE:              0
es_afluencia_decimal = TRUE:         516

es_colision_clave = TRUE:              0
es_duplicado_exacto = TRUE:            0
es_outlier_iqr_global = TRUE:          0
```

Las banderas coinciden con los diagnósticos independientes.

---

## 26. Preservación de información

Comparación:

```text
STAGING → TYPED
```

Resultado:

```text
diferencias_afluencia = 0
```

Comparación:

```text
TYPED → CLEAN
```

Resultado:

```text
diferencias_core = 0
```

Por tanto:

```text
afluencia STAGING
=
afluencia TYPED
=
afluencia CLEAN
```

en significado y valor numérico.

---

## 27. Auditoría integral

La auditoría final produjo:

```text
VALIDACION TREN LIGERO OK
```

Resultados:

```text
Filas:                              3,530
NULL:                                   0
Ceros:                                  0
Decimales:                            516
Negativos:                              0
Pagos:                                  2
Colisiones:                             0
Duplicados:                             0
Outliers:                               0
Fechas:                             1,765
Claves fecha-tipo_pago:             3,530
Diferencias STAGE-TYPED:                0
Diferencias TYPED-CLEAN:                0
linea/unidad_operativa artificiales:    0
```

Resultado:

```text
AUDITORÍA INDIVIDUAL: APROBADA
```

---

## 28. Contrato individual

La granularidad definitiva del recurso individual es:

```text
fecha × tipo_pago
```

Medida:

```text
afluencia
```

Dominios:

```text
tipo_pago:
- Gratuidad
- Prepago
```

Estructura:

```text
cada fecha
=
2 observaciones
```

No existe dimensión física adicional de:

```text
linea
servicio
unidad_operativa
```

---

## 29. Candidato diario

El recurso puede producir conceptualmente una medida diaria mediante:

```text
SUM(afluencia)
```

sobre:

```text
Gratuidad
+
Prepago
```

para cada fecha.

Estructura validada para las 1,765 fechas:

```text
filas = 2
tipos_pago = 2
NULL = 0
colisiones = 0
```

Por tanto, el candidato diario produciría:

```text
1,765 registros
```

con granularidad:

```text
fecha
```

Este candidato no se materializa todavía.

---

## 30. Situación frente al contrato multisistema

El contrato multisistema vigente es:

```text
fecha × sistema × unidad_operativa
```

Mapeo vigente:

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

Tren Ligero no contiene una dimensión física equivalente.

Por tanto:

```text
unidad_operativa = PENDIENTE DE EVALUACIÓN FORMAL
```

No debe asumirse automáticamente:

```text
unidad_operativa = linea
```

porque la fuente no contiene dicha variable.

---

## 31. Hipótesis de compatibilidad

La siguiente etapa deberá evaluar si Tren Ligero puede representarse conceptualmente mediante:

```text
sistema = Tren Ligero
unidad_operativa = unidad constante del sistema
```

Esta propuesta todavía no constituye una decisión aprobada.

Deberá comprobarse formalmente que:

1. la agregación diaria es válida;
2. cada fecha produce una sola observación;
3. no existen componentes faltantes;
4. la afluencia se preserva;
5. la clave candidata es única;
6. la unidad constante funciona como abstracción analítica;
7. la dimensión derivada se distingue explícitamente de una columna física de la fuente;
8. la clave global multisistema permanece única.

---

## 32. Restricción semántica

Si posteriormente se aprueba una unidad constante, deberá documentarse que:

```text
unidad_operativa
```

es un atributo derivado de integración.

No deberá afirmarse que la fuente original publica dicho campo.

Formalmente:

```text
unidad_operativa derivada
≠
campo físico de la fuente
```

El pipeline individual validado no deberá modificarse.

---

## 33. Medida común

Tren Ligero utiliza:

```text
afluencia NUMERIC(18,12)
```

Por contener:

```text
516
```

observaciones con componente decimal, una futura integración multisistema deberá mantener:

```text
NUMERIC
```

como dominio común de la medida.

No debe reducirse a:

```text
BIGINT
```

porque produciría pérdida de precisión.

---

## 34. Restricciones vigentes

Todavía no debe construirse:

```text
tabla de hechos multisistema definitiva
modelo dimensional definitivo
dataset processed definitivo
cubo OLAP definitivo
```

Primero debe ejecutarse el checkpoint de compatibilidad de Tren Ligero.

---

## 35. Decisiones del checkpoint individual

1. La fuente oficial fue identificada y preservada.
2. RAW permanece inmutable.
3. El archivo principal contiene 3,530 observaciones.
4. El archivo contiene 5 columnas.
5. La cobertura es 2022-01-01 → 2026-10-31.
6. Existen 1,765 fechas distintas.
7. No existen fechas faltantes en la cobertura.
8. La granularidad física es `fecha × tipo_pago`.
9. Existen 3,530 claves únicas.
10. Cada fecha contiene exactamente 2 observaciones.
11. Cada fecha contiene Gratuidad y Prepago.
12. No existen categorías adicionales de tipo de pago.
13. No existen campos vacíos.
14. No existen NaN.
15. No existen afluencias no numéricas.
16. No existen afluencias negativas.
17. No existen ceros.
18. Existen 516 valores decimales.
19. La escala máxima observada es 12.
20. La precisión física utilizada es `NUMERIC(18,12)`.
21. No se redondeó afluencia.
22. No existen duplicados exactos.
23. No existen colisiones.
24. El criterio IQR global detecta 0 posibles outliers.
25. No se eliminaron observaciones.
26. STAGING contiene 3,530 filas.
27. TYPED contiene 3,530 filas.
28. CLEAN contiene 3,530 filas.
29. La pérdida total es 0.
30. STAGING → TYPED genera 0 diferencias de afluencia.
31. TYPED → CLEAN genera 0 diferencias del núcleo.
32. La fuente no contiene `linea`.
33. El pipeline no crea `linea`.
34. El pipeline no crea `unidad_operativa`.
35. La compatibilidad multisistema continúa pendiente.
36. No se materializa todavía ninguna integración.

---

# 36. RESULTADO DEL CHECKPOINT

Resultado:

```text
CHECKPOINT INDIVIDUAL TREN LIGERO: APROBADO
```

El sistema cumple los criterios necesarios para avanzar a:

```text
EVALUACIÓN DE COMPATIBILIDAD
TREN LIGERO ↔ CONTRATO MULTISISTEMA
```

Contrato individual:

```text
fecha × tipo_pago
```

Medida:

```text
afluencia NUMERIC(18,12)
```

Registros:

```text
3,530
```

Pérdida:

```text
0
```

Estado de `unidad_operativa`:

```text
PENDIENTE DE EVALUACIÓN FORMAL
```

---

## 37. Siguiente etapa

El siguiente artefacto deberá evaluar formalmente:

```text
Tren Ligero
↔
fecha × sistema × unidad_operativa
```

sin modificar este pipeline individual.

La evaluación deberá determinar si es válido construir una representación candidata:

```text
fecha
×
sistema = Tren Ligero
×
unidad_operativa = unidad constante derivada
```

y posteriormente comprobarla junto con:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
Tren Ligero
```

dentro de la ventana temporal estrictamente común.

Hasta completar esa evaluación:

```text
INTEGRACIÓN MULTISISTEMA TREN LIGERO:
PENDIENTE
```