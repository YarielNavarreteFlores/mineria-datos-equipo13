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

## Interpretación de códigos especiales

### Nacionalidad

El catálogo define los códigos:

- 1 = MEXICANA
- 2 = EXTRANJERA
- 99 = NO ESPECIFICADO

Los códigos se conservaron como categorías y no se transformaron
automáticamente a NULL.

`PAIS_NACIONALIDAD` representa la nacionalidad del paciente, mientras que
`PAIS_ORIGEN` representa el país desde el cual partió rumbo a México. El valor
textual `97` observado en `PAIS_ORIGEN` se conserva según el dominio de la
fuente.

### Municipio de residencia

`MUNICIPIO_RES` no debe interpretarse de forma aislada, sino en conjunto con
`ENTIDAD_RES`.

Los valores 97, 98 y 99 pueden corresponder a códigos municipales ordinarios
dentro de una entidad, por lo que no se consideran automáticamente anomalías.

El código 999 puede representar MUNICIPIO NO ESPECIFICADO. Además, el catálogo
contempla combinaciones especiales asociadas a las entidades 97, 98 y 99.

Por ello, la validación territorial se realizó utilizando la combinación:

`ENTIDAD_RES + MUNICIPIO_RES`.