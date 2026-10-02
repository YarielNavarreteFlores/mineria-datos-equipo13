# Práctica 2 — Ingesta, limpieza y EDA

Unidad de Aprendizaje: Minería de Datos  
Licenciatura en Ciencia de Datos — ESCOM-IPN  
Periodo: 2026-B

## Equipo 13

- Navarrete Flores Yariel — Coordinador / Analista de datos
- Nava Villar Eric — Ingeniero de datos / Arquitecto
- Uribe Sánchez Edén — Machine Learning / Visualizador

## Objetivo

Implementar un proceso reproducible de inspección, ingesta, limpieza,
tipado, consolidación y análisis exploratorio sobre archivos históricos
de COVID-19 utilizando PostgreSQL.

## Tecnología utilizada

- PostgreSQL 18.3
- psql
- DBeaver
- Python 3
- Git / GitHub
- PowerShell
- Visual Studio Code

## Flujo de procesamiento

RAW
→ inspección
→ preparación del archivo 2022
→ STAGING
→ perfilado
→ tablas tipadas
→ consolidación histórica
→ auditoría de calidad
→ EDA
→ validación final

## Volúmenes verificados

| Fuente | Registros |
|---|---:|
| COVID 2022 | 1,999,998 |
| COVID 2023 | 99,999 |
| Histórica consolidada | 2,099,997 |

## Estructura

`data/raw/`  
Contiene los archivos originales. No deben modificarse.

`data/working/`  
Contiene archivos derivados reproducibles.

`data/catalogos/`  
Catálogos y descriptores proporcionados para interpretar los dominios.

`scripts/`  
Scripts Python para inspección, perfilado y preparación de fuentes.

`sql/postgresql/`  
Pipeline SQL oficial de la práctica.

`docs/`  
Documentación técnica, decisiones y problemas de calidad.

`evidencias/`  
Capturas seleccionadas de la ejecución.

`reporte/`  
Reporte final en Word y PDF.

## Orden de ejecución

### 1. Inspección de fuentes
```powershell
python practica02\scripts\inspeccionar_fuentes.py
```
### 2. Preparar fuente 2022
```powershell
python practica02\scripts\preparar_2022.py
```
### 3. Perfilado de archivos
```powershell
python practica02\scripts\perfilar_fuentes.py
```
### 4. PostgreSQL
Ejecutar en orden:
1. 00_database.sql
2. 01_stage.sql
### 5. Ingesta mediante psql
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" `
-h localhost `
-p 5432 `
-U postgres `
-d covid20a23sedi `
-v ON_ERROR_STOP=1 `
-f "practica02\sql\postgresql\02_ingesta.sql"
```
Las rutas del script deben ajustarse si el repositorio se encuentra en
otra ubicación.
### 6. Continuar en PostgreSQL
Ejecutar en este orden:

3. 03_perfilado.sql
4. 04_tabla_tipada.sql
5. 05_consolidacion.sql
6. 06_calidad.sql
7. 07_eda.sql
8. 08_validacion_final.sql

## Resultados finales de control
- STAGE 2022: 1,999,998 — OK
- TIPADA 2022: 1,999,998 — OK
- STAGE 2023: 99,999 — OK
- TIPADA 2023: 99,999 — OK
- HISTÓRICA: 2,099,997 — OK
- ID_REGISTRO NULL: 0 — OK
- ID_REGISTRO repetidos: 0 — OK
- Inconsistencias de nacionalidad analizadas: 0 — OK

## Consideraciones
Los valores originales se preservan en las capas RAW y STAGE.


Los códigos categóricos 97, 98 y 99 no se sustituyen automáticamente por
NULL. Su interpretación depende del catálogo correspondiente.


El centinela de fecha `9999-99-99` se transforma a NULL únicamente en
las tablas tipadas.


Las columnas exclusivas de 2023 producen NULL estructural al homologar
los registros de 2022.


No se incluyen credenciales, contraseñas ni llaves en el repositorio.