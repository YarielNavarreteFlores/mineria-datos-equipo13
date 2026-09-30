Motor:
PostgreSQL

Base utilizada durante la práctica:
mineria_datos_2026b

Esquema:
practica01

Tablas RAW:
- metro_simple_raw
- metro_desglosada_raw

Tablas generadas posteriormente:
- metro_simple_clean
- metro_desglosada_clean
- resumen_procesamiento

CONFIGURACIÓN INICIAL
1. Crear en PostgreSQL una base de datos llamada:
   mineria_datos_2026b

2. Conectarse a dicha base.

3. Ejecutar:
   esquema_practica01.sql

4. Importar los archivos:
   01_Datos_Originales/datos_metro_simple_raw.csv
   01_Datos_Originales/datos_metro_desglosada_raw.csv
   en las tablas:
   practica01.metro_simple_raw
   practica01.metro_desglosada_raw

5. Ejecutar los scripts de 04_SQL en orden numérico.


CONEXIÓN UTILIZADA

Host: localhost
Puerto: 5432
Base de datos: mineria_datos_2026b
Esquema: practica01
Usuario: postgres

Nota:
La contraseña no se incluye por razones de seguridad.
Cada usuario debe utilizar sus propias credenciales locales.


Para TABLEAU

El archivo .twbx conserva una conexión a PostgreSQL.
Al abrirlo en otro equipo puede solicitar autenticación.

Antes de abrir Tableau:
1. Reconstruir la base de datos.
2. Verificar que PostgreSQL esté activo.
3. Confirmar la conexión al esquema practica01.
4. Ingresar las credenciales locales cuando Tableau las solicite.