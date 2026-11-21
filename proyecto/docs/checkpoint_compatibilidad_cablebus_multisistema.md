# Checkpoint de compatibilidad — Cablebús ↔ Contrato multisistema preliminar

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema incorporado:** Cablebús
**Iteración:** 4
**Fecha:** 2026-11-12

**Resultado de Cablebús:**

```text
COMPATIBILIDAD CABLEBÚS ↔ CONTRATO MULTISISTEMA:
APROBADA
```

**Estado global del contrato multisistema:**

```text
APROBADO CON RESTRICCIONES
```

Las restricciones globales existentes corresponden a RTP y no son introducidas por Cablebús.

---

# 2. Objetivo

Este checkpoint evalúa si Cablebús puede incorporarse conceptualmente al contrato multisistema preliminar vigente:

```text
fecha × sistema × unidad_operativa
```

sin modificar los pipelines individuales previamente validados de:

```text
Metro
Metrobús
RTP
Cablebús
```

El análisis es exclusivamente diagnóstico.

No se construye todavía una integración física multisistema.

---

# 3. Contrato previo

Después de la incorporación de RTP, el contrato multisistema preliminar vigente quedó establecido como:

```text
fecha × sistema × unidad_operativa
```

Mapeo:

```text
Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio
```

Para Cablebús se evaluó:

```text
unidad_operativa = linea
```

---

# 4. Fuente Cablebús

Recurso validado:

```text
Afluencia Diaria Cablebus (Desglosada)
```

Fuente:

```text
Portal de Datos Abiertos de la Ciudad de México
```

Mantenedor:

```text
Secretaría de Movilidad de la Ciudad de México
```

El pipeline individual de Cablebús fue validado previamente.

---

# 5. Pipeline individual Cablebús

Estado:

```text
PIPELINE INDIVIDUAL CABLEBÚS: VALIDADO
```

Conciliación:

```text
STAGING: 7,972
TYPED:   7,972
CLEAN:   7,972
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

# 6. Ventana temporal estrictamente común

Se evaluaron las coberturas CLEAN de:

```text
Metro
Metrobús
RTP
Cablebús
```

La intersección temporal estricta es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

Por tanto, la incorporación de Cablebús:

```text
NO modifica
```

la ventana común establecida previamente con RTP.

---

# 7. Cablebús dentro de la ventana común

Dentro del periodo:

```text
2022-01-01 → 2026-07-31
```

Cablebús contiene:

```text
Registros detallados:       7,606
Fechas distintas:           1,673
Líneas lógicas:                 3
Tipos de pago:                  2
```

Calidad:

```text
Afluencia NULL:              0
Afluencia cero:            179
Filas con colisión:          0
Duplicados exactos:          0
Outliers origen:             0
```

---

# 8. Estructura nativa Cablebús

La granularidad CLEAN individual es:

```text
fecha × linea × tipo_pago
```

Los tipos de pago son:

```text
Gratuidad
Prepago
```

Para cada combinación normal:

```text
fecha × linea
```

se observaron exactamente:

```text
2 filas
2 tipos de pago
```

---

# 9. Claves fecha × linea

Dentro de la ventana común se identificaron:

```text
3,803
```

claves distintas:

```text
fecha × linea
```

Estructura:

```text
2 filas
2 tipos_pago
3,803 claves
```

Controles:

```text
Claves con colisión:             0
Claves con duplicado:            0
Claves con afluencia incompleta: 0
```

---

# 10. Clasificación exhaustiva

Las 3,803 claves fueron clasificadas.

Resultado:

```text
Claves totales:            3,803
Claves OK:                 3,803

Solo colisión:                 0
Solo NULL:                     0
Colisión + NULL:               0
Estructura inesperada:         0
```

Por tanto:

```text
100 % de las claves Cablebús
son estructuralmente seguras y completas
dentro de la ventana común.
```

---

# 11. Regla de agregación Cablebús

Para obtener demanda diaria por línea se evaluó:

```text
SUM(afluencia)
```

sobre:

```text
Gratuidad
+
Prepago
```

La agregación es válida porque para las 3,803 claves:

```text
filas = 2
tipos_pago = 2
componentes NULL = 0
colisiones = 0
```

---

# 12. Candidato diario Cablebús

El candidato agregado produjo:

```text
Registros:             3,803
Claves distintas:      3,803
Fechas distintas:      1,673
Unidades operativas:       3
Afluencia NULL:             0
Restricciones:              0
```

Cobertura:

```text
2022-01-01 → 2026-07-31
```

---

# 13. Cobertura por unidad operativa

## Linea 1

```text
Claves totales:  1,673
Claves seguras:  1,673

Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 2

```text
Claves totales:  1,673
Claves seguras:  1,673

Cobertura:
2022-01-01 → 2026-07-31
```

## Linea 3

```text
Claves totales:    457
Claves seguras:    457

Cobertura:
2025-05-01 → 2026-07-31
```

No debe esperarse que Linea 3 tenga registros anteriores a su periodo observado.

---

# 14. Unicidad del candidato Cablebús

La representación:

```text
fecha × unidad_operativa
```

produjo:

```text
Registros totales: 3,803
Claves distintas:  3,803
Claves duplicadas:     0
```

Por tanto:

```text
fecha × linea
```

es una granularidad válida para representar la demanda diaria agregada de Cablebús dentro del candidato multisistema.

---

# 15. Mapeo al contrato común

Cablebús puede representarse mediante:

```text
sistema = Cablebús
unidad_operativa = linea
```

Por tanto:

```text
fecha × sistema × unidad_operativa
```

se transforma para Cablebús en:

```text
fecha × Cablebús × linea
```

---

# 16. Semántica de unidad_operativa

`unidad_operativa` continúa siendo una abstracción analítica.

No significa que:

```text
linea de Metro
linea de Metrobús
servicio de RTP
linea de Cablebús
```

sean entidades operacionalmente idénticas.

La semántica específica se conserva mediante:

```text
sistema
```

y trazabilidad hacia cada pipeline individual.

---

# 17. Resultado Metro

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

# 18. Resultado Metrobús

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

# 19. Resultado RTP

Dentro de la ventana común:

```text
Registros:               13,382
Claves distintas:        13,382
Fechas distintas:         1,673
Unidades operativas:         21
Afluencia NULL:             223
Claves con restricción:     223
```

Las 223 restricciones corresponden a:

```text
92 COLISION
131 AFLUENCIA_INCOMPLETA
```

Estas restricciones ya estaban documentadas antes de incorporar Cablebús.

---

# 20. Resultado Cablebús

Dentro de la ventana común:

```text
Registros:                3,803
Claves distintas:         3,803
Fechas distintas:         1,673
Unidades operativas:          3
Afluencia NULL:               0
Claves con restricción:       0
```

Cablebús no añade claves problemáticas al contrato.

---

# 21. Candidato multisistema de cuatro sistemas

La construcción conceptual produce:

```text
Metro:       20,076
Metrobús:    11,711
RTP:         13,382
Cablebús:     3,803
```

Total:

```text
20,076
+ 11,711
+ 13,382
+  3,803
--------
 48,972
```

---

# 22. Validación global de la clave

La construcción conceptual produjo:

```text
Registros totales:       48,972
Claves distintas:        48,972
Claves duplicadas:            0

Fechas distintas:         1,673
Fecha mínima:       2022-01-01
Fecha máxima:       2026-07-31

Afluencia NULL:            223
Claves con restricción:    223
```

Por tanto:

```text
48,972 registros
=
48,972 claves distintas
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

continúa funcionando como clave conceptual única para los cuatro sistemas evaluados.

Cablebús no obliga a modificar la estructura del contrato preliminar.

---

# 24. Evolución del contrato

El contrato previo a RTP:

```text
fecha × sistema × linea
```

fue generalizado a:

```text
fecha × sistema × unidad_operativa
```

para admitir RTP.

Cablebús puede incorporarse directamente a esta abstracción mediante:

```text
unidad_operativa = linea
```

Por tanto:

```text
NO se requiere una nueva generalización
del contrato por Cablebús.
```

---

# 25. Identidad de las unidades operativas

La identidad de una unidad continúa requiriendo:

```text
sistema × unidad_operativa
```

Una etiqueta como:

```text
Linea 1
```

no identifica globalmente una entidad.

Ejemplo conceptual:

```text
Metro / Linea 1
≠
Cablebús / Linea 1
```

aunque las etiquetas puedan parecer similares.

---

# 26. Medida común

La medida conceptual continúa siendo:

```text
afluencia reportada
```

Para Cablebús se obtiene mediante:

```text
SUM(Gratuidad + Prepago)
```

cuando la clave se encuentra completa.

En el periodo evaluado todas las claves Cablebús son completas.

---

# 27. Tipo de medida común

Cablebús utiliza individualmente:

```text
BIGINT
```

El contrato multisistema debe continuar utilizando:

```text
NUMERIC
```

porque otros sistemas contienen valores decimales.

La promoción:

```text
BIGINT → NUMERIC
```

para Cablebús no genera pérdida de información.

---

# 28. NULL

Se mantiene:

```text
NULL ≠ 0
```

Dentro del candidato de cuatro sistemas:

```text
Metro:       0 NULL
Metrobús:    0 NULL
Cablebús:    0 NULL
RTP:       223 NULL
```

Los 223 NULL pertenecen al candidato RTP y representan restricciones conocidas.

---

# 29. Ceros

Los ceros continúan siendo valores válidos.

Cablebús presenta dentro de la ventana común:

```text
179
```

filas detalladas con afluencia igual a cero.

Estos valores no deben interpretarse como faltantes.

---

# 30. Tipo de pago

Cablebús contiene:

```text
Gratuidad
Prepago
```

El detalle:

```text
tipo_pago
```

permanece disponible en el pipeline individual.

Para el núcleo multisistema se agrega desde:

```text
fecha × linea × tipo_pago
```

hacia:

```text
fecha × linea
```

No se destruye el nivel detallado original.

---

# 31. Colisiones

Cablebús:

```text
0 colisiones
```

antes de agregación.

Después de homologación:

```text
0 colisiones
```

En el candidato diario:

```text
0 claves con colisión
```

No se requiere política especial adicional para Cablebús.

---

# 32. Duplicados

Cablebús presenta:

```text
0 duplicados exactos
```

No se eliminó ninguna observación.

---

# 33. Outliers

El pipeline individual Cablebús identificó:

```text
0 outliers IQR globales
```

Esto no significa que deba utilizarse una única definición global de outlier para todos los sistemas.

Las reglas de outliers permanecen específicas de cada pipeline.

---

# 34. Estados de calidad

El contrato multisistema conserva el concepto:

```text
estado_calidad
```

Cablebús dentro de la ventana evaluada tiene:

```text
3,803 OK
0 COLISION
0 AFLUENCIA_INCOMPLETA
0 COLISION_Y_NULL
0 ESTRUCTURA_INESPERADA
```

---

# 35. Restricciones globales

Las restricciones globales permanecen:

```text
223
```

y pertenecen únicamente a RTP.

Distribución:

```text
RTP:
92 COLISION
131 AFLUENCIA_INCOMPLETA
```

Cablebús:

```text
0 restricciones
```

---

# 36. Matriz actualizada de compatibilidad

| Elemento | Metro | Metrobús | RTP | Cablebús | Decisión |
|---|---|---|---|---|---|
| Fecha diaria | Sí | Sí | Sí | Sí | Común |
| Sistema | Metro | Metrobús | RTP | Cablebús | Obligatorio |
| Línea | Sí | Sí | No universal | Sí | No usar sola globalmente |
| Servicio | No | No | Sí | No | Específico RTP |
| Unidad operativa | Línea | Línea | Servicio | Línea | Abstracción común |
| Afluencia | Sí | Sí | Sí | Sí | Medida común |
| Tipo pago | Sí | Sí | Sí | Sí | Detalle adicional |
| Estación | Sí | No | No | No | Específica Metro |
| NULL candidato | 0 | 0 | 223 | 0 | Mantener |
| Colisiones candidato | 0 | 0 | 92 | 0 | Marcar |
| Incompletas | 0 | 0 | 131 | 0 | Mantener NULL |
| NUMERIC compatible | Sí | Sí | Sí | Sí | Tipo común |
| Unidad nativa | línea | línea | servicio | línea | Preservar semántica |

---

# 37. Granularidad multisistema preliminar

Se mantiene:

```text
fecha × sistema × unidad_operativa
```

Validación con cuatro sistemas:

```text
48,972 registros
48,972 claves distintas
0 claves duplicadas
```

---

# 38. Ventana común

Se mantiene:

```text
2022-01-01 → 2026-07-31
```

Fechas:

```text
1,673
```

Cablebús no reduce la ventana común vigente.

---

# 39. Resultado específico Cablebús

La compatibilidad de Cablebús queda:

```text
APROBADA
```

porque:

1. existe una unidad operativa claramente identificable;
2. `unidad_operativa = linea` está respaldado por la fuente;
3. la agregación diaria es estructuralmente completa;
4. no existen NULL;
5. no existen colisiones;
6. no existen duplicados;
7. las 3,803 claves son únicas;
8. no se introducen nuevas restricciones.

---

# 40. Estado global

Aunque Cablebús individualmente no presenta restricciones, el contrato multisistema completo conserva:

```text
APROBADO CON RESTRICCIONES
```

debido a RTP.

Por tanto:

```text
Cablebús:
APROBADO

Contrato multisistema global:
APROBADO CON RESTRICCIONES
```

---

# 41. Integración física

Estado:

```text
NO REALIZADA
```

No se creó:

```text
tabla multisistema
vista materializada
dataset processed
tabla de hechos
modelo dimensional
cubo OLAP
```

---

# 42. Qué queda aprobado

Para Cablebús:

```text
fecha × linea
```

es una representación diaria válida después de agregar `tipo_pago`.

Dentro del contrato:

```text
sistema = Cablebús
unidad_operativa = linea
```

y:

```text
fecha × sistema × unidad_operativa
```

funciona como clave conceptual única.

---

# 43. Qué NO queda aprobado

No se aprueba todavía:

- integración física multisistema;
- tabla de hechos definitiva;
- modelo dimensional definitivo;
- dataset definitivo en `processed/`;
- eliminación de las restricciones RTP;
- imputación de valores RTP;
- modificación de Metro;
- modificación de Metrobús;
- modificación de RTP;
- reinterpretar todas las unidades operativas como conceptos idénticos.

---

# 44. Estado actual del proyecto

```text
Metro
Pipeline individual:
VALIDADO

Metrobús
Pipeline individual:
VALIDADO

RTP
Pipeline individual:
VALIDADO

Cablebús
Pipeline individual:
VALIDADO
```

Checkpoints:

```text
Metro ↔ Metrobús:
APROBADO CON RESTRICCIONES

RTP ↔ contrato multisistema:
APROBADO CON RESTRICCIONES

Cablebús ↔ contrato multisistema:
APROBADO
```

Contrato global:

```text
fecha × sistema × unidad_operativa
```

Estado global:

```text
APROBADO CON RESTRICCIONES
```

---

# 45. Decisión final

Resultado:

```text
COMPATIBILIDAD CABLEBÚS
↔
CONTRATO MULTISISTEMA PRELIMINAR

APROBADA
```

Cablebús aporta:

```text
3,803 claves
3,803 OK
0 restricciones
```

Candidato de cuatro sistemas:

```text
48,972 registros
48,972 claves distintas
0 claves duplicadas
1,673 fechas distintas
223 claves con restricción
```

Las 223 restricciones pertenecen únicamente a RTP.

---

# 46. Punto exacto de continuación

Con este checkpoint queda cerrada la evaluación técnica de compatibilidad de Cablebús.

Antes de integrar la Iteración 4 en `main` todavía deberán revisarse:

```text
metadata Cablebús
contrato de datos Cablebús
checkpoint individual Cablebús
scripts SQL Cablebús
script de compatibilidad
checkpoint de compatibilidad
README general
proyecto/README.md
```

No debe realizarse todavía una integración física multisistema.