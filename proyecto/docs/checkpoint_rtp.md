# Checkpoint — Iteración 3: RTP

Fecha del checkpoint:

`2026-11-09`

Rama de trabajo:

`feature/etl-rtp`

Commit base de `main` utilizado al iniciar la iteración:

`e661a67ac959a004bc217d2e831b58fd2ab663e2`

Commit base abreviado:

`e661a67`

Descripción del commit base:

`feat: agrega checkpoint de compatibilidad Metro y Metrobus (#10)`

La Iteración 3 fue iniciada desde un `main` limpio y sincronizado con `origin/main`.

El trabajo descrito en este checkpoint todavía no debe considerarse integrado en `main` hasta completar posteriormente:

```text
revisión
↓
documentación final
↓
git add
↓
commit
↓
push
↓
Pull Request
↓
Squash and merge
↓
sincronización local de main
```

---

# 1. Proyecto

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

Equipo 13 — Minería de Datos — ESCOM-IPN.

La Iteración 3 corresponde a:

**Red de Transporte de Pasajeros de la Ciudad de México (RTP).**

Metro permanece como baseline técnico validado.

Metrobús permanece como segundo sistema validado.

El checkpoint previo:

```text
Metro ↔ Metrobús
```

se encuentra:

**APROBADO CON RESTRICCIONES**

y definió como representación multisistema preliminar:

```text
fecha × sistema × linea
```

RTP no fue forzado a dicha estructura.

---

# 2. Estado de la Iteración 3

La Iteración 3 completó:

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
```

Resultado:

# PIPELINE INDIVIDUAL RTP: VALIDADO

No existe todavía integración física de RTP con Metro ni Metrobús.

---

# 3. Entorno utilizado

Entorno observado durante la iteración:

- Windows 11.
- Git Bash.
- VS Code.
- Python 3.12.
- PostgreSQL 18.
- DBeaver.
- `psql` 18.
- Base de datos: `mineria_datos_2026b`.
- Esquema PostgreSQL: `proyecto`.
- Usuario utilizado: `postgres`.
- Servidor local: `127.0.0.1`.
- Puerto PostgreSQL: `5432`.

El ejecutable `psql.exe` fue localizado en:

```text
C:\Program Files\PostgreSQL\18\bin\psql.exe
```

La ingesta mediante `\copy` se ejecutó desde la raíz del repositorio utilizando `psql`.

---

# 4. Fuente oficial

Portal:

```text
https://www.datos.cdmx.gob.mx/dataset/afluencia-diaria-de-la-red-de-transporte-de-pasajeros
```

Nombre del conjunto:

**Afluencia diaria de la Red de Transporte de Pasajeros**

Organización / mantenedor:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI).**

Etiqueta observada:

`RTP`

Licencia publicada:

`CC-BY-4.0-ESP`

Fecha de consulta y adquisición:

`2026-11-08`

Última actualización mostrada por el portal durante la adquisición:

`2026-10-22 16:25 (UTC-06:00)`

La descripción oficial indica información de afluencia de usuarios de RTP con desagregación diaria a partir de:

`2022-01-01`

La fecha mostrada por el portal no se utilizó como sustituto de la cobertura temporal física del CSV.

Procedencia detallada:

```text
proyecto/data/metadata/rtp/procedencia_rtp.md
```

---

# 5. Recursos oficiales adquiridos

Se identificaron dos recursos oficiales.

## 5.1 Dataset de afluencia

Nombre publicado:

**Afluencia Diaria de la RTP (desglosada)**

Archivo recibido:

```text
afluenciartp_desglosado_09_2026.csv
```

Ubicación RAW:

```text
proyecto/data/raw/rtp/afluenciartp_desglosado_09_2026.csv
```

Tamaño:

`1,924,794 bytes`

Tamaño aproximado:

`1.84 MiB`

Encoding detectado:

`utf-8-sig`

Delimitador:

`,`

Columnas:

`6`

Filas de datos:

`41,676`

Filas estructuralmente malformadas:

`0`

---

## 5.2 Diccionario oficial

Archivo recibido:

```text
53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv
```

Ubicación RAW:

```text
proyecto/data/raw/rtp/53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv
```

Copia preservada para metadatos:

```text
proyecto/data/metadata/rtp/diccionario_rtp_original.csv
```

La copia fue comparada contra el RAW mediante:

```text
cmp
```

Resultado:

`sin diferencias`

Tamaño:

`1,947 bytes`

Encoding detectado:

`latin-1`

Columnas:

`9`

Filas de datos:

`9`

Filas estructuralmente malformadas:

`0`

El archivo original no fue recodificado.

---

# 6. Integridad SHA-256

Archivo de checksums:

```text
proyecto/data/metadata/rtp/checksums_fuentes_rtp.sha256
```

Hash del archivo de afluencia:

```text
a91f3c239d60553c1c8e1e48642e4fc513cdb5909840dce10f89425a5c385c2a
```

Hash del diccionario preservado:

```text
dd2b9d08e2f66c83a5b1dcf564d2d0033cf7cb5ad9bd9c072f45d1afa915e345
```

La comprobación mediante:

```text
sha256sum -c
```

produjo:

```text
afluenciartp_desglosado_09_2026.csv: OK
diccionario_rtp_original.csv: OK
```

---

# 7. Inspección reproducible

Script reutilizado:

```text
proyecto/etl/inspeccionar_fuentes.py
```

Salida generada:

```text
proyecto/data/metadata/rtp/inspeccion_fuentes_rtp.json
```

Resultados del recurso principal:

```text
Registros:              41,676
Columnas:                    6
Filas malformadas:           0
Encoding:            utf-8-sig
Delimitador:                 ,
```

Estructura física recibida:

```text
fecha
mes
anio
servicio
tipo_pago
afluencia
```

No se modificó el CSV para ajustarlo a ninguna estructura previa.

---

# 8. Manifest

Script utilizado:

```text
proyecto/etl/generar_manifest.py
```

Manifest generado:

```text
proyecto/data/metadata/rtp/manifest_fuentes_rtp.csv
```

Sistema registrado:

```text
rtp
```

Fuentes registradas:

`2`

Estado registrado:

```text
INSPECCIONADO_PENDIENTE_VALIDACION
```

Este estado corresponde al momento histórico en que se generó el manifest.

No debe modificarse retrospectivamente porque la validación posterior se documenta mediante SQL, contrato y checkpoint.

---

# 9. Diccionario oficial vs estructura física

El diccionario oficial no coincide exactamente con el CSV recibido.

El diccionario documenta:

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

El CSV recibido contiene:

```text
fecha
mes
anio
servicio
tipo_pago
afluencia
```

También se observa:

```text
diccionario: ano
CSV:         anio
```

Decisión metodológica:

- conservar el diccionario como evidencia oficial;
- no modificarlo;
- no modificar RAW;
- utilizar para el pipeline la estructura física realmente recibida y validada.

---

# 10. Scripts implementados

## Ingestión

```text
proyecto/sql/ingestion/rtp/01_stage_rtp.sql
proyecto/sql/ingestion/rtp/02_ingesta_rtp.sql
```

## Perfilado

```text
proyecto/sql/quality/rtp/03_perfilado_rtp.sql
```

## Tipado y limpieza

```text
proyecto/sql/integration/rtp/04_typed_rtp.sql
proyecto/sql/integration/rtp/05_clean_rtp.sql
```

## Validación

```text
proyecto/sql/quality/rtp/06_validacion_rtp.sql
```

Contrato:

```text
proyecto/docs/contrato_datos_rtp.md
```

---

# 11. STAGING

Tabla:

```text
proyecto.rtp_desglosada_stage
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

Todas las columnas ingresaron inicialmente como `TEXT`.

No se aplicó:

- limpieza;
- homologación;
- tipado semántico;
- eliminación de filas;
- conversión de NaN;
- eliminación de ceros;
- eliminación de duplicados;
- eliminación de outliers.

Conteo:

```text
41,676
```

Conciliación contra manifest:

```text
Esperado:       41,676
Obtenido:       41,676
Diferencia:          0
```

Carga:

```text
COPY 41676
```

Resultado:

**STAGING RTP VALIDADO**

---

# 12. Perfilado estructural

Vacíos:

```text
fecha:        0
mes:          0
anio:         0
servicio:     0
tipo_pago:    0
afluencia:    0
```

Convertibilidad:

```text
fechas inválidas:                     0
años inválidos:                       0
NaN:                                187
afluencias inválidas distintas NaN:   0
afluencias numéricas finitas:    41,489
```

Control total:

```text
41,489 numéricos
+ 187 NaN
= 41,676 registros
```

Diferencia:

`0`

---

# 13. Cobertura temporal

Cobertura validada:

```text
2022-01-01 → 2026-09-30
```

Fechas distintas:

`1,734`

Año mínimo:

`2022`

Año máximo:

`2026`

Coherencia:

```text
fecha ↔ anio: 0 inconsistencias
fecha ↔ mes:  0 inconsistencias
```

Los doce meses fueron reconocidos.

---

# 14. Tipo de pago

Dominio observado:

```text
Boleto
Gratuidad
Prepago
```

Distribución:

| Tipo de pago | Registros |
|---|---:|
| Boleto | 13,892 |
| Gratuidad | 13,892 |
| Prepago | 13,892 |

Total:

`41,676`

No se identificaron valores adicionales.

---

# 15. Afluencia

Valores numéricos finitos:

`41,489`

Valores no disponibles:

`187`

Mínimo:

`0`

Q1:

`49`

Mediana:

`1,723`

Media:

`12,522.74`

Q3:

`13,899`

Máximo:

`214,689`

Ceros:

`7,450`

Negativos:

`0`

Valores con componente decimal:

`53`

Decisión física:

```text
afluencia → NUMERIC
```

---

# 16. Tratamiento de NaN

STAGING preserva:

```text
187 literales NaN
```

Transformación:

```text
NaN RAW/STAGING
      ↓
NULL TYPED/CLEAN
```

No se convierte a cero.

Conteos validados:

```text
NaN STAGING:                187
NULL TYPED:                 187
NULL CLEAN:                 187
bandera no disponible:      187
inconsistencias:              0
```

Regla:

```text
NULL ≠ 0
```

---

# 17. Ceros

Ceros observados:

`7,450`

Los ceros permanecen como observaciones válidas.

No fueron:

- eliminados;
- convertidos a NULL;
- imputados;
- reemplazados.

CLEAN utiliza:

```text
es_afluencia_cero
```

Resultado:

```text
7,450 filas marcadas
```

---

# 18. Valores decimales

Valores con componente decimal:

`53`

Se conservan mediante:

```text
NUMERIC
```

No se aplicó:

- redondeo;
- truncamiento;
- conversión a entero.

---

# 19. TYPED

Tabla:

```text
proyecto.rtp_desglosada_typed
```

Tipos:

```text
fecha       DATE
mes         TEXT
anio        SMALLINT
servicio    TEXT
tipo_pago   TEXT
afluencia   NUMERIC
```

Conteos:

```text
STAGING: 41,676
TYPED:   41,676
Diferencia: 0
```

Preservación:

```text
NULL:       187
ceros:    7,450
decimales:   53
```

Resultado:

**TYPED RTP VALIDADO**

---

# 20. Semántica de servicio

La fuente utiliza el campo:

```text
servicio
```

No contiene un campo físico denominado:

```text
linea
```

El diccionario oficial define `servicio` como:

```text
Servicio de RTP de la medición de afluencia
```

El dominio observado contiene categorías operativas como:

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

Decisión:

```text
servicio ≠ linea
```

no puede asumirse automáticamente.

Para RTP, `servicio` se conserva como categoría operativa reportada por la fuente.

---

# 21. Variantes de servicio

STAGING/TYPED presentan:

`30`

representaciones textuales distintas.

Se detectaron cambios de:

- mayúsculas;
- minúsculas;
- acentuación;
- escritura;
- representación temporal.

No se homologó automáticamente todo el dominio.

Cada posible homologación fue evaluada contra la granularidad observada.

---

# 22. Homologación conservadora

Se validó la homologación de:

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

La prueba de seguridad produjo:

```text
276 claves con colisión
552 filas involucradas
276 registros excedentes
máximo 2 repeticiones
máximo 1 variante original por clave
```

Es decir:

**la homologación conservadora no genera nuevas colisiones.**

Filas homologadas:

`11,640`

---

# 23. Variantes no homologadas

Se probó una homologación más amplia para las familias textuales de:

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

Resultado:

```text
Baseline:
276 claves con colisión
552 filas

Después de homologar:
429 claves con colisión
858 filas
```

Colisiones artificiales nuevas:

`153`

Distribución:

```text
Ecobús:    90
Nochebús:  63
```

Decisión:

**NO homologar actualmente esas variantes.**

La similitud textual no constituye evidencia suficiente.

---

# 24. Dominio CLEAN

Después de la homologación conservadora:

```text
21 servicios
```

Dominio:

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

No debe interpretarse como 21 líneas físicas.

---

# 25. Granularidad

Hipótesis evaluada:

```text
fecha × servicio × tipo_pago
```

Resultado:

```text
276 grupos con colisión
552 filas involucradas
276 registros excedentes
máximo de 2 repeticiones
```

Por tanto:

```text
fecha × servicio × tipo_pago
```

**NO constituye una clave natural única validada.**

Se conserva como:

**granularidad analítica candidata con colisiones conocidas.**

No debe crearse una restricción `UNIQUE` sobre esa combinación.

---

# 26. Duplicados exactos

Resultado:

```text
81 grupos de duplicados exactos
162 filas involucradas
81 registros excedentes
máximo 2 repeticiones
```

No se eliminaron.

CLEAN los identifica mediante:

```text
es_duplicado_exacto
```

---

# 27. Colisiones no exactas

Total de claves con colisión:

`276`

Clasificación:

```text
81 exactas
195 con afluencia distinta
```

Dentro de las 195 diferentes:

```text
105:
0 + valor positivo

90:
valor positivo + valor positivo
```

Por tanto, las colisiones no pueden resolverse mediante una única regla automática.

---

# 28. Anomalía ATENEA

Todas las colisiones de la granularidad candidata se concentran en:

```text
ATENEA / Atenea
```

Fechas afectadas:

`92`

Distribución:

| Periodo | Días |
|---|---:|
| septiembre 2024 | 30 |
| julio 2025 | 31 |
| enero 2026 | 31 |

En cada fecha afectada:

```text
6 filas
3 tipos de pago
```

Es decir:

```text
2 Boleto
2 Gratuidad
2 Prepago
```

Distribución de las 276 colisiones:

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

No existe evidencia suficiente para decidir que:

- una fila sea incorrecta;
- las dos deban sumarse;
- deba usarse el máximo;
- deba usarse el mínimo;
- deba conservarse únicamente una;
- una represente una corrección posterior.

Decisión:

**preservar todas las observaciones y marcar la anomalía.**

---

# 29. Interpretación de la anomalía

Una hipótesis posible es que exista una dimensión operacional no publicada que distinga las observaciones.

Esta hipótesis no está demostrada.

No se inventó una dimensión para resolver artificialmente las colisiones.

Regla adoptada:

```text
preservar
+
marcar
+
documentar
```

---

# 30. Outliers

Método:

```text
IQR
```

Regla:

```text
x < Q1 - 1.5 × IQR
o
x > Q3 + 1.5 × IQR
```

Resultados:

```text
Q1:                49
Q3:            13,899
Límite inferior: -20,726
Límite superior: 34,674
```

Valores numéricos evaluados:

`41,489`

Posibles outliers:

`4,688`

Los outliers permanecen en CLEAN.

Bandera:

```text
es_outlier_iqr_global
```

---

# 31. CLEAN

Tabla:

```text
proyecto.rtp_desglosada_clean
```

Conteo:

`41,676`

Pérdida TYPED → CLEAN:

`0`

CLEAN conserva:

```text
servicio_original
servicio
```

para mantener la representación original y la versión homologada.

Variables temporales derivadas:

```text
mes_num
dia_semana_num
dia_semana
es_fin_semana
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

# 32. Flags CLEAN

Resultados:

```text
No disponibles:             187
Ceros:                    7,450
Filas colisión origen:      552
Filas colisión CLEAN:       552
Filas duplicado exacto:     162
Posibles outliers:        4,688
Filas servicio homologado: 11,640
```

Comparación de colisiones:

```text
Origen: 552
CLEAN:  552
```

Por tanto, CLEAN no creó nuevas colisiones.

---

# 33. Coherencia temporal CLEAN

Resultados:

```text
error_anio:        0
error_mes:         0
error_dia_semana:  0
```

Las variables temporales derivadas son coherentes con `fecha`.

---

# 34. Conciliación completa

| Capa | Registros |
|---|---:|
| STAGING | 41,676 |
| TYPED | 41,676 |
| CLEAN | 41,676 |

Pérdida total:

`0`

Se preservaron:

```text
187 valores no disponibles
7,450 ceros
53 valores decimales
81 grupos de duplicados exactos
276 grupos con colisión
4,688 posibles outliers
```

---

# 35. Validación integral

Script:

```text
proyecto/sql/quality/rtp/06_validacion_rtp.sql
```

Resultado observado:

# VALIDACIÓN RTP OK

La validación comprobó:

- conteos de STAGING, TYPED y CLEAN;
- trazabilidad NaN → NULL;
- campos críticos;
- coherencia temporal;
- cobertura;
- dominio de tipo de pago;
- dominio CLEAN de servicio;
- ceros;
- decimales;
- ausencia de negativos;
- duplicados exactos;
- colisiones;
- trazabilidad de colisiones origen ↔ CLEAN;
- anomalía ATENEA;
- outliers;
- banderas de calidad.

---

# 36. Estado final del pipeline

```text
FUENTE OFICIAL          ✅
RAW                     ✅
METADATA / PROCEDENCIA  ✅
INSPECCIÓN              ✅
SHA-256                 ✅
MANIFEST                ✅
STAGING                 ✅
PERFILADO               ✅
TYPED                   ✅
CLEAN                   ✅
VALIDACIÓN              ✅
CONTRATO DE DATOS       ✅
```

Resultado:

# PIPELINE INDIVIDUAL RTP: VALIDADO

---

# 37. Contrato de datos

Contrato:

```text
proyecto/docs/contrato_datos_rtp.md
```

El contrato establece formalmente:

- estructura;
- semántica;
- dominios;
- reglas de tipado;
- tratamiento de NaN;
- tratamiento de ceros;
- tratamiento de decimales;
- homologación conservadora;
- granularidad candidata;
- duplicados;
- colisiones;
- anomalía ATENEA;
- outliers;
- restricciones de uso.

---

# 38. Reglas vigentes de RTP

1. RAW es inmutable.

2. No sobrescribir los archivos adquiridos.

3. `NaN` no significa cero.

4. `NaN` pasa a `NULL` desde TYPED.

5. Los 7,450 ceros se preservan.

6. Los 53 valores decimales se preservan mediante `NUMERIC`.

7. Los 4,688 posibles outliers se preservan.

8. Los 81 grupos de duplicados exactos se preservan.

9. Las 276 colisiones se preservan.

10. No imponer unicidad sobre:

```text
fecha × servicio × tipo_pago
```

11. No interpretar automáticamente:

```text
servicio = linea
```

12. No fusionar variantes de Ecobús sin nueva evidencia.

13. No fusionar variantes de Nochebús sin nueva evidencia.

14. Mantener trazabilidad entre:

```text
servicio_original
servicio
```

15. Mantener las banderas de calidad.

16. No modificar Metro ni Metrobús para adaptar RTP.

---

# 39. Relación con el contrato multisistema preliminar

El checkpoint Metro ↔ Metrobús estableció provisionalmente:

```text
fecha × sistema × linea
```

RTP presenta una estructura distinta:

```text
fecha
servicio
tipo_pago
afluencia
```

y no posee una dimensión física `linea` demostrada como equivalente.

Además:

```text
fecha × servicio × tipo_pago
```

no es única.

Por tanto, todavía NO se declara compatible RTP con:

```text
fecha × sistema × linea
```

La incorporación de RTP puede obligar a reevaluar la granularidad multisistema preliminar.

---

# 40. Lo que NO se ha construido

Todavía no existe:

```text
integración física Metro + Metrobús + RTP
tabla de hechos multisistema definitiva
modelo dimensional definitivo
dataset multisistema definitivo
dataset integrado en processed/
cubo OLAP definitivo
modelo de minería definitivo
```

No deben crearse antes de terminar la evaluación multisistema correspondiente.

---

# 41. Estado de `processed/`

RTP no produjo un dataset materializado en:

```text
proyecto/data/processed/
```

La carpeta continúa reservada para etapas posteriores.

No se debe materializar todavía un dataset multisistema definitivo.

---

# 42. Próximo paso

Con el pipeline individual, contrato y checkpoint de RTP completos, el siguiente bloque será:

```text
CHECKPOINT DE COMPATIBILIDAD
RTP ↔ CONTRATO MULTISISTEMA PRELIMINAR
```

La evaluación deberá considerar al menos:

- cobertura temporal;
- semántica de afluencia;
- granularidad;
- `servicio` frente a `linea`;
- `tipo_pago`;
- existencia de colisiones;
- duplicados;
- NULL;
- ceros;
- NUMERIC;
- banderas de calidad;
- posibilidad de agregación segura;
- nivel analítico común;
- efecto de RTP sobre:

```text
fecha × sistema × linea
```

No debe realizarse integración física durante ese checkpoint.

---

# 43. Estado Git

Rama activa durante la Iteración 3:

```text
feature/etl-rtp
```

El trabajo todavía no debe considerarse integrado en `main`.

Antes de commit/push/PR deberá revisarse:

- metadata RTP;
- SQL de ingestión;
- SQL de perfilado;
- SQL de integración;
- SQL de validación;
- contrato;
- checkpoint;
- documentación general afectada.

No realizar todavía commit hasta completar esa revisión.

---

# 44. Respaldo

Los RAW están excluidos de Git.

El repositorio permitirá recuperar:

- scripts;
- metadata;
- manifest;
- hashes;
- contrato;
- checkpoint;
- decisiones metodológicas.

No permitirá recuperar automáticamente los bytes originales de los RAW.

Debe conservarse una copia externa de:

```text
afluenciartp_desglosado_09_2026.csv
53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv
```

junto con:

```text
checksums_fuentes_rtp.sha256
```

para garantizar reproducibilidad aun si el portal actualiza retroactivamente los archivos.

---

# 45. Punto exacto de continuación

Estado:

# ITERACIÓN 3 — RTP
# PIPELINE INDIVIDUAL VALIDADO

Siguiente actividad:

```text
COMPATIBILIDAD RTP
CON EL CONTRATO MULTISISTEMA PRELIMINAR
```

Antes de comenzar esa evaluación deberá comprobarse que toda la documentación de esta iteración está presente y consistente.

No se debe hacer commit, push ni Pull Request hasta completar primero esa revisión.