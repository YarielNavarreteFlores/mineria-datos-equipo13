CREATE TABLE proyecto.afluencia_diaria_multisistema (
    fecha                  date           NOT NULL,
    sistema                text           NOT NULL,
    unidad_operativa       text           NOT NULL,
    origen_unidad_operativa text          NOT NULL,
    estado_calidad         text           NOT NULL,
    afluencia              numeric(20,13),

    PRIMARY KEY (fecha, sistema, unidad_operativa),

    CONSTRAINT ck_sistema
        CHECK (sistema IN (
            'Metro', 'Metrobús', 'RTP',
            'Cablebús', 'Trolebús', 'Tren Ligero'
        )),

    CONSTRAINT ck_unidad_operativa
        CHECK (btrim(unidad_operativa) <> ''),

    CONSTRAINT ck_procedencia_unidad
        CHECK (
            (sistema = 'Tren Ligero'
             AND unidad_operativa = 'Sistema completo'
             AND origen_unidad_operativa = 'DERIVADA_CONSTANTE')
            OR
            (sistema <> 'Tren Ligero'
             AND origen_unidad_operativa = 'FUENTE')
        ),

    CONSTRAINT ck_calidad_afluencia
        CHECK (
            (estado_calidad = 'OK' AND afluencia IS NOT NULL)
            OR
            (estado_calidad IN (
                'COLISION',
                'AFLUENCIA_INCOMPLETA',
                'COLISION_Y_NULL',
                'ESTRUCTURA_INESPERADA'
             ) AND afluencia IS NULL)
        )
);