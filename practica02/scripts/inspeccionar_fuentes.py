from pathlib import Path
import hashlib
import csv

BASE = Path(__file__).resolve().parents[1]
RAW = BASE / "data" / "raw"

ARCHIVOS = [
    RAW / "muestra200k_COVID19MEXICOLOC2022.csv",
    RAW / "muestra100k_COVID19MEXICOLOC2023.csv",
]


def sha256_archivo(ruta, limite=None):
    h = hashlib.sha256()

    with open(ruta, "rb") as f:
        restantes = limite

        while True:
            if restantes is None:
                bloque = f.read(8 * 1024 * 1024)
            else:
                if restantes <= 0:
                    break

                bloque = f.read(min(8 * 1024 * 1024, restantes))

            if not bloque:
                break

            h.update(bloque)

            if restantes is not None:
                restantes -= len(bloque)

    return h.hexdigest()


def inspeccionar(ruta):
    print("=" * 80)
    print(f"ARCHIVO: {ruta.name}")

    tamano = ruta.stat().st_size

    print(f"Tamaño bytes: {tamano:,}")
    print(f"Tamaño MiB: {tamano / (1024 ** 2):.2f}")
    print(f"SHA-256: {sha256_archivo(ruta)}")

    saltos_lf = 0
    saltos_crlf = 0

    with open(ruta, "rb") as f:
        while True:
            bloque = f.read(8 * 1024 * 1024)

            if not bloque:
                break

            saltos_lf += bloque.count(b"\n")
            saltos_crlf += bloque.count(b"\r\n")

    print(f"Saltos LF: {saltos_lf:,}")
    print(f"Saltos CRLF: {saltos_crlf:,}")

    # Validación UTF-8
    try:
        with open(ruta, "r", encoding="utf-8", newline="") as f:
            primera_linea = f.readline()

        print("Codificación UTF-8: VÁLIDA")

    except UnicodeDecodeError:
        print("Codificación UTF-8: ERROR")
        return

    encabezados = next(csv.reader([primera_linea]))

    print(f"Número de columnas del encabezado: {len(encabezados)}")
    print("Encabezados:")

    for i, columna in enumerate(encabezados, start=1):
        print(f"  {i:02d}. {columna}")


def verificar_duplicacion_2022(ruta):
    print("=" * 80)
    print("VERIFICACIÓN ESPECIAL 2022")

    tamano = ruta.stat().st_size

    if tamano % 2 != 0:
        print("El archivo no puede dividirse en dos mitades exactas.")
        return

    mitad = tamano // 2

    print(f"Tamaño total: {tamano:,} bytes")
    print(f"Tamaño de cada mitad: {mitad:,} bytes")

    hash1 = hashlib.sha256()
    hash2 = hashlib.sha256()

    with open(ruta, "rb") as f:

        restantes = mitad

        while restantes > 0:
            bloque = f.read(min(8 * 1024 * 1024, restantes))

            if not bloque:
                break

            hash1.update(bloque)
            restantes -= len(bloque)

        restantes = mitad

        while restantes > 0:
            bloque = f.read(min(8 * 1024 * 1024, restantes))

            if not bloque:
                break

            hash2.update(bloque)
            restantes -= len(bloque)

    print(f"SHA-256 mitad 1: {hash1.hexdigest()}")
    print(f"SHA-256 mitad 2: {hash2.hexdigest()}")

    if hash1.digest() == hash2.digest():
        print("RESULTADO: LAS DOS MITADES SON BYTE A BYTE IDÉNTICAS.")
    else:
        print("RESULTADO: LAS DOS MITADES SON DIFERENTES.")


for archivo in ARCHIVOS:
    if not archivo.exists():
        print(f"ERROR: no existe {archivo}")
    else:
        inspeccionar(archivo)

archivo_2022 = RAW / "muestra200k_COVID19MEXICOLOC2022.csv"

if archivo_2022.exists():
    verificar_duplicacion_2022(archivo_2022)