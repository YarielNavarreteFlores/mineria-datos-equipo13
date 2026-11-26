# Integración física de la afluencia diaria multisistema

## Resultado

La carga inicial de `proyecto.afluencia_diaria_multisistema` quedó validada
en PostgreSQL, en la base `mineria_datos_2026b`. La comparación contra el
candidato del checkpoint `e610dde` cubrió las 70,844 claves del corte
2022-01-01 a 2026-07-31. Los seis sistemas tienen registros en los 1,673 días.

La clave primaria es `(fecha, sistema, unidad_operativa)`. Cada fila conserva
la procedencia de su unidad operativa, el estado de calidad y la afluencia.
La medida utiliza `NUMERIC(20,13)`. El control previo a la inserción encontró
0 valores fuera de la precisión admitida.

## Resultados por sistema

| Sistema | Claves comparadas | Con afluencia | Restringidas | Origen de la unidad operativa |
|---|---:|---:|---:|---|
| Cablebús | 3,803 | 3,803 | 0 | `FUENTE` |
| Metro | 20,076 | 20,076 | 0 | `FUENTE` |
| Metrobús | 11,711 | 11,711 | 0 | `FUENTE` |
| RTP | 13,382 | 13,159 | 223 | `FUENTE` |
| Tren Ligero | 1,673 | 1,673 | 0 | `DERIVADA_CONSTANTE` |
| Trolebús | 20,199 | 20,199 | 0 | `FUENTE` |
| **Total** | **70,844** | **70,621** | **223** | |

RTP conserva 92 claves con estado `COLISION` y 131 con estado
`AFLUENCIA_INCOMPLETA`. Su afluencia permanece en `NULL`.
Para Tren Ligero, `Sistema completo` identifica la agregación diaria
del sistema y su procedencia queda registrada como `DERIVADA_CONSTANTE`.

## Reproducción y verificación

Los scripts se encuentran en `proyecto/sql/integration/multisistema/`.

1. `01_crear_afluencia_diaria_multisistema.sql` crea la tabla con su clave
   primaria y cuatro restricciones `CHECK`. Se ejecuta cuando la tabla
   todavía no existe.
2. `02_carga_inicial_afluencia_diaria_multisistema.sql` calcula la ventana
   común desde las seis tablas `CLEAN` y carga el candidato cuando el destino
   está vacío y los valores cumplen la precisión prevista.
3. `03_validar_carga_contra_checkpoint.sql` recalcula el candidato desde las
   tablas `CLEAN` y lo compara con la tabla física mediante `FULL JOIN` por
   la clave primaria. Esta consulta es de solo lectura y puede repetirse.

En el corte validado, el tercer script devolvió seis filas, una por sistema.
En todas ellas, `faltan_en_tabla`, `sobran_en_tabla`, `diferencias_afluencia`,
`diferencias_calidad` y `diferencias_procedencia` dieron 0.

La comparación utiliza las tablas `CLEAN` disponibles al ejecutar el control.
Si las fuentes cambian posteriormente, una diferencia puede indicar que la
tabla física conserva un corte anterior.