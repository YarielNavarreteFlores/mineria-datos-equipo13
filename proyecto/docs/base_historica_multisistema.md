# Base histórica de afluencia diaria multisistema

## Resultado y alcance

La tabla `proyecto.afluencia_diaria_historica`, en la base PostgreSQL
`mineria_datos_2026b`, reúne 168,053 claves de seis sistemas de transporte.
La clave primaria es `(fecha, sistema, unidad_operativa)`. La afluencia se
almacena como `NUMERIC(20,13)` y cada fila conserva su estado de calidad
y la procedencia de su unidad operativa.

La cobertura histórica depende de cada fuente. Para comparaciones entre los
seis sistemas en las mismas fechas, la referencia validada es
`proyecto.afluencia_diaria_multisistema`, del 2022-01-01 al 2026-07-31.
Sus 70,844 claves están contenidas en la base histórica. La ampliación
aporta 97,209 claves fuera de ese intervalo.

## Cobertura y resultados por sistema

| Sistema | Primera fecha | Última fecha | Claves históricas | Con afluencia | Sin afluencia |
|---|---|---|---:|---:|---:|
| Cablebús | 2022-01-01 | 2026-09-30 | 3,986 | 3,986 | 0 |
| Metro | 2010-01-01 | 2026-07-31 | 72,672 | 72,641 | 31 |
| Metrobús | 2005-07-26 | 2026-09-30 | 54,159 | 36,932 | 17,227 |
| RTP | 2022-01-01 | 2026-09-30 | 13,800 | 13,577 | 223 |
| Tren Ligero | 2022-01-01 | 2026-10-31 | 1,765 | 1,765 | 0 |
| Trolebús | 2022-01-01 | 2026-10-31 | 21,671 | 21,671 | 0 |
| **Total** | | | **168,053** | **150,572** | **17,481** |

## Reglas de integración

- Metro usa el recurso Simple. La afluencia diaria por línea se obtiene
  agrupando las estaciones. En el periodo compartido con Desglosada se
  compararon 397,410 claves fecha × línea × estación con diferencia cero.
- Metrobús usa el recurso Simple a nivel fecha × línea. La suma por tipo de
  pago de Desglosada coincidió en las 14,693 claves compartidas.
  Los desgloses de Metro y Metrobús se conservan para análisis y contraste;
  sumarlos nuevamente al recurso Simple duplicaría la demanda.
- RTP utiliza `servicio` como unidad operativa. Cablebús y Trolebús utilizan
  `linea`. Para estos tres sistemas se agregan los componentes por tipo de pago.
- Tren Ligero se agrega por fecha. `Sistema completo` es una unidad derivada
  para la integración y se identifica con `DERIVADA_CONSTANTE`. En los otros
  cinco sistemas la procedencia de la unidad es `FUENTE`.

## Interpretación de las 17,481 afluencias NULL

| Sistema | Estado de calidad | Claves | Interpretación |
|---|---|---:|---|
| Metro | `COLISION` | 31 | En Oceanía, Línea B, cada día del 1 al 31 de diciembre de 2020 tiene dos registros de estación con afluencias distintas. Se conserva la clave diaria de la línea y su total queda en `NULL`. |
| Metrobús | `SIN_DATO_PREVIO_AL_PRIMER_VALOR` | 17,227 | La fuente contiene la clave, pero la fecha precede al primer valor conocido de esa línea. El primer valor observado por sí solo no acredita la fecha de apertura. |
| RTP | `COLISION` | 92 | El grupo contiene una colisión identificada en la fuente preparada. |
| RTP | `AFLUENCIA_INCOMPLETA` | 131 | Falta al menos un componente de afluencia y la suma disponible podría ser parcial. |

Estas claves se conservan para analizar cobertura y calidad. Al evaluar un
modelo de afluencia, solo las filas con valor observado pueden aportar una
etiqueta. Sustituir `NULL` por cero introduciría una observación artificial.

## Reproducción y controles

Los scripts están en `proyecto/sql/integration/historico/`.

| Script | Función |
|---|---|
| `01_inventario_cobertura_historica.sql` | Mide la cobertura de los ocho recursos e identifica las seis fuentes principales. |
| `02_candidato_historico.sql` | Construye el candidato lógico y verifica claves, estados de calidad y precisión. |
| `03_reconciliar_ventana_comun.sql` | Compara las 70,844 claves del intervalo común contra la integración física validada. |
| `04_reconciliar_fuera_de_ventana.sql` | Compara las 97,209 claves adicionales contra las fuentes `CLEAN`. |
| `05_crear_afluencia_diaria_historica.sql` | Crea la tabla, su clave primaria y las restricciones de calidad y procedencia. |
| `06_carga_inicial_historica.sql` | Ejecuta la carga inicial con el destino vacío y los conteos y la precisión del corte validado. |
| `07_validar_tabla_historica.sql` | Compara el candidato con la tabla física por fecha, sistema y unidad operativa. |

En la validación posterior a la carga se compararon las 168,053 claves.
Los seis sistemas obtuvieron cero claves faltantes, cero sobrantes y cero
diferencias de afluencia, estado de calidad o procedencia.

El script `07` recalcula el candidato con las tablas `CLEAN` disponibles en
el momento de ejecución. Si se actualizan las fuentes, se deberá identificar
el nuevo corte y reconciliar sus diferencias con la carga histórica documentada.