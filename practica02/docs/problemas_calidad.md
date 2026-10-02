# Problemas de calidad e ingesta — Práctica 2

Este documento resume los problemas detectados durante la inspección,
ingesta, limpieza y consolidación de los archivos COVID-19 utilizados en
la Práctica 2.

## DQ-001 — Duplicación física del archivo 2022

**Etapa:** inspección inicial.

**Evidencia:** el archivo
`muestra200k_COVID19MEXICOLOC2022.csv` tiene un tamaño de
686,356,922 bytes y puede dividirse exactamente en dos segmentos de
343,178,461 bytes.

Ambos segmentos producen el mismo SHA-256:

`9192b9abe85267252cb8ebaf0b2f6b3ea6e36bf0617eb70c3637a85d5946c782`

**Causa probable:** concatenación accidental de dos copias idénticas del
mismo archivo.

**Solución:** conservar el archivo RAW intacto y generar mediante
`scripts/preparar_2022.py` una copia de trabajo con una sola instancia
del segmento válido.

**Verificación:** la copia de trabajo contiene 1,999,998 registros,
41 columnas y 0 filas estructuralmente malformadas.

---

## DQ-002 — Evolución de esquema entre 2022 y 2023

**Etapa:** inspección y diseño de STAGING.

**Evidencia:**

- 2022 contiene 41 columnas.
- 2023 contiene 44 columnas.
- 2023 incorpora `MUNICIPIO_UM`, `CLUES` y `FECHA_RESULTADO`.

**Causa:** evolución del esquema publicado entre periodos.

**Solución:** utilizar tablas STAGE separadas para 2022 y 2023 y
homologar posteriormente ambas fuentes en `covid_historica`.

**Verificación:** `covid_stage_2022` contiene 41 columnas TEXT y
`covid_stage_2023` contiene 44 columnas TEXT.

---

## DQ-003 — Centinela 9999-99-99 en campos de fecha

**Etapa:** perfilado y refinamiento de tipos.

**Evidencia:**

- `FECHA_DEF` 2022: 1,983,215 valores `9999-99-99`.
- `FECHA_DEF` 2023: 99,223 valores `9999-99-99`.
- `FECHA_RESULTADO` 2023: 82,283 valores `9999-99-99`.

**Causa:** representación no-fecha utilizada por la fuente para indicar
ausencia o no aplicación.

**Solución:** mantener el valor original en STAGE y convertirlo a NULL
únicamente en las tablas tipadas.

**Verificación:**

- `FECHA_DEF` NULL 2022: 1,983,215.
- `FECHA_DEF` NULL 2023: 99,223.
- `FECHA_RESULTADO` NULL 2023: 82,283.

No se detectaron fechas inválidas adicionales.

---

## DQ-004 — Carácter de tabulación en MIGRANTE

**Etapa:** perfilado previo al tipado.

**Evidencia:** el registro `ID_REGISTRO = 15ec76` contiene el valor
`<TAB>99` en `MIGRANTE`.

**Causa probable:** carácter de control incorporado durante la generación
o exportación de la fuente.

**Solución:** aplicar `BTRIM(valor, E' \t\r\n')` antes de convertir a
SMALLINT.

**Verificación:** el valor tipado resultante es `99` y el registro
original permanece disponible en STAGE.

---

## ING-001 — Codificación del cliente psql

**Etapa:** ingesta.

**Evidencia:** durante la primera ejecución, `psql` reportó que el byte
`0x81` bajo `WIN1252` no tenía equivalente durante la ejecución del
script UTF-8.

**Causa:** el cliente inició con `client_encoding = WIN1252`, mientras
que los scripts y fuentes se manejan en UTF-8.

**Solución:** establecer `\encoding UTF8` al inicio de
`02_ingesta.sql`.

**Verificación:** `SHOW client_encoding;` devolvió `UTF8` y las cargas
finalizaron con:

- `COPY 1999998`
- `COPY 99999`

---

## DQ-005 — NULL estructural por evolución de esquema

**Etapa:** consolidación histórica.

**Evidencia:** las variables `MUNICIPIO_UM`, `CLUES` y
`FECHA_RESULTADO` no existen en el archivo 2022.

**Causa:** cambio de esquema entre periodos.

**Solución:** asignar NULL durante la homologación de 2022 hacia
`covid_historica`.

**Verificación:**

- `MUNICIPIO_UM`: 1,999,998 NULL correspondientes a 2022.
- `CLUES`: 1,999,998 NULL correspondientes a 2022.
- `FECHA_RESULTADO`: 1,999,998 NULL estructurales en 2022, además de
  los NULL derivados del centinela en 2023.

Estos NULL no se interpretan automáticamente como pérdida de calidad,
sino como ausencia estructural de la variable en el esquema 2022.

---

## Resultado general

La tabla histórica consolidada contiene 2,099,997 registros.

No se detectaron:

- valores NULL en `ID_REGISTRO`;
- identificadores repetidos;
- duplicados exactos;
- pérdidas de filas entre STAGE y tablas tipadas;
- inconsistencias entre `NACIONALIDAD` y `PAIS_NACIONALIDAD` bajo las
  reglas analizadas.

La validación final definida en `08_validacion_final.sql` terminó con
estado `OK` en todos los controles críticos.