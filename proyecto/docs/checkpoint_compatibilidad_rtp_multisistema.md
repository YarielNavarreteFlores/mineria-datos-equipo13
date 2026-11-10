# Checkpoint de compatibilidad analítica — RTP ↔ contrato multisistema preliminar

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Equipo:** 13
**Unidad de aprendizaje:** Minería de Datos
**Iteración:** 3 — RTP
**Estado:** APROBADO CON RESTRICCIONES

---

# 1. Propósito

Este documento registra la evaluación de compatibilidad analítica de la Red de Transporte de Pasajeros de la Ciudad de México (RTP) contra el contrato multisistema preliminar previamente establecido durante el checkpoint:

```text
Metro ↔ Metrobús
```

El objetivo es determinar si RTP puede incorporarse conceptualmente a una futura capa analítica multisistema sin:

- modificar su pipeline individual;
- eliminar observaciones;
- resolver artificialmente colisiones;
- convertir valores faltantes a cero;
- forzar `servicio` a representar una `linea`;
- construir todavía una integración física;
- construir todavía una tabla de hechos definitiva.

El checkpoint es exclusivamente diagnóstico.

---

# 2. Estado previo

Antes de esta evaluación se encontraban validados:

```text
Metro
Pipeline individual:
VALIDADO

Metrobús
Pipeline individual:
VALIDADO

Compatibilidad Metro ↔ Metrobús:
APROBADA CON RESTRICCIONES

RTP
Pipeline individual:
VALIDADO
```

El checkpoint Metro ↔ Metrobús había establecido provisionalmente como granularidad multisistema:

```text
fecha × sistema × linea
```

con ventana temporal:

```text
2021-01-01 → 2026-07-31
```

La incorporación de RTP obliga a reevaluar ese contrato porque RTP no posee una columna física `linea`.

---

# 3. Pipeline individual RTP

RTP completó:

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
↓
CONTRATO DE DATOS
↓
CHECKPOINT INDIVIDUAL
```

Resultado:

```text
PIPELINE INDIVIDUAL RTP: VALIDADO
```

Contrato individual:

```text
proyecto/docs/contrato_datos_rtp.md
```

Checkpoint individual:

```text
proyecto/docs/checkpoint_rtp.md
```

---

# 4. Script de diagnóstico

El análisis de compatibilidad se implementó en:

```text
proyecto/sql/quality/compatibilidad/02_compatibilidad_rtp_contrato_preliminar.sql
```

El script fue diseñado exclusivamente para lectura.

No ejecuta:

```text
CREATE TABLE
INSERT
UPDATE
DELETE
```

Los bloques diagnósticos utilizan:

```text
BEGIN TRANSACTION READ ONLY;
```

por lo que Metro, Metrobús y RTP permanecen sin modificaciones.

---

# 5. Contrato multisistema anterior

Durante el checkpoint Metro ↔ Metrobús se había validado preliminarmente:

```text
fecha × sistema × linea
```

porque ambos sistemas contenían una dimensión denominada `linea`.

Mapeo:

```text
Metro
→ linea

Metrobús
→ linea
```

La inclusión de:

```text
sistema
```

era obligatoria porque una misma etiqueta textual de línea no identifica la misma entidad operacional entre sistemas.

Ejemplo:

```text
Metro — Línea 1
≠
Metrobús — Línea 1
```

---

# 6. Problema introducido por RTP

El recurso validado de RTP contiene:

```text
fecha
mes
anio
servicio
tipo_pago
afluencia
```

No contiene:

```text
linea
```

El campo:

```text
servicio
```

incluye categorías como:

```text
Atenea
Ecoatenea
Ecobús
Expdirecto
Expreso
Nochebús
Ordinario
S/Metro
Servicios Temporales
Apoyo Metro L1
Circuito Hospitales
Centrobus
```

Por tanto:

```text
servicio = linea
```

no puede declararse.

La equivalencia no está respaldada por la fuente.

---

# 7. Necesidad de una abstracción más general

Para incorporar sistemas con estructuras operativas distintas se evaluó una dimensión conceptual común:

```text
unidad_operativa
```

Mapeo propuesto:

```text
Metro
unidad_operativa = linea

Metrobús
unidad_operativa = linea

RTP
unidad_operativa = servicio
```

La abstracción:

```text
unidad_operativa
```

no afirma equivalencia semántica entre `linea` y `servicio`.

Representa únicamente la unidad operacional con la cual cada fuente publica su demanda diaria en el nivel seleccionado.

---

# 8. Ventana temporal común

Coberturas disponibles:

```text
Metro:
hasta 2026-07-31

Metrobús:
hasta 2026-09-30

RTP:
2022-01-01 → 2026-09-30
```

La intersección estricta de los tres sistemas es:

```text
2022-01-01 → 2026-07-31
```

Fechas distintas:

```text
1,673
```

Esta ventana reemplaza para el análisis de tres sistemas a la ventana previa:

```text
2021-01-01 → 2026-07-31
```

utilizada únicamente para Metro y Metrobús.

---

# 9. RTP dentro de la ventana común

RTP contiene en la ventana:

```text
Registros CLEAN:               40,422
Fechas distintas:               1,673
Servicios distintos:               21
Tipos de pago:                       3
```

Calidad:

```text
Afluencia NULL:                   187
Afluencia cero:                 7,032
Filas con colisión:               552
Filas duplicadas exactas:         162
Outliers de origen:             4,516
```

Estas banderas pertenecen al pipeline individual RTP y se conservan como trazabilidad.

---

# 10. Estructura nativa de RTP

El nivel observado antes de agregación es:

```text
fecha × servicio × tipo_pago
```

Los tipos de pago son:

```text
Boleto
Gratuidad
Prepago
```

La estructura habitual de una combinación:

```text
fecha × servicio
```

es:

```text
3 filas
3 tipos de pago
```

Sin embargo, existen excepciones asociadas principalmente con la anomalía documentada de ATENEA.

---

# 11. Claves fecha × servicio

Dentro de la ventana común se identificaron:

```text
13,382
```

claves distintas:

```text
fecha × servicio
```

Distribución estructural:

```text
13,290 claves:
3 filas
3 tipos de pago

92 claves:
6 filas
3 tipos de pago
```

Las 92 claves de seis filas corresponden a las colisiones ya documentadas en el pipeline individual de RTP.

---

# 12. Evaluación inicial de agregación

Para representar demanda diaria por servicio se evaluó:

```text
SUM(Boleto + Gratuidad + Prepago)
```

La suma únicamente puede considerarse completa cuando:

- existen los tres tipos de pago;
- cada componente posee una afluencia disponible;
- la clave no contiene colisiones.

No debe realizarse una suma indiscriminada porque PostgreSQL:

```text
SUM()
```

ignora los valores `NULL`.

Por ejemplo:

```text
Boleto = 9,063
Gratuidad = 3,010
Prepago = NULL
```

no debe producir artificialmente:

```text
12,073
```

como si fuera la afluencia total diaria.

La afluencia completa es desconocida.

---

# 13. Clasificación exhaustiva de las claves RTP

Las 13,382 claves se clasificaron de forma exhaustiva:

```text
Claves totales:                 13,382

Seguras y completas:            13,159

Solo colisión:                      92

Solo afluencia incompleta:         131

Colisión + NULL:                      0
```

Control:

```text
13,159
+   92
+  131
+    0
-------
13,382
```

No existe solapamiento entre las claves con colisión y las claves con afluencia incompleta.

---

# 14. Claves con afluencia incompleta

Se identificaron:

```text
131
```

claves:

```text
fecha × servicio
```

con al menos un componente de afluencia `NULL`.

Distribución por cantidad de componentes NULL:

```text
101 claves
→ 1 componente NULL
→ 101 filas NULL

4 claves
→ 2 componentes NULL
→ 8 filas NULL

26 claves
→ 3 componentes NULL
→ 78 filas NULL
```

Total:

```text
101 + 8 + 78
=
187 filas NULL
```

El resultado reconcilia exactamente los 187 valores no disponibles del pipeline RTP.

---

# 15. NULL por tipo de pago

Distribución:

```text
Boleto:
30 NULL

Gratuidad:
26 NULL

Prepago:
131 NULL
```

Todas las 131 claves con afluencia incompleta presentan:

```text
Prepago = NULL
```

en al menos una observación.

Por esta razón no se puede calcular una afluencia total diaria completa para dichas claves.

---

# 16. Servicios afectados por NULL

Las claves incompletas se concentran en:

```text
Atenea:
55 claves
55 componentes NULL

Servicios Temporales:
42 claves
42 componentes NULL

Ecoatenea:
28 claves
80 componentes NULL

Expdirecto:
4 claves
8 componentes NULL

Nochebús:
2 claves
2 componentes NULL
```

Los faltantes se concentran principalmente entre:

```text
febrero de 2023
y
marzo de 2023
```

No se imputaron.

---

# 17. Colisiones RTP

Las colisiones conocidas permanecen:

```text
92 claves fecha × servicio
```

equivalentes a:

```text
276 claves fecha × servicio × tipo_pago
552 filas
```

Todas pertenecen a:

```text
Atenea
```

y se concentran en:

```text
septiembre 2024
julio 2025
enero 2026
```

No existe evidencia suficiente para:

- sumar las dos observaciones;
- conservar solo una;
- utilizar máximo;
- utilizar mínimo;
- eliminar duplicados indiscriminadamente.

Por tanto, esas claves no reciben una afluencia agregada automática.

---

# 18. Candidato seguro RTP

Se definió como clave segura:

```text
fecha × servicio
```

cuando cumple simultáneamente:

```text
3 filas
3 tipos de pago
0 componentes NULL
0 colisiones
```

Resultado:

```text
13,159
```

claves seguras y completas.

La agregación:

```text
SUM(afluencia)
```

sobre estas claves produjo:

```text
13,159 registros
13,159 claves distintas
0 afluencias NULL
21 servicios representados
```

Por tanto, la suma es válida para estas claves.

---

# 19. Preservación de claves problemáticas

No se decidió eliminar:

```text
92 claves con colisión
131 claves incompletas
```

En lugar de eliminarlas, la representación analítica candidata mantiene todas las:

```text
13,382
```

claves RTP.

La afluencia se calcula únicamente para claves seguras.

Para las demás:

```text
afluencia = NULL
```

y se incorpora una clasificación explícita de calidad.

---

# 20. Estados de calidad RTP propuestos

Los estados conceptuales evaluados fueron:

```text
OK
COLISION
AFLUENCIA_INCOMPLETA
COLISION_Y_NULL
ESTRUCTURA_INESPERADA
```

Resultados:

| Estado | Claves |
|---|---:|
| OK | 13,159 |
| COLISION | 92 |
| AFLUENCIA_INCOMPLETA | 131 |
| COLISION_Y_NULL | 0 |
| ESTRUCTURA_INESPERADA | 0 |

Por tanto:

```text
223
```

claves RTP presentan una restricción para calcular demanda diaria agregada.

---

# 21. Representación RTP candidata

La representación conceptual validada para el checkpoint es:

```text
sistema = RTP
fecha
unidad_operativa = servicio
afluencia
estado_calidad
```

Regla de afluencia:

```text
SI
estructura completa
AND
sin NULL
AND
sin colisión

ENTONCES

afluencia =
SUM(Boleto + Gratuidad + Prepago)
```

En cualquier caso problemático:

```text
afluencia = NULL
```

con la causa indicada en:

```text
estado_calidad
```

---

# 22. Cobertura de los servicios RTP

La cobertura no es homogénea entre servicios.

Algunos servicios poseen cobertura extensa:

```text
Expreso
Ordinario
Atenea
Expdirecto
```

Otros corresponden a ventanas parciales o temporales:

```text
Apoyo Metro L1
Circuito Hospitales
Expreso Directo
Circuito Hospitales $8.00
Apoyo Concesionado
CENTROBUS
```

Por tanto, no debe imponerse una expectativa de cobertura:

```text
1,673 días × 21 servicios
```

RTP no representa una matriz completa fija de 21 servicios durante toda la ventana.

La disponibilidad de cada servicio depende de su periodo operativo observado.

---

# 23. Contrato multisistema generalizado

Se evaluó la granularidad:

```text
fecha × sistema × unidad_operativa
```

con:

```text
Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio
```

La nueva abstracción permite preservar las diferencias estructurales sin modificar los datos de origen.

---

# 24. Resultado por sistema

En la ventana:

```text
2022-01-01 → 2026-07-31
```

se obtuvo:

## Metro

```text
Registros:               20,076
Claves distintas:        20,076
Fechas distintas:         1,673
Unidades operativas:         12
Afluencia NULL:               0
Claves con restricción:       0
```

## Metrobús

```text
Registros:               11,711
Claves distintas:        11,711
Fechas distintas:         1,673
Unidades operativas:          7
Afluencia NULL:               0
Claves con restricción:       0
```

## RTP

```text
Registros:               13,382
Claves distintas:        13,382
Fechas distintas:         1,673
Unidades operativas:         21
Afluencia NULL:             223
Claves con restricción:     223
```

---

# 25. Validación global de la clave

La construcción conceptual de los tres sistemas produjo:

```text
Registros totales:        45,169
Claves distintas:         45,169
Claves duplicadas:             0
Fechas distintas:          1,673
Fecha mínima:        2022-01-01
Fecha máxima:        2026-07-31
Afluencia NULL:             223
Claves con restricción:     223
```

Por tanto:

```text
45,169 registros
=
45,169 claves distintas
```

y:

```text
claves duplicadas = 0
```

La combinación:

```text
fecha × sistema × unidad_operativa
```

funciona como clave única dentro del candidato multisistema evaluado.

---

# 26. Evolución del contrato multisistema

El contrato anterior:

```text
fecha × sistema × linea
```

era válido para:

```text
Metro + Metrobús
```

pero no es suficientemente general para incorporar RTP.

Se reemplaza conceptualmente, para el contrato multisistema preliminar ampliado, por:

```text
fecha × sistema × unidad_operativa
```

La modificación no invalida el checkpoint previo.

Dentro de Metro y Metrobús:

```text
unidad_operativa = linea
```

por lo que el contrato anterior se mantiene como caso particular del nuevo.

---

# 27. Semántica de unidad_operativa

`unidad_operativa` es una abstracción analítica.

No significa que:

```text
linea
```

y:

```text
servicio
```

sean conceptos idénticos.

Su función es proporcionar un identificador de la unidad operacional utilizada por la fuente para reportar afluencia diaria en el nivel seleccionado.

La semántica específica debe mantenerse mediante:

```text
sistema
```

y trazabilidad hacia la fuente.

---

# 28. Identidad de unidad_operativa

Una unidad operativa no puede identificarse globalmente únicamente por su etiqueta.

La identidad mínima requiere:

```text
sistema × unidad_operativa
```

Por ejemplo, cualquier coincidencia textual entre dos sistemas no implica que representen la misma entidad.

Por tanto:

```text
unidad_operativa
```

no debe utilizarse como identificador independiente.

---

# 29. Medida común

Se mantiene como concepto común:

```text
afluencia reportada
```

La medida debe utilizar tipo:

```text
NUMERIC
```

porque los pipelines validados incluyen valores decimales.

La medida no debe reinterpretarse como:

```text
pasajeros únicos
usuarios únicos
viajes completos
```

sin evidencia adicional.

---

# 30. Política común para valores faltantes

Se mantiene la regla:

```text
NULL ≠ 0
```

En el candidato multisistema:

```text
Metro:
0 NULL

Metrobús:
0 NULL

RTP:
223 NULL
```

Los NULL de RTP en este nivel representan:

```text
131 claves con componentes incompletos
+
92 claves cuya agregación no puede resolverse por colisión
```

No deben imputarse automáticamente.

---

# 31. Política para colisiones RTP

Las colisiones no se eliminan.

En la representación agregada:

```text
estado_calidad = COLISION
```

y:

```text
afluencia = NULL
```

hasta disponer de evidencia suficiente para resolverlas.

Esto evita introducir una cifra de demanda potencialmente incorrecta.

---

# 32. Política para afluencia incompleta

Cuando alguno de los componentes requeridos:

```text
Boleto
Gratuidad
Prepago
```

no está disponible:

```text
estado_calidad =
AFLUENCIA_INCOMPLETA
```

y:

```text
afluencia = NULL
```

No se utiliza la suma parcial de los componentes disponibles como total diario.

---

# 33. Política para ceros

Los ceros permanecen diferenciados de los NULL.

En RTP existen ceros válidos en los componentes de tipo de pago.

Una suma completa puede resultar legítimamente en:

```text
0
```

si sus tres componentes válidos son cero.

Esto es distinto de una clave cuya demanda completa no puede calcularse.

---

# 34. Tipo de pago

RTP contiene:

```text
Boleto
Gratuidad
Prepago
```

Metro también contiene estas categorías.

Metrobús Desglosada contiene:

```text
Gratuidad
Prepago
```

`tipo_pago` permanece como dimensión de detalle.

No se incorpora obligatoriamente a la clave del núcleo multisistema:

```text
fecha × sistema × unidad_operativa
```

---

# 35. Estación

La dimensión:

```text
estacion
```

permanece específica de Metro.

Metro debe agregarse desde:

```text
fecha × linea × estacion
```

hacia:

```text
fecha × linea
```

para participar en el núcleo común.

Las capas originales detalladas permanecen preservadas.

---

# 36. Banderas de calidad

Las banderas de los pipelines individuales mantienen trazabilidad con su sistema de origen.

No deben interpretarse necesariamente de manera idéntica entre sistemas.

La futura representación común debería disponer al menos de un concepto equivalente a:

```text
estado_calidad
```

para indicar si la medida agregada es:

```text
OK
COLISION
AFLUENCIA_INCOMPLETA
```

u otra categoría validada posteriormente.

---

# 37. Outliers

Los outliers individuales fueron calculados sobre distribuciones y granularidades distintas.

Por tanto, no se deben trasladar automáticamente como una única definición común.

Las banderas existentes deben mantenerse como trazabilidad.

Si posteriormente se requiere detectar outliers multisistema, deberán recalcularse en la granularidad analítica correspondiente.

---

# 38. Matriz actualizada de compatibilidad

| Elemento | Metro | Metrobús | RTP | Decisión |
|---|---|---|---|---|
| Fecha diaria | Sí | Sí | Sí | Dimensión común |
| Sistema | Metro | Metrobús | RTP | Obligatorio |
| Línea | Sí | Sí | No demostrada | No usar como concepto universal |
| Servicio | No | No | Sí | Específico de RTP |
| Unidad operativa | Línea | Línea | Servicio | Abstracción común |
| Afluencia | Sí | Sí | Sí | Medida común con restricciones |
| Tipo de pago | Sí | Sí | Sí | Detalle adicional |
| Estación | Sí | No | No | Específica de Metro |
| NULL | 0 en ventana | 0 en ventana | 223 en candidato | Mantener |
| Ceros | Sí | según recurso | Sí | Mantener |
| Colisiones relevantes | No en ventana común agregada | No | 92 claves | Marcar, no resolver |
| Afluencia incompleta | No | No | 131 claves | Mantener como NULL |
| NUMERIC | Compatible | Necesario | Necesario | Tipo común |
| Clave propuesta | fecha+sistema+unidad_operativa | | | Validada preliminarmente |

---

# 39. Granularidad multisistema preliminar actualizada

Se aprueba preliminarmente:

```text
fecha × sistema × unidad_operativa
```

como clave conceptual común para la futura representación de afluencia diaria.

Resultado observado:

```text
45,169 registros
45,169 claves distintas
0 claves duplicadas
```

Ventana:

```text
2022-01-01 → 2026-07-31
```

---

# 40. Restricciones de RTP

La aprobación de RTP está condicionada a preservar:

```text
92 claves COLISION
131 claves AFLUENCIA_INCOMPLETA
```

Total:

```text
223 claves con restricción
```

Para estas claves:

```text
afluencia = NULL
```

en el candidato agregado.

No deben eliminarse para aparentar cobertura completa.

---

# 41. Resultado del checkpoint

# APROBADO CON RESTRICCIONES

RTP es compatible con una futura capa multisistema siempre que el contrato se generalice desde:

```text
fecha × sistema × linea
```

hacia:

```text
fecha × sistema × unidad_operativa
```

y se preserve explícitamente la semántica particular de cada sistema.

---

# 42. Qué queda aprobado

Se aprueba conceptualmente:

```text
Metro:
fecha × sistema × linea

Metrobús:
fecha × sistema × linea

RTP:
fecha × sistema × servicio
```

bajo la representación común:

```text
fecha × sistema × unidad_operativa
```

La afluencia RTP únicamente se calcula automáticamente para claves seguras y completas.

---

# 43. Qué NO queda aprobado

No se aprueba:

```text
servicio = linea
```

como equivalencia semántica.

No se aprueba:

```text
SUM()
```

indiscriminado sobre RTP.

No se aprueba:

- eliminar las 92 claves con colisión;
- eliminar las 131 claves incompletas;
- convertir NULL a cero;
- imputar afluencia;
- fusionar servicios no validados;
- construir todavía la tabla de hechos definitiva;
- construir integración física persistente.

---

# 44. Integración física

Estado:

```text
NO REALIZADA
```

El presente checkpoint únicamente demuestra compatibilidad conceptual.

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

# 45. Contrato multisistema preliminar actualizado

Una futura fuente deberá permitir evaluar al menos:

1. sistema;
2. fecha;
3. unidad operativa nativa;
4. semántica de esa unidad;
5. afluencia o demanda equivalente;
6. granularidad original;
7. posibilidad de agregación diaria;
8. cobertura temporal;
9. NULL;
10. ceros;
11. duplicados;
12. colisiones;
13. outliers;
14. valores decimales;
15. dimensiones específicas;
16. trazabilidad hasta RAW;
17. estado de calidad de una eventual medida agregada.

No debe exigirse que todas las fuentes utilicen una columna denominada:

```text
linea
```

---

# 46. Efecto sobre las próximas iteraciones

Las próximas fuentes:

```text
Cablebús
Trolebús
Tren Ligero
```

deberán evaluarse contra:

```text
fecha × sistema × unidad_operativa
```

y no exclusivamente contra:

```text
fecha × sistema × linea
```

La semántica de `unidad_operativa` deberá determinarse individualmente para cada sistema.

---

# 47. Estado actual del proyecto

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

Metro ↔ Metrobús:
APROBADO CON RESTRICCIONES

RTP ↔ contrato multisistema:
APROBADO CON RESTRICCIONES
```

Granularidad multisistema preliminar actual:

```text
fecha × sistema × unidad_operativa
```

Ventana común actual:

```text
2022-01-01 → 2026-07-31
```

---

# 48. Arquitectura conceptual actual

El núcleo futuro podría conceptualmente adoptar:

```text
                    DIM_FECHA
                        │
                        │
DIM_SISTEMA ── HECHO_AFLUENCIA_UNIDAD_DIA
                        │
                        │
                DIM_UNIDAD_OPERATIVA
```

con una medida:

```text
afluencia
```

y un atributo / indicador equivalente a:

```text
estado_calidad
```

Esta arquitectura es únicamente conceptual.

No debe implementarse todavía.

---

# 49. Regla de trazabilidad

Toda futura observación multisistema deberá poder regresar a:

```text
representación analítica
↓
CLEAN del sistema
↓
TYPED
↓
STAGING
↓
RAW
```

La generalización a `unidad_operativa` no sustituye ni elimina las dimensiones nativas.

---

# 50. Decisión final

Resultado:

# COMPATIBILIDAD RTP ↔ CONTRATO MULTISISTEMA
# APROBADA CON RESTRICCIONES

Contrato anterior:

```text
fecha × sistema × linea
```

Contrato multisistema preliminar actualizado:

```text
fecha × sistema × unidad_operativa
```

Ventana temporal común:

```text
2022-01-01 → 2026-07-31
```

Validación global:

```text
45,169 registros
45,169 claves distintas
0 claves duplicadas
1,673 fechas distintas
223 claves con restricción
```

RTP:

```text
13,382 claves
13,159 OK
92 COLISION
131 AFLUENCIA_INCOMPLETA
```

---

# 51. Punto exacto de continuación

Con este checkpoint queda cerrada la compatibilidad analítica inicial de RTP.

Todavía no debe realizarse integración física.

Antes de hacer commit y Pull Request deberán revisarse:

- metadata RTP;
- contrato RTP;
- checkpoint RTP;
- scripts SQL RTP;
- script de compatibilidad;
- presente checkpoint;
- README y documentación general que necesite registrar la nueva granularidad preliminar.

Después deberá decidirse si la Iteración 3 se integra en `main` antes de comenzar el siguiente sistema.

El siguiente sistema individual deberá evaluarse contra el contrato:

```text
fecha × sistema × unidad_operativa
```