# Procedencia de las fuentes de Metrobús

## Identificación

- Sistema: Metrobús de la Ciudad de México.
- Conjunto: Afluencia diaria de Metrobús CDMX.
- Organización y mantenedor: Secretaría de Movilidad (SEMOVI).
- Portal: Portal de Datos Abiertos de la Ciudad de México.
- URL del conjunto: https://datos.cdmx.gob.mx/dataset/afluencia-diaria-de-metrobus-cdmx
- Fecha de consulta: 2026-11-01.
- Última actualización mostrada por el portal: 2026-10-22 11:50 (UTC-06:00).
- Licencia mostrada: CC-BY-4.0-ESP.
- Formato publicado: CSV.

## Descripción anunciada por el portal

El conjunto describe afluencia diaria por línea de Metrobús,
con historia anunciada desde julio de 2005.

La descripción del recurso desglosado distingue los medios de
acceso Tarjeta Única de Movilidad Integrada y gratuidad.

El portal indica que las actualizaciones posteriores a enero
de 2022 se reflejan en la base desglosada y que el total puede
obtenerse de la columna afluencia_total.

Estas afirmaciones deberán contrastarse con los archivos
descargados y sus diccionarios.

## Recursos identificados

| Recurso | Nombre local previsto |
|---|---|
| Afluencia Diaria del Metrobús (Simple) | datos_metrobus_simple_raw.csv |
| Afluencia Diaria del Metrobús (Desglosada) | datos_metrobus_desglosada_raw.csv |
| Diccionario de Datos | diccionario_metrobus_simple_original.csv |
| Diccionario Afluencia Desglosada - MB | diccionario_metrobus_desglosada_original.csv |

## Advertencias de la fuente

- El portal advierte posibles actualizaciones retroactivas.
- La descripción anuncia actualización mensual, pero el campo
  de frecuencia de actualización muestra no_aplica.
- La fecha de actualización de la ficha no demuestra el corte
  temporal de cada archivo.
- No se asumirá que Simple y Desglosada pueden concatenarse
  o sumarse sin estudiar sus coberturas y medidas.

## Verificaciones pendientes

- Encabezados y estructura física.
- Encoding y delimitador.
- Número de registros y columnas.
- Periodo efectivo de cada archivo.
- Granularidad y claves candidatas.
- Definición de las medidas según los diccionarios.
- Compatibilidad entre Simple y Desglosada.

Estado: fuente identificada; archivos y calidad aún no validados.

## Hallazgos de inspección preliminar

### Recurso Simple

Encabezado observado:
fecha,anio,mes,linea,afluencia

La muestra contiene el valor literal NaN en afluencia.
El diccionario describe ceros para líneas previas a su
inauguración. Esta diferencia queda pendiente de cuantificar
y explicar mediante perfilado.

No se sustituirán automáticamente los NaN por cero.

### Recurso Desglosado

Encabezado observado:
fecha,mes,anio,linea,tipo_pago,afluencia

La muestra presenta las categorías Prepago y Gratuidad
como valores de tipo_pago, en filas separadas.

La granularidad candidata es:
fecha × linea × tipo_pago.

Su unicidad todavía no ha sido comprobada.

### Diferencia respecto al diccionario y al portal

El diccionario desglosado describe campos como estacion,
afluencia_prepago, afluencia_gratuidad y afluencia_total,
ausentes en el encabezado del CSV descargado.

La referencia del portal a afluencia_total tampoco coincide
con la estructura observada.

El diccionario se conserva como evidencia oficial, pero no
se considera un contrato validado del archivo recibido.

### Estado

Integridad verificada mediante SHA-256.
Inspección estructural en curso.
Cobertura, calidad semántica y claves pendientes de validar.