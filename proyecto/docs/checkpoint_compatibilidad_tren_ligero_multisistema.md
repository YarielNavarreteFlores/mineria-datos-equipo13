# Checkpoint de compatibilidad — Tren Ligero ↔ Contrato multisistema

## 1. Identificación

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Sistema incorporado:** Tren Ligero
**Iteración:** 6
**Fecha:** 2026-11-25

**Resultado de Tren Ligero:**

```text
COMPATIBILIDAD TREN LIGERO ↔ CONTRATO MULTISISTEMA:
APROBADA CON RESTRICCIONES
```

**Estado global del contrato multisistema:**

```text
APROBADO CON RESTRICCIONES
```

Tren Ligero no introduce restricciones de calidad en la medida de afluencia.

Su restricción es exclusivamente semántica:

```text
unidad_operativa = Sistema completo
```

es una dimensión derivada para integración y no una columna publicada físicamente por la fuente.

Las 223 restricciones de calidad del candidato multisistema continúan correspondiendo exclusivamente a RTP.

---

# 2. Objetivo

Este checkpoint evalúa formalmente si Tren Ligero puede incorporarse conceptualmente al contrato multisistema vigente:

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
Tren Ligero
```

La evaluación es exclusivamente diagnóstica.

No se construye todavía una integración física multisistema.

---

# 3. Contrato multisistema previo

Después de incorporar Trolebús, el contrato vigente era:

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

Cablebús:
unidad_operativa = linea

Trolebús:
unidad_operativa = linea
```

Para Tren Ligero existe una diferencia estructural:

```text
la fuente no contiene linea,
servicio ni unidad_operativa.
```

Por tanto, se evaluó una abstracción derivada exclusivamente para integración:

```text
Tren Ligero:
unidad_operativa = Sistema completo
```

---

# 4. Pipeline individual Tren Ligero

Estado:

```text
PIPELINE INDIVIDUAL TREN LIGERO: VALIDADO
```

Checkpoint:

```text
CHECKPOINT INDIVIDUAL TREN LIGERO: APROBADO
```

Conciliación:

```text
STAGING: 3,530
TYPED:   3,530
CLEAN:   3,530
```

Pérdida:

```text
0
```

Granularidad individual:

```text
fecha × tipo_pago
```

---

# 5. Ausencia de unidad operativa física

El recurso original contiene:

```text
fecha
mes
anio
tipo_pago
afluencia
```

No contiene:

```text
linea
linea_original
servicio
unidad_operativa
```

La auditoría del pipeline individual confirmó:

```text
columnas linea/unidad_operativa artificiales: 0
```

Por tanto, ninguna dimensión operacional fue inventada dentro de RAW, STAGING, TYPED o CLEAN.

---

# 6. Hipótesis de integración evaluada

Para incorporar Tren Ligero al contrato común se evaluó:

```text
sistema = Tren Ligero
unidad_operativa = Sistema completo
```

La etiqueta:

```text
Sistema completo
```

representa una dimensión:

```text
DERIVADA EXCLUSIVAMENTE PARA INTEGRACIÓN
```

No representa una columna física de la fuente.

No debe interpretarse como una línea publicada por STE.

---

# 7. Ventana temporal estrictamente común

Se evaluaron las coberturas CLEAN de:

```text
Metro
Metrobús
RTP
Cablebús
Trolebús
Tren Ligero
```

La intersección temporal estricta obtenida es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

Por tanto, la incorporación de Tren Ligero:

```text
NO REDUCE
```

la ventana temporal común vigente.

---

# 8. Tren Ligero dentro de la ventana común

Dentro de:

```text
2022-01-01 → 2026-07-31
```

la estructura observada es:

```text
Fechas distintas:       1,673
Tipos de pago:              2
```

Cada fecha contiene:

```text
2 filas
2 tipos de pago
```

correspondientes a:

```text
Gratuidad
Prepago
```

Por tanto:

```text
1,673 × 2 = 3,346
```

observaciones detalladas dentro de la ventana común.

---

# 9. Estructura nativa

La granularidad CLEAN individual es:

```text
fecha × tipo_pago
```

Para las 1,673 fechas dentro de la ventana común se observaron:

```text
2 filas
2 tipos_pago
0 colisiones
0 duplicados
0 afluencias incompletas
```

---

# 10. Clasificación exhaustiva de fechas

Resultado:

```text
Claves totales:            1,673
Claves OK:                 1,673

Solo colisión:                 0
Solo NULL:                     0
Colisión + NULL:               0
Estructura inesperada:         0
```

Por tanto:

```text
1,673 / 1,673
```

fechas son estructuralmente completas.

---

# 11. Regla de agregación diaria

Para producir demanda diaria de Tren Ligero se evaluó:

```text
SUM(afluencia)
```

sobre:

```text
Gratuidad
+
Prepago
```

La agregación es válida porque para todas las fechas:

```text
filas = 2
tipos_pago = 2
componentes NULL = 0
colisiones = 0
```

No se realiza redondeo.

La medida permanece en dominio:

```text
NUMERIC
```

---

# 12. Candidato diario Tren Ligero

El candidato producido contiene:

```text
Registros:                 1,673
Claves distintas:          1,673
Fechas distintas:          1,673
Unidades operativas:           1

Afluencia NULL:                0
Claves con restricción:        0
```

Cobertura:

```text
2022-01-01 → 2026-07-31
```

---

# 13. Unidad operativa derivada

La única unidad operativa evaluada es:

```text
Sistema completo
```

Validación:

```text
Fechas:       1,673
Fecha mínima: 2022-01-01
Fecha máxima: 2026-07-31
```

Por tanto:

```text
unidad_operativa = Sistema completo
```

tiene cobertura completa en toda la ventana multisistema.

---

# 14. Naturaleza de la unidad derivada

La etiqueta:

```text
Sistema completo
```

NO significa:

```text
que exista una columna denominada unidad_operativa
en la fuente Tren Ligero.
```

Tampoco significa:

```text
que la fuente publique una línea denominada
Sistema completo.
```

Su propósito es permitir que la observación diaria de Tren Ligero pueda representarse dentro de la abstracción común:

```text
fecha × sistema × unidad_operativa
```

sin alterar el pipeline individual.

---

# 15. Preservación total de afluencia

Se comparó la suma de todas las observaciones originales dentro de la ventana común contra la suma del candidato diario.

Resultado:

```text
Afluencia origen:
128,678,219.683676

Afluencia candidato:
128,678,219.683676

Diferencia:
0
```

Por tanto:

```text
SUM(origen)
=
SUM(candidato)
```

No existe pérdida ni alteración de demanda.

---

# 16. Preservación por fecha

Se compararon individualmente las:

```text
1,673
```

fechas.

Resultado:

```text
Fechas comparadas:       1,673
Fechas con diferencia:       0
```

Por tanto:

```text
100 % de las fechas
preservan exactamente su afluencia
después de la agregación.
```

---

# 17. Unicidad del candidato Tren Ligero

La representación:

```text
fecha × unidad_operativa
```

produjo:

```text
Registros totales: 1,673
Claves distintas:  1,673
Claves duplicadas:     0
```

Por tanto, la representación candidata es única.

---

# 18. Mapeo al contrato común

Tren Ligero puede representarse conceptualmente mediante:

```text
sistema = Tren Ligero
unidad_operativa = Sistema completo
```

Por tanto:

```text
fecha × sistema × unidad_operativa
```

se particulariza como:

```text
fecha
×
Tren Ligero
×
Sistema completo
```

---

# 19. Restricción semántica

La compatibilidad no se clasifica simplemente como:

```text
APROBADA
```

porque:

```text
unidad_operativa
```

no está respaldada directamente por una columna física de Tren Ligero.

Por tanto, se mantiene explícitamente:

```text
APROBADA CON RESTRICCIONES
```

La restricción significa:

```text
unidad_operativa es derivada
```

y no:

```text
dato incompleto
dato inválido
NULL
colisión
duplicado
```

---

# 20. Pipeline individual preservado

La comprobación de columnas operativas artificiales produjo:

```text
0
```

Por tanto, el pipeline individual continúa sin:

```text
linea
linea_original
unidad_operativa
```

artificiales.

La derivación ocurre exclusivamente dentro de la representación candidata de integración.

---

# 21. Resultado Metro

Dentro de la ventana común:

```text
Registros:             20,076
Claves distintas:      20,076
Fechas distintas:       1,673
Unidades operativas:       12

Afluencia NULL:             0
Restricciones:              0
```

---

# 22. Resultado Metrobús

```text
Registros:             11,711
Claves distintas:      11,711
Fechas distintas:       1,673
Unidades operativas:        7

Afluencia NULL:             0
Restricciones:              0
```

---

# 23. Resultado RTP

```text
Registros:             13,382
Claves distintas:      13,382
Fechas distintas:       1,673
Unidades operativas:       21

Afluencia NULL:           223
Restricciones:            223
```

Estas restricciones ya existían antes de incorporar Tren Ligero.

---

# 24. Resultado Cablebús

```text
Registros:              3,803
Claves distintas:       3,803
Fechas distintas:       1,673
Unidades operativas:        3

Afluencia NULL:             0
Restricciones:              0
```

---

# 25. Resultado Trolebús

```text
Registros:             20,199
Claves distintas:      20,199
Fechas distintas:       1,673
Unidades operativas:       17

Afluencia NULL:             0
Restricciones:              0
```

---

# 26. Resultado Tren Ligero

```text
Registros:              1,673
Claves distintas:       1,673
Fechas distintas:       1,673
Unidades operativas:        1

Afluencia NULL:             0
Restricciones de calidad:   0
```

Claves cuya unidad operativa es derivada:

```text
1,673
```

Origen de la unidad:

```text
DERIVADA_CONSTANTE
```

---

# 27. Candidato multisistema de seis sistemas

La construcción conceptual produce:

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

Formalmente:

```text
20,076
+ 11,711
+ 13,382
+  3,803
+ 20,199
+  1,673
--------
 70,844
```

---

# 28. Validación global de la clave

Resultado:

```text
Registros totales:       70,844
Claves distintas:        70,844
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
70,844 registros
=
70,844 claves distintas
```

y:

```text
claves duplicadas = 0
```

---

# 29. Validación del contrato

La combinación:

```text
fecha × sistema × unidad_operativa
```

continúa funcionando como clave conceptual única para los seis sistemas evaluados.

Tren Ligero no obliga a modificar la estructura sintáctica del contrato.

Sin embargo, amplía la semántica de:

```text
unidad_operativa
```

porque ahora también puede representar:

```text
una unidad analítica derivada correspondiente
al sistema completo.
```

---

# 30. Evolución semántica del contrato

Antes de Tren Ligero:

```text
unidad_operativa
=
linea
o
servicio
```

Después de evaluar Tren Ligero:

```text
unidad_operativa
=
entidad operacional o analítica
que define el nivel diario comparable
dentro de cada sistema.
```

Por tanto, el contrato continúa siendo:

```text
fecha × sistema × unidad_operativa
```

pero su definición semántica debe reconocer que una unidad operativa puede ser:

```text
FUENTE
```

o:

```text
DERIVADA PARA INTEGRACIÓN
```

---

# 31. Identidad global

La identidad de una unidad continúa requiriendo:

```text
sistema × unidad_operativa
```

Ejemplos:

```text
Metro / Linea 1
≠
Cablebús / Linea 1
≠
Trolebús / Linea 1
≠
Tren Ligero / Sistema completo
```

Por tanto:

```text
sistema
```

continúa siendo indispensable.

---

# 32. Medida común

La medida conceptual continúa siendo:

```text
afluencia reportada
```

Para Tren Ligero se obtiene mediante:

```text
SUM(
    Gratuidad
    +
    Prepago
)
```

para cada fecha.

Las:

```text
1,673 / 1,673
```

fechas son completas.

---

# 33. Tipo de medida común

Tren Ligero utiliza individualmente:

```text
NUMERIC(18,12)
```

y contiene valores con componente decimal.

Por tanto, el contrato multisistema continúa requiriendo:

```text
NUMERIC
```

como dominio común de la medida.

No debe utilizarse:

```text
BIGINT
```

porque provocaría pérdida de precisión.

---

# 34. NULL

Se mantiene:

```text
NULL ≠ 0
```

Dentro del candidato multisistema:

```text
Metro:          0 NULL
Metrobús:       0 NULL
RTP:          223 NULL
Cablebús:       0 NULL
Trolebús:       0 NULL
Tren Ligero:    0 NULL
```

Total:

```text
223 NULL
```

Todos corresponden a RTP.

---

# 35. Restricciones globales

Resultado:

```text
Metro:          0
Metrobús:       0
RTP:          223
Cablebús:       0
Trolebús:       0
Tren Ligero:    0
```

Total de restricciones de calidad:

```text
223
```

Por tanto, Tren Ligero:

```text
NO incrementa
```

el número de claves con restricción de calidad.

---

# 36. Restricción propia de Tren Ligero

Aunque no añade restricciones de calidad, Tren Ligero sí posee una restricción conceptual:

```text
unidad_operativa = Sistema completo
```

es una abstracción derivada.

Por tanto deben distinguirse:

```text
restricción de calidad
```

y:

```text
restricción semántica
```

Tren Ligero:

```text
restricciones de calidad = 0
restricción semántica = 1 regla explícita
```

---

# 37. Matriz actualizada de compatibilidad

| Elemento | Metro | Metrobús | RTP | Cablebús | Trolebús | Tren Ligero | Decisión |
|---|---|---|---|---|---|---|---|
| Fecha diaria | Sí | Sí | Sí | Sí | Sí | Sí | Común |
| Sistema | Metro | Metrobús | RTP | Cablebús | Trolebús | Tren Ligero | Obligatorio |
| Línea | Sí | Sí | No universal | Sí | Sí | No | No usar sola globalmente |
| Servicio | No | No | Sí | No | No | No | Específico RTP |
| Unidad operativa | Línea | Línea | Servicio | Línea | Línea | Sistema completo | Abstracción común |
| Origen unidad | Fuente | Fuente | Fuente | Fuente | Fuente | Derivada | Conservar procedencia |
| Afluencia | Sí | Sí | Sí | Sí | Sí | Sí | Medida común |
| Tipo pago | Sí | Sí | Sí | Sí | Sí | Sí | Detalle adicional |
| NULL candidato | 0 | 0 | 223 | 0 | 0 | 0 | Mantener |
| Restricciones calidad | 0 | 0 | 223 | 0 | 0 | 0 | Mantener |
| NUMERIC compatible | Sí | Sí | Sí | Sí | Sí | Sí | Tipo común |

---

# 38. Granularidad multisistema

Se mantiene:

```text
fecha × sistema × unidad_operativa
```

Validación:

```text
70,844 registros
70,844 claves distintas
0 claves duplicadas
```

Por tanto, la clave conceptual continúa siendo única.

---

# 39. Ventana común

La incorporación de Tren Ligero conserva:

```text
2022-01-01 → 2026-07-31
```

con:

```text
1,673 fechas distintas
```

No existe reducción adicional de cobertura.

---

# 40. Resultado específico Tren Ligero

La compatibilidad queda:

```text
APROBADA CON RESTRICCIONES
```

porque:

1. existen 1,673 fechas en la ventana común;
2. cada fecha contiene exactamente 2 tipos de pago;
3. no existen NULL en la medida;
4. no existen colisiones;
5. no existen duplicados;
6. la agregación diaria produce exactamente 1,673 claves;
7. las 1,673 claves son únicas;
8. la afluencia se conserva globalmente;
9. la afluencia se conserva fecha por fecha;
10. el tipo `NUMERIC` preserva los valores decimales;
11. la ventana multisistema no se reduce;
12. no se introducen nuevas restricciones de calidad;
13. la clave global continúa siendo única;
14. el pipeline individual permanece fiel a la fuente;
15. `unidad_operativa = Sistema completo` es una dimensión derivada y debe documentarse como tal.

---

# 41. Estado global

Resultado Tren Ligero:

```text
APROBADO CON RESTRICCIONES
```

Contrato multisistema:

```text
APROBADO CON RESTRICCIONES
```

Las restricciones globales de calidad siguen siendo:

```text
223
```

y corresponden exclusivamente a RTP.

La restricción específica de Tren Ligero es semántica.

---

# 42. Integración física

Estado:

```text
NO REALIZADA
```

No se creó:

```text
tabla multisistema definitiva
vista materializada multisistema
dataset processed definitivo
tabla de hechos definitiva
modelo dimensional definitivo
cubo OLAP definitivo
```

La evaluación continúa siendo conceptual y diagnóstica.

---

# 43. Qué queda aprobado

Se aprueba conceptualmente para Tren Ligero:

```text
fecha × tipo_pago
```

como granularidad individual.

Después de agregación:

```text
fecha
```

produce una observación diaria válida.

Dentro del contrato:

```text
sistema = Tren Ligero
unidad_operativa = Sistema completo
```

con la advertencia:

```text
unidad_operativa:
DERIVADA PARA INTEGRACIÓN
```

La clave:

```text
fecha × sistema × unidad_operativa
```

continúa siendo única.

---

# 44. Qué NO queda aprobado

No se aprueba afirmar que:

```text
Sistema completo
```

sea una unidad publicada directamente por la fuente.

Tampoco queda aprobado todavía:

```text
integración física multisistema
tabla de hechos definitiva
modelo dimensional definitivo
dataset processed definitivo
cubo OLAP definitivo
```

No se modifica ningún pipeline individual.

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

Tren Ligero
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

Tren Ligero ↔ contrato multisistema:
APROBADO CON RESTRICCIONES
```

---

# 47. Contrato multisistema vigente

Contrato:

```text
fecha × sistema × unidad_operativa
```

Mapeo actualizado:

```text
Metro:
unidad_operativa = linea
origen = FUENTE

Metrobús:
unidad_operativa = linea
origen = FUENTE

RTP:
unidad_operativa = servicio
origen = FUENTE

Cablebús:
unidad_operativa = linea
origen = FUENTE

Trolebús:
unidad_operativa = linea
origen = FUENTE

Tren Ligero:
unidad_operativa = Sistema completo
origen = DERIVADA PARA INTEGRACIÓN
```

Medida:

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

Unicidad:

```text
70,844 registros
70,844 claves distintas
0 claves duplicadas
```

Cobertura:

```text
1,673 fechas
2022-01-01 → 2026-07-31
```

Calidad:

```text
Metro:            0 restricciones
Metrobús:         0 restricciones
RTP:            223 restricciones
Cablebús:         0 restricciones
Trolebús:         0 restricciones
Tren Ligero:      0 restricciones de calidad
```

Total:

```text
223 restricciones de calidad
```

---

# 49. Decisión final

Resultado:

```text
COMPATIBILIDAD TREN LIGERO
↔
CONTRATO MULTISISTEMA

APROBADA CON RESTRICCIONES
```

Tren Ligero aporta:

```text
1,673 claves
1,673 estructuralmente OK
0 NULL
0 duplicadas
0 restricciones de calidad
```

Unidad operativa:

```text
Sistema completo
```

Origen:

```text
DERIVADA PARA INTEGRACIÓN
```

Candidato de seis sistemas:

```text
70,844 registros
70,844 claves distintas
0 claves duplicadas
1,673 fechas distintas
223 claves con restricción de calidad
```

Estado global:

```text
APROBADO CON RESTRICCIONES
```

---

# 50. Estado técnico de la Iteración 6

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
Compatibilidad multisistema          APROBADA CON RESTRICCIONES
```

Por tanto:

```text
ITERACIÓN 6 — TREN LIGERO

TÉCNICAMENTE COMPLETADA
```

antes de la revisión documental general, actualización del README e integración Git de la rama.