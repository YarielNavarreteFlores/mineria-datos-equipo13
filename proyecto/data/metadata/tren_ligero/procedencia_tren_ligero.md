# Procedencia de datos — Tren Ligero

## 1. Sistema

**Sistema:** Tren Ligero
**Organismo responsable:** Secretaría de Movilidad de la Ciudad de México (SEMOVI) / Servicio de Transportes Eléctricos (STE)
**Proyecto:** Inteligencia de demanda de los principales sistemas de transporte público de la Ciudad de México
**Iteración:** 6 — Tren Ligero
**Fecha de recuperación:** 2026-11-22

---

## 2. Fuente oficial

Los datos fueron obtenidos del Portal de Datos Abiertos de la Ciudad de México, dentro del conjunto:

**Afluencia diaria Servicio de Transportes Eléctricos**

El conjunto integra información de:

- Cablebús;
- Tren Ligero;
- Trolebús.

Para esta iteración se utilizaron exclusivamente el recurso correspondiente a Tren Ligero y el diccionario oficial de datos del conjunto.

Institución responsable:

```text
Secretaría de Movilidad de la Ciudad de México (SEMOVI)
```

El recurso utilizado para Tren Ligero se identifica como:

```text
Afluencia Diaria Tren Ligero (desglosada)
```

El Portal describe el recurso como información de afluencia diaria del Tren Ligero con registros a partir del 1 de enero de 2022.

---

## 3. Archivos recuperados

### 3.1 Afluencia desglosada

Archivo preservado en RAW:

```text
proyecto/data/raw/tren_ligero/afluencia_desglosada_tl_10_2026.csv
```

Tamaño aproximado:

```text
135 KiB
```

Tipo físico detectado:

```text
CSV ASCII text
```

SHA-256:

```text
20f7ce65a095a58306b788070f93d882f0d23885345f7add2954f0e8a2ccc15f
```

Este archivo constituye la evidencia RAW principal para la Iteración 6.

No debe modificarse directamente.

---

### 3.2 Diccionario oficial de datos

Archivo descargado originalmente:

```text
proyecto/data/raw/tren_ligero/1fd34251-b1e7-4a00-ba07-5d3b9d8701e9.csv
```

Copia preservada para versionamiento:

```text
proyecto/data/metadata/tren_ligero/diccionario_tren_ligero_original.csv
```

Tamaño aproximado:

```text
1.6 KiB
```

Codificación física detectada:

```text
ISO-8859
```

SHA-256:

```text
0ea0fc2a8ed1894802ccd4ee63fd93ef0b8d2d564b610d301a21c34341c29c39
```

La copia almacenada en `metadata/` fue comparada byte a byte contra el archivo RAW.

Resultado:

```text
RAW = METADATA
```

No se realizó:

- conversión de codificación;
- modificación de delimitadores;
- normalización de finales de línea;
- limpieza de espacios;
- modificación de contenido.

El archivo deberá mantenerse byte a byte idéntico al recurso oficial.

---

## 4. Política de preservación

Los archivos almacenados en:

```text
proyecto/data/raw/tren_ligero/
```

constituyen evidencia original de la fuente y permanecen fuera del versionamiento de Git mediante `.gitignore`.

La información RAW:

- no se limpia;
- no se transforma;
- no se sobrescribe;
- no se homologa;
- no se utiliza directamente como capa analítica definitiva.

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

El diccionario oficial almacenado en `metadata/` está protegido mediante una regla específica `-text` en `.gitattributes` para impedir normalización automática de finales de línea por Git.

---

## 5. Consideraciones metodológicas

La estructura semántica de Tren Ligero todavía no se considera demostrada.

En esta etapa no se asume:

```text
unidad_operativa = linea
```

aunque el conjunto institucional contenga variables con nombres relacionados con líneas o unidades de operación.

Tampoco se asume todavía que la granularidad sea:

```text
fecha × linea × tipo_pago
```

La granularidad, dominios, cobertura temporal, categorías de acceso, valores de afluencia y posible equivalencia con `unidad_operativa` deberán demostrarse mediante inspección y perfilado reproducibles.

No se reutilizarán automáticamente las reglas desarrolladas para:

```text
Cablebús
Trolebús
```

aunque los tres sistemas pertenezcan al Servicio de Transportes Eléctricos.

Toda transformación deberá sustentarse directamente en los datos y metadatos de Tren Ligero.

---

## 6. Estado

```text
FUENTE OFICIAL IDENTIFICADA
RAW PRESERVADO
DICCIONARIO OFICIAL PRESERVADO BYTE A BYTE
INSPECCIÓN ESTRUCTURAL PENDIENTE
```