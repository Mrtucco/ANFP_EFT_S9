-- ============================================================================
-- Modelamiento de Bases de Datos
-- ============================================================================

-- ----------------------------------------------------------------------------
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE table_name IN ('JUGADOR_IDIOMA','JUGADOR_CLUB','PERSONAL_PLANTA','JUGADOR',
                                   'TRABAJADOR','IDIOMA','ESCUELA_FUTBOL','CLUB_FUTBOL',
                                   'ASOCIACION','NACIONALIDAD','COMUNA','REGION')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name = 'SEQ_CLUB_FUTBOL') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ============================================================================
-- FASE 3: CREACIÓN DE TABLAS (según orden de dependencia)
-- ============================================================================

-- ---------------------------- Tablas sin FK ---------------------------------
CREATE TABLE region (
    id_region  NUMBER(2)     NOT NULL,
    nombre     VARCHAR2(60)  NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (id_region)
);

CREATE TABLE nacionalidad (
    id_nacion    NUMBER(4)     GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 2) NOT NULL,
    descripcion  VARCHAR2(40)  NOT NULL,
    CONSTRAINT pk_nacionalidad PRIMARY KEY (id_nacion)
);

CREATE TABLE asociacion (
    id_asociacion      NUMBER(3)     NOT NULL,
    nombre_asociacion  VARCHAR2(60)  NOT NULL,
    fecha_creacion     DATE          NOT NULL,
    tipo_asociacion    CHAR(1)       NOT NULL,
    CONSTRAINT pk_asociacion PRIMARY KEY (id_asociacion),
    CONSTRAINT ck_asociacion_tipo  CHECK (tipo_asociacion IN ('P','A')),
    CONSTRAINT ck_asociacion_fecha CHECK (fecha_creacion >= DATE '1980-12-31')
);

CREATE TABLE club_futbol (
    id_club          NUMBER(4)      NOT NULL,
    nombre_club      VARCHAR2(60)   NOT NULL,
    patrimonio       NUMBER(12)     DEFAULT 0 NOT NULL,
    ubicacion_calle  VARCHAR2(80)   NOT NULL,
    tipo_club        VARCHAR2(12)   DEFAULT 'Profesional' NOT NULL,
    CONSTRAINT pk_club_futbol PRIMARY KEY (id_club),
    CONSTRAINT un_club_futbol_nombre UNIQUE (nombre_club),
    CONSTRAINT ck_club_futbol_patrimonio CHECK (patrimonio >= 0),
    CONSTRAINT ck_club_futbol_tipo CHECK (tipo_club IN ('Profesional','Amateur'))
);

CREATE TABLE escuela_futbol (
    id_escuela        NUMBER(4)     NOT NULL,
    nombre_escuela    VARCHAR2(60)  NOT NULL,
    capacidad         NUMBER(5)     NOT NULL,
    fecha_fundacion   DATE          NOT NULL,
    CONSTRAINT pk_escuela_futbol PRIMARY KEY (id_escuela),
    CONSTRAINT ck_escuela_capacidad CHECK (capacidad > 0)
);

CREATE TABLE idioma (
    id_idioma      NUMBER(3)     NOT NULL,
    nombre_idioma  VARCHAR2(40)  NOT NULL,
    CONSTRAINT pk_idioma PRIMARY KEY (id_idioma),
    CONSTRAINT un_idioma_nombre UNIQUE (nombre_idioma)
);

-- ------------------------------ Con FK --------------------------------------
CREATE TABLE comuna (
    id_comuna  NUMBER(4)     NOT NULL,
    nombre     VARCHAR2(60)  NOT NULL,
    id_region  NUMBER(2)     NOT NULL,
    CONSTRAINT pk_comuna PRIMARY KEY (id_comuna),
    CONSTRAINT fk_comuna_region FOREIGN KEY (id_region) REFERENCES region (id_region)
);

CREATE TABLE trabajador (
    nro_inscripcion   NUMBER(9)     NOT NULL,
    rut               NUMBER(8)     NOT NULL,
    dv_rut            CHAR(1)       NOT NULL,
    nombres           VARCHAR2(60)  NOT NULL,
    apellidos         VARCHAR2(60)  NOT NULL,
    sueldo_base       NUMBER(9)     DEFAULT 0 NOT NULL,
    fecha_nacimiento  DATE          NOT NULL,
    genero            CHAR(1)       NOT NULL,
    estado_civil      VARCHAR2(15)  NOT NULL,
    telefono_movil    VARCHAR2(15)  NOT NULL,
    email             VARCHAR2(80),
    direccion         VARCHAR2(80)  NOT NULL,
    id_comuna         NUMBER(4)     NOT NULL,
    id_nacion         NUMBER(4)     NOT NULL,
    CONSTRAINT pk_trabajador PRIMARY KEY (nro_inscripcion),
    CONSTRAINT un_trabajador_rut UNIQUE (rut),
    CONSTRAINT ck_trabajador_genero CHECK (genero IN ('M','F')),
    CONSTRAINT ck_trabajador_sueldo CHECK (sueldo_base >= 0),
    CONSTRAINT fk_trabajador_comuna FOREIGN KEY (id_comuna) REFERENCES comuna (id_comuna),
    CONSTRAINT fk_trabajador_nacionalidad FOREIGN KEY (id_nacion) REFERENCES nacionalidad (id_nacion)
);

CREATE TABLE jugador (
    nro_inscripcion        NUMBER(9)     NOT NULL,
    puesto                 VARCHAR2(30)  NOT NULL,
    monto_total_premios    NUMBER(12)    DEFAULT 0 NOT NULL,
    id_asociacion          NUMBER(3)     NOT NULL,
    id_escuela             NUMBER(4),
    anio_fin_amateur       NUMBER(4),
    CONSTRAINT pk_jugador PRIMARY KEY (nro_inscripcion),
    CONSTRAINT ck_jugador_premios CHECK (monto_total_premios >= 0),
    CONSTRAINT fk_jugador_trabajador FOREIGN KEY (nro_inscripcion) REFERENCES trabajador (nro_inscripcion),
    CONSTRAINT fk_jugador_asociacion FOREIGN KEY (id_asociacion) REFERENCES asociacion (id_asociacion),
    CONSTRAINT fk_jugador_escuela FOREIGN KEY (id_escuela) REFERENCES escuela_futbol (id_escuela)
);

CREATE TABLE personal_planta (
    nro_inscripcion      NUMBER(9)    NOT NULL,
    horas_trabajadas     NUMBER(4),
    valor_hora_extra     NUMBER(8),
    id_club              NUMBER(4)    NOT NULL,
    CONSTRAINT pk_personal_planta PRIMARY KEY (nro_inscripcion),
    CONSTRAINT fk_personal_planta_trabajador FOREIGN KEY (nro_inscripcion) REFERENCES trabajador (nro_inscripcion),
    CONSTRAINT fk_personal_planta_club FOREIGN KEY (id_club) REFERENCES club_futbol (id_club)
);

CREATE TABLE jugador_club (
    nro_inscripcion  NUMBER(9)  NOT NULL,
    id_club          NUMBER(4)  NOT NULL,
    fecha_inicio     DATE       NOT NULL,
    fecha_fin        DATE,
    CONSTRAINT pk_jugador_club PRIMARY KEY (nro_inscripcion, id_club, fecha_inicio),
    CONSTRAINT ck_jugador_club_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT fk_jugador_club_jugador FOREIGN KEY (nro_inscripcion) REFERENCES jugador (nro_inscripcion),
    CONSTRAINT fk_jugador_club_club FOREIGN KEY (id_club) REFERENCES club_futbol (id_club)
);

CREATE TABLE jugador_idioma (
    nro_inscripcion  NUMBER(9)     NOT NULL,
    id_idioma        NUMBER(3)     NOT NULL,
    nivel_dominio    VARCHAR2(15)  NOT NULL,
    CONSTRAINT pk_jugador_idioma PRIMARY KEY (nro_inscripcion, id_idioma),
    CONSTRAINT ck_jugador_idioma_nivel CHECK (nivel_dominio IN ('Basico','Intermedio','Avanzado','Nativo')),
    CONSTRAINT fk_jugador_idioma_jugador FOREIGN KEY (nro_inscripcion) REFERENCES jugador (nro_inscripcion),
    CONSTRAINT fk_jugador_idioma_idioma FOREIGN KEY (id_idioma) REFERENCES idioma (id_idioma)
);

-- Secuencia para el código de CLUB_FUTBOL (inicia en 703, de 4 en 4)
CREATE SEQUENCE seq_club_futbol START WITH 703 INCREMENT BY 4 NOCACHE NOCYCLE;

-- ============================================================================
-- POBLAMIENTO (respetando el orden de dependencia)
-- ============================================================================

-- REGION (se incluyen las regiones 8 y 16, referenciadas por COMUNA en la Figura 2)
INSERT INTO region VALUES (1,  'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO region VALUES (2,  'ANTOFAGASTA');
INSERT INTO region VALUES (3,  'ATACAMA Y COQUIMBO');
INSERT INTO region VALUES (5,  'VALPARAISO');
INSERT INTO region VALUES (13, 'METROPOLITANA');
INSERT INTO region VALUES (8,  'BIOBIO');
INSERT INTO region VALUES (16, 'ÑUBLE');

-- COMUNA
INSERT INTO comuna VALUES (101, 'Santiago',    13);
INSERT INTO comuna VALUES (102, 'Valparaíso',   5);
INSERT INTO comuna VALUES (103, 'Concepción',   8);
INSERT INTO comuna VALUES (104, 'Antofagasta',  2);
INSERT INTO comuna VALUES (105, 'Chillán',     16);

-- ASOCIACION
INSERT INTO asociacion VALUES (25, 'Asociación de Fútbol de Santiago',        TO_DATE('15-05-2001','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (26, 'Asociación Nacional de Fútbol Amateur',   TO_DATE('10-03-1998','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (27, 'Asociación de Fútbol de Valparaíso',      TO_DATE('21-07-1987','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (28, 'Asociación de Fútbol de Concepción',      TO_DATE('30-11-1995','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (29, 'Asociación de Fútbol de Antofagasta',     TO_DATE('25-06-2003','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (30, 'Asociación de Fútbol de Temuco',          TO_DATE('12-01-2010','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (31, 'Asociación de Fútbol de Rancagua',        TO_DATE('08-09-1999','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (32, 'Asociación de Fútbol de Puerto Montt',    TO_DATE('20-04-2005','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (33, 'Asociación de Fútbol de La Serena',       TO_DATE('14-08-2012','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (34, 'Asociación de Fútbol de Chillán',         TO_DATE('01-12-2018','DD-MM-YYYY'), 'A');

-- NACIONALIDAD (IDENTITY: 210, 212, 214, 216, 218)
INSERT INTO nacionalidad (descripcion) VALUES ('Chilena');
INSERT INTO nacionalidad (descripcion) VALUES ('Argentina');
INSERT INTO nacionalidad (descripcion) VALUES ('Peruana');
INSERT INTO nacionalidad (descripcion) VALUES ('Boliviana');
INSERT INTO nacionalidad (descripcion) VALUES ('Brasileña');

-- CLUB_FUTBOL (SECUENCIA: 703, 707, 711, 715, 719)
INSERT INTO club_futbol VALUES (seq_club_futbol.NEXTVAL, 'Colo-Colo',            500000000, 'Av. Marathon 5300',               'Profesional');
INSERT INTO club_futbol VALUES (seq_club_futbol.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931',              'Profesional');
INSERT INTO club_futbol VALUES (seq_club_futbol.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606',            'Profesional');
INSERT INTO club_futbol VALUES (seq_club_futbol.NEXTVAL, 'Huachipato',           220000000, 'Avenida Desiderio García 909',     'Profesional');
INSERT INTO club_futbol VALUES (seq_club_futbol.NEXTVAL, 'Ñublense',             170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');

COMMIT;

-- ============================================================================
-- FASE 4: RECUPERACIÓN DE DATOS
-- ============================================================================

-- INFORME 1: Asociaciones de fútbol profesional
--   Tipo profesional (P), creadas después del año 2000, orden descendente por fecha de creación
SELECT 'ID:' || id_asociacion || ' * ' || nombre_asociacion AS "ASOCIACION",
       TO_CHAR(fecha_creacion, 'DD-MM-YYYY')                AS "CREADA",
       tipo_asociacion                                      AS "TIPO"
FROM   asociacion
WHERE  tipo_asociacion = 'P'
AND    EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER  BY fecha_creacion DESC;

-- INFORME 2: Patrimonio de clubes de fútbol (tipo de cambio $955 por dólar)
--   Nombre con la letra "a", patrimonio > $200.000.000, tipo profesional, orden desc por código
SELECT id_club                  AS "CLUB",
       nombre_club              AS "NOMBRE CLUB",
       patrimonio               AS "PATRIMONIO EN PESOS",
       patrimonio / 955         AS "PATRIMONIO EN DOLARES"
FROM   club_futbol
WHERE  UPPER(nombre_club) LIKE '%A%'
AND    patrimonio > 200000000
AND    UPPER(tipo_club) = 'PROFESIONAL'
ORDER  BY id_club DESC;
