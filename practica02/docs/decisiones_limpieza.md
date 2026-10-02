## Duplicados en la tabla histórica

Se auditó la tabla `covid_historica` utilizando `ID_REGISTRO` como
identificador principal y, adicionalmente, la combinación
`ID_REGISTRO + FECHA_ACTUALIZACION`.

La tabla contiene 2,099,997 registros y 2,099,997 valores distintos de
`ID_REGISTRO`, sin valores NULL en dicho campo.

No se detectaron:

- identificadores repetidos;
- repeticiones dentro de 2022;
- repeticiones dentro de 2023;
- identificadores presentes simultáneamente en ambos años;
- combinaciones repetidas de `ID_REGISTRO + FECHA_ACTUALIZACION`;
- duplicados exactos.

Por lo tanto, no se aplicó eliminación ni deduplicación. Los 2,099,997
registros históricos se conservan.