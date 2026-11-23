# Checkpoint de compatibilidad — Trolebús ↔ Contrato multisistema

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema incorporado:** Trolebús
**Iteración:** 5
**Fecha:** 2026-11-22

**Resultado de Trolebús:**

```text
COMPATIBILIDAD TROLEBÚS ↔ CONTRATO MULTISISTEMA:
APROBADA
```

**Estado global del contrato multisistema:**

```text
APROBADO CON RESTRICCIONES
```

Las restricciones globales vigentes corresponden exclusivamente a RTP y no son introducidas por Trolebús.

---

# 2. Objetivo

Este checkpoint evalúa formalmente si Trolebús puede incorporarse conceptualmente al contrato multisistema vigente:

```text
fecha × sistema × unidad_operativa
```

sin modificar los pipelines individuales previamente validados de:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
```

El análisis es exclusivamente diagnóstico.

No se construye todavía una integración física multisistema.

---

# 3. Contrato previo

Después de la incorporación de Cablebús, el contrato multisistema vigente quedó establecido como:

```text
fecha × sistema × unidad_operativa
```

Mapeo previo:

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

Para Trolebús se evaluó:

```text
unidad_operativa = linea
```

---

# 4. Pipeline individual Trolebús

Estado previo:

```text
PIPELINE INDIVIDUAL TROLEBÚS: VALIDADO
```

Checkpoint individual:

```text
CHECKPOINT INDIVIDUAL TROLEBÚS: APROBADO
```

Conciliación:

```text
STAGING: 65,013
TYPED:   65,013
CLEAN:   65,013
```

Pérdida:

```text
0
```

Granularidad individual:

```text
fecha × linea × tipo_pago
```

---

# 5. Ventana temporal estrictamente común

Se evaluaron las coberturas CLEAN de:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
```

La intersección temporal estricta resultante es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

Por tanto, la incorporación de Trolebús:

```text
NO modifica
```

la ventana temporal común que ya se encontraba vigente después de incorporar Cablebús.

---

# 6. Trolebús dentro de la ventana común

Dentro del periodo:

```text
2022-01-01 → 2026-07-31
```

Trolebús contiene:

```text
Registros detallados:        60,597
Fechas distintas:             1,673
Líneas lógicas:                  17
Tipos de pago:                    3
```

Calidad:

```text
Afluencia NULL:                   0
Afluencia cero:              18,454
Afluencia decimal:            1,419
Filas con colisión:                0
Duplicados exactos:                0
Outliers de origen:            5,873
```

Los outliers corresponden a la bandera diagnóstica ya definida en el pipeline individual y no implican eliminación de observaciones.

---

# 7. Estructura nativa de Trolebús

La granularidad CLEAN individual es:

```text
fecha × linea × tipo_pago
```

Los tipos de pago son:

```text
Boleto
Gratuidad
Prepago
```

Para todas las combinaciones:

```text
fecha × linea
```

dentro de la ventana común se observaron exactamente:

```text
3 filas
3 tipos de pago
```

---

# 8. Claves fecha × linea

Dentro de la ventana común se identificaron:

```text
20,199
```

claves distintas:

```text
fecha × linea
```

Estructura:

```text
3 filas
3 tipos_pago
20,199 claves
```

Controles:

```text
Claves con colisión:                 0
Claves con duplicado:                0
Claves con afluencia incompleta:     0
```

Por tanto:

```text
20,199 × 3 = 60,597
```

observaciones detalladas.

---

# 9. Clasificación exhaustiva

Las 20,199 claves fueron clasificadas individualmente.

Resultado:

```text
Claves totales:             20,199
Claves OK:                  20,199

Solo colisión:                   0
Solo NULL:                       0
Colisión + NULL:                 0
Estructura inesperada:           0
```

Por tanto:

```text
100 % de las claves Trolebús
son estructuralmente completas y seguras
dentro de la ventana común.
```

---

# 10. Regla de agregación Trolebús

Para producir demanda diaria por línea se evaluó:

```text
SUM(afluencia)
```

sobre:

```text
Boleto
+
Gratuidad
+
Prepago
```

La agregación es válida porque para las 20,199 claves:

```text
filas = 3
tipos_pago = 3
componentes NULL = 0
colisiones = 0
```

No se realiza redondeo.

La medida resultante permanece dentro del dominio:

```text
NUMERIC
```

para preservar los valores decimales presentes en la fuente.

---

# 11. Candidato diario Trolebús

El candidato agregado produjo:

```text
Registros:                20,199
Claves distintas:         20,199
Fechas distintas:          1,673
Unidades operativas:          17

Afluencia NULL:                0
Claves con restricción:        0
```

Cobertura:

```text
2022-01-01 → 2026-07-31
```

---

# 12. Cobertura por unidad operativa

Dentro de la ventana común se obtuvieron las siguientes unidades.

## Linea 0

```text
Claves totales: 61
Claves seguras: 61
Cobertura:
2026-06-01 → 2026-07-31
```

## Linea 1

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 1 Nochebus

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 2

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 3

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 4

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 5

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 6

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 7

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 8

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 9

```text
Claves totales: 1,673
Claves seguras: 1,673
Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 10

```text
Claves totales: 883
Claves seguras: 883
Cobertura:
2024-03-01 → 2026-07-31
```

## Linea 10 (Trolebus elevado)

```text
Claves totales: 790
Claves seguras: 790
Cobertura:
2022-01-01 → 2024-02-29
```

## Linea 11

```text
Claves totales: 457
Claves seguras: 457
Cobertura:
2025-05-01 → 2026-07-31
```

## Linea 12

```text
Claves totales: 791
Claves seguras: 791
Cobertura:
2024-06-01 → 2026-07-31
```

## Linea 13

```text
Claves totales: 426
Claves seguras: 426
Cobertura:
2025-06-01 → 2026-07-31
```

## Linea 14

```text
Claves totales: 61
Claves seguras: 61
Cobertura:
2026-06-01 → 2026-07-31
```

La suma de las claves por unidad operativa es:

```text
20,199
```

Las diferencias de cobertura entre líneas se preservan como características de la fuente.

No se imputan fechas anteriores al inicio observado de cada servicio.

---

# 13. Unicidad del candidato Trolebús

La representación:

```text
fecha × unidad_operativa
```

produjo:

```text
Registros totales: 20,199
Claves distintas:  20,199
Claves duplicadas:      0
```

Por tanto:

```text
fecha × linea
```

es una granularidad válida para representar la demanda diaria agregada de Trolebús dentro del candidato multisistema.

---

# 14. Mapeo al contrato común

Trolebús puede representarse mediante:

```text
sistema = Trolebús
unidad_operativa = linea
```

Por tanto:

```text
fecha × sistema × unidad_operativa
```

se particulariza para Trolebús como:

```text
fecha × Trolebús × linea
```

---

# 15. Semántica de unidad_operativa

`unidad_operativa` continúa siendo una abstracción analítica.

No significa que:

```text
linea de Metro
linea de Metrobús
servicio de RTP
linea de Cablebús
linea de Trolebús
```

sean entidades operacionalmente idénticas.

La semántica específica se conserva mediante:

```text
sistema
```

y mediante la trazabilidad hacia cada pipeline individual.

---

# 16. Resultado Metro

Dentro de la ventana común:

```text
Registros:               20,076
Claves distintas:        20,076
Fechas distintas:         1,673
Unidades operativas:         12
Afluencia NULL:               0
Claves con restricción:       0
```

---

# 17. Resultado Metrobús

Dentro de la ventana común:

```text
Registros:               11,711
Claves distintas:        11,711
Fechas distintas:         1,673
Unidades operativas:          7
Afluencia NULL:               0
Claves con restricción:       0
```

---

# 18. Resultado RTP

Dentro de la ventana común:

```text
Registros:               13,382
Claves distintas:        13,382
Fechas distintas:         1,673
Unidades operativas:         21
Afluencia NULL:             223
Claves con restricción:     223
```

Estas restricciones fueron documentadas en la Iteración 3.

Corresponden a problemas conocidos de RTP y no fueron provocadas por Cablebús ni Trolebús.

---

# 19. Resultado Cablebús

Dentro de la ventana común:

```text
Registros:                3,803
Claves distintas:         3,803
Fechas distintas:         1,673
Unidades operativas:          3
Afluencia NULL:               0
Claves con restricción:       0
```

---

# 20. Resultado Trolebús

Dentro de la ventana común:

```text
Registros:               20,199
Claves distintas:        20,199
Fechas distintas:         1,673
Unidades operativas:         17
Afluencia NULL:               0
Claves con restricción:       0
```

Trolebús no añade claves problemáticas al contrato multisistema.

---

# 21. Candidato multisistema de cinco sistemas

La construcción conceptual produce:

```text
Metro:        20,076
Metrobús:     11,711
RTP:          13,382
Cablebús:      3,803
Trolebús:     20,199
```

Total:

```text
20,076
+ 11,711
+ 13,382
+  3,803
+ 20,199
--------
 69,171
```

---

# 22. Validación global de la clave

La construcción conceptual produjo:

```text
Registros totales:       69,171
Claves distintas:        69,171
Claves duplicadas:            0

Fechas distintas:         1,673

Fecha mínima:
2022-01-01

Fecha máxima:
2026-07-31

Afluencia NULL:            223
Claves con restricción:    223
```

Por tanto:

```text
69,171 registros
=
69,171 claves distintas
```

y:

```text
claves duplicadas = 0
```

---

# 23. Validación del contrato

La combinación:

```text
fecha × sistema × unidad_operativa
```

continúa funcionando como clave conceptual única para los cinco sistemas evaluados.

Trolebús no obliga a modificar la estructura conceptual del contrato vigente.

---

# 24. Evolución del contrato

La primera abstracción utilizada para Metro y Metrobús fue posteriormente generalizada para permitir incorporar RTP.

El contrato vigente es:

```text
fecha × sistema × unidad_operativa
```

Cablebús pudo incorporarse mediante:

```text
unidad_operativa = linea
```

Trolebús también puede incorporarse mediante:

```text
unidad_operativa = linea
```

Por tanto:

```text
NO se requiere una nueva generalización
del contrato por Trolebús.
```

---

# 25. Identidad global de las unidades

La identidad de una unidad requiere siempre:

```text
sistema × unidad_operativa
```

Una etiqueta como:

```text
Linea 1
```

no identifica globalmente una entidad.

Por ejemplo:

```text
Metro / Linea 1
≠
Cablebús / Linea 1
≠
Trolebús / Linea 1
```

El atributo:

```text
sistema
```

es indispensable para preservar la semántica.

---

# 26. Medida común

La medida conceptual continúa siendo:

```text
afluencia reportada
```

Para Trolebús se obtiene mediante:

```text
SUM(
    Boleto
    +
    Gratuidad
    +
    Prepago
)
```

cuando la clave está completa.

Dentro de la ventana evaluada:

```text
20,199 / 20,199
```

claves son completas.

---

# 27. Tipo de medida común

Trolebús utiliza individualmente:

```text
NUMERIC(19,13)
```

y contiene:

```text
1,419
```

observaciones detalladas con componente decimal dentro de la ventana común.

Por tanto, el contrato multisistema deberá utilizar:

```text
NUMERIC
```

como dominio común de la medida.

Esto permite promocionar sin pérdida medidas provenientes de:

```text
INTEGER
BIGINT
NUMERIC
```

No debe utilizarse:

```text
BIGINT
```

como dominio común, debido a que provocaría pérdida de información en los valores decimales de Trolebús y de cualquier otro sistema con medidas decimales.

---

# 28. NULL

Se conserva la regla:

```text
NULL ≠ 0
```

Dentro del candidato multisistema:

```text
Metro:         0 NULL
Metrobús:      0 NULL
RTP:         223 NULL
Cablebús:      0 NULL
Trolebús:      0 NULL
```

Los:

```text
223 NULL
```

pertenecen exclusivamente al candidato RTP y representan restricciones conocidas.

---

# 29. Ceros

Los ceros permanecen como valores válidos.

Trolebús presenta dentro de la ventana común:

```text
18,454
```

filas detalladas con afluencia igual a cero.

Estos valores no se interpretan como datos faltantes.

No se sustituyen por `NULL`.

---

# 30. Decimales

Dentro de la ventana común Trolebús contiene:

```text
1,419
```

observaciones detalladas con componente decimal.

Estos valores se preservan.

No se aplica:

```text
ROUND
TRUNC
CAST a BIGINT
```

sobre la medida para construir el candidato.

La agregación permanece como:

```text
NUMERIC
```

---

# 31. Tipo de pago

Trolebús contiene:

```text
Boleto
Gratuidad
Prepago
```

El detalle:

```text
tipo_pago
```

continúa disponible en el pipeline individual.

El candidato multisistema agrega desde:

```text
fecha × linea × tipo_pago
```

hacia:

```text
fecha × linea
```

sin destruir ni modificar el nivel detallado original.

---

# 32. Colisiones

Trolebús presenta:

```text
0 colisiones
```

en su granularidad individual.

Después de la homologación gráfica:

```text
0 colisiones
```

Dentro de la ventana multisistema:

```text
0 claves con colisión
```

No se requiere una política especial de resolución para Trolebús.

---

# 33. Duplicados

Trolebús presenta:

```text
0 duplicados exactos
```

Dentro del candidato:

```text
20,199 registros
20,199 claves
0 duplicadas
```

No se eliminó ninguna observación.

---

# 34. Outliers

Dentro de la ventana común existen:

```text
5,873
```

filas marcadas mediante la regla diagnóstica:

```text
es_outlier_iqr_global
```

Los outliers permanecen en el conjunto.

No afectan la validez estructural de:

```text
fecha × linea
```

ni la unicidad del contrato multisistema.

Las reglas de identificación de outliers continúan siendo específicas del pipeline individual de cada sistema.

---

# 35. Estados de calidad

El candidato Trolebús contiene:

```text
20,199 OK
0 COLISION
0 AFLUENCIA_INCOMPLETA
0 COLISION_Y_NULL
0 ESTRUCTURA_INESPERADA
```

Por tanto:

```text
claves_con_restriccion = 0
```

---

# 36. Restricciones globales

El candidato multisistema contiene:

```text
223
```

restricciones.

Estas corresponden exclusivamente a RTP.

Trolebús aporta:

```text
20,199 claves
20,199 OK
0 restricciones
```

Por tanto, Trolebús:

```text
NO incrementa
```

las restricciones globales existentes.

---

# 37. Matriz actualizada de compatibilidad

| Elemento | Metro | Metrobús | RTP | Cablebús | Trolebús | Decisión |
|---|---|---|---|---|---|---|
| Fecha diaria | Sí | Sí | Sí | Sí | Sí | Común |
| Sistema | Metro | Metrobús | RTP | Cablebús | Trolebús | Obligatorio |
| Línea | Sí | Sí | No universal | Sí | Sí | No usar sola globalmente |
| Servicio | No | No | Sí | No | No | Específico RTP |
| Unidad operativa | Línea | Línea | Servicio | Línea | Línea | Abstracción común |
| Afluencia | Sí | Sí | Sí | Sí | Sí | Medida común |
| Tipo pago | Sí | Sí | Sí | Sí | Sí | Detalle adicional |
| Estación | Sí | No | No | No | No | Específica Metro |
| NULL candidato | 0 | 0 | 223 | 0 | 0 | Mantener |
| Restricciones | 0 | 0 | 223 | 0 | 0 | Mantener estado |
| NUMERIC compatible | Sí | Sí | Sí | Sí | Sí | Tipo común |
| Unidad nativa | línea | línea | servicio | línea | línea | Preservar semántica |

---

# 38. Granularidad multisistema

Se mantiene:

```text
fecha × sistema × unidad_operativa
```

Validación con cinco sistemas:

```text
69,171 registros
69,171 claves distintas
0 claves duplicadas
```

Por tanto, la clave conceptual continúa siendo única en el candidato evaluado.

---

# 39. Ventana común

La incorporación de Trolebús conserva:

```text
2022-01-01 → 2026-07-31
```

con:

```text
1,673 fechas distintas
```

Trolebús no reduce la ventana temporal común previamente establecida.

---

# 40. Resultado específico Trolebús

La compatibilidad de Trolebús queda:

```text
APROBADA
```

porque:

1. existe una unidad operativa claramente identificable;
2. `unidad_operativa = linea` está respaldado por la fuente;
3. existen 20,199 claves `fecha × linea`;
4. todas contienen exactamente 3 tipos de pago;
5. no existen NULL;
6. no existen colisiones;
7. no existen duplicados;
8. las 20,199 claves son únicas;
9. la agregación preserva valores decimales mediante `NUMERIC`;
10. no se introducen nuevas restricciones;
11. la ventana temporal común permanece sin cambios;
12. el contrato multisistema no necesita ser generalizado nuevamente.

---

# 41. Estado global

Aunque Trolebús individualmente no presenta restricciones, el contrato multisistema continúa teniendo:

```text
223
```

claves con restricción provenientes de RTP.

Por tanto:

```text
Trolebús:
APROBADO

Contrato multisistema global:
APROBADO CON RESTRICCIONES
```

---

# 42. Integración física

Estado:

```text
NO REALIZADA
```

No se creó:

```text
tabla multisistema
vista materializada multisistema
dataset processed definitivo
tabla de hechos definitiva
modelo dimensional definitivo
cubo OLAP definitivo
```

La evaluación realizada continúa siendo conceptual y diagnóstica.

---

# 43. Qué queda aprobado

Para Trolebús:

```text
fecha × linea
```

es una representación diaria válida después de agregar:

```text
tipo_pago
```

mediante:

```text
SUM(afluencia)
```

Dentro del contrato:

```text
sistema = Trolebús
unidad_operativa = linea
```

y:

```text
fecha × sistema × unidad_operativa
```

funciona como clave conceptual única.

---

# 44. Qué NO queda aprobado

No se aprueba todavía:

```text
integración física multisistema
tabla de hechos definitiva
modelo dimensional definitivo
dataset definitivo en processed/
cubo OLAP definitivo
imputación de las restricciones RTP
eliminación de las restricciones RTP
modificación de Metro
modificación de Metrobús
modificación de RTP
modificación de Cablebús
modificación de Trolebús
```

Tampoco se afirma que todas las unidades operativas de los sistemas sean operacionalmente equivalentes.

---

# 45. Estado de los pipelines individuales

```text
Metro
VALIDADO

Metrobús
VALIDADO

RTP
VALIDADO

Cablebús
VALIDADO

Trolebús
VALIDADO
```

---

# 46. Checkpoints de compatibilidad

```text
Metro ↔ Metrobús:
APROBADO CON RESTRICCIONES

RTP ↔ contrato multisistema:
APROBADO CON RESTRICCIONES

Cablebús ↔ contrato multisistema:
APROBADO

Trolebús ↔ contrato multisistema:
APROBADO
```

---

# 47. Contrato multisistema vigente

Contrato:

```text
fecha × sistema × unidad_operativa
```

Mapeo actual:

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

Medida conceptual:

```text
afluencia
```

Tipo común:

```text
NUMERIC
```

Estado:

```text
APROBADO CON RESTRICCIONES
```

---

# 48. Resumen cuantitativo

Dentro de la ventana común:

```text
Metro:        20,076
Metrobús:     11,711
RTP:          13,382
Cablebús:      3,803
Trolebús:     20,199
--------------------
Total:        69,171
```

Unicidad:

```text
69,171 registros
69,171 claves distintas
0 claves duplicadas
```

Calidad:

```text
Metro:          0 restricciones
Metrobús:       0 restricciones
RTP:          223 restricciones
Cablebús:       0 restricciones
Trolebús:       0 restricciones
```

Total:

```text
223 restricciones
```

---

# 49. Decisión final

Resultado:

```text
COMPATIBILIDAD TROLEBÚS
↔
CONTRATO MULTISISTEMA

APROBADA
```

Trolebús aporta:

```text
20,199 claves
20,199 OK
0 restricciones
```

Candidato de cinco sistemas:

```text
69,171 registros
69,171 claves distintas
0 claves duplicadas
1,673 fechas distintas
223 claves con restricción
```

Las 223 restricciones pertenecen exclusivamente a RTP.

Estado global:

```text
APROBADO CON RESTRICCIONES
```

---

# 50. Estado técnico de la Iteración 5

```text
Fuente oficial                       COMPLETADA
RAW                                  COMPLETADO
Metadata / procedencia               COMPLETADA
Inspección                           COMPLETADA
SHA-256                              COMPLETADO
Manifest                             COMPLETADO
STAGING                              VALIDADO
Perfilado                            VALIDADO
TYPED                                VALIDADO
CLEAN                                VALIDADO
Validación integral                  VALIDADA
Contrato de datos                    COMPLETADO
Checkpoint individual                APROBADO
Compatibilidad multisistema          APROBADA
```

Por tanto:

```text
ITERACIÓN 5 — TROLEBÚS

TÉCNICAMENTE COMPLETADA
```

antes de la revisión documental general y la integración Git de la rama.