# Problemas de calidad e ingesta — Práctica 2

## ING-001 — Codificación del cliente psql

| Elemento | Descripción |
|---|---|
| Etapa | Ingesta |
| Evidencia | `psql` reportó que el byte `0x81` interpretado bajo `WIN1252` no tenía equivalente durante la ejecución del script UTF-8. |
| Causa | El cliente `psql` inició con `client_encoding = WIN1252`, mientras que el script SQL y los archivos de trabajo utilizan UTF-8. |
| Solución | Se estableció `\encoding UTF8` al inicio de `02_ingesta.sql`. |
| Verificación | `SHOW client_encoding;` devolvió `UTF8` y posteriormente las cargas finalizaron con `COPY 1999998` y `COPY 99999`. |
| Resultado | Problema resuelto sin modificar los CSV fuente. |