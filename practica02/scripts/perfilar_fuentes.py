from pathlib import Path
from collections import Counter
from datetime import datetime
import csv
import hashlib


BASE = Path(__file__).resolve().parents[1]

RAW = BASE / "data" / "raw"
WORKING = BASE / "data" / "working"
DOCS = BASE / "docs"

MANIFEST = BASE / "data" / "manifest_fuentes.csv"
REPORTE = DOCS / "inspeccion_inicial.md"


RAW_2022 = RAW / "muestra200k_COVID19MEXICOLOC2022.csv"

WORK_2022 = (
    WORKING
    / "muestra200k_COVID19MEXICOLOC2022_trabajo.csv"
)

RAW_2023 = RAW / "muestra100k_COVID19MEXICOLOC2023.csv"


CHUNK = 8 * 1024 * 1024


FECHAS = {
    "FECHA_ACTUALIZACION",
    "FECHA_INGRESO",
    "FECHA_SINTOMAS",
    "FECHA_DEF",
    "FECHA_RESULTADO",
}


def sha256_archivo(ruta):
    h = hashlib.sha256()

    with open(ruta, "rb") as f:
        while True:
            bloque = f.read(CHUNK)

            if not bloque:
                break

            h.update(bloque)

    return h.hexdigest()


def metadata(ruta):
    tamano = ruta.stat().st_size

    return {
        "archivo": ruta.name,
        "tamano_bytes": tamano,
        "tamano_mib": round(
            tamano / (1024 ** 2),
            2
        ),
        "sha256": sha256_archivo(ruta),
    }


def es_fecha_iso(valor):
    try:
        datetime.strptime(
            valor,
            "%Y-%m-%d"
        )

        return True

    except ValueError:
        return False


def perfilar_csv(ruta):
    print()
    print("=" * 80)
    print(f"PERFILANDO: {ruta.name}")

    with open(
        ruta,
        "r",
        encoding="utf-8",
        newline=""
    ) as f:

        reader = csv.reader(f)

        encabezados = next(reader)
        columnas_esperadas = len(encabezados)

        vacios = Counter()
        centinelas_fecha = Counter()
        fechas_invalidas = Counter()
        tabulaciones = Counter()
        max_longitud = Counter()

        filas = 0
        filas_malformadas = 0
        ejemplos_malformados = []

        for numero_fila, fila in enumerate(
            reader,
            start=2
        ):
            filas += 1

            if len(fila) != columnas_esperadas:
                filas_malformadas += 1

                if len(ejemplos_malformados) < 5:
                    ejemplos_malformados.append(
                        (
                            numero_fila,
                            len(fila)
                        )
                    )

                continue

            for columna, valor in zip(
                encabezados,
                fila
            ):
                limpio = valor.strip(
                    " \t\r\n"
                )

                if limpio == "":
                    vacios[columna] += 1

                longitud = len(limpio)

                if longitud > max_longitud[columna]:
                    max_longitud[columna] = longitud

                if "\t" in valor:
                    tabulaciones[columna] += 1

                if columna in FECHAS:
                    if limpio == "":
                        continue

                    if limpio == "9999-99-99":
                        centinelas_fecha[columna] += 1

                    elif not es_fecha_iso(limpio):
                        fechas_invalidas[columna] += 1

    print(f"Registros: {filas:,}")
    print(
        f"Columnas esperadas: "
        f"{columnas_esperadas}"
    )
    print(
        f"Filas con número incorrecto "
        f"de campos: {filas_malformadas:,}"
    )

    print(
        f"Celdas vacías: "
        f"{sum(vacios.values()):,}"
    )

    print(
        f"Valores 9999-99-99: "
        f"{sum(centinelas_fecha.values()):,}"
    )

    print(
        f"Fechas inválidas adicionales: "
        f"{sum(fechas_invalidas.values()):,}"
    )

    print(
        f"Campos con tabulación: "
        f"{sum(tabulaciones.values()):,}"
    )

    return {
        "encabezados": encabezados,
        "filas": filas,
        "columnas": columnas_esperadas,
        "filas_malformadas": filas_malformadas,
        "ejemplos_malformados": ejemplos_malformados,
        "vacios": vacios,
        "centinelas_fecha": centinelas_fecha,
        "fechas_invalidas": fechas_invalidas,
        "tabulaciones": tabulaciones,
        "max_longitud": max_longitud,
    }


# ----------------------------------------------------------
# Validaciones de existencia
# ----------------------------------------------------------

for ruta in [
    RAW_2022,
    WORK_2022,
    RAW_2023
]:
    if not ruta.exists():
        raise FileNotFoundError(
            f"No existe el archivo requerido:\n{ruta}"
        )


# ----------------------------------------------------------
# Metadatos
# ----------------------------------------------------------

print("=" * 80)
print("GENERANDO MANIFIESTO DE FUENTES")

meta_raw_2022 = metadata(RAW_2022)
meta_work_2022 = metadata(WORK_2022)
meta_raw_2023 = metadata(RAW_2023)


# ----------------------------------------------------------
# Perfilado de archivos utilizables
# ----------------------------------------------------------

perfil_2022 = perfilar_csv(WORK_2022)
perfil_2023 = perfilar_csv(RAW_2023)


# ----------------------------------------------------------
# Comparación de esquemas
# ----------------------------------------------------------

set_2022 = set(perfil_2022["encabezados"])
set_2023 = set(perfil_2023["encabezados"])

solo_2022 = sorted(
    set_2022 - set_2023
)

solo_2023 = sorted(
    set_2023 - set_2022
)


# ----------------------------------------------------------
# manifest_fuentes.csv
# ----------------------------------------------------------

MANIFEST.parent.mkdir(
    parents=True,
    exist_ok=True
)

with open(
    MANIFEST,
    "w",
    encoding="utf-8",
    newline=""
) as f:

    campos = [
        "archivo",
        "capa",
        "periodo",
        "tamano_bytes",
        "tamano_mib",
        "sha256",
        "registros_datos",
        "columnas",
        "observacion",
    ]

    writer = csv.DictWriter(
        f,
        fieldnames=campos
    )

    writer.writeheader()

    writer.writerow({
        **meta_raw_2022,
        "capa": "RAW",
        "periodo": "2022",
        "registros_datos": "3999996",
        "columnas": "41",
        "observacion":
            "Archivo recibido. Contiene dos "
            "copias byte a byte identicas."
    })

    writer.writerow({
        **meta_work_2022,
        "capa": "WORKING",
        "periodo": "2022",
        "registros_datos":
            perfil_2022["filas"],
        "columnas":
            perfil_2022["columnas"],
        "observacion":
            "Primera copia valida derivada "
            "del RAW sin modificar el original."
    })

    writer.writerow({
        **meta_raw_2023,
        "capa": "RAW",
        "periodo": "2023",
        "registros_datos":
            perfil_2023["filas"],
        "columnas":
            perfil_2023["columnas"],
        "observacion":
            "Archivo fuente 2023."
    })


# ----------------------------------------------------------
# inspeccion_inicial.md
# ----------------------------------------------------------

DOCS.mkdir(
    parents=True,
    exist_ok=True
)


def escribir_counter(
    archivo,
    titulo,
    contador
):
    archivo.write(
        f"\n### {titulo}\n\n"
    )

    if not contador:
        archivo.write(
            "No se detectaron casos.\n"
        )
        return

    archivo.write(
        "| Campo | Cantidad |\n"
    )

    archivo.write(
        "|---|---:|\n"
    )

    for campo, cantidad in sorted(
        contador.items()
    ):
        archivo.write(
            f"| `{campo}` | "
            f"{cantidad:,} |\n"
        )


with open(
    REPORTE,
    "w",
    encoding="utf-8"
) as md:

    md.write(
        "# Inspección inicial de fuentes "
        "— Práctica 2\n\n"
    )

    md.write(
        "Este documento fue generado "
        "a partir de los archivos utilizados "
        "en la Práctica 2.\n\n"
    )

    md.write(
        "## 1. Archivos\n\n"
    )

    md.write(
        "| Archivo | Capa | Registros | "
        "Columnas | Tamaño MiB |\n"
    )

    md.write(
        "|---|---|---:|---:|---:|\n"
    )

    md.write(
        f"| {RAW_2022.name} | RAW | "
        f"3,999,996 | 41 | "
        f"{meta_raw_2022['tamano_mib']} |\n"
    )

    md.write(
        f"| {WORK_2022.name} | WORKING | "
        f"{perfil_2022['filas']:,} | "
        f"{perfil_2022['columnas']} | "
        f"{meta_work_2022['tamano_mib']} |\n"
    )

    md.write(
        f"| {RAW_2023.name} | RAW | "
        f"{perfil_2023['filas']:,} | "
        f"{perfil_2023['columnas']} | "
        f"{meta_raw_2023['tamano_mib']} |\n"
    )

    md.write(
        "\n## 2. Integridad estructural\n\n"
    )

    md.write(
        f"- 2022 WORKING: "
        f"{perfil_2022['filas_malformadas']:,} "
        "filas con número incorrecto "
        "de columnas.\n"
    )

    md.write(
        f"- 2023 RAW: "
        f"{perfil_2023['filas_malformadas']:,} "
        "filas con número incorrecto "
        "de columnas.\n"
    )

    md.write(
        "\n## 3. Diferencias de esquema\n\n"
    )

    md.write(
        "Campos presentes solamente en 2022:\n\n"
    )

    if solo_2022:
        for campo in solo_2022:
            md.write(
                f"- `{campo}`\n"
            )
    else:
        md.write(
            "- Ninguno.\n"
        )

    md.write(
        "\nCampos presentes solamente en 2023:\n\n"
    )

    if solo_2023:
        for campo in solo_2023:
            md.write(
                f"- `{campo}`\n"
            )
    else:
        md.write(
            "- Ninguno.\n"
        )

    md.write(
        "\n## 4. Perfil 2022\n"
    )

    escribir_counter(
        md,
        "Celdas vacías",
        perfil_2022["vacios"]
    )

    escribir_counter(
        md,
        "Centinelas de fecha 9999-99-99",
        perfil_2022["centinelas_fecha"]
    )

    escribir_counter(
        md,
        "Fechas inválidas adicionales",
        perfil_2022["fechas_invalidas"]
    )

    escribir_counter(
        md,
        "Campos que contienen tabulación",
        perfil_2022["tabulaciones"]
    )

    md.write(
        "\n## 5. Perfil 2023\n"
    )

    escribir_counter(
        md,
        "Celdas vacías",
        perfil_2023["vacios"]
    )

    escribir_counter(
        md,
        "Centinelas de fecha 9999-99-99",
        perfil_2023["centinelas_fecha"]
    )

    escribir_counter(
        md,
        "Fechas inválidas adicionales",
        perfil_2023["fechas_invalidas"]
    )

    escribir_counter(
        md,
        "Campos que contienen tabulación",
        perfil_2023["tabulaciones"]
    )

    md.write(
        "\n## 6. Longitudes máximas relevantes\n\n"
    )

    md.write(
        "| Campo | 2022 | 2023 |\n"
    )

    md.write(
        "|---|---:|---:|\n"
    )

    for campo in [
        "ID_REGISTRO",
        "PAIS_NACIONALIDAD",
        "PAIS_ORIGEN",
        "CLUES",
    ]:

        valor_2022 = (
            perfil_2022["max_longitud"]
            .get(campo, "N/A")
        )

        valor_2023 = (
            perfil_2023["max_longitud"]
            .get(campo, "N/A")
        )

        md.write(
            f"| `{campo}` | "
            f"{valor_2022} | "
            f"{valor_2023} |\n"
        )


print()
print("=" * 80)
print("PERFILADO COMPLETADO")
print()
print(f"Manifest generado:")
print(MANIFEST)
print()
print(f"Reporte generado:")
print(REPORTE)