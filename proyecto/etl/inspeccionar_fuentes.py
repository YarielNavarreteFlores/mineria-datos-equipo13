from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
from typing import Any


ENCODINGS_CANDIDATOS = (
    "utf-8-sig",
    "utf-8",
    "cp1252",
    "latin-1",
)

DELIMITADORES_CANDIDATOS = ",;\t|"


def calcular_sha256(ruta: Path, bloque: int = 1024 * 1024) -> str:
    """Calcula SHA-256 sin cargar el archivo completo en memoria."""
    digest = hashlib.sha256()

    with ruta.open("rb") as archivo:
        while True:
            datos = archivo.read(bloque)
            if not datos:
                break
            digest.update(datos)

    return digest.hexdigest().upper()


def detectar_encoding(ruta: Path) -> str:
    """
    Selecciona el primer encoding capaz de decodificar una muestra
    del archivo sin producir UnicodeDecodeError.
    """
    muestra = ruta.read_bytes()[:1024 * 1024]

    for encoding in ENCODINGS_CANDIDATOS:
        try:
            muestra.decode(encoding)
            return encoding
        except UnicodeDecodeError:
            continue

    return "latin-1"


def detectar_delimitador(ruta: Path, encoding: str) -> str:
    """Intenta inferir el separador con csv.Sniffer."""
    with ruta.open(
        "r",
        encoding=encoding,
        errors="replace",
        newline=""
    ) as archivo:
        muestra = archivo.read(64 * 1024)

    try:
        dialecto = csv.Sniffer().sniff(
            muestra,
            delimiters=DELIMITADORES_CANDIDATOS
        )
        return dialecto.delimiter
    except csv.Error:
        return ","


def inspeccionar_csv(ruta: Path) -> dict[str, Any]:
    encoding = detectar_encoding(ruta)
    delimitador = detectar_delimitador(ruta, encoding)

    total_lineas = 0
    filas_datos = 0
    filas_malformadas = 0
    encabezados: list[str] = []
    ejemplos: list[list[str]] = []

    with ruta.open(
        "r",
        encoding=encoding,
        errors="replace",
        newline=""
    ) as archivo:

        lector = csv.reader(archivo, delimiter=delimitador)

        try:
            encabezados = next(lector)
            total_lineas += 1
        except StopIteration:
            return {
                "archivo": ruta.name,
                "ruta": str(ruta),
                "error": "Archivo vacío",
            }

        numero_columnas = len(encabezados)

        for fila in lector:
            total_lineas += 1
            filas_datos += 1

            if len(fila) != numero_columnas:
                filas_malformadas += 1

            if len(ejemplos) < 3:
                ejemplos.append(fila)

    return {
        "archivo": ruta.name,
        "ruta": str(ruta),
        "tamano_bytes": ruta.stat().st_size,
        "tamano_mib": round(
            ruta.stat().st_size / (1024 * 1024),
            2
        ),
        "sha256": calcular_sha256(ruta),
        "encoding_detectado": encoding,
        "delimitador": repr(delimitador),
        "numero_columnas": len(encabezados),
        "encabezados": encabezados,
        "filas_datos": filas_datos,
        "filas_malformadas": filas_malformadas,
        "ejemplos": ejemplos,
    }


def imprimir_resultado(resultado: dict[str, Any]) -> None:
    print("=" * 72)
    print(f"Archivo: {resultado.get('archivo')}")
    print("=" * 72)

    if "error" in resultado:
        print(f"ERROR: {resultado['error']}")
        return

    print(f"Tamaño bytes:       {resultado['tamano_bytes']:,}")
    print(f"Tamaño MiB:         {resultado['tamano_mib']}")
    print(f"SHA-256:            {resultado['sha256']}")
    print(f"Encoding detectado: {resultado['encoding_detectado']}")
    print(f"Delimitador:        {resultado['delimitador']}")
    print(f"Columnas:           {resultado['numero_columnas']}")
    print(f"Filas de datos:     {resultado['filas_datos']:,}")
    print(f"Filas malformadas:  {resultado['filas_malformadas']:,}")

    print("\nEncabezados:")
    for numero, encabezado in enumerate(
        resultado["encabezados"],
        start=1
    ):
        print(f"  {numero:02d}. {encabezado}")

    print("\nPrimeras filas:")
    for fila in resultado["ejemplos"]:
        print(f"  {fila}")


def guardar_json(
    resultados: list[dict[str, Any]],
    salida: Path
) -> None:
    salida.parent.mkdir(parents=True, exist_ok=True)

    with salida.open("w", encoding="utf-8") as archivo:
        json.dump(
            resultados,
            archivo,
            ensure_ascii=False,
            indent=2
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspector reproducible de fuentes del proyecto."
    )

    parser.add_argument(
        "archivos",
        nargs="+",
        help="Uno o más archivos CSV que se desean inspeccionar."
    )

    parser.add_argument(
        "--salida-json",
        type=Path,
        default=None,
        help="Ruta opcional para guardar resultados JSON."
    )

    args = parser.parse_args()

    resultados: list[dict[str, Any]] = []

    for archivo_texto in args.archivos:
        ruta = Path(archivo_texto)

        if not ruta.exists():
            resultado = {
                "archivo": ruta.name,
                "ruta": str(ruta),
                "error": "El archivo no existe",
            }
        else:
            resultado = inspeccionar_csv(ruta)

        resultados.append(resultado)
        imprimir_resultado(resultado)

    if args.salida_json is not None:
        guardar_json(resultados, args.salida_json)

        print("\n" + "=" * 72)
        print(
            f"Resultado JSON guardado en: "
            f"{args.salida_json.resolve()}"
        )


if __name__ == "__main__":
    main()