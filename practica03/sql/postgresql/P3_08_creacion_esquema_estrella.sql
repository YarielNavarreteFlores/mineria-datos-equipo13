-- Equipo 13 | Práctica 3 | PostgreSQL 18
-- Instalación inicial en covid20a23sedi. Ejecutar el archivo completo.
-- Un esquema existente produce error y protege la instalación anterior.
BEGIN;

DO $control$
BEGIN
    IF current_database() <> 'covid20a23sedi' THEN
        RAISE EXCEPTION 'Seleccione la base covid20a23sedi';
    END IF;
END;
$control$;

CREATE SCHEMA p3_covid;

-- Una fecha puede desempeñar cinco funciones en el mismo registro.
CREATE TABLE p3_covid.dim_fecha (
    id_fecha integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha date NOT NULL UNIQUE,
    anio smallint GENERATED ALWAYS AS (EXTRACT(YEAR FROM fecha)::smallint) STORED,
    trimestre smallint GENERATED ALWAYS AS (EXTRACT(QUARTER FROM fecha)::smallint) STORED,
    mes smallint GENERATED ALWAYS AS (EXTRACT(MONTH FROM fecha)::smallint) STORED,
    dia smallint GENERATED ALWAYS AS (EXTRACT(DAY FROM fecha)::smallint) STORED
);

CREATE TABLE p3_covid.dim_residencia (
    id_residencia integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entidad_res smallint,
    municipio_res smallint,
    nombre_entidad text,
    nombre_municipio text,
    estado_validacion text NOT NULL,
    UNIQUE NULLS NOT DISTINCT (entidad_res, municipio_res)
);

CREATE TABLE p3_covid.dim_unidad_medica (
    id_unidad_medica integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entidad_um smallint,
    municipio_um smallint,
    clues varchar(11),
    sector smallint,
    origen smallint,
    UNIQUE NULLS NOT DISTINCT (entidad_um, municipio_um, clues, sector, origen)
);

CREATE TABLE p3_covid.dim_perfil_demografico (
    id_perfil integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sexo smallint,
    edad smallint,
    entidad_nac smallint,
    nacionalidad smallint,
    embarazo smallint,
    habla_lengua_indig smallint,
    indigena smallint,
    migrante smallint,
    pais_nacionalidad varchar(60),
    pais_origen varchar(60),
    UNIQUE NULLS NOT DISTINCT (sexo, edad, entidad_nac, nacionalidad, embarazo, habla_lengua_indig, indigena, migrante, pais_nacionalidad, pais_origen)
);

CREATE TABLE p3_covid.dim_comorbilidad (
    id_comorbilidad integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    diabetes smallint,
    epoc smallint,
    asma smallint,
    inmusupr smallint,
    hipertension smallint,
    otra_com smallint,
    cardiovascular smallint,
    obesidad smallint,
    renal_cronica smallint,
    tabaquismo smallint,
    UNIQUE NULLS NOT DISTINCT (diabetes, epoc, asma, inmusupr, hipertension, otra_com, cardiovascular, obesidad, renal_cronica, tabaquismo)
);

CREATE TABLE p3_covid.dim_atencion_clinica (
    id_atencion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_paciente smallint,
    intubado smallint,
    neumonia smallint,
    uci smallint,
    UNIQUE NULLS NOT DISTINCT (tipo_paciente, intubado, neumonia, uci)
);

CREATE TABLE p3_covid.dim_diagnostico (
    id_diagnostico integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    otro_caso smallint,
    toma_muestra_lab smallint,
    resultado_lab smallint,
    toma_muestra_antigeno smallint,
    resultado_antigeno smallint,
    clasificacion_final smallint,
    UNIQUE NULLS NOT DISTINCT (otro_caso, toma_muestra_lab, resultado_lab, toma_muestra_antigeno, resultado_antigeno, clasificacion_final)
);

CREATE TABLE p3_covid.dim_fuente (
    id_fuente integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio_fuente smallint NOT NULL,
    archivo_fuente varchar(100) NOT NULL,
    UNIQUE NULLS NOT DISTINCT (anio_fuente, archivo_fuente)
);

CREATE TABLE p3_covid.fact_registro_covid (
    id_registro varchar(7) PRIMARY KEY,
    id_fecha_actualizacion integer REFERENCES p3_covid.dim_fecha(id_fecha),
    id_fecha_ingreso integer REFERENCES p3_covid.dim_fecha(id_fecha),
    id_fecha_sintomas integer REFERENCES p3_covid.dim_fecha(id_fecha),
    id_fecha_def integer REFERENCES p3_covid.dim_fecha(id_fecha),
    id_fecha_resultado integer REFERENCES p3_covid.dim_fecha(id_fecha),
    id_residencia integer NOT NULL REFERENCES p3_covid.dim_residencia(id_residencia),
    id_unidad_medica integer NOT NULL REFERENCES p3_covid.dim_unidad_medica(id_unidad_medica),
    id_perfil integer NOT NULL REFERENCES p3_covid.dim_perfil_demografico(id_perfil),
    id_comorbilidad integer NOT NULL REFERENCES p3_covid.dim_comorbilidad(id_comorbilidad),
    id_atencion integer NOT NULL REFERENCES p3_covid.dim_atencion_clinica(id_atencion),
    id_diagnostico integer NOT NULL REFERENCES p3_covid.dim_diagnostico(id_diagnostico),
    id_fuente integer NOT NULL REFERENCES p3_covid.dim_fuente(id_fuente),
    cantidad_registros smallint NOT NULL DEFAULT 1 CHECK (cantidad_registros = 1)
);

COMMIT;

-- Inventario esperado: nueve tablas, nueve claves primarias y doce foráneas.
SELECT t.table_name AS tabla,
       COUNT(c.constraint_name) FILTER (WHERE c.constraint_type = 'PRIMARY KEY') AS primarias,
       COUNT(c.constraint_name) FILTER (WHERE c.constraint_type = 'FOREIGN KEY') AS foraneas
FROM information_schema.tables AS t
LEFT JOIN information_schema.table_constraints AS c
       ON c.table_schema = t.table_schema AND c.table_name = t.table_name
WHERE t.table_schema = 'p3_covid' AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name
ORDER BY t.table_name;