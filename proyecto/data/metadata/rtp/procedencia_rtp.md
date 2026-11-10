# Procedencia de fuentes — RTP

## 1. Sistema

**Red de Transporte de Pasajeros de la Ciudad de México (RTP).**

Esta fuente corresponde a la Iteración 3 del proyecto semestral:

**Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México.**

---

## 2. Fuente oficial

Portal:

`https://www.datos.cdmx.gob.mx/dataset/afluencia-diaria-de-la-red-de-transporte-de-pasajeros`

Nombre del conjunto:

**Afluencia diaria de la Red de Transporte de Pasajeros**

Organización publicadora:

**Secretaría de Movilidad de la Ciudad de México (SEMOVI).**

Etiqueta del conjunto:

`RTP`

Categorías observadas:

- Movilidad
- Visualizaciones

Licencia publicada:

`CC-BY-4.0-ESP`

Fecha de consulta y adquisición:

`2026-11-08`

Última actualización mostrada por el portal durante la adquisición:

`2026-10-22 16:25 (UTC-06:00)`

La fecha mostrada en la ficha del conjunto no se utilizará como sustituto de la cobertura temporal efectiva del archivo CSV. La cobertura real deberá obtenerse directamente de los registros durante el perfilado.

---

## 3. Descripción oficial observada

El Portal de Datos Abiertos de la Ciudad de México describe el conjunto como información de afluencia de usuarios de la Red de Transporte de Pasajeros (RTP), con desagregación diaria a partir del:

`2022-01-01`

Esta descripción se conserva como referencia de la fuente.

La cobertura temporal real deberá validarse posteriormente mediante inspección del archivo recibido.

---

## 4. Recursos oficiales identificados

Durante la consulta del portal se identificaron dos recursos:

### 4.1 Afluencia Diaria de la RTP (desglosada)

Formato publicado:

`CSV`

Archivo recibido:

`afluenciartp_desglosado_09_2026.csv`

Ubicación RAW:

`proyecto/data/raw/rtp/afluenciartp_desglosado_09_2026.csv`

Tamaño aproximado observado localmente:

`1.9 MiB`

Detección inicial mediante `file`:

`CSV Unicode text, UTF-8 text`

El archivo se conserva sin modificaciones.

---

### 4.2 Diccionario de Datos

Formato publicado:

`CSV`

Archivo recibido originalmente:

`53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv`

Ubicación RAW:

`proyecto/data/raw/rtp/53082e7b-85af-4fe7-8e4d-d4698f8bc1be.csv`

Copia preservada para metadatos:

`proyecto/data/metadata/rtp/diccionario_rtp_original.csv`

Tamaño aproximado observado localmente:

`2.0 KiB`

Detección inicial mediante `file`:

`CSV Non-ISO extended-ASCII text`

La copia almacenada en `metadata/rtp/` fue contrastada mediante `cmp` contra el archivo RAW.

Resultado:

`sin diferencias`

Por tanto, la copia conserva los mismos bytes que el recurso descargado.

El diccionario no debe recodificarse ni sobrescribirse.

---

## 5. Estructura publicada preliminar

La ficha del recurso **Afluencia Diaria de la RTP (desglosada)** muestra preliminarmente las siguientes columnas:

```text
fecha
mes
anio
servicio
tipo_pago
afluencia
```

Esta información se considera únicamente una descripción preliminar.

La estructura física real deberá comprobarse directamente sobre el CSV recibido.

No se asumirá todavía que:

- el archivo contiene exactamente seis columnas;
- `servicio` equivale a una línea;
- `servicio` equivale a una ruta;
- `fecha × servicio × tipo_pago` constituye una clave única;
- `afluencia` posee un tipo físico determinado;
- todos los registros poseen el mismo nivel de granularidad.

Estas propiedades deberán demostrarse mediante inspección y perfilado.

---

## 6. Advertencia de actualización histórica

El portal indica que algunos conjuntos de datos pueden contener actualizaciones retroactivas y que la información histórica puede modificarse en versiones posteriores.

Por esta razón:

- los archivos RAW de esta adquisición se preservan sin modificaciones;
- se calculará SHA-256 para identificar exactamente la versión utilizada;
- se registrarán tamaños, estructura y número de registros;
- futuras descargas no deberán sobrescribir esta versión sin documentar el cambio;
- la procedencia y el manifest deberán permitir reconstruir qué versión fue utilizada por el proyecto.

---

## 7. Política RAW

Los archivos de:

`proyecto/data/raw/rtp/`

son inmutables.

No se permite:

- editar manualmente los CSV;
- guardarlos desde Excel;
- recodificarlos;
- renombrarlos dentro de RAW;
- eliminar filas;
- corregir valores;
- reemplazar valores faltantes;
- transformar tipos;
- sobrescribirlos con versiones posteriores.

Toda transformación posterior deberá producirse mediante procesos reproducibles fuera de RAW.

---

## 8. Estado actual de la fuente

Estado:

`ADQUIRIDA — PENDIENTE DE INSPECCIÓN ESTRUCTURAL`

Completado:

- identificación de fuente oficial;
- revisión del conjunto en el Portal de Datos Abiertos;
- identificación de los recursos;
- descarga del CSV de afluencia;
- descarga del diccionario oficial;
- preservación en RAW;
- copia byte a byte del diccionario en metadata;
- registro preliminar de procedencia.

Pendiente:

- inspección reproducible;
- SHA-256;
- conteo de registros;
- conteo de columnas;
- delimitador;
- encoding mediante inspector;
- estructura física real;
- cobertura temporal;
- dominios de `servicio`;
- dominios de `tipo_pago`;
- semántica de `servicio`;
- granularidad;
- duplicados;
- colisiones;
- valores faltantes;
- ceros;
- valores extremos;
- manifest;
- STAGING;
- TYPED;
- CLEAN;
- validación;
- contrato de datos;
- checkpoint individual;
- compatibilidad multisistema.