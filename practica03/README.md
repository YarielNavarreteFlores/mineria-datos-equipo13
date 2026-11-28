# Práctica 3 · Modelo multidimensional y ETL

Minería de Datos · ESCOM-IPN · Equipo 13 · Grupo 5AV1 · 2026-B

A partir de la tabla histórica de vigilancia de COVID-19 de la [Práctica 2](../practica02/), construimos un esquema estrella en PostgreSQL para analizar los registros por mes de ingreso, entidad de residencia y clasificación final.

## Entrega y evidencias

- [Reporte entregado en Classroom (PDF)](reporte/Practica_3_Equipo_13.pdf)
- [Reporte editable (Word)](reporte/Practica_3_Equipo_13.docx)
- [Diagrama del esquema estrella](docs/Figuras/P3_15_diagrama_estrella.png)
- [Scripts SQL](sql/postgresql/) y [guía de ejecución](docs/LEEME.txt)
- [Catálogos y correspondencia de las 46 columnas](docs/Catalogos/)
- [Resultados exportados desde DBeaver](docs/Resultados/)
- [Gráficas](docs/Figuras/) y [12 capturas de ejecución seleccionadas](evidencias/)
- [Prompt, fichas y respuestas de los tres modelos locales](docs/Consultas_LLM/)

## Reproducción y validación

La entrada es `public.covid_historica` en la base `covid20a23sedi`.
En una instalación nueva, ejecutar P3_08 a P3_12 en ese orden para crear
el esquema `p3_covid`, cargar las dimensiones y conciliar la tabla de hechos.
P3_13 y P3_14_16 permiten consultar la exploración y los controles de calidad.

P3_08, P3_11 y P3_12 corresponden a los scripts recuperados de la ejecución.
P3_09 y P3_10 se incluyen como versiones de reproducción.

Cada fila de `fact_registro_covid` representa un registro de vigilancia.
La carga conservó 1,999,998 registros de la fuente 2022 y 99,999 de la
fuente 2023, para un total de **2,099,997**. El modelo contiene ocho
dimensiones y doce claves foráneas. Los agregados de una, dos y tres
dimensiones recuperan ese mismo total al verificarse por separado.
