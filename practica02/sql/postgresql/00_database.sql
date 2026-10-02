/*
    PRÁCTICA 2 - MINERÍA DE DATOS
    Punto 2.1 - Creación de la base de datos

    Ejecutar conectado a una base administrativa,
    por ejemplo: postgres.

    Se utiliza UTF8 para conservar correctamente
    caracteres acentuados y nombres de países.
*/

CREATE DATABASE covid20a23sedi
    WITH
    ENCODING = 'UTF8'
    TEMPLATE = template0;