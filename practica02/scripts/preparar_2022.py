from pathlib import Path
import hashlib
import os
import csv


BASE = Path(__file__).resolve().parents[1]

ORIGEN = (
    BASE
    / "data"
    / "raw"
    / "muestra200k_COVID19MEXICOLOC2022.csv"
)

CARPETA_WORKING = BASE / "data" / "working"

DESTINO = (
    CARPETA_WORKING
    / "muestra200k_COVID19MEXICOLOC2022_trabajo.csv"
)

CHUNK = 8 * 1024 * 1024


def sha256_rango(ruta, inicio, cantidad):
    h = hashlib.sha256()

    with open(ruta, "rb") as archivo:
        archivo.seek(inicio)
        restante = cantidad

        while restante > 0:
            bloque = archivo.read(min(CHUNK, restante))

            if not bloque:
                raise RuntimeError(
                    "El archivo terminó antes de completar "
                    "el rango solicitado."
                )

            h.update(bloque)
            restante -= len(bloque)

    return h.hexdigest()


def contar_saltos(ruta):
    lf = 0
    crlf = 0

    with open(ruta, "rb") as archivo:
        while True:
            bloque = archivo.read(CHUNK)

            if not bloque:
                break

            lf += bloque.count(b"\n")
            crlf += bloque.count(b"\r\n")

    return lf, crlf


print("=" * 75)
print("PREPARACIÓN REPRODUCIBLE DEL ARCHIVO 2022")

if not ORIGEN.exists():
    raise FileNotFoundError(
        f"No se encontró el archivo RAW:\n{ORIGEN}"
    )

tamano_total = ORIGEN.stat().st_size

print(f"Archivo RAW: {ORIGEN.name}")
print(f"Tamaño total: {tamano_total:,} bytes")

if tamano_total % 2 != 0:
    raise RuntimeError(
        "El tamaño del archivo no permite dividirlo "
        "en dos mitades exactas."
    )

tamano_mitad = tamano_total // 2

print(f"Tamaño mitad 1: {tamano_mitad:,} bytes")
print(f"Tamaño mitad 2: {tamano_mitad:,} bytes")

hash_1 = sha256_rango(
    ORIGEN,
    0,
    tamano_mitad
)

hash_2 = sha256_rango(
    ORIGEN,
    tamano_mitad,
    tamano_mitad
)

print(f"SHA-256 mitad 1: {hash_1}")
print(f"SHA-256 mitad 2: {hash_2}")

if hash_1 != hash_2:
    raise RuntimeError(
        "Las mitades no son idénticas. "
        "No se generará ningún archivo derivado."
    )

print("Validación: las dos mitades son idénticas.")

CARPETA_WORKING.mkdir(
    parents=True,
    exist_ok=True
)

temporal = DESTINO.with_suffix(".tmp")

with open(ORIGEN, "rb") as entrada, \
     open(temporal, "wb") as salida:

    restante = tamano_mitad

    while restante > 0:
        bloque = entrada.read(
            min(CHUNK, restante)
        )

        if not bloque:
            raise RuntimeError(
                "Lectura incompleta del archivo RAW."
            )

        salida.write(bloque)
        restante -= len(bloque)

os.replace(temporal, DESTINO)

print()
print("Archivo de trabajo generado:")
print(DESTINO)

tamano_salida = DESTINO.stat().st_size
hash_salida = sha256_rango(
    DESTINO,
    0,
    tamano_salida
)

lf, crlf = contar_saltos(DESTINO)

with open(
    DESTINO,
    "r",
    encoding="utf-8",
    newline=""
) as archivo:

    primera_linea = archivo.readline()
    encabezados = next(
        csv.reader([primera_linea])
    )

numero_lineas = lf + 1
registros_datos = numero_lineas - 1

print()
print("=" * 75)
print("VALIDACIÓN DEL ARCHIVO DERIVADO")
print(f"Tamaño: {tamano_salida:,} bytes")
print(f"SHA-256: {hash_salida}")
print(f"Saltos LF: {lf:,}")
print(f"Saltos CRLF: {crlf:,}")
print(f"Líneas físicas: {numero_lineas:,}")
print(f"Registros de datos: {registros_datos:,}")
print(
    f"Columnas del encabezado: "
    f"{len(encabezados)}"
)

if tamano_salida != tamano_mitad:
    raise RuntimeError(
        "El tamaño del archivo derivado es incorrecto."
    )

if hash_salida != hash_1:
    raise RuntimeError(
        "El hash del archivo derivado "
        "no coincide con la primera copia."
    )

if len(encabezados) != 41:
    raise RuntimeError(
        "El encabezado no contiene 41 columnas."
    )

print()
print("RESULTADO FINAL: ARCHIVO DE TRABAJO VÁLIDO.")
print("El archivo RAW original NO fue modificado.")