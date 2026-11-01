# Metadatos y procedencia

Esta carpeta registra información sobre las fuentes utilizadas por el proyecto semestral.

El objetivo es separar dos conceptos:

**Integridad**

Permite comprobar que un archivo no fue modificado.

Principal mecanismo:

`SHA-256`

**Procedencia**

Permite explicar de dónde proviene el archivo y bajo qué condiciones se obtuvo.

---

# Manifest técnico

Cada sistema debe disponer de un manifest reproducible.

Como mínimo debe registrar:

- sistema;
- nombre del archivo;
- tamaño;
- SHA-256;
- encoding;
- delimitador;
- columnas;
- registros;
- filas estructuralmente malformadas;
- estado de validación.

Ejemplo:

```text
metadata/metro/manifest_fuentes_metro.csv
```

---

# Procedencia

Además del manifest técnico debe poder documentarse:

- organismo publicador;
- portal o fuente;
- URL del recurso cuando esté disponible;
- fecha de descarga;
- periodo cubierto;
- descripción del recurso;
- granularidad;
- observaciones de versión.

No se deben inventar datos de procedencia que no hayan sido registrados.

Cuando un dato histórico no pueda recuperarse con certeza debe documentarse explícitamente como no disponible.

Para Metro, la procedencia registrada se encuentra en:

`metro/procedencia_metro.md`

---

# Evidencias derivadas

Los resultados automáticos de inspección pueden almacenarse como JSON.

Ejemplo:

```text
metadata/metro/inspeccion_fuentes_metro.json
```

Dichos archivos permiten auditar:

- encabezados;
- ejemplos;
- conteos;
- encoding;
- estructura física.

---

# Convención por sistema

```text
metadata/
├── metro/
├── metrobus/
├── rtp/
├── cablebus/
├── trolebus/
└── tren_ligero/
```

Cada directorio se crea cuando comienza formalmente la iteración del sistema correspondiente.

---

# Regla de aceptación

Una fuente no debe avanzar a integración multisistema hasta contar con:

1. fuente identificada;
2. RAW preservado;
3. SHA-256;
4. manifest;
5. inspección estructural;
6. granularidad documentada;
7. contrato de datos;
8. validación del pipeline.

## Checkpoint Metrobús — 2026-11-01

Directorio: `metrobus/`.

Archivos del checkpoint:

- `procedencia_metrobus.md`
- `checksums_fuentes_metrobus.sha256`
- `inspeccion_fuentes_metrobus.json`
- `manifest_fuentes_metrobus.csv`
- `diccionario_metrobus_simple_original.csv`
- `diccionario_metrobus_desglosada_original.csv`

El manifest contiene cuatro fuentes: dos datasets y dos diccionarios.
Todas tienen estado INSPECCIONADO_PENDIENTE_VALIDACION.

Se verificaron conteos, estructura CSV y decodificación estricta
con los decodificadores registrados. Esto no certifica la
codificación original ni elimina problemas de mojibake.

El generador compartido `proyecto/etl/generar_manifest.py` se
actualizó para evitar declarar VALIDADO un archivo solo porque
terminó la inspección. El manifest existente de Metro no se regeneró.

Consultar `../../docs/checkpoint_metrobus.md`.