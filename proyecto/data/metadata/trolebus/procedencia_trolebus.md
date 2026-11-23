# Procedencia de datos — Trolebús

## 1. Sistema

**Sistema:** Trolebús
**Organismo responsable:** Secretaría de Movilidad de la Ciudad de México (SEMOVI) / Servicio de Transportes Eléctricos (STE)
**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Iteración:** 5 — Trolebús
**Fecha de recuperación:** 2026-11-21

---

## 2. Fuente oficial

Los datos fueron obtenidos del Portal de Datos Abiertos de la Ciudad de México, dentro del conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

El conjunto integra información de:

- Cablebús;
- Tren Ligero;
- Trolebús.

Para esta iteración se utilizaron exclusivamente los recursos correspondientes a Trolebús y su diccionario oficial.

Página oficial del conjunto:

```text
https://www.datos.cdmx.gob.mx/dataset/afluencia-diaria-servicio-de-transportes-electricos
```

Institución responsable:

```text
Secretaría de Movilidad de la Ciudad de México (SEMOVI)
```

El recurso de Trolebús publicado por el portal se identifica como:

```text
Afluencia Diaria Trolebus (desglosado)
```

El portal describe este recurso como información de afluencia diaria del Trolebús con registros a partir del 1 de enero de 2022.

---

## 3. Archivos recuperados

### 3.1 Afluencia desglosada

Archivo preservado en RAW:

```text
proyecto/data/raw/trolebus/afluencia_desglosada_trolebus_10_2026.csv
```

Tamaño aproximado:

```text
2.9 MiB
```

Codificación detectada:

```text
UTF-8
```

SHA-256:

```text
4775b452dc7fa5376581b5dfe4cc9fe3f344552ae48a1dee802cb6124ab81ff4
```

Este archivo constituye la evidencia RAW principal para la Iteración 5.

No debe modificarse directamente.

---

### 3.2 Diccionario oficial de datos

Archivo descargado originalmente:

```text
proyecto/data/raw/trolebus/1fd34251-b1e7-4a00-ba07-5d3b9d8701e9.csv
```

Copia preservada para versionamiento:

```text
proyecto/data/metadata/trolebus/diccionario_trolebus_original.csv
```

Tamaño aproximado:

```text
1.6 KiB
```

Codificación detectada:

```text
ISO-8859
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

La copia en `metadata/` fue verificada contra el archivo RAW mediante comparación byte a byte.

Resultado:

```text
RAW = METADATA
```

No se realizó:

- conversión de codificación;
- modificación de delimitadores;
- normalización de finales de línea;
- limpieza de espacios;
- modificación del contenido.

El archivo deberá mantenerse byte a byte idéntico al recurso oficial.

---

## 4. Política de preservación

Los archivos almacenados en:

```text
proyecto/data/raw/trolebus/
```

son evidencia original de la fuente y permanecen fuera del versionamiento de Git mediante `.gitignore`.

La información RAW:

- no se limpia;
- no se transforma;
- no se sobrescribe;
- no se homologa;
- no se utiliza como capa analítica definitiva.

Las transformaciones posteriores deberán realizarse mediante capas reproducibles:

```text
RAW
↓
STAGING
↓
TYPED
↓
CLEAN
```

---

## 5. Consideraciones metodológicas

La estructura semántica de Trolebús todavía no se considera demostrada.

En esta etapa no se asume:

```text
unidad_operativa = linea
```

aunque otros sistemas del Servicio de Transportes Eléctricos utilicen una variable denominada `linea`.

La granularidad, dominios, estructura temporal, tipos de pago y posible equivalencia con `unidad_operativa` deberán demostrarse mediante inspección y perfilado reproducibles.

Tampoco se asume que el pipeline de Cablebús pueda reutilizarse sin modificaciones.

---

## 6. Estado

```text
FUENTE OFICIAL IDENTIFICADA
RAW PRESERVADO
DICCIONARIO OFICIAL PRESERVADO BYTE A BYTE
INSPECCIÓN ESTRUCTURAL PENDIENTE
```