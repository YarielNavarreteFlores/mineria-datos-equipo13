# Checkpoint multisistema final

**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.
**Rama de trabajo:** `feature/checkpoint-multisistema-final`.
**Commit base de `main`:** `b7e6704`.
**Resultado de los controles ejecutados:** APROBADO CON RESTRICCIONES.
**Estado de la entrega:** pendiente de auditoría y commit.

## 1. Objetivo y alcance

Evaluar si las seis tablas `CLEAN` pueden representarse a la granularidad
`fecha × sistema × unidad_operativa`, conservando la afluencia conocida,
las restricciones de calidad y la procedencia de la unidad operativa.

La evaluación se realizó con consultas de lectura en PostgreSQL sobre la
base `mineria_datos_2026b`. El candidato se construyó dentro de las consultas.
La materialización física corresponde a una etapa posterior.

## 2. Ventana temporal y clave

La ventana común observada comprende del **2022-01-01 al 2026-07-31**, ambos
inclusive. Se obtuvo tomando la mayor de las seis fechas iniciales y la menor
de las seis fechas finales. El control de cobertura diaria encontró registros
en los **1,673 días** para cada sistema.

El candidato produjo **70,844 registros y 70,844 claves distintas**.
Se observaron **0 claves duplicadas** y **0 claves con algún componente NULL**.
La cobertura diaria se verificó por sistema. Las unidades operativas pueden
tener distintos periodos de actividad.

## 3. Semántica y resultados por sistema

| Sistema | Unidad operativa | Procedencia | Claves totales | Claves OK | Claves restringidas |
|---|---|---|---:|---:|---:|
| Cablebús | `linea` | Fuente | 3,803 | 3,803 | 0 |
| Metro | `linea` | Fuente | 20,076 | 20,076 | 0 |
| Metrobús | `linea` | Fuente | 11,711 | 11,711 | 0 |
| RTP | `servicio` | Fuente | 13,382 | 13,159 | 223 |
| Tren Ligero | `Sistema completo` | Derivada para integración | 1,673 | 1,673 | 0 |
| Trolebús | `linea` | Fuente | 20,199 | 20,199 | 0 |
| **Total** | | | **70,844** | **70,621** | **223** |

En Tren Ligero, `Sistema completo` representa la agregación diaria de los
componentes por tipo de pago. Su procedencia debe permanecer explícita para
que los análisis distingan una observación del sistema completo de una
observación por línea. Las 1,673 claves de Tren Ligero tienen afluencia conocida.

## 4. Restricciones de RTP

| Estado | Claves | Claves con afluencia publicable |
|---|---:|---:|
| `OK` | 13,159 | 13,159 |
| `COLISION` | 92 | 0 |
| `AFLUENCIA_INCOMPLETA` | 131 | 0 |

Las 131 claves incompletas contienen **187 filas de origen con afluencia NULL**.
En 26 claves faltan todos los componentes de afluencia y en 105 se mezclan
componentes conocidos y faltantes. Publicar la suma disponible de estas
últimas produciría una cifra parcial.

Se observaron **0 claves `COLISION_Y_NULL`** y **0 claves clasificadas como
`ESTRUCTURA_INESPERADA`**. Las 223 claves restringidas conservan su identidad
y su estado de calidad, con `afluencia = NULL` en el candidato.

## 5. Precisión de afluencia

`NUMERIC(20,13)` representó exactamente los valores individuales observados
en el perfil de las tablas `CLEAN` y las **70,621 afluencias conocidas**
del candidato. El tipo admite siete dígitos enteros y trece decimales.

Después de agregar por clave, el mayor valor absoluto observado fue **807,078**
en Metro. Trolebús requirió la mayor escala observada, **13 decimales**.
El control encontró **0 valores del candidato fuera de `NUMERIC(20,13)`**.
La suficiencia del tipo debe volver a comprobarse cuando cambien los datos.

## 6. Reconciliación con el origen

El control agrupó las filas `CLEAN` a la granularidad del contrato y comparó
ambos lados mediante `FULL JOIN` por `sistema`, `fecha` y `unidad_operativa`.

| Control en la ventana común | Resultado |
|---|---:|
| Claves presentes solo en el origen | 0 |
| Claves presentes solo en el candidato | 0 |
| Claves `OK` con diferencia de afluencia o componentes faltantes | 0 |
| Claves restringidas con afluencia publicada | 0 |

Las **70,621 claves `OK`** coincidieron individualmente con la suma de sus
componentes de origen. Para las **223 claves restringidas** se verificaron
la presencia de la clave y la conservación de `NULL` en la medida.

## 7. Evidencia reproducible

Ejecutar los archivos SQL sobre las seis tablas `CLEAN` de la base del proyecto.

| Evidencia | Qué permite comprobar |
|---|---|
| `proyecto/sql/quality/compatibilidad/05_compatibilidad_tren_ligero_contrato_preliminar.sql`, sección 12 | Unicidad global y conteos del candidato en la ventana evaluada por ese script |
| `proyecto/sql/quality/compatibilidad/06_checkpoint_multisistema_final.sql` | Ventana calculada desde las seis fuentes, resultados por sistema y estado, integridad de la clave y precisión de afluencia |
| `proyecto/sql/quality/compatibilidad/07_reconciliacion_afluencia_por_clave.sql` | Correspondencia de claves y preservación exacta de afluencia por sistema |

Los resultados numéricos corresponden a las tablas disponibles durante esta
ejecución. Al actualizar las fuentes, deben registrarse la nueva ventana,
los conteos obtenidos y cualquier diferencia antes de aprobar el nuevo corte.

## 8. Condiciones para la integración física posterior

- Mantener una sola fila por `fecha × sistema × unidad_operativa`.
- Conservar la procedencia de la unidad operativa, incluida la derivación
  `Sistema completo` de Tren Ligero.
- Preservar las claves restringidas de RTP con su estado y su afluencia `NULL`.
- Utilizar aritmética decimal exacta y comprobar la capacidad del tipo antes
  de cargar un nuevo corte.
- Repetir la cobertura diaria, la unicidad y la reconciliación por clave
  después de materializar la integración.