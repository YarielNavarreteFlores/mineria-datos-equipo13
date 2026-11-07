# Checkpoint de compatibilidad analítica — Metro ↔ Metrobús

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México  
**Equipo:** 13  
**Periodo:** 2026-B  
**Unidad de aprendizaje:** Minería de Datos  
**Estado:** APROBADO CON RESTRICCIONES  

---

# 1. Propósito

Este documento registra el checkpoint de compatibilidad analítica entre los sistemas:

- Sistema de Transporte Colectivo Metro;
- Metrobús de la Ciudad de México.

El objetivo del checkpoint es determinar, antes de construir cualquier integración física o modelo dimensional:

- qué elementos de ambos sistemas son semántica y estructuralmente compatibles;
- qué variables deben permanecer específicas de cada sistema;
- qué granularidad analítica común puede utilizarse posteriormente;
- qué ventana temporal resulta adecuada para comparaciones multisistema;
- qué restricciones de calidad deben conservarse;
- qué arquitectura debe considerarse en la siguiente etapa del proyecto.

Este checkpoint **no construye una tabla integrada**, no modifica los pipelines existentes y no altera archivos RAW.

---

# 2. Estado previo

Antes de realizar este análisis, ambos sistemas habían completado individualmente el pipeline:

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

## 2.1 Metro

Metro permanece como baseline validado.

### Metro Simple

```text
Registros:       1,180,920
Cobertura:       2010-01-01 → 2026-07-31
Granularidad:    fecha × linea × estacion
Tipo afluencia:  INTEGER
```

### Metro Desglosada

```text
Registros:       1,192,230
Cobertura:       2021-01-01 → 2026-07-31
Granularidad:    fecha × linea × estacion × tipo_pago
Tipo afluencia:  INTEGER
```

Metro Simple conserva 31 grupos conocidos de colisión de granularidad, correspondientes a 62 filas de:

```text
Línea B
Estación Oceanía
Diciembre de 2020
```

Estas observaciones no fueron eliminadas.

---

## 2.2 Metrobús

### Metrobús Simple

```text
Registros:       54,159
Cobertura:       2005-07-26 → 2026-09-30
Granularidad:    fecha × linea
Tipo afluencia:  NUMERIC
```

### Metrobús Desglosada

```text
Registros:       29,386
Cobertura:       2021-01-01 → 2026-09-30
Granularidad:    fecha × linea × tipo_pago
Tipo afluencia:  NUMERIC
```

Metrobús Simple contiene:

```text
17,227 valores NaN históricos
```

que se conservan como texto en STAGING y se representan como:

```text
NULL
```

desde TYPED.

No se convierten a cero.

---

# 3. Verificación del estado del repositorio

Antes de iniciar el checkpoint se verificó remotamente que el Pull Request correspondiente a la Iteración 2 de Metrobús había sido integrado correctamente en `main`.

Pull Request:

```text
#9
feat(metrobus): incorpora pipeline validado de Metrobús
```

Rama origen:

```text
feature/etl-metrobus
```

Merge commit:

```text
f857ecdf2efac654c5f73fa8131822fc6f2b08f3
```

La pertenencia del merge commit a `origin/main` también fue verificada localmente mediante Git.

Después de esta comprobación se creó la rama:

```text
feature/checkpoint-compatibilidad-metro-metrobus
```

para desarrollar el presente checkpoint.

---

# 4. Script de diagnóstico

El análisis se implementa mediante:

```text
proyecto/sql/quality/compatibilidad/01_compatibilidad_metro_metrobus.sql
```

El script se diseñó exclusivamente para lectura.

No realiza:

```text
CREATE TABLE
INSERT
UPDATE
DELETE
```

Las consultas se ejecutan dentro de transacciones:

```sql
BEGIN TRANSACTION READ ONLY;
```

por lo que las capas validadas permanecen sin modificaciones.

---

# 5. Cobertura y estructura general

Los resultados observados fueron:

| Recurso | Fecha mínima | Fecha máxima | Registros | Fechas distintas | Líneas | Afluencia NULL |
|---|---|---|---:|---:|---:|---:|
| Metro Simple | 2010-01-01 | 2026-07-31 | 1,180,920 | 6,056 | 12 | 0 |
| Metro Desglosada | 2021-01-01 | 2026-07-31 | 1,192,230 | 2,038 | 12 | 0 |
| Metrobús Simple | 2005-07-26 | 2026-09-30 | 54,159 | 7,737 | 7 | 17,227 |
| Metrobús Desglosada | 2021-01-01 | 2026-09-30 | 29,386 | 2,099 | 7 | 0 |

Los conteos coinciden con los contratos y pipelines previamente validados.

---

# 6. Significado de afluencia

La medida `afluencia` posee significado suficientemente compatible para un análisis multisistema posterior.

En Metro representa el número de accesos o afluencia reportada en la granularidad correspondiente.

El diccionario oficial de Metrobús Simple define `afluencia` como:

```text
Afluencia en número de personas.
```

El diccionario de Metrobús Desglosada describe las medidas asociadas a Prepago y Gratuidad como personas que han ingresado al sistema bajo cada modalidad.

Por tanto, el concepto común aceptado para una futura capa analítica será:

```text
afluencia reportada
```

No debe reinterpretarse como:

```text
pasajeros únicos
viajes completos
usuarios únicos
```

porque los contratos y archivos disponibles no demuestran esas equivalencias.

---

# 7. Comparación de granularidades

Las granularidades validadas son:

## Metro Simple

```text
fecha × linea × estacion
```

## Metro Desglosada

```text
fecha × linea × estacion × tipo_pago
```

## Metrobús Simple

```text
fecha × linea
```

## Metrobús Desglosada

```text
fecha × linea × tipo_pago
```

La diferencia principal es la dimensión:

```text
estacion
```

Metro dispone de estación en ambos recursos.

El CSV validado de Metrobús no contiene estación.

Por tanto, no es metodológicamente correcto exigir:

```text
fecha × linea × estacion
```

como granularidad multisistema común.

---

# 8. Dimensión línea

Metro contiene 12 líneas lógicas:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
Línea 8
Línea 9
Línea 12
Línea A
Línea B
```

Metrobús contiene 7:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
```

La intersección textual entre ambos sistemas es:

```text
Línea 1
Línea 2
Línea 3
Línea 4
Línea 5
Línea 6
Línea 7
```

Sin embargo, la igualdad textual **no representa igualdad de entidad operacional**.

Por ejemplo:

```text
Metro — Línea 1
```

y:

```text
Metrobús — Línea 1
```

son líneas pertenecientes a sistemas distintos.

Por esta razón:

```text
linea
```

no puede funcionar de manera independiente como identificador global.

La identificación mínima requiere:

```text
sistema × linea
```

---

# 9. Tipo de pago

Los dominios observados son:

## Metro

| Tipo de pago | Registros |
|---|---:|
| Boleto | 397,410 |
| Gratuidad | 397,410 |
| Prepago | 397,410 |

## Metrobús

| Tipo de pago | Registros |
|---|---:|
| Gratuidad | 14,693 |
| Prepago | 14,693 |

La intersección semántica es:

```text
Gratuidad
Prepago
```

Metro contiene además:

```text
Boleto
```

Por tanto, `tipo_pago` puede utilizarse posteriormente como dimensión analítica cuando se trabaje con recursos desglosados, pero **no debe formar parte obligatoria de la granularidad del hecho multisistema principal**.

---

# 10. Calidad de la medida

Los resultados obtenidos fueron:

| Recurso | Nulos | Ceros | Outliers IQR | Filas con colisión |
|---|---:|---:|---:|---:|
| Metro Simple | 0 | 62,025 | 66,361 | 62 |
| Metro Desglosada | 0 | 291,457 | 103,485 | 0 |
| Metrobús Simple | 17,227 | 0 | 3,000 | 0 |
| Metrobús Desglosada | 0 | 0 | 1,090 | 0 |

Estos resultados coinciden con las validaciones individuales previas.

---

# 11. Tratamiento de valores NULL

Los valores faltantes no poseen la misma semántica que una afluencia igual a cero.

En Metrobús Simple:

```text
NaN en RAW/STAGING
        ↓
NULL en TYPED/CLEAN
```

Los 17,227 valores históricos representan información no disponible de acuerdo con el tratamiento validado del pipeline.

Por tanto:

```text
NULL ≠ 0
```

y ninguna integración posterior deberá sustituir automáticamente estos valores por cero.

---

# 12. Tratamiento de ceros

Los ceros se conservan como observaciones potencialmente válidas.

Metro contiene ceros tanto en Simple como en Desglosada.

Metrobús no presenta ceros en los recursos validados.

No existe evidencia para:

- eliminar ceros;
- transformarlos a NULL;
- sustituirlos por promedios;
- considerarlos automáticamente errores.

Una integración posterior deberá conservar su valor original.

---

# 13. Tratamiento de outliers

Los outliers IQR permanecen preservados en ambos sistemas.

Los conteos actuales pertenecen a las granularidades individuales de cada recurso.

Por esta razón, la bandera:

```text
es_outlier_iqr_global
```

no debe interpretarse automáticamente como una bandera comparable entre sistemas.

Al existir posteriormente una nueva granularidad multisistema, cualquier definición de outlier común deberá evaluarse nuevamente sobre la distribución analítica correspondiente.

Las banderas actuales deben mantenerse como trazabilidad de sus respectivos pipelines.

---

# 14. Tratamiento de colisiones

Metrobús no presenta colisiones en sus granularidades validadas.

Metro Simple contiene:

```text
31 grupos
62 filas
```

en:

```text
Línea B
Oceanía
Diciembre de 2020
```

No se modificaron ni eliminaron estas observaciones.

La ventana multisistema seleccionada inicia en 2021, por lo que estas colisiones quedan fuera del periodo analítico común propuesto.

---

# 15. Reconciliación interna de Metro

Antes del presente checkpoint no se había documentado formalmente la equivalencia entre Metro Simple y Metro Desglosada en su periodo común.

Se compararon ambos recursos a la granularidad:

```text
fecha × linea × estacion
```

en la ventana:

```text
2021-01-01 → 2026-07-31
```

Metro Desglosada fue agregada mediante:

```text
SUM(afluencia)
GROUP BY fecha, linea, estacion
```

Resultados:

```text
Claves en la unión:       397,410
Claves comparables:       397,410
Solo Simple:                    0
Solo Desglosada:                0
Coincidencias exactas:    397,410
Diferencias:                    0
Máxima diferencia:              0
```

Por tanto, para todas las claves comparables de la ventana analizada:

```text
Metro Simple.afluencia
=
SUM(Metro Desglosada.afluencia)
```

La medida queda reconciliada internamente para el periodo utilizado.

---

# 16. Reconciliación interna de Metrobús

La Iteración 2 ya había validado previamente el periodo:

```text
2021-01-01 → 2026-09-30
```

con granularidad:

```text
fecha × linea
```

y agregando Desglosada mediante:

```text
SUM(afluencia)
GROUP BY fecha, linea
```

Resultado:

```text
Claves comparables:       14,693
Coincidencias exactas:    14,693
Diferencias:                   0
```

Por tanto:

```text
Metrobús Simple.afluencia
=
SUM(Metrobús Desglosada.afluencia)
```

para todas las claves comparables del periodo previamente validado.

---

# 17. Ventana temporal multisistema propuesta

Las coberturas completas son distintas entre recursos.

Para el primer análisis multisistema se selecciona como ventana preliminar:

```text
2021-01-01 → 2026-07-31
```

La selección se justifica porque durante esta ventana:

- Metro Simple dispone de información;
- Metro Desglosada dispone de información;
- Metrobús Simple dispone de información;
- Metrobús Desglosada dispone de información;
- Metro ya no presenta las colisiones conocidas de diciembre de 2020;
- Metrobús Simple ya superó los periodos históricos de `NaN`;
- los cuatro recursos pueden compararse durante el mismo intervalo temporal.

La ventana contiene:

```text
2,038 fechas distintas
```

---

# 18. Evaluación de granularidad multisistema candidata

Se evaluó la granularidad:

```text
fecha × sistema × linea
```

Para ello Metro Simple fue agregado desde:

```text
fecha × linea × estacion
```

hacia:

```text
fecha × linea
```

mediante:

```text
SUM(afluencia)
GROUP BY fecha, linea
```

Metrobús Simple ya se encuentra naturalmente en:

```text
fecha × linea
```

Resultados:

| Sistema | Registros | Claves `fecha × linea` | Fecha mínima | Fecha máxima | Líneas | NULL | Ceros | Claves con colisión origen |
|---|---:|---:|---|---|---:|---:|---:|---:|
| Metro | 24,456 | 24,456 | 2021-01-01 | 2026-07-31 | 12 | 0 | 699 | 0 |
| Metrobús | 14,266 | 14,266 | 2021-01-01 | 2026-07-31 | 7 | 0 | 0 | 0 |

Se cumple en ambos sistemas:

```text
registros = claves_fecha_linea
```

Por tanto no aparecen colisiones después de llevar ambos sistemas al nivel analítico candidato.

---

# 19. Cobertura diaria por línea

La ventana contiene:

```text
2,038 días
```

Para Metro:

```text
2,038 días × 12 líneas
=
24,456 claves
```

Para Metrobús:

```text
2,038 días × 7 líneas
=
14,266 claves
```

Los valores coinciden exactamente con los registros obtenidos en la granularidad candidata.

Esto demuestra cobertura diaria completa para las líneas incluidas durante la ventana seleccionada.

---

# 20. Validación de clave multisistema

La combinación lógica de ambos sistemas produjo:

```text
Registros totales:       38,722
Claves distintas:        38,722
Claves duplicadas:            0
Fechas distintas:         2,038
Fecha mínima:        2021-01-01
Fecha máxima:        2026-07-31
Afluencia NULL:                0
```

Por tanto, dentro de la ventana evaluada:

```text
fecha × sistema × linea
```

funciona como clave única de una futura representación analítica multisistema preliminar.

Resultado:

```text
38,722 registros
=
38,722 claves distintas
```

con:

```text
0 claves duplicadas
```

---

# 21. Granularidad multisistema preliminar aprobada

Con base en los controles realizados, se aprueba de forma preliminar:

```text
fecha × sistema × linea
```

como granularidad común para una futura capa analítica de afluencia por línea y día.

La inclusión de `sistema` es obligatoria.

No debe utilizarse únicamente:

```text
fecha × linea
```

porque líneas con el mismo nombre textual pertenecen a sistemas distintos.

---

# 22. Elementos compatibles

Los siguientes elementos pueden formar parte de una futura capa multisistema:

## Dimensión temporal

```text
fecha
anio
mes
mes_num
dia_semana_num
dia_semana
es_fin_semana
```

## Sistema

Debe existir un identificador explícito del sistema:

```text
Metro
Metrobús
```

## Línea

Puede utilizarse como dimensión operativa dentro de cada sistema.

Su identidad conceptual debe considerar:

```text
sistema × linea
```

## Medida

```text
afluencia
```

La representación común deberá aceptar valores:

```text
NUMERIC
```

debido a que Metrobús contiene valores decimales válidos.

---

# 23. Elementos específicos de cada sistema

## Estación

Debe permanecer como nivel de detalle específico de Metro mientras Metrobús no disponga de esta dimensión en el archivo validado.

No debe generarse artificialmente una estación para Metrobús.

## Tipo de pago

Es una dimensión disponible en ambos recursos Desglosados, pero sus dominios no son idénticos.

Debe conservarse como nivel de análisis adicional y no como componente obligatorio del hecho principal.

## Banderas de calidad

Las banderas generadas por cada pipeline deben mantener trazabilidad con sus tablas CLEAN originales.

No todas deben convertirse automáticamente en atributos comunes del futuro hecho multisistema.

---

# 24. Arquitectura recomendada

La arquitectura posterior no debería consistir en concatenar directamente todas las tablas CLEAN.

La estructura conceptual recomendada es separar un núcleo común de los niveles de detalle específicos.

## Núcleo analítico común

Granularidad:

```text
fecha × sistema × linea
```

Medida:

```text
afluencia
```

Conceptualmente:

```text
                 DIM_FECHA
                     │
                     │
DIM_SISTEMA ── HECHO_AFLUENCIA_LINEA_DIA ── DIM_LINEA
                     │
                     │
                afluencia
```

Esta representación todavía **no debe implementarse físicamente** durante el presente checkpoint.

---

# 25. Detalles específicos que deben preservarse

La arquitectura futura deberá permitir conservar los niveles originales.

## Metro

```text
fecha × linea × estacion
```

y:

```text
fecha × linea × estacion × tipo_pago
```

## Metrobús

```text
fecha × linea
```

y:

```text
fecha × linea × tipo_pago
```

El nivel común no debe destruir los detalles disponibles en los sistemas originales.

---

# 26. Riesgos identificados

## 26.1 Confundir líneas con el mismo nombre

```text
Metro — Línea 1
```

no es:

```text
Metrobús — Línea 1
```

La futura integración necesita una dimensión de sistema.

---

## 26.2 Perder el nivel estación

Agregar Metro a línea permite compararlo con Metrobús, pero elimina temporalmente detalle espacial.

Por ello, la tabla o vista agregada futura no debe sustituir las capas detalladas de Metro.

---

## 26.3 Interpretar NULL como cero

En Metrobús:

```text
NULL
```

representa información no disponible.

Debe mantenerse separado de:

```text
0
```

---

## 26.4 Comparar directamente banderas de outlier

Los outliers actuales se calcularon sobre distribuciones y granularidades distintas.

Una futura capa multisistema deberá evaluar nuevamente cualquier criterio de atipicidad común.

---

## 26.5 Generalizar prematuramente la arquitectura

El presente checkpoint analiza únicamente:

```text
Metro ↔ Metrobús
```

Todavía faltan:

```text
RTP
Cablebús
Trolebús
Tren Ligero
```

Por tanto, la granularidad aprobada es **preliminar** y deberá reevaluarse al incorporar cada nuevo sistema.

---

# 27. Matriz final de compatibilidad

| Elemento | Estado | Decisión |
|---|---|---|
| Fecha diaria | Compatible | Dimensión común |
| Año / mes | Compatible | Dimensiones comunes |
| Afluencia | Compatible con restricciones | Medida común, usar NUMERIC |
| Sistema | Necesario | Identificador obligatorio |
| Línea | Compatible con restricciones | Identidad mediante sistema + línea |
| Estación | No común | Mantener específica de Metro |
| Tipo de pago | Parcialmente compatible | Mantener como detalle adicional |
| NULL | Semántica específica | No convertir a cero |
| Ceros | Válidos | Conservar |
| Outliers | Política compatible | Conservar; recalcular si se requiere análisis común |
| Colisiones | Diferentes por sistema | Conservar trazabilidad |
| Decimales | Diferencia física | NUMERIC en futura medida común |
| `fecha × sistema × linea` | Validada preliminarmente | Granularidad común candidata |
| Integración física | No realizada | Pendiente |

---

# 28. Decisión del checkpoint

Resultado:

# APROBADO CON RESTRICCIONES

Existe evidencia suficiente para afirmar que Metro y Metrobús son compatibles para una futura capa analítica de afluencia diaria a nivel:

```text
fecha × sistema × linea
```

durante la ventana preliminar:

```text
2021-01-01 → 2026-07-31
```

La validación produjo:

```text
38,722 registros
38,722 claves distintas
0 claves duplicadas
0 afluencias NULL
2,038 fechas distintas
```

Sin embargo, esta decisión no implica que:

- todas las dimensiones sean compartidas;
- los recursos puedan concatenarse directamente;
- las tablas CLEAN puedan sustituirse;
- deba construirse todavía una tabla de hechos;
- el modelo dimensional definitivo esté aprobado.

---

# 29. Qué sí puede integrarse posteriormente

Una futura capa común puede representar:

```text
fecha
sistema
linea
afluencia
```

con variables temporales derivadas cuando corresponda.

La afluencia de Metro deberá agregarse desde estación hasta línea para este nivel analítico.

---

# 30. Qué debe permanecer específico

Debe conservarse fuera del núcleo obligatorio:

```text
estacion
```

por ser una dimensión actualmente disponible en Metro pero no en el CSV validado de Metrobús.

También deben preservarse de manera independiente:

- detalle por tipo de pago;
- banderas de calidad de origen;
- granularidades nativas;
- contratos individuales;
- trazabilidad hacia CLEAN, TYPED, STAGING y RAW.

---

# 31. Qué no debe hacerse todavía

No debe construirse todavía:

```text
tabla de hechos definitiva
modelo dimensional definitivo
cubo OLAP
integración física persistente
dataset processed multisistema definitivo
```

Tampoco debe modificarse Metro para hacerlo estructuralmente idéntico a Metrobús.

---

# 32. Siguiente arquitectura de trabajo

El checkpoint permite establecer un contrato multisistema preliminar para evaluar las siguientes fuentes.

Orden recomendado:

```text
Metro
  ✅

Metrobús
  ✅

Checkpoint Metro ↔ Metrobús
  ✅

RTP
  ↓
pipeline individual
  ↓
comparación contra contrato preliminar

Cablebús
  ↓
pipeline individual
  ↓
comparación contra contrato preliminar

Trolebús
  ↓
pipeline individual
  ↓
comparación contra contrato preliminar

Tren Ligero
  ↓
pipeline individual
  ↓
comparación contra contrato preliminar
```

Una vez completadas las iteraciones individuales deberá realizarse:

```text
CHECKPOINT MULTISISTEMA FINAL
```

y únicamente después:

```text
INTEGRACIÓN FÍSICA
↓
MODELO DIMENSIONAL
↓
OLAP
↓
EDA CONSOLIDADO
↓
MINERÍA
↓
EVALUACIÓN
```

---

# 33. Contrato multisistema preliminar

Una fuente candidata para incorporarse posteriormente a la capa multisistema deberá permitir evaluar al menos:

1. sistema de transporte;
2. fecha;
3. unidad operativa equivalente a línea o ruta;
4. afluencia o medida de demanda equivalente;
5. granularidad exacta;
6. cobertura temporal;
7. nulos;
8. ceros;
9. duplicados exactos;
10. colisiones de clave;
11. valores extremos;
12. tipos físicos;
13. dimensiones específicas;
14. posibilidad de agregación al nivel diario por unidad operativa;
15. trazabilidad desde RAW hasta CLEAN;
16. compatibilidad semántica con la medida común.

La equivalencia entre conceptos deberá demostrarse y no inferirse únicamente porque las columnas tengan nombres similares.

---

# 34. Reglas vigentes después del checkpoint

- No modificar archivos RAW.
- No sobrescribir fuentes originales.
- Metro continúa como baseline validado.
- Metrobús continúa como pipeline individual validado.
- No convertir NULL a cero.
- No eliminar outliers únicamente por su magnitud.
- No eliminar colisiones sin evidencia.
- No confundir líneas de distintos sistemas.
- Mantener `sistema` en cualquier futura clave multisistema.
- Mantener trazabilidad hacia la granularidad original.
- No crear todavía el modelo dimensional definitivo.
- No implementar integración persistente antes de evaluar los sistemas restantes.
- Toda nueva iteración debe completar su propio pipeline antes de ingresar a una integración común.

---

# 35. Estado final

```text
Metro
Pipeline individual:
VALIDADO

Metrobús
Pipeline individual:
VALIDADO

Compatibilidad Metro ↔ Metrobús:
APROBADA CON RESTRICCIONES

Granularidad multisistema preliminar:
fecha × sistema × linea

Ventana común preliminar:
2021-01-01 → 2026-07-31

Integración física:
PENDIENTE

Modelo dimensional:
PENDIENTE
```

---

# 36. Punto exacto de continuación

El checkpoint Metro ↔ Metrobús queda técnicamente cerrado.

El siguiente bloque del proyecto es:

```text
ITERACIÓN 3 — RTP
```

RTP deberá completar individualmente:

```text
FUENTE
↓
RAW
↓
METADATA / PROCEDENCIA
↓
INSPECCIÓN
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

Después se deberá evaluar su compatibilidad con el contrato multisistema preliminar definido en este documento.

No debe construirse todavía una integración física definitiva de Metro y Metrobús.

---

**Resultado del checkpoint:**

```text
APROBADO CON RESTRICCIONES
```