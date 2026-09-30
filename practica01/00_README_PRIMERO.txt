PRÁCTICA 1 · MINERÍA DE DATOS · 2026-B

Proyecto:
Inteligencia de demanda de los principales sistemas
de transporte público de la Ciudad de México.

Integrantes:
- Yariel Navarrete Flores
- Eric Nava Villar
- Edén Uribe Sánchez

SOFTWARE:
- PostgreSQL
- DBeaver
- Tableau

ORDEN DE REPRODUCCIÓN:

1. Consultar los datos RAW en:
   01_Datos_Originales/

2. Consultar diccionarios en:
   02_Diccionarios/

3. Crear/importar la base siguiendo:
   04_SQL/01_validacion_importacion.sql

4. Ejecutar:
   04_SQL/02_auditoria_calidad.sql

5. Ejecutar:
   04_SQL/03_limpieza_tableau.sql

6. Ejecutar:
   04_SQL/04_resumen_procesamiento.sql

7. Abrir el workbook:
   05_Tableau/Practica01_Afluencia_Metro.twbx

CONTEOS ESPERADOS:
Metro Simple RAW:       1,180,920
Metro Desglosada RAW:   1,192,230

NOTA:
Antes de abrir el libro de Tableau, reconstruir la base PostgreSQL y verificar la conexión a practica01.

Las tablas RAW se conservan sin modificaciones.
La capa CLEAN corrige representación y homologación
sin eliminar los registros originales.