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