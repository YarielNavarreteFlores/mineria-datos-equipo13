# Checkpoint — Iteración 2: Metrobús

Fecha del checkpoint: 2026-11-01.
Rama de trabajo: feature/etl-metrobus.
Commit base observado de main:
1e68aadf8a8287be0aca544702f2b51d381d53eb.

## Proyecto

Inteligencia de demanda de los principales sistemas de transporte
público de la Ciudad de México.

La pregunta de minería, hipótesis, objetivos y alcance siguen
siendo los definidos en el README raíz.

Metro es el baseline validado. Metrobús está en comprensión y
preparación de datos; todavía no está integrado con Metro.

## Entorno

- Windows y Git Bash.
- VS Code para editar archivos.
- Python 3.12.10.
- PostgreSQL como motor principal.
- Base prevista: mineria_datos_2026b.
- Esquema previsto: proyecto.
- DBeaver para consultas SQL.
- psql para ejecutar \copy.
- Verificar conexión, usuario y disponibilidad de psql antes de cargar.

## Fuente

Portal:
https://datos.cdmx.gob.mx/dataset/afluencia-diaria-de-metrobus-cdmx

Organización y mantenedor: SEMOVI.
Licencia anunciada: CC-BY-4.0-ESP.
Actualización mostrada en la captura del portal:
2026-10-22 11:50 (UTC-06:00).

La fecha del portal no demuestra el periodo efectivo de los CSV.

La procedencia detallada se mantiene en:
proyecto/data/metadata/metrobus/procedencia_metrobus.md

Verificar que el registro de adquisición incluya URL directa,
fecha efectiva y nombres originales; no inventar datos faltantes.

## Archivos y resultados

| Archivo | Bytes | Registros | Columnas |
|---|---:|---:|---:|
| datos_metrobus_simple_raw.csv | 2068083 | 54159 | 5 |
| datos_metrobus_desglosada_raw.csv | 1388641 | 29386 | 6 |
| diccionario_metrobus_simple_original.csv | 948 | 5 | 9 |
| diccionario_metrobus_desglosada_original.csv | 1703 | 9 | 9 |

RAW:
proyecto/data/raw/metrobus/

Diccionarios y metadatos:
proyecto/data/metadata/metrobus/

Los cuatro archivos tienen 0 filas con longitud incorrecta.
Los hashes están en checksums_fuentes_metrobus.sha256.
La comprobación de los cuatro hashes devolvió OK.

## Estructura real de los CSV

Simple, en este orden:
fecha,anio,mes,linea,afluencia

Desglosada, en este orden:
fecha,mes,anio,linea,tipo_pago,afluencia

No confundir el orden de anio y mes entre recursos.

Granularidades candidatas, todavía no comprobadas:
- Simple: fecha × linea.
- Desglosada: fecha × linea × tipo_pago.

No imponer restricciones UNIQUE sobre estas claves sin perfilado.

## Encoding y lectura

Simple, Desglosada y diccionario Simple:
lectura estricta exitosa con utf-8-sig, sin BOM UTF-8.

Diccionario Desglosada:
lectura estricta exitosa con latin-1, sin BOM UTF-8.

No se encontraron caracteres U+FFFD.
Esto no demuestra ausencia de mojibake.
Latin-1 decodifica cualquier byte; su éxito no certifica
la codificación original del diccionario.

## Hallazgos pendientes

1. Simple contiene el literal NaN en afluencia.
   No convertirlo automáticamente a cero.

2. La primera fila observada de Simple contiene:
   2005-07-26,2005,Julio,Línea 1,3032667.
   Investigar escala, significado y consistencia durante el perfilado.
   No corregir ni eliminar por parecer extrema.

3. Desglosada tiene tipo_pago y afluencia.
   La muestra incluye Prepago y Gratuidad.

4. Su diccionario describe otra estructura, con estacion,
   afluencia_prepago, afluencia_gratuidad y afluencia_total.
   No corresponde directamente al CSV recibido.

5. El diccionario Simple usa ano donde el CSV utiliza anio.

6. El diccionario Desglosada contiene mojibake visible en parte
   del texto. Conservar el original.

7. La cobertura temporal completa, los dominios, los nulos,
   los duplicados, las colisiones y la convertibilidad
   todavía no han sido perfilados.

8. Simple y Desglosada no deben concatenarse ni sumarse
   automáticamente: primero estudiar solapamientos y medidas.

## Trabajo completado

- Creación de rama feature/etl-metrobus.
- Identificación de fuentes oficiales.
- Descarga y preservación de dos CSV RAW y dos diccionarios.
- Confirmación de exclusión de RAW mediante .gitignore.
- SHA-256 de los cuatro archivos y comprobación satisfactoria.
- Inspección mediante proyecto/etl/inspeccionar_fuentes.py.
- Lectura estricta y conciliación de conteos.
- Generación de inspeccion_fuentes_metrobus.json.
- Actualización de proyecto/etl/generar_manifest.py.
- Generación de manifest_fuentes_metrobus.csv con cuatro fuentes.
- Estado: INSPECCIONADO_PENDIENTE_VALIDACION.

El manifest de Metro no fue regenerado.
No se modificaron datos ni tablas de Metro.

## Punto exacto de continuación

Todavía no se han creado ni cargado tablas STAGING de Metrobús.

El siguiente bloque de trabajo es:
1. Revisar los scripts SQL existentes de Metro como referencia.
2. Confirmar conexión PostgreSQL y disponibilidad de psql.
3. Crear scripts STAGING específicos para Metrobús.
4. Recibir las columnas originales como TEXT.
5. Preparar ingestión reproducible con listas explícitas de columnas.
6. Preservar el literal NaN y documentar el tratamiento de vacíos.
7. Conciliar cargas: Simple 54159 y Desglosada 29386.
8. Perfilar antes de diseñar TYPED.
9. Continuar con CLEAN, validación y contrato de datos.
10. Evaluar compatibilidad con Metro después de validar Metrobús.

No se ha definido el modelo dimensional ni el modelo de minería.

## Reglas para continuar

- Indicar siempre dónde ejecutar: Git Bash, PowerShell,
  DBeaver o VS Code.
- Proporcionar pasos pequeños y código completo cuando se solicite.
- No modificar RAW.
- No eliminar ceros, extremos o colisiones sin evidencia.
- Trabajar mediante rama y Pull Request.
- No declarar validado el pipeline a partir del manifest.
- Mantener los cinco entregables finales previstos en el README raíz.

## Respaldo

Los RAW están excluidos de Git.
El repositorio permite recuperar código y metadatos, pero no
los bytes originales de esos datasets.

Conservar una copia externa de los RAW y de sus checksums,
porque la fuente oficial puede actualizar datos históricos.