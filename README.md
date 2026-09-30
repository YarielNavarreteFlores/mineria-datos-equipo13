# Minería de Datos — Equipo 13

> **Documento maestro operativo del semestre**  
> Licenciatura en Ciencia de Datos · ESCOM · Instituto Politécnico Nacional  
> Unidad de Aprendizaje: **Minería de Datos** · Periodo **2026-B**

---

## 0. Propósito de este README

Este archivo es la **fuente central de contexto, operación y coordinación del Equipo 13** durante el semestre.

Su objetivo es que cualquier integrante pueda responder, sin depender de mensajes dispersos o conocimiento informal, las siguientes preguntas:

- ¿Qué problema estamos resolviendo?
- ¿Cuál es la pregunta de minería y la hipótesis de trabajo?
- ¿Qué se ha completado y qué sigue pendiente?
- ¿Qué datos utilizamos y cómo se deben manejar?
- ¿Cuál es la arquitectura técnica del proyecto?
- ¿Cómo se relacionan las prácticas con el proyecto semestral?
- ¿Qué herramientas son oficiales o previstas?
- ¿Qué reglas de calidad seguimos?
- ¿Cómo trabajamos con Git y GitHub?
- ¿Cómo se aprueba un cambio?
- ¿Qué significa que una tarea esté realmente terminada?
- ¿Qué entregables finales debemos preparar?
- ¿Qué decisiones debemos poder defender técnicamente?

Este README debe mantenerse actualizado durante todo el semestre. Si una instrucción del profesor cambia el alcance, una fuente de datos, una práctica, una técnica o un entregable, el cambio debe reflejarse aquí mediante un Pull Request.

---

# 1. Contexto académico

| Elemento | Información |
|---|---|
| Institución | Instituto Politécnico Nacional |
| Unidad académica | Escuela Superior de Cómputo (ESCOM) |
| Programa académico | Licenciatura en Ciencia de Datos |
| Unidad de aprendizaje | Minería de Datos |
| Semestre curricular | V |
| Periodo del proyecto | 2026-B |
| Equipo | Equipo 13 |
| Repositorio | `mineria-datos-equipo13` |
| Visibilidad | Privado |
| Rama estable | `main` |

La Unidad de Aprendizaje busca implementar procesos de minería de datos utilizando modelos de datos, procesamiento analítico en línea y técnicas de minado. El proyecto semestral debe evolucionar desde la comprensión y preparación de los datos hasta la construcción, evaluación e interpretación de modelos.

---

# 2. Equipo y responsabilidades

| Integrante | Rol principal | Rol complementario | Responsabilidades base |
|---|---|---|---|
| **Navarrete Flores Yariel** | Coordinador | Analista de datos | Control de alcance, coordinación, CRISP-DM, análisis, integración de entregables, revisión de Pull Requests y seguimiento del repositorio |
| **Nava Villar Eric** | Ingeniero de datos | Arquitecto | Ingesta, PostgreSQL, estructura de datos, auditoría, ETL, RAW/CLEAN, integración y arquitectura |
| **Uribe Sánchez Edén** | Machine Learning | Visualizador | EDA, Tableau, preparación para modelado, modelos, evaluación, interpretación y comunicación visual |

### 2.1 Principio de corresponsabilidad

Los roles indican una **responsabilidad primaria**, no propiedad exclusiva.

Ejemplo:

- Eric puede ser responsable principal de un ETL, pero otro integrante debe poder entenderlo y revisarlo.
- Edén puede desarrollar una visualización o modelo, pero debe quedar documentado y reproducible.
- Yariel coordina e integra, pero también debe trabajar mediante ramas y Pull Requests.

Ninguna parte crítica del proyecto debe depender únicamente del conocimiento de una persona.

---

# 3. Nombre del proyecto semestral

## **Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México**

---

# 4. Planteamiento del problema

Los datos de afluencia de los principales sistemas de transporte público de la Ciudad de México se publican de forma separada y pueden presentar diferencias en:

- periodos históricos;
- nombres de variables;
- granularidad;
- estructuras de archivo;
- codificación;
- categorías;
- unidades operativas;
- cobertura temporal;
- nivel de detalle.

Esta heterogeneidad dificulta construir una visión integrada y comparable de la demanda.

Antes de aplicar técnicas de minería de datos se requiere un proceso reproducible que permita:

1. localizar y documentar las fuentes;
2. preservar los datos originales;
3. cargar los datos a un DBMS;
4. perfilar su estructura;
5. auditar calidad;
6. limpiar y homologar;
7. integrar sistemas compatibles;
8. definir una granularidad analítica;
9. construir una base histórica;
10. habilitar análisis OLAP;
11. preparar variables para minería;
12. modelar;
13. evaluar;
14. interpretar;
15. comunicar los resultados.

---

# 5. Pregunta de minería

> **¿Qué patrones temporales y operativos caracterizan la demanda de los principales sistemas de transporte público de la Ciudad de México y en qué medida dichos patrones pueden utilizarse para clasificar o estimar niveles de afluencia?**

---

# 6. Hipótesis de trabajo

La demanda presenta patrones diferenciables por variables como:

- sistema de transporte;
- línea;
- estación o unidad operativa equivalente;
- día;
- mes;
- periodo del año;
- modalidad de acceso, cuando esté disponible.

Estos patrones pueden permitir identificar perfiles de comportamiento y, posteriormente, construir modelos capaces de **clasificar o estimar niveles de afluencia** a partir de información histórica.

La hipótesis deberá ser revisada conforme aumente la cobertura multisistema y se defina con precisión la variable objetivo del modelado.

---

# 7. Objetivo general

Analizar y modelar los patrones históricos de demanda de los principales sistemas de transporte público de la Ciudad de México mediante técnicas de minería de datos, integrando información oficial de afluencia para identificar comportamientos temporales y operativos y evaluar modelos descriptivos y predictivos.

---

# 8. Objetivos específicos

1. Recolectar y documentar conjuntos oficiales de afluencia de los sistemas seleccionados.
2. Preservar los datos originales en una capa RAW.
3. Diseñar un proceso ETL reproducible.
4. Perfilar los conjuntos de datos antes de modificarlos.
5. Detectar y documentar problemas de calidad.
6. Limpiar, homologar e integrar las fuentes sin destruir trazabilidad.
7. Construir una base histórica analítica.
8. Definir un modelo multidimensional para análisis OLAP.
9. Analizar estadísticamente evolución, distribución, variabilidad y atipicidad.
10. Preparar variables para técnicas descriptivas y predictivas.
11. Aplicar técnicas de minería coherentes con la pregunta del proyecto.
12. Evaluar modelos con métricas apropiadas.
13. Analizar interpretabilidad y limitaciones.
14. Comunicar hallazgos mediante visualización, reporte, presentación y exposición.
15. Mantener el proyecto reproducible y versionado mediante Git y GitHub.

---

# 9. Alcance actual

## 9.1 Sistemas contemplados

El proyecto se plantea de forma incremental.

### Primera iteración validada

- **STC Metro**

### Sistemas previstos para evaluación e integración posterior

- Metrobús
- RTP
- Cablebús
- Trolebús
- Tren Ligero

La incorporación de una fuente no debe hacerse únicamente porque exista. Antes de integrarla se debe comprobar:

- procedencia;
- cobertura;
- esquema;
- granularidad;
- calidad;
- compatibilidad temporal;
- compatibilidad semántica;
- utilidad para la pregunta de minería.

## 9.2 Fuera de alcance actual

Salvo que el profesor indique un cambio, no se considera parte del alcance inicial:

- ruteo en tiempo real;
- optimización operacional de rutas;
- predicción de retrasos;
- causalidad de cambios de demanda;
- recomendaciones personalizadas de viaje;
- sistemas de navegación;
- inferencias causales sin diseño estadístico que las sustente.

El proyecto puede describir asociaciones o cambios observados, pero **no debe convertir correlación en causalidad**.

---

# 10. Metodología principal: CRISP-DM

El proyecto se organiza principalmente mediante **CRISP-DM**.

| Fase | Propósito | Estado actual |
|---|---|---|
| 1. Comprensión del negocio/problema | Problema, pregunta, hipótesis, objetivos, alcance y criterios de éxito | **Avanzada** |
| 2. Comprensión de los datos | Fuentes, volumen, cobertura, granularidad, diccionarios, perfilado y calidad | **Avanzada con Metro** |
| 3. Preparación de los datos | Ingesta, limpieza, homologación, integración, transformación y variables derivadas | **En desarrollo** |
| 4. Modelado | Técnicas estadísticas, asociación, árboles, redes y modelos pertinentes | **Pendiente** |
| 5. Evaluación | Métricas, validación, comparación, interpretación y limitaciones | **Pendiente** |
| 6. Despliegue académico | Base analítica, tablero, reporte, presentación, código y exposición | **Pendiente** |

CRISP-DM es iterativo. Una fase posterior puede obligar a regresar a una fase anterior.

---

# 11. Fases operativas del proyecto

Para trabajar con mayor detalle, el equipo utiliza la siguiente ruta operativa:

| Fase operativa | Resultado esperado |
|---|---|
| 0. Fundamentos | Reglas, herramientas, repositorio y metodología |
| 1. Formulación | Problema, pregunta, hipótesis, objetivos y alcance |
| 2. Datos | Inventario, fuentes, diccionarios, granularidad y auditoría inicial |
| 3. ETL | RAW → staging → tipado → limpieza → consolidación |
| 4. Data Warehouse / OLAP | Modelo dimensional y consultas analíticas |
| 5. EDA | Análisis descriptivo, temporal, operativo y visual |
| 6. Minería | Construcción de modelos y patrones |
| 7. Evaluación | Validación, métricas, comparación e interpretación |
| 8. Interpretación | Hallazgos, limitaciones y conocimiento obtenido |
| 9. Entregables | Reporte, presentación, código, datos y exposición |

---

# 12. Arquitectura de datos objetivo

La arquitectura debe conservar trazabilidad desde la fuente hasta el resultado final.

```text
FUENTES OFICIALES
      │
      ▼
RAW
(datos originales, inmutables)
      │
      ▼
STAGING
(carga inicial / tipos flexibles)
      │
      ▼
PERFILADO Y AUDITORÍA
(nulos, duplicados, dominios, claves, formatos, outliers)
      │
      ▼
TIPADO
(conversión controlada a tipos correctos)
      │
      ▼
CLEAN
(correcciones y homologación)
      │
      ▼
CONSOLIDACIÓN / INTEGRACIÓN
(unión de fuentes compatibles)
      │
      ▼
PROCESSED / ANALYTICAL
(datos preparados para análisis)
      │
      ├─────────────► OLAP
      │
      ├─────────────► EDA / TABLEAU
      │
      └─────────────► FEATURES / MODELOS
                            │
                            ▼
                       EVALUACIÓN
                            │
                            ▼
                       RESULTADOS
```

---

# 13. Capas de datos

## 13.1 RAW

Contiene los archivos exactamente como fueron obtenidos.

Reglas:

- No corregir.
- No renombrar columnas dentro del archivo original.
- No eliminar filas.
- No sobreescribir una descarga anterior sin documentarlo.
- Registrar fuente y fecha de obtención.
- Los archivos grandes RAW **no se versionan en Git**.

## 13.2 STAGING

Zona de ingestión inicial al DBMS.

Objetivos:

- cargar sin perder información;
- detectar problemas antes de tipar;
- evitar transformaciones prematuras;
- permitir auditoría reproducible.

## 13.3 TYPED / tipada

Convierte campos desde staging a tipos controlados:

- fechas;
- enteros;
- numéricos;
- booleanos;
- categorías.

Toda conversión debe contemplar qué sucede cuando un valor no puede convertirse.

## 13.4 CLEAN

Capa donde se aplican correcciones justificadas:

- codificación;
- homologación;
- formatos;
- variables derivadas;
- banderas de calidad.

Una transformación CLEAN debe poder explicarse mediante:

> problema → evidencia → decisión → transformación → validación.

## 13.5 PROCESSED / ANALYTICAL

Datos específicamente preparados para:

- agregaciones;
- OLAP;
- EDA;
- minería;
- modelado;
- evaluación.

No debe confundirse con RAW ni con CLEAN.

---

# 14. Política de calidad de datos

## 14.1 Principio general

> **Detectar una anomalía no significa que deba eliminarse.**

Toda decisión debe sustentarse en evidencia.

## 14.2 Aspectos mínimos de auditoría

Cada nueva fuente debe revisar al menos:

- número de filas;
- número de columnas;
- nombres de variables;
- tipos;
- cobertura temporal;
- granularidad;
- nulos;
- duplicados exactos;
- colisiones de claves candidatas;
- valores negativos cuando no sean válidos;
- categorías;
- codificación;
- fechas;
- dominios;
- valores extremos;
- consistencia entre columnas;
- consistencia con diccionario oficial.

## 14.3 Nulos

Antes de imputar o eliminar:

1. cuantificar;
2. localizar;
3. determinar si el nulo es estructural o anómalo;
4. documentar;
5. justificar el tratamiento.

## 14.4 Duplicados

Distinguir:

- duplicado exacto;
- repetición válida;
- colisión de una clave candidata;
- múltiples registros válidos a mayor granularidad.

No eliminar registros solo porque una combinación aparente repetirse.

## 14.5 Outliers

Un outlier estadístico no implica un error de captura.

Opciones posibles:

- conservar;
- marcar;
- investigar;
- filtrar solo en análisis específicos;
- transformar únicamente con justificación.

## 14.6 Ceros

Un valor cero puede representar un estado real.

No convertir automáticamente cero a nulo ni eliminarlo.

## 14.7 Codificación

Problemas como mojibake deben resolverse preservando:

- valor original;
- regla de corrección;
- valor homologado;
- evidencia de que la corrección no altera categorías legítimas.

---

# 15. Baseline técnico: Práctica 1

La Práctica 1 constituye la primera iteración técnica documentada del proyecto.

## 15.1 Recursos analizados

### Metro Simple

| Propiedad | Valor |
|---|---|
| Registros | 1,180,920 |
| Cobertura | 2010-01-01 a 2026-07-31 |
| Granularidad | fecha – línea – estación |
| Formato | CSV |

### Metro Desglosada

| Propiedad | Valor |
|---|---|
| Registros | 1,192,230 |
| Cobertura | 2021-01-01 a 2026-07-31 |
| Granularidad | fecha – línea – estación – tipo_pago |
| Formato | CSV |

## 15.2 Hallazgos principales

En el recurso simple se documentaron, entre otros:

- 0 nulos en los campos auditados;
- 0 duplicados exactos;
- 31 grupos de colisión de clave candidata;
- 62 filas involucradas en esas colisiones;
- 62,025 registros con afluencia igual a cero;
- 66,361 observaciones detectadas como outliers por IQR;
- problemas de mojibake en nombres de estaciones;
- variantes de codificación en líneas.

En el recurso desglosado también se documentaron ceros, outliers y problemas de representación, sin tratarlos automáticamente como errores.

## 15.3 Decisiones establecidas

- RAW se preserva.
- CLEAN no elimina filas sin justificación.
- Ceros se conservan y pueden marcarse.
- Outliers se conservan y pueden marcarse.
- Colisiones de clave se conservan mientras no exista evidencia suficiente para resolverlas.
- Se derivan variables temporales cuando sean útiles.
- Las visualizaciones analíticas pueden aplicar filtros documentados sin destruir los datos base.

## 15.4 Flujo validado

```text
Portal de Datos Abiertos CDMX
        ↓
RAW
        ↓
PostgreSQL
        ↓
Auditoría SQL
        ↓
CLEAN
        ↓
Tableau
        ↓
Preparación para OLAP / minería
```

La Práctica 1 se conserva en el repositorio como histórico y está marcada con el tag:

```text
practica-01-entregada
```

---

# 16. Práctica 2 — Estado operativo

> **Estado: EN DESARROLLO**

La Práctica 2 se desarrolla desde el inicio con trazabilidad en Git/GitHub.

Su estructura actual es:

```text
practica02/
│
├── README.md
│
├── data/
│   ├── raw/
│   ├── catalogos/
│   ├── manifest_fuentes.csv
│   └── README.md
│
├── sql/
│   ├── README.md
│   ├── postgresql/
│   │   ├── 00_database.sql
│   │   ├── 01_stage.sql
│   │   ├── 02_ingesta.sql
│   │   ├── 03_perfilado.sql
│   │   ├── 04_tabla_tipada.sql
│   │   ├── 05_consolidacion.sql
│   │   ├── 06_calidad.sql
│   │   ├── 07_eda.sql
│   │   └── 08_validacion_final.sql
│   │
│   └── sqlserver/
│       ├── 01_stage.sql
│       └── 02_ingesta.sql
│
├── docs/
│   ├── inspeccion_inicial.md
│   ├── problemas_calidad.md
│   ├── decisiones_limpieza.md
│   └── bitacora.md
│
├── evidencias/
│   └── README.md
│
└── reporte/
    └── README.md
```

## 16.1 Orden lógico PostgreSQL

```text
00_database.sql
      ↓
01_stage.sql
      ↓
02_ingesta.sql
      ↓
03_perfilado.sql
      ↓
04_tabla_tipada.sql
      ↓
05_consolidacion.sql
      ↓
06_calidad.sql
      ↓
07_eda.sql
      ↓
08_validacion_final.sql
```

La numeración indica orden lógico de ejecución.

## 16.2 PostgreSQL y SQL Server

- **PostgreSQL** es la implementación principal del proyecto.
- **SQL Server** se utiliza como implementación secundaria/comparativa cuando la práctica lo requiera.
- No se mantendrá artificialmente paridad absoluta entre ambos motores si el curso no la exige.
- La arquitectura semestral principal continuará construyéndose alrededor de PostgreSQL.

---

# 17. Registro real de prácticas del curso

Esta tabla representa **lo que realmente asigna el profesor**, no lo que suponemos que ocurrirá.

Debe actualizarse cada vez que exista una nueva práctica.

| # | Práctica real asignada | Relación con proyecto semestral | Estado | Carpeta / evidencia |
|---|---|---|---|---|
| 1 | Definición del proyecto semestral | Directa | ✅ Entregada | `practica01/` |
| 2 | En desarrollo — consultar instrucciones vigentes | Por determinar / en validación | 🟡 En desarrollo | `practica02/` |
| 3 | Por definir | Por determinar | ⚪ Pendiente | — |
| 4 | Por definir | Por determinar | ⚪ Pendiente | — |
| 5 | Por definir | Por determinar | ⚪ Pendiente | — |
| 6 | Por definir | Por determinar | ⚪ Pendiente | — |
| 7 | Por definir | Por determinar | ⚪ Pendiente | — |
| 8 | Por definir | Por determinar | ⚪ Pendiente | — |
| 9 | Por definir | Por determinar | ⚪ Pendiente | — |
| 10 | Por definir | Por determinar | ⚪ Pendiente | — |

> La cantidad real de prácticas y su relación con el proyecto dependerán de las instrucciones del profesor.

---

# 18. Referencia curricular de prácticas

El programa oficial de la Unidad de Aprendizaje incluye como referencia una secuencia de diez prácticas:

| Referencia | Nombre en programa oficial | Unidad |
|---|---|---|
| 1 | Creación de cubos de datos | I |
| 2 | Administración de un cubo de datos | I |
| 3 | Preprocesamiento de datos I | II |
| 4 | Preprocesamiento de datos II | II |
| 5 | Técnicas de modelado I | III |
| 6 | Técnicas de modelado II | III |
| 7 | Técnicas de modelado III | III |
| 8 | Técnicas de modelado IV | III |
| 9 | Obtención e interpretación de los modelos obtenidos | IV |
| 10 | Evaluación del modelo | IV |

**Importante:** esta tabla es una referencia curricular. No sustituye las instrucciones reales del profesor ni significa que las prácticas del grupo deban tener exactamente esos nombres, números o entregables.

---

# 19. Arquitectura técnica del proyecto

## 19.1 DBMS principal

### PostgreSQL + DBeaver

Uso previsto:

- carga RAW;
- staging;
- auditoría;
- consultas;
- tipado;
- CLEAN;
- integración;
- índices;
- trazabilidad;
- base histórica;
- modelo dimensional;
- consultas OLAP.

## 19.2 SQL Server

Uso previsto:

- ejercicios o comparaciones solicitadas;
- implementación secundaria en prácticas específicas;
- validación de portabilidad conceptual cuando corresponda.

No reemplaza a PostgreSQL como arquitectura principal salvo decisión documentada del equipo/profesor.

## 19.3 Python

### pandas

Uso previsto:

- automatización ETL;
- análisis estadístico;
- preparación de variables;
- validaciones;
- integración cuando sea conveniente;
- exportación reproducible.

### scikit-learn

Uso previsto:

- árboles de decisión;
- modelos complementarios;
- pipelines;
- evaluación;
- selección/preparación de variables.

### Redes neuronales

Se definirán cuando la fase de modelado lo requiera y exista una formulación adecuada del problema.

## 19.4 PySpark

Se utilizará **solo si el volumen o la práctica justifican procesamiento distribuido**.

No se incorporará únicamente por complejidad tecnológica.

## 19.5 Tableau

Uso previsto:

- EDA;
- verificación visual;
- tendencias;
- comparación;
- comunicación de resultados;
- apoyo a hallazgos.

Las visualizaciones deben construirse sobre capas analíticas controladas, no sobre archivos manipulados manualmente sin trazabilidad.

## 19.6 Git + GitHub

Uso previsto:

- control de versiones;
- colaboración;
- Issues;
- ramas;
- Pull Requests;
- revisión;
- tags;
- historial;
- trazabilidad técnica.

---

# 20. Modelo dimensional / OLAP

> **Estado: diseño por validar. No existe todavía un modelo dimensional definitivo.**

La arquitectura futura deberá evaluar un esquema dimensional compatible con la granularidad integrada.

Posibles dimensiones candidatas:

- `dim_tiempo`
- `dim_sistema`
- `dim_linea`
- `dim_estacion`
- `dim_tipo_acceso` cuando aplique
- dimensiones geográficas si se autoriza y justifica su integración

Posible hecho central:

- afluencia / demanda observada

Antes de implementar el modelo se debe resolver:

1. granularidad común;
2. claves sustitutas o naturales;
3. compatibilidad entre sistemas;
4. historia disponible;
5. dimensiones con diferente nivel de detalle;
6. medidas aditivas y no aditivas;
7. manejo de categorías no disponibles en todos los sistemas.

No debe crearse un esquema estrella únicamente por apariencia; debe representar correctamente el proceso analítico.

---

# 21. Plan de minería de datos

Las técnicas deben responder a la pregunta del proyecto y a los datos disponibles.

## 21.1 Estadística

Objetivos:

- describir demanda;
- variabilidad;
- tendencia;
- estacionalidad;
- comparación;
- distribución;
- atipicidad.

## 21.2 Reglas de asociación

Se evaluarán solo si existe una representación transaccional o categórica que haga razonable medir:

- soporte;
- confianza;
- lift.

No se forzarán reglas de asociación sobre datos que no tengan semántica apropiada.

## 21.3 Árboles de decisión

Posibles usos:

- clasificación de niveles de demanda;
- interpretación de reglas;
- identificación de variables relevantes.

## 21.4 Redes neuronales

Se utilizarán cuando:

- exista suficiente volumen;
- exista una variable objetivo bien definida;
- su complejidad esté justificada;
- pueda evaluarse correctamente;
- exista comparación con modelos más simples.

## 21.5 Modelos complementarios

Pueden incorporarse modelos adicionales si ayudan a construir una línea base o mejorar la comparación, siempre documentando por qué se utilizan.

---

# 22. Evaluación de modelos

La evaluación dependerá del tipo de problema final.

## Si es regresión

Métricas candidatas:

- MAE
- RMSE
- R²

## Si es clasificación

Métricas candidatas:

- accuracy;
- precision;
- recall;
- F1;
- matriz de confusión;
- ROC-AUC cuando corresponda.

## Si son reglas de asociación

- soporte;
- confianza;
- lift.

## Reglas de evaluación

- evitar fuga de información;
- separar datos de entrenamiento y evaluación;
- documentar estrategia de partición;
- preferir particiones temporales cuando la tarea sea predictiva sobre el futuro;
- comparar contra una línea base;
- registrar hiperparámetros;
- fijar semillas cuando aplique;
- no elegir un modelo únicamente por una métrica;
- interpretar errores y limitaciones.

---

# 23. Estructura oficial del repositorio

```text
mineria-datos-equipo13/
│
├── README.md
├── .gitignore
├── .gitattributes
│
├── practica01/
│   └── histórico completo de la entrega
│
├── practica02/
│   ├── README.md
│   ├── data/
│   ├── sql/
│   ├── docs/
│   ├── evidencias/
│   └── reporte/
│
└── proyecto/
    ├── README.md
    │
    ├── data/
    │   ├── raw/
    │   ├── clean/
    │   ├── processed/
    │   └── metadata/
    │
    ├── sql/
    │   ├── ingestion/
    │   ├── quality/
    │   ├── integration/
    │   └── olap/
    │
    ├── etl/
    ├── notebooks/
    ├── models/
    ├── tableau/
    └── docs/
```

---

# 24. Diferencia entre `practicaXX/` y `proyecto/`

Esta regla es fundamental.

## `practicaXX/`

Responde:

> **¿Qué se hizo y entregó específicamente en esta práctica?**

Puede contener:

- instrucciones;
- SQL;
- evidencias;
- documentos;
- capturas;
- reporte;
- resultados propios de esa práctica.

## `proyecto/`

Responde:

> **¿Cuál es el estado acumulativo, reusable y técnicamente vigente del proyecto semestral?**

Debe contener solo componentes que hayan sido:

- validados;
- generalizados;
- integrados;
- aceptados como parte del producto semestral.

### Promoción de componentes

Ejemplo:

```text
practica02/sql/postgresql/06_calidad.sql
                 │
                 │ validación
                 ▼
proyecto/sql/quality/...
```

La práctica desarrolla y demuestra.

El proyecto conserva y generaliza.

No se debe copiar todo automáticamente desde una práctica hacia `proyecto/`.

---

# 25. Política de archivos y datos en Git

## Se versiona

- código;
- SQL;
- Markdown;
- diccionarios pequeños;
- metadatos;
- manifiestos;
- configuraciones no secretas;
- notebooks;
- documentación;
- evidencias razonables;
- reportes;
- presentaciones;
- archivos de Tableau cuando su tamaño sea razonable.

## No se versiona normalmente

- datasets RAW grandes;
- respaldos de bases de datos;
- archivos temporales;
- entornos virtuales;
- credenciales;
- tokens;
- llaves;
- `.env`;
- archivos innecesarios generados por software.

## Regla de seguridad

Nunca subir:

- contraseñas;
- tokens GitHub;
- claves privadas;
- cadenas de conexión con credenciales;
- información personal sensible.

---

# 26. Manifiesto de fuentes

Cada práctica o componente que incorpore datos debe mantener un inventario.

Ejemplo de campos:

```text
archivo
organismo
fuente
url
fecha_descarga
periodo
filas
columnas
formato
checksum
observaciones
```

El checksum recomendado para verificar identidad de archivos es SHA-256.

La existencia de un archivo local no es suficiente para considerarlo reproducible: debe conocerse su procedencia.

---

# 27. Convenciones de SQL

Los scripts deben:

- tener propósito explícito;
- tener orden de ejecución;
- evitar pasos manuales no documentados;
- incluir validaciones;
- registrar conteos relevantes;
- no destruir RAW;
- documentar decisiones no evidentes;
- ser reproducibles desde un estado conocido.

En prácticas con secuencia de scripts se utilizará numeración:

```text
00_
01_
02_
03_
...
```

Los nombres deben describir la función del script.

---

# 28. Convenciones de Python

Cuando exista código Python:

- funciones antes que bloques repetidos;
- nombres descriptivos;
- rutas configurables;
- evitar rutas absolutas personales;
- registrar dependencias;
- usar `random_state` cuando corresponda;
- separar exploración de código reusable;
- evitar modificar RAW;
- documentar inputs y outputs.

Los notebooks son para exploración y comunicación.

La lógica reusable debe migrar gradualmente a módulos dentro de `proyecto/etl/` o componentes equivalentes.

---

# 29. Convención de evidencias

Evitar nombres como:

```text
Captura1.png
Captura2.png
final.png
final2.png
```

Preferir:

```text
E01_creacion_bd.png
E02_ingesta.png
E03_perfilado_nulos.png
E04_validacion_tipos.png
E05_calidad.png
```

Una evidencia debe permitir responder:

- qué demuestra;
- qué script la generó;
- qué resultado se esperaba;
- si el resultado fue correcto.

---

# 30. Flujo Git/GitHub oficial

## 30.1 Rama `main`

`main` representa la versión estable.

### Regla

> **No se trabaja directamente sobre `main`.**

Actualmente `main` está protegida mediante ruleset.

Configuración base:

- Pull Request requerido;
- 1 aprobación requerida;
- resolución de conversaciones antes de merge;
- force push bloqueado;
- eliminación de la rama protegida restringida.

---

# 31. Tipos de ramas

Formato:

```text
tipo/descripcion-corta
```

Tipos principales:

```text
feature/
fix/
docs/
refactor/
experiment/
```

Ejemplos:

```text
feature/perfilado-postgresql
feature/etl-metrobus
fix/codificacion-estaciones
docs/decisiones-limpieza
refactor/etl-metro
experiment/arbol-demanda
```

Evitar:

```text
eric
eden
yariel
rama1
prueba
avance
nuevo
final
```

Las ramas representan **trabajo**, no personas.

---

# 32. Flujo de trabajo por tarea

## Antes de empezar

```bash
git switch main
git pull
```

## Crear una rama

```bash
git switch -c feature/nombre-tarea
```

## Trabajar

Revisar frecuentemente:

```bash
git status
```

## Preparar cambios

Preferir agregar explícitamente:

```bash
git add ruta/del/archivo
```

o varios archivos relacionados.

## Commit

```bash
git commit -m "tipo: descripcion"
```

## Publicar rama

Primera vez:

```bash
git push -u origin feature/nombre-tarea
```

Después:

```bash
git push
```

## GitHub

1. Abrir Pull Request hacia `main`.
2. Explicar cambio.
3. Relacionar Issue.
4. Solicitar revisión.
5. Resolver comentarios.
6. Obtener aprobación.
7. Hacer merge.
8. Actualizar `main` local.

Después del merge:

```bash
git switch main
git pull
```

---

# 33. Convención de commits

Se utilizará una convención simple inspirada en Conventional Commits.

| Prefijo | Uso |
|---|---|
| `feat:` | funcionalidad nueva |
| `fix:` | corrección |
| `docs:` | documentación |
| `data:` | metadatos/diccionarios/datos versionables |
| `refactor:` | reorganización sin cambio funcional |
| `test:` | pruebas o validaciones |
| `chore:` | mantenimiento/configuración |

Ejemplos:

```text
feat: agrega perfilado de datos en PostgreSQL
fix: corrige codificacion de estaciones
docs: documenta decisiones de limpieza
data: actualiza diccionario de variables
test: valida ausencia de afluencias negativas
chore: actualiza estructura de practica 2
```

Evitar:

```text
cambios
avance
hola
ya quedo
final
final2
```

---

# 34. Pull Requests

Todo Pull Request debe responder:

## ¿Qué cambia?

Descripción concreta.

## ¿Por qué?

Relación con:

- Issue;
- práctica;
- fase CRISP-DM;
- problema técnico.

## ¿Cómo se validó?

Ejemplo:

- conteos;
- consultas;
- capturas;
- pruebas;
- comparación antes/después.

## ¿Qué archivos afecta?

Indicar componentes relevantes.

## ¿Existen decisiones metodológicas?

Si sí, documentarlas.

---

# 35. Issues

Todo trabajo que tenga entidad propia debe convertirse en Issue cuando sea útil.

Ejemplo:

```text
Título:
Implementar perfilado inicial en PostgreSQL

Responsable:
Eric

Labels:
sql
data-quality
practica-02

Objetivo:
Cuantificar nulos, duplicados, dominios y cobertura.

Definition of Done:
- script reproducible
- resultados documentados
- evidencia
- PR revisado
```

---

# 36. Milestones

Cuando resulte útil se crearán milestones como:

```text
Práctica 2
Práctica 3
...
Proyecto final
```

Un milestone representa una entrega o hito, no una persona.

---

# 37. Tags

Los tags congelan hitos importantes.

Convención:

```text
practica-01-entregada
practica-02-entregada
practica-03-entregada
...
v1.0.0
```

`v1.0.0` se reservará para una versión final estable del proyecto semestral.

---

# 38. Reglas prohibidas o de alto riesgo

## No hacer

```bash
git push --force origin main
```

No borrar `main`.

No trabajar directamente en `main`.

No subir datasets RAW grandes.

No subir credenciales.

No reescribir historial compartido sin acuerdo.

No resolver conflictos borrando arbitrariamente cambios de otra persona.

No hacer commits masivos de archivos no relacionados.

No usar archivos `final_final_ahora_si`.

---

# 39. Protocolo ante conflictos Git

Si ocurre un conflicto:

1. no entrar en pánico;
2. no usar `--force`;
3. identificar archivos en conflicto;
4. comprender ambos cambios;
5. hablar con el autor si la decisión no es obvia;
6. resolver contenido;
7. validar;
8. agregar archivos resueltos;
9. completar merge/rebase según el caso;
10. documentar si afectó lógica o datos.

En caso de duda, detenerse antes de ejecutar comandos destructivos.

---

# 40. Definition of Done — Tarea técnica

Una tarea no está terminada solo porque “corre”.

Debe cumplir, cuando aplique:

- [ ] alcance definido;
- [ ] código o SQL reproducible;
- [ ] no modifica RAW indebidamente;
- [ ] entradas identificadas;
- [ ] salidas identificadas;
- [ ] validaciones ejecutadas;
- [ ] resultados revisados;
- [ ] documentación actualizada;
- [ ] evidencia disponible;
- [ ] commit descriptivo;
- [ ] Pull Request abierto;
- [ ] revisión completada;
- [ ] conversaciones resueltas;
- [ ] merge realizado.

---

# 41. Definition of Done — Transformación de datos

- [ ] problema cuantificado;
- [ ] causa investigada;
- [ ] regla definida;
- [ ] transformación reproducible;
- [ ] filas antes/después verificadas;
- [ ] pérdida de información evaluada;
- [ ] decisión documentada;
- [ ] evidencia guardada;
- [ ] resultado validado.

---

# 42. Definition of Done — Modelo

- [ ] pregunta predictiva/descriptiva explícita;
- [ ] target definido si aplica;
- [ ] features documentadas;
- [ ] partición documentada;
- [ ] fuga de datos revisada;
- [ ] línea base;
- [ ] hiperparámetros registrados;
- [ ] métricas apropiadas;
- [ ] interpretación;
- [ ] limitaciones;
- [ ] reproducibilidad;
- [ ] comparación con alternativas cuando aplique.

---

# 43. Definition of Done — Práctica

Antes de declarar una práctica terminada:

- [ ] instrucciones revisadas;
- [ ] todos los incisos respondidos;
- [ ] datos correctos;
- [ ] scripts ordenados;
- [ ] evidencias completas;
- [ ] documentación consistente;
- [ ] reporte terminado;
- [ ] nombres y equipo correctos;
- [ ] resultados reproducibles;
- [ ] README de la práctica actualizado;
- [ ] PR integrado a `main`;
- [ ] `main` validada;
- [ ] tag de entrega creado cuando corresponda.

---

# 44. Criterios de éxito del proyecto

## Datos

- trazabilidad RAW → CLEAN;
- fuente documentada;
- granularidad explícita;
- transformaciones reproducibles;
- calidad cuantificada;
- integración controlada.

## Ingeniería

- scripts reproducibles;
- repositorio ordenado;
- historial comprensible;
- ausencia de credenciales;
- dependencias documentadas.

## Analítica

- técnicas coherentes con la pregunta;
- métricas apropiadas;
- resultados interpretables;
- comparación razonable;
- limitaciones explícitas.

## Académico

El equipo debe poder justificar:

- procedencia de datos;
- selección de fuentes;
- granularidad;
- decisiones de limpieza;
- integración;
- modelo dimensional;
- variables;
- técnicas de minería;
- evaluación;
- interpretación;
- limitaciones.

---

# 45. Entregables finales obligatorios

El equipo debe prepararse para entregar:

## 1. Datos recolectados originales

Formato esperado:

```text
ZIP
```

Debe preservar los archivos originales utilizados.

## 2. Código fuente de ETL y modelo de minería

Formato esperado:

```text
ZIP
```

Debe permitir identificar:

- ingestión;
- limpieza;
- integración;
- preparación;
- modelado;
- evaluación.

## 3. Presentación

Formato esperado:

- PPT / PPTX;
- PDF.

Objetivo operativo:

- aproximadamente 10 diapositivas según lineamiento del curso.

## 4. Reporte final

Formatos:

- PDF;
- Word.

Debe documentar el proceso completo y justificar decisiones.

## 5. Exposición grabada

Formato:

- MP4.

Duración máxima:

- 7 minutos.

---

# 46. Productos de apoyo del proyecto

Además de los cinco entregables principales, el desarrollo puede producir:

- base histórica;
- modelo dimensional;
- consultas OLAP;
- tablero;
- diccionarios;
- metadatos;
- scripts de auditoría;
- notebooks;
- modelos;
- resultados de evaluación;
- evidencias técnicas.

---

# 47. Preparación para defensa técnica

Todo integrante debe poder explicar, al menos:

### Datos

- de dónde vienen;
- quién los publica;
- cuándo se descargaron;
- cuántos registros tienen;
- qué representa una fila;
- qué periodo cubren;
- qué variables contienen.

### Calidad

- qué problemas se encontraron;
- cómo se detectaron;
- qué se corrigió;
- qué se conservó;
- por qué.

### Integración

- qué claves se utilizaron;
- qué granularidad se eligió;
- qué información se pierde o conserva;
- cómo se manejaron periodos distintos.

### Modelado

- por qué se eligió una técnica;
- qué variable se predice o describe;
- qué significan las métricas;
- cómo se evitó leakage;
- qué limitaciones tiene el modelo.

### Resultados

- qué hallazgos son descriptivos;
- qué hallazgos son predictivos;
- qué NO puede concluirse;
- qué utilidad potencial tienen.

---

# 48. Jerarquía de fuentes de verdad

Cuando exista conflicto entre documentos, utilizar este orden:

1. **Instrucción vigente del profesor para la entrega actual.**
2. **Programa oficial y material de la Unidad de Aprendizaje.**
3. **Entregables previamente aprobados/entregados.**
4. **Decisiones técnicas documentadas por el equipo.**
5. **Este README.**

Si una fuente superior cambia una decisión, este README debe actualizarse.

Nunca se debe mantener una regla del README si contradice una instrucción posterior del profesor.

---

# 49. Estado global del proyecto

| Componente | Estado |
|---|---|
| Repositorio Git local | ✅ Configurado |
| Repositorio GitHub privado | ✅ Configurado |
| `main` protegida | ✅ Configurada |
| Colaboradores | ✅ Invitados |
| Tag Práctica 1 | ✅ `practica-01-entregada` |
| Práctica 1 | ✅ Entregada |
| Práctica 2 | 🟡 En desarrollo |
| Comprensión del problema | ✅ Avanzada |
| Comprensión de datos Metro | ✅ Avanzada |
| ETL Metro | 🟡 En desarrollo / iteración |
| Integración multisistema | ⚪ Pendiente |
| Modelo dimensional / OLAP | ⚪ Pendiente |
| Modelado | ⚪ Pendiente |
| Evaluación | ⚪ Pendiente |
| Entregables finales | ⚪ Pendiente |

---

# 50. Roadmap semestral

```text
Práctica 1
Definición + comprensión + baseline Metro
        │
        ▼
Práctica 2
Preparación / SQL / calidad / reproducibilidad
        │
        ▼
ETL multisistema
Metro + Metrobús + RTP + Cablebús + Trolebús + Tren Ligero
        │
        ▼
Homologación e integración
        │
        ▼
Base histórica
        │
        ▼
Modelo dimensional
        │
        ▼
OLAP
        │
        ▼
EDA consolidado
        │
        ▼
Minería de datos
        │
        ▼
Evaluación
        │
        ▼
Interpretación
        │
        ▼
Reporte + presentación + código + datos + video
```

Este roadmap puede modificarse conforme el profesor defina las prácticas reales.

---

# 51. Mantenimiento de este README

El README debe actualizarse cuando cambie:

- estado de una práctica;
- fuente de datos;
- arquitectura;
- herramienta;
- alcance;
- pregunta de minería;
- modelo;
- entregable;
- convención Git;
- responsable;
- decisión metodológica importante.

La actualización debe hacerse mediante rama:

```text
docs/...
```

y Pull Request.

---

# 52. Regla de oro del Equipo 13

> **Si un resultado no puede rastrearse desde su fuente, reproducirse mediante código y justificarse metodológicamente, todavía no está terminado.**

---

# 53. Resumen operativo para cada sesión de trabajo

Antes de empezar:

```bash
git switch main
git pull
```

Crear o cambiar a la rama de la tarea.

Durante el trabajo:

```bash
git status
```

Antes de commit:

- revisar archivos;
- validar resultados;
- confirmar que no haya RAW ni secretos.

Después:

```bash
git add ...
git commit -m "tipo: descripcion"
git push
```

En GitHub:

- Pull Request;
- revisión;
- resolver conversaciones;
- aprobación;
- merge.

Después del merge:

```bash
git switch main
git pull
```

---

# 54. Estado del documento

**Documento:** README maestro operativo  
**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México  
**Equipo:** 13  
**Periodo:** 2026-B  
**Estado:** Activo — debe mantenerse durante todo el semestre
