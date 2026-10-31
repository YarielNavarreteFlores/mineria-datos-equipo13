from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


COLUMNAS_MANIFEST = [
    "sistema",
    "archivo",
    "ruta_origen",
    "tamano_bytes",
    "tamano_mib",
    "sha256",
    "encoding_detectado",
    "delimitador",
    "numero_columnas",
    "filas_datos",
    "filas_malformadas",
    "estado",
]


def cargar_inspeccion(ruta_json: Path) -> list[dict[str, Any]]:
    with ruta_json.open("r", encoding="utf-8") as archivo:
        datos = json.load(archivo)

    if not isinstance(datos, list):
        raise ValueError(
            "El archivo de inspección debe contener una lista JSON."
        )

    return datos


def construir_filas(
    resultados: list[dict[str, Any]],
    sistema: str
) -> list[dict[str, Any]]:
    filas: list[dict[str, Any]] = []

    for resultado in resultados:
        tiene_error = "error" in resultado

        fila = {
            "sistema": sistema,
            "archivo": resultado.get("archivo", ""),
            "ruta_origen": resultado.get("ruta", ""),
            "tamano_bytes": resultado.get("tamano_bytes", ""),
            "tamano_mib": resultado.get("tamano_mib", ""),
            "sha256": resultado.get("sha256", ""),
            "encoding_detectado": resultado.get(
                "encoding_detectado",
                ""
            ),
            "delimitador": resultado.get("delimitador", ""),
            "numero_columnas": resultado.get(
                "numero_columnas",
                ""
            ),
            "filas_datos": resultado.get("filas_datos", ""),
            "filas_malformadas": resultado.get(
                "filas_malformadas",
                ""
            ),
            "estado": (
                f"ERROR: {resultado['error']}"
                if tiene_error
                else "VALIDADO"
            ),
        }

        filas.append(fila)

    return filas


def guardar_manifest(
    filas: list[dict[str, Any]],
    salida: Path
) -> None:
    salida.parent.mkdir(parents=True, exist_ok=True)

    with salida.open(
        "w",
        encoding="utf-8-sig",
        newline=""
    ) as archivo:
        escritor = csv.DictWriter(
            archivo,
            fieldnames=COLUMNAS_MANIFEST
        )

        escritor.writeheader()
        escritor.writerows(filas)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Genera un manifest CSV a partir de una "
            "inspección JSON."
        )
    )

    parser.add_argument(
        "--inspeccion",
        required=True,
        type=Path,
        help="JSON generado por inspeccionar_fuentes.py",
    )

    parser.add_argument(
        "--sistema",
        required=True,
        help="Nombre del sistema de transporte.",
    )

    parser.add_argument(
        "--salida",
        required=True,
        type=Path,
        help="Ruta del manifest CSV de salida.",
    )

    args = parser.parse_args()

    resultados = cargar_inspeccion(args.inspeccion)

    filas = construir_filas(
        resultados=resultados,
        sistema=args.sistema
    )

    guardar_manifest(
        filas=filas,
        salida=args.salida
    )

    print("=" * 72)
    print("MANIFEST GENERADO")
    print("=" * 72)
    print(f"Sistema:  {args.sistema}")
    print(f"Fuentes:  {len(filas)}")
    print(f"Salida:   {args.salida.resolve()}")

    for fila in filas:
        print(
            f"- {fila['archivo']}: "
            f"{fila['filas_datos']} registros | "
            f"{fila['estado']}"
        )


if __name__ == "__main__":
    main()