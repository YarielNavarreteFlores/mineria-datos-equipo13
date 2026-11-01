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


def cargar_inspeccion(ruta: Path) -> list[dict[str, Any]]:
    """Carga los resultados JSON del inspector de fuentes."""
    with ruta.open("r", encoding="utf-8") as archivo:
        datos = json.load(archivo)

    if not isinstance(datos, list):
        raise ValueError(
            "El archivo de inspección debe contener una lista JSON."
        )

    if not datos:
        raise ValueError("La lista de inspección está vacía.")

    for posicion, resultado in enumerate(datos, start=1):
        if not isinstance(resultado, dict):
            raise ValueError(
                f"El elemento {posicion} debe ser un objeto JSON."
            )

    return datos


def determinar_estado(resultado: dict[str, Any]) -> str:
    """Describe la inspección sin declarar validado el pipeline."""
    if "error" in resultado:
        return f"ERROR: {resultado['error']}"

    filas_malformadas = resultado.get("filas_malformadas")

    if (
        not isinstance(filas_malformadas, int)
        or isinstance(filas_malformadas, bool)
        or filas_malformadas < 0
    ):
        return "INSPECCION_INCOMPLETA"

    if filas_malformadas > 0:
        return "REVISAR_ESTRUCTURA"

    return "INSPECCIONADO_PENDIENTE_VALIDACION"


def construir_filas(
    resultados: list[dict[str, Any]],
    sistema: str,
) -> list[dict[str, Any]]:
    """Convierte cada resultado de inspección en una fila del manifest."""
    filas: list[dict[str, Any]] = []

    for resultado in resultados:
        fila = {
            "sistema": sistema,
            "archivo": resultado.get("archivo", ""),
            "ruta_origen": resultado.get("ruta", ""),
            "tamano_bytes": resultado.get("tamano_bytes", ""),
            "tamano_mib": resultado.get("tamano_mib", ""),
            "sha256": resultado.get("sha256", ""),
            "encoding_detectado": resultado.get(
                "encoding_detectado", ""
            ),
            "delimitador": resultado.get("delimitador", ""),
            "numero_columnas": resultado.get("numero_columnas", ""),
            "filas_datos": resultado.get("filas_datos", ""),
            "filas_malformadas": resultado.get(
                "filas_malformadas", ""
            ),
            "estado": determinar_estado(resultado),
        }

        filas.append(fila)

    return filas


def guardar_manifest(
    filas: list[dict[str, Any]],
    salida: Path,
) -> None:
    """Guarda el manifest CSV sin modificar las fuentes originales."""
    salida.parent.mkdir(parents=True, exist_ok=True)

    with salida.open(
        "w",
        encoding="utf-8-sig",
        newline="",
    ) as archivo:
        escritor = csv.DictWriter(
            archivo,
            fieldnames=COLUMNAS_MANIFEST,
        )
        escritor.writeheader()
        escritor.writerows(filas)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera un manifest CSV desde una inspección JSON."
    )

    parser.add_argument(
        "--inspeccion",
        required=True,
        type=Path,
        help="JSON generado por inspeccionar_fuentes.py.",
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

    sistema = args.sistema.strip()

    if not sistema:
        parser.error("--sistema no puede estar vacío.")

    if args.inspeccion.resolve() == args.salida.resolve():
        parser.error("La entrada y la salida deben ser archivos distintos.")

    try:
        resultados = cargar_inspeccion(args.inspeccion)
        filas = construir_filas(resultados, sistema)
        guardar_manifest(filas, args.salida)
    except (OSError, ValueError, csv.Error) as error:
        parser.exit(1, f"ERROR: {error}\n")

    print("=" * 72)
    print("MANIFEST GENERADO")
    print("=" * 72)
    print(f"Sistema: {sistema}")
    print(f"Fuentes: {len(filas)}")
    print(f"Salida:  {args.salida.resolve()}")

    for fila in filas:
        print(
            f"- {fila['archivo']} | "
            f"{fila['filas_datos']} registros | "
            f"{fila['estado']}"
        )


if __name__ == "__main__":
    main()