# Contrato de datos — RTP

## 1. Propósito

Este documento define el contrato de datos validado para la Iteración 3 — RTP del proyecto semestral:

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

El contrato documenta:

- procedencia;
- estructura física recibida;
- cobertura temporal;
- tipos físicos;
- dominios observados;
- tratamiento de valores no disponibles;
- tratamiento de ceros y valores decimales;
- comportamiento de la dimensión `servicio`;
- granularidad observada;
- duplicados exactos;
- colisiones;
- transformaciones CLEAN;
- indicadores de calidad;
- condiciones para su utilización analítica posterior.

La fuente de verdad técnica del pipeline permanece en los scripts SQL versionados dentro de:

```text
proyecto/sql/
```

---

# 2. Sistema

**Sistema de transporte:** Red de Transporte de Pasajeros de la Ciudad de México.

**Identificador utilizado en el proyecto:** RTP.

**Conjunto:** Afluencia diaria de la Red de Transporte de Pasajeros.

**Publicador / mantenedor:** Secretaría de Movilidad de la Ciudad de México (SEMOVI).

**Portal:** Portal de Datos Abiertos de la Ciudad de México.

La procedencia completa se mantiene en:

```text
proyecto/data/metadata/rtp/procedencia_rtp.md
```

---

# 3. Fuente oficial

Página oficial consultada:

```text
https://www.datos.cdmx.gob.mx/dataset/afluencia-diaria-de-la-red-de-transporte-de-pasajeros
```

Fecha de consulta y adquisición:

```text
2026-11-08
```

Última actualización mostrada por el portal durante la adquisición:

```text
2026-10-22 16:25 (UTC-06:00)
```

Licencia publicada:

```text
CC-BY-4.0-ESP
```

La descripción del portal indica información de afluencia de usuarios de RTP con desagregación diaria a partir del:

```text
2022-01-01
```

La fecha de actualización de la ficha no se utiliza como sustituto de la cobertura temporal real del archivo.

La cobertura temporal efectiva fue determinada directamente mediante el perfilado de los registros.

---

# 4. Recursos utilizados

## 4.1 Afluencia diaria RTP desglosada

Archivo RAW recibido:

```text
proyecto/data/raw/rtp/afluenciartp_desglosado_09_2026.csv
```

Estructura física observada:

```text
fecha,mes,anio,servicio,tipo_pago,afluencia
```

Registros:

```text
41,676
```

Columnas:

```text
6
```

Filas estructuralmente malformadas:

```text
0
```

Encoding detectado:

```text
utf-8-sig
```

Delimitador:

```text
,
```

Cobertura temporal validada:

```text
2022-01-01 → 2026-09-30
```

Fechas distintas:

```text
1,734
```

---

## 4.2 Diccionario oficial

Archivo descargado originalmente:

```text
53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv
```

Copia byte a byte preservada en:

```text
proyecto/data/metadata/rtp/diccionario_rtp_original.csv
```

Registros:

```text
9
```

Columnas:

```text
9
```

Filas estructuralmente malformadas:

```text
0
```

Encoding detectado:

```text
latin-1
```

La copia almacenada en `metadata/rtp/` fue comparada mediante `cmp` contra el archivo RAW.

Resultado:

```text
sin diferencias
```

Por tanto, conserva los mismos bytes que el recurso oficial descargado.

---

# 5. Integridad y trazabilidad

Los archivos RAW permanecen excluidos de Git.

La integridad se controla mediante:

```text
proyecto/data/metadata/rtp/checksums_fuentes_rtp.sha256
```

Los SHA-256 fueron comprobados satisfactoriamente mediante:

```text
sha256sum -c
```

Resultados:

```text
afluenciartp_desglosado_09_2026.csv: OK
diccionario_rtp_original.csv: OK
```

La inspección reproducible se encuentra en:

```text
proyecto/data/metadata/rtp/inspeccion_fuentes_rtp.json
```

El manifest técnico se encuentra en:

```text
proyecto/data/metadata/rtp/manifest_fuentes_rtp.csv
```

El estado registrado en el manifest es:

```text
INSPECCIONADO_PENDIENTE_VALIDACION
```

Ese valor representa el estado técnico existente cuando se generó el manifest.

No debe modificarse retrospectivamente para reflejar la validación posterior.

La validación posterior queda registrada mediante:

- scripts SQL;
- este contrato;
- el checkpoint individual de RTP.

---

# 6. Arquitectura validada

El pipeline individual implementado es:

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

Scripts implementados:

## Ingestión

```text
proyecto/sql/ingestion/rtp/01_stage_rtp.sql
proyecto/sql/ingestion/rtp/02_ingesta_rtp.sql
```

## Perfilado y validación

```text
proyecto/sql/quality/rtp/03_perfilado_rtp.sql
proyecto/sql/quality/rtp/06_validacion_rtp.sql
```

## Tipado y limpieza

```text
proyecto/sql/integration/rtp/04_typed_rtp.sql
proyecto/sql/integration/rtp/05_clean_rtp.sql
```

---

# 7. STAGING

Tabla:

```text
proyecto.rtp_desglosada_stage
```

STAGING recibe las seis columnas como:

```text
TEXT
```

Estructura:

```text
fecha       TEXT
mes         TEXT
anio        TEXT
servicio    TEXT
tipo_pago   TEXT
afluencia   TEXT
```

Objetivos:

- preservar la representación recibida;
- evitar conversiones prematuras;
- conservar el literal `NaN`;
- conservar ceros;
- conservar valores decimales;
- conservar variantes textuales de `servicio`;
- permitir perfilado reproducible;
- evitar eliminación o corrección de observaciones.

Conteo validado:

```text
41,676
```

Conciliación contra manifest:

```text
Esperado:       41,676
Obtenido:       41,676
Diferencia:          0
```

---

# 8. Calidad estructural inicial

El perfilado de STAGING produjo:

```text
Vacíos fecha:          0
Vacíos mes:            0
Vacíos anio:           0
Vacíos servicio:       0
Vacíos tipo_pago:      0
Vacíos afluencia:      0
```

Convertibilidad:

```text
Fechas inválidas:                     0
Años inválidos:                       0
NaN en afluencia:                   187
Afluencia inválida distinta de NaN:   0
Afluencias numéricas finitas:    41,489
```

Coherencia temporal:

```text
fecha ↔ anio:  0 inconsistencias
fecha ↔ mes:   0 inconsistencias
```

Los doce meses fueron reconocidos correctamente.

---

# 9. Cobertura temporal

Cobertura validada:

```text
2022-01-01 → 2026-09-30
```

Fechas distintas:

```text
1,734
```

Años observados:

```text
2022 → 2026
```

La cobertura corresponde a los registros realmente recibidos y no se infiere únicamente de la descripción del portal.

---

# 10. Tipo de pago

El recurso contiene exactamente tres categorías:

| tipo_pago | Registros |
|---|---:|
| Boleto | 13,892 |
| Gratuidad | 13,892 |
| Prepago | 13,892 |

Total:

```text
41,676
```

No se identificaron categorías adicionales.

El diccionario oficial describe conceptualmente estas modalidades como personas que ingresaron bajo esquemas de:

- boleto;
- prepago;
- gratuidad.

Por tanto, `tipo_pago` se interpreta como una dimensión de modalidad de acceso.

---

# 11. Semántica de afluencia

El diccionario oficial describe las medidas históricas asociadas a boleto, prepago y gratuidad como cantidades de personas que ingresaron a RTP.

Para el proyecto, la interpretación conservadora de la medida será:

```text
afluencia reportada
```

No debe reinterpretarse automáticamente como:

```text
pasajeros únicos
usuarios únicos
viajes completos
origen-destino
abordajes únicos de individuos
```

porque la fuente no demuestra esas equivalencias.

Esta interpretación mantiene compatibilidad conceptual preliminar con la medida de afluencia utilizada para Metro y Metrobús.

La compatibilidad multisistema definitiva deberá evaluarse posteriormente.

---

# 12. Tratamiento del literal NaN

STAGING contiene:

```text
187
```

registros cuyo valor original de `afluencia` es:

```text
NaN
```

No se interpreta como cero.

La transformación validada es:

```text
NaN en RAW/STAGING
        ↓
NULL en TYPED/CLEAN
```

Conteos:

```text
NaN STAGING:                      187
NULL TYPED:                       187
NULL CLEAN:                       187
es_afluencia_no_disponible:       187
```

Inconsistencias entre `NULL` y la bandera:

```text
0
```

Regla:

```text
NULL ≠ 0
```

---

# 13. Tratamiento de ceros

El recurso contiene:

```text
7,450
```

afluencias iguales a cero.

Los ceros:

- no se eliminan;
- no se transforman a NULL;
- no se reemplazan por promedios;
- no se consideran automáticamente errores.

CLEAN incorpora:

```text
es_afluencia_cero
```

Conteos validados:

```text
Ceros STAGING/TYPED: 7,450
Ceros CLEAN:         7,450
Bandera de cero:     7,450
```

---

# 14. Valores decimales

El perfilado identificó:

```text
53
```

valores válidos con componente decimal.

Por esta razón:

```text
afluencia → NUMERIC
```

y no `INTEGER`.

Los 53 valores se conservan sin:

- redondeo;
- truncamiento;
- conversión artificial a entero.

---

# 15. Valores negativos

Valores negativos detectados:

```text
0
```

No se implementa ninguna regla automática para valores negativos futuros.

Una actualización posterior de la fuente deberá volver a perfilarse antes de asumir este resultado.

---

# 16. TYPED

Tabla:

```text
proyecto.rtp_desglosada_typed
```

Tipos físicos:

| Campo | Tipo |
|---|---|
| fecha | DATE |
| mes | TEXT |
| anio | SMALLINT |
| servicio | TEXT |
| tipo_pago | TEXT |
| afluencia | NUMERIC |

Transformaciones principales:

```text
fecha       TEXT → DATE
anio        TEXT → SMALLINT
afluencia   TEXT → NUMERIC
NaN         TEXT → NULL
```

No se aplica homologación semántica de `servicio` en TYPED.

Conteos:

```text
STAGING: 41,676
TYPED:   41,676
Diferencia: 0
```

Los siguientes elementos permanecen preservados:

```text
187 NULL
7,450 ceros
53 valores decimales
276 grupos con colisión
81 grupos de duplicados exactos
```

---

# 17. Dimensión servicio

El CSV utiliza:

```text
servicio
```

y no contiene un campo denominado:

```text
linea
ruta
corredor
```

El diccionario oficial describe `servicio` como:

```text
Servicio de RTP de la medición de afluencia
```

y presenta como ejemplo:

```text
"Línea X"
```

Sin embargo, el dominio físico observado contiene categorías como:

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
servicio ≠ linea
```

no puede suponerse automáticamente.

En el contrato RTP, `servicio` se considera una:

```text
unidad operativa / categoría de servicio reportada por la fuente
```

hasta que exista evidencia oficial suficiente para asignarle una equivalencia distinta.

---

# 18. Variantes originales de servicio

El perfilado encontró:

```text
30
```

representaciones textuales distintas en STAGING/TYPED.

Se observaron cambios históricos de escritura, mayúsculas, acentos y representación.

Entre ellos:

```text
Atenea
ATENEA

Expreso
EXPRESO

Ordinario
ORDINARIO

S/Metro
S/METRO

Expdirecto
EXPDIRECTO

Circuito Hospitales
CIRCUITO HOSPITALES

Apoyo Concesionado
Apoyo concesionado
APOYO A CONCESIONADO

Servicios Temporales
SERVICIOS TEMPORALES
```

Antes de realizar cualquier homologación se comprobó si la transformación generaba nuevas colisiones.

---

# 19. Homologación conservadora de servicio

CLEAN aplica únicamente homologaciones que no introducen nuevas colisiones.

Se homologan:

```text
Atenea / ATENEA
→ Atenea

Expreso / EXPRESO
→ Expreso

Ordinario / ORDINARIO
→ Ordinario

S/Metro / S/METRO
→ S/Metro

Expdirecto / EXPDIRECTO
→ Expdirecto

Circuito Hospitales / CIRCUITO HOSPITALES
→ Circuito Hospitales

Apoyo Concesionado /
Apoyo concesionado /
APOYO A CONCESIONADO
→ Apoyo Concesionado

Servicios Temporales /
SERVICIOS TEMPORALES
→ Servicios Temporales
```

Filas cuyo servicio fue homologado:

```text
11,640
```

CLEAN conserva simultáneamente:

```text
servicio_original
servicio
```

para mantener trazabilidad.

---

# 20. Variantes que NO se homologan

Se evaluó también fusionar las familias:

```text
Ecobús
ECOBÚS
ECOBUS
ECOB S
```

y:

```text
Nochebús
NOCHEBÚS
NOCHEBUS
NOCHEB S
```

La prueba generó nuevas colisiones.

Baseline:

```text
276 claves con colisión
552 filas involucradas
```

Después de la homologación amplia:

```text
429 claves con colisión
858 filas involucradas
```

Colisiones artificiales nuevas:

```text
153
```

Distribución:

```text
Ecobús:     90 claves nuevas
Nochebús:   63 claves nuevas
```

Por tanto, estas representaciones se mantienen separadas en CLEAN.

La similitud textual no constituye evidencia suficiente para fusionarlas.

---

# 21. Dominio CLEAN de servicio

Después de aplicar únicamente la homologación conservadora, CLEAN contiene:

```text
21
```

representaciones de `servicio`.

Dominio validado:

```text
Apoyo Concesionado
Apoyo Metro L1
Atenea
CENTROBUS
Circuito Hospitales
Circuito Hospitales $8.00
Ecoatenea
ECOB S
ECOBUS
Ecobús
ECOBÚS
Expdirecto
Expreso
Expreso Directo
NOCHEB S
NOCHEBUS
Nochebús
NOCHEBÚS
Ordinario
S/Metro
Servicios Temporales
```

No debe interpretarse que estas 21 categorías equivalen necesariamente a 21 líneas físicas.

---

# 22. Granularidad candidata

La granularidad inicialmente evaluada fue:

```text
fecha × servicio × tipo_pago
```

Esta combinación NO es única en toda la fuente.

Resultados:

```text
276 grupos con colisión
552 filas involucradas
276 registros excedentes
máximo de 2 repeticiones por clave
```

Por tanto:

```text
fecha × servicio × tipo_pago
```

se considera una:

```text
granularidad analítica candidata con colisiones preservadas
```

y no una clave primaria natural validada.

No debe imponerse una restricción `UNIQUE` sobre esa combinación.

---

# 23. Duplicados exactos

Se detectaron:

```text
81 grupos de duplicados exactos
162 filas involucradas
81 registros excedentes
máximo de 2 repeticiones
```

Los duplicados exactos:

- se conservan;
- no se eliminan automáticamente;
- se identifican mediante bandera en CLEAN.

Bandera:

```text
es_duplicado_exacto
```

La existencia de duplicados exactos se documenta como una propiedad de calidad de la fuente.

---

# 24. Colisiones de granularidad

Las 276 colisiones no corresponden únicamente a duplicados exactos.

Clasificación:

```text
276 claves con colisión
81 colisiones exactas
195 colisiones con afluencia distinta
```

Las 195 claves conflictivas incluyen:

```text
105 pares:
0 + valor positivo

90 pares:
valor positivo + valor positivo
```

Por tanto, las colisiones no pueden tratarse globalmente como simples duplicados.

---

# 25. Anomalía de ATENEA

Las colisiones se concentran completamente en:

```text
ATENEA / Atenea
```

Fechas afectadas:

```text
92
```

Distribución:

```text
2024-09:
30 días

2025-07:
31 días

2026-01:
31 días
```

En cada fecha afectada se observaron:

```text
6 filas
3 tipos de pago
```

es decir, dos observaciones para cada una de:

```text
Boleto
Gratuidad
Prepago
```

Distribución de colisiones por tipo de pago:

```text
Boleto:
92 claves
81 exactas
11 diferentes

Gratuidad:
92 claves
0 exactas
92 diferentes

Prepago:
92 claves
0 exactas
92 diferentes
```

No existe evidencia suficiente para determinar que:

- una de las filas sea incorrecta;
- deba seleccionarse el mínimo;
- deba seleccionarse el máximo;
- deba conservarse únicamente la última;
- ambas deban sumarse;
- una observación deba descartarse.

Las 552 filas involucradas permanecen preservadas.

---

# 26. Interpretación de las colisiones

La combinación:

```text
fecha × servicio × tipo_pago
```

es insuficiente para identificar unívocamente todas las observaciones disponibles.

Una explicación posible es la existencia de una dimensión operacional no incluida en el archivo publicado.

Sin embargo, esta explicación no está demostrada por la fuente y no debe declararse como hecho.

La decisión metodológica es:

```text
preservar las observaciones
+
marcar las colisiones
+
no inventar una dimensión faltante
```

CLEAN incluye:

```text
es_colision_clave_origen
es_colision_clave
```

La homologación conservadora mantiene:

```text
552 filas con colisión antes de homologar
552 filas con colisión después de homologar
```

Por tanto, CLEAN no genera nuevas colisiones.

---

# 27. CLEAN

Tabla:

```text
proyecto.rtp_desglosada_clean
```

CLEAN conserva:

```text
41,676
```

registros.

Pérdida TYPED → CLEAN:

```text
0
```

Variables principales:

```text
fecha
anio
mes
mes_num
dia_semana_num
dia_semana
es_fin_semana

servicio_original
servicio

tipo_pago
afluencia
```

Indicadores de calidad:

```text
es_afluencia_no_disponible
es_afluencia_cero
es_colision_clave_origen
es_colision_clave
es_duplicado_exacto
es_outlier_iqr_global
es_servicio_homologado
```

---

# 28. Variables temporales derivadas

CLEAN incorpora:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana
```

La validación encontró:

```text
error_anio:         0
error_mes:          0
error_dia_semana:   0
```

Por tanto, las variables temporales derivadas son coherentes con `fecha`.

---

# 29. Afluencia

Valores numéricos disponibles:

```text
41,489
```

Valores no disponibles:

```text
187
```

Mínimo observado:

```text
0
```

Q1:

```text
49
```

Mediana:

```text
1,723
```

Media aproximada:

```text
12,522.74
```

Q3:

```text
13,899
```

Máximo observado:

```text
214,689
```

Ceros:

```text
7,450
```

Negativos:

```text
0
```

Valores con componente decimal:

```text
53
```

---

# 30. Outliers IQR

Los posibles outliers se identifican mediante:

```text
x < Q1 - 1.5 × IQR

o

x > Q3 + 1.5 × IQR
```

Resultados:

```text
Q1 = 49
Q3 = 13,899

Límite inferior = -20,726
Límite superior = 34,674

Valores numéricos evaluados = 41,489
Posibles outliers = 4,688
```

Los outliers:

- no se eliminan;
- no se reemplazan;
- no se winsorizan;
- no se interpretan automáticamente como errores.

CLEAN incorpora:

```text
es_outlier_iqr_global
```

---

# 31. Conciliación entre capas

| Capa | Registros |
|---|---:|
| STAGING | 41,676 |
| TYPED | 41,676 |
| CLEAN | 41,676 |

Pérdida total:

```text
0
```

Se preservan a lo largo del pipeline:

```text
187 valores no disponibles
7,450 ceros
53 valores decimales
81 grupos de duplicados exactos
276 grupos con colisión
4,688 posibles outliers
```

---

# 32. Calidad final

Resumen validado:

| Control | Resultado |
|---|---:|
| Registros | 41,676 |
| Fechas distintas | 1,734 |
| Fecha mínima | 2022-01-01 |
| Fecha máxima | 2026-09-30 |
| Fechas inválidas | 0 |
| Años inválidos | 0 |
| Vacíos estructurales | 0 |
| NaN / NULL | 187 |
| Ceros | 7,450 |
| Negativos | 0 |
| Valores decimales | 53 |
| Tipos de pago | 3 |
| Servicios CLEAN | 21 |
| Filas homologadas | 11,640 |
| Grupos duplicados exactos | 81 |
| Filas en duplicados exactos | 162 |
| Grupos con colisión | 276 |
| Filas con colisión | 552 |
| Posibles outliers IQR | 4,688 |
| Pérdida de registros | 0 |

---

# 33. Discrepancia con el diccionario oficial

El diccionario descargado no representa exactamente la estructura física del CSV utilizado.

El diccionario describe campos como:

```text
fecha
dia
mes
ano
servicio
afluencia_boleto
afluencia_prepago
afluencia_gratuidad
afluencia_total
```

mientras que el CSV realmente recibido utiliza:

```text
fecha
mes
anio
servicio
tipo_pago
afluencia
```

También existe la diferencia:

```text
ano
```

en el diccionario frente a:

```text
anio
```

en el CSV.

El diccionario se conserva como evidencia oficial, pero la implementación del pipeline utiliza la estructura física realmente recibida y validada.

No se modificó el RAW para ajustarlo al diccionario.

---

# 34. Reglas de uso

1. No modificar RAW.

2. No sobrescribir la versión adquirida de los archivos oficiales.

3. No convertir `NaN` a cero.

4. En TYPED/CLEAN, `NULL` en `afluencia` representa información no disponible.

5. Conservar los 7,450 ceros salvo evidencia posterior que demuestre un error específico.

6. No redondear ni truncar los 53 valores decimales.

7. No eliminar los 4,688 posibles outliers únicamente por su magnitud.

8. No eliminar automáticamente los 81 grupos de duplicados exactos.

9. No resolver artificialmente las 276 colisiones.

10. No imponer `UNIQUE` sobre:

```text
fecha × servicio × tipo_pago
```

11. No interpretar `servicio` automáticamente como `linea`.

12. No fusionar las variantes de Ecobús y Nochebús actualmente separadas.

13. Utilizar `servicio_original` cuando sea necesario reconstruir la representación recibida.

14. Utilizar `servicio` para análisis que requieran las homologaciones conservadoras validadas.

15. Mantener `tipo_pago` como nivel de detalle del recurso.

16. Toda transformación posterior debe mantener trazabilidad hacia:

```text
CLEAN
↓
TYPED
↓
STAGING
↓
RAW
```

17. La eventual integración multisistema deberá respetar que RTP no posee actualmente una `linea` equivalente demostrada al concepto utilizado por Metro y Metrobús.

---

# 35. Compatibilidad multisistema todavía no aprobada

Este contrato valida únicamente el pipeline individual de RTP.

No implica todavía que RTP sea compatible con la granularidad preliminar:

```text
fecha × sistema × linea
```

definida durante el checkpoint Metro ↔ Metrobús.

En RTP:

```text
servicio
```

no ha sido demostrado como equivalente a:

```text
linea
```

Además:

```text
fecha × servicio × tipo_pago
```

presenta colisiones reales preservadas.

Por tanto, RTP deberá someterse posteriormente a un checkpoint explícito de compatibilidad contra el contrato multisistema preliminar.

No debe forzarse la estructura de RTP para ajustarla a Metro o Metrobús.

---

# 36. Estado de validación

Pipeline:

```text
FUENTE OFICIAL
  ✅

RAW
  ✅

METADATA / PROCEDENCIA
  ✅

INSPECCIÓN
  ✅

SHA-256
  ✅

MANIFEST
  ✅

STAGING
  ✅

PERFILADO
  ✅

TYPED
  ✅

CLEAN
  ✅

VALIDACIÓN
  ✅
```

Resultado:

# PIPELINE INDIVIDUAL RTP: VALIDADO

Script principal de validación:

```text
proyecto/sql/quality/rtp/06_validacion_rtp.sql
```

---

# 37. Punto exacto de continuación

Con el pipeline individual y el presente contrato completos, el siguiente bloque será:

```text
CHECKPOINT INDIVIDUAL RTP
```

Ese checkpoint deberá consolidar:

- fuente;
- archivos adquiridos;
- SHA-256;
- cobertura;
- estructura;
- calidad;
- tratamiento de NaN;
- ceros;
- decimales;
- servicios;
- homologaciones;
- duplicados;
- colisiones;
- anomalía ATENEA;
- outliers;
- scripts implementados;
- estado final del pipeline.

Después del checkpoint individual deberá evaluarse:

```text
RTP
↓
COMPATIBILIDAD CON CONTRATO MULTISISTEMA PRELIMINAR
```

No debe construirse todavía:

```text
integración física multisistema
tabla de hechos definitiva
modelo dimensional definitivo
dataset multisistema en processed/
cubo OLAP definitivo
```