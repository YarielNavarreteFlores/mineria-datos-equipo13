# Contrato de datos — STC Metro

## 1. Propósito

Este documento establece el contrato de datos utilizado por el proyecto semestral para procesar información de afluencia del Sistema de Transporte Colectivo Metro.

El contrato describe la semántica, granularidad, cobertura y reglas mínimas que deben cumplir las capas analíticas del sistema Metro.

---

## 2. Fuentes

### Metro Simple

Archivo RAW:

`datos_metro_simple_raw.csv`

Cobertura observada:

`2010-01-01 → 2026-07-31`

Registros:

1,180,920

Granularidad conceptual:

`fecha × línea × estación`

Medida principal:

`afluencia`

### Metro Desglosada

Archivo RAW:

`datos_metro_desglosada_raw.csv`

Cobertura observada:

`2021-01-01 → 2026-07-31`

Registros:

1,192,230

Granularidad conceptual:

`fecha × línea × estación × tipo_pago`

Medida principal:

`afluencia`

---

## 3. Variables comunes

### fecha

Tipo analítico:

`DATE`

Representa el día al que corresponde la observación.

### anio

Tipo analítico:

`SMALLINT`

Debe coincidir con el año derivado de `fecha`.

### mes

Tipo analítico:

`TEXT`

Representa el nombre del mes reportado por la fuente.

### mes_num

Variable derivada.

Tipo:

`SMALLINT`

Dominio:

1 a 12.

### linea

Tipo:

`TEXT`

Después de CLEAN debe utilizar la forma homologada:

`Línea <identificador>`

Dominio observado:

12 líneas.

### estacion

Tipo:

`TEXT`

Nombre de la estación después de corregir problemas de representación textual.

### afluencia

Tipo:

`INTEGER`

Representa el número de accesos o afluencia reportada por la fuente para la granularidad correspondiente.

Los valores cero se conservan.

---

## 4. Variable exclusiva de Metro Desglosada

### tipo_pago

Tipo:

`TEXT`

Dominio observado:

- Boleto
- Gratuidad
- Prepago

---

## 5. Variables derivadas CLEAN

Las capas CLEAN incluyen:

- `mes_num`;
- `dia_semana_num`;
- `dia_semana`;
- `es_fin_semana`;
- `es_afluencia_cero`;
- `es_colision_clave`;
- `es_outlier_iqr_global`;
- `es_texto_corregido`.

Estas variables no forman parte de los archivos RAW.

---

## 6. Reglas de calidad

### Integridad de volumen

Los registros deben conservarse entre:

`STAGING → TYPED → CLEAN`

salvo que una transformación futura documente explícitamente una exclusión.

### Texto

RAW no se modifica.

Los problemas de mojibake se corrigen únicamente en CLEAN.

### Afluencia cero

No se considera automáticamente un error.

### Outliers

Los outliers detectados mediante IQR se marcan, pero no se eliminan automáticamente.

### Colisiones de clave

Metro Simple contiene 31 colisiones conocidas en la combinación:

`fecha + línea + estación`

correspondientes a Línea B, estación Oceanía, durante diciembre de 2020.

No deben eliminarse automáticamente.

Metro Desglosada no presenta actualmente colisiones en:

`fecha + línea + estación + tipo_pago`

---

## 7. Uso permitido

La capa CLEAN puede utilizarse para:

- análisis exploratorio;
- visualización;
- agregaciones;
- preparación del modelo dimensional;
- construcción de variables;
- minería de datos.

Las capas RAW y STAGING no deben utilizarse directamente como fuente final de modelado.

---

## 8. Trazabilidad

El flujo oficial es:

`RAW → STAGING → TYPED → CLEAN`

Toda transformación adicional deberá indicar:

- entrada;
- regla aplicada;
- salida;
- validación;
- efecto sobre el número de registros.