-- Script SQL para la creación de tablas optimizadas en PostgreSQL

-- ENUMs para estados
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_empleado') THEN
        CREATE TYPE estado_empleado AS ENUM ('activo', 'inactivo', 'baja');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_postulacion') THEN
        CREATE TYPE estado_postulacion AS ENUM ('recibido', 'en_revision', 'entrevista', 'rechazado', 'contratado');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_candidatura') THEN
        CREATE TYPE estado_candidatura AS ENUM ('pendiente', 'en_proceso', 'contratado', 'descartado');
    END IF;
END$$;

-- Tabla: puestos
CREATE TABLE puestos (
    puesto_id SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(100) NOT NULL,
    descripcion_puesto TEXT,
    salario_rango_min DECIMAL(10, 2),
    salario_rango_max DECIMAL(10, 2),
    CHECK (salario_rango_min < salario_rango_max)
);

CREATE INDEX idx_puestos_nombre ON puestos (nombre_puesto);

-- Tabla: departamentos
CREATE TABLE departamentos (
    departamento_id SERIAL PRIMARY KEY,
    nombre_departamento VARCHAR(100) NOT NULL UNIQUE,
    ubicacion VARCHAR(100)
);

CREATE INDEX idx_departamentos_nombre ON departamentos (nombre_departamento);

-- Tabla: empleados
CREATE TABLE empleados (
    empleado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE,
    dni_nif VARCHAR(20) UNIQUE,
    direccion VARCHAR(255),
    ciudad VARCHAR(100),
    provincia VARCHAR(100),
    codigo_postal VARCHAR(10),
    email VARCHAR(254) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    fecha_contratacion DATE NOT NULL DEFAULT CURRENT_DATE,
    puesto_id INT,
    salario DECIMAL(10, 2),
    departamento_id INT,
    estado_empleado estado_empleado DEFAULT 'activo',
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_puesto_empleado
        FOREIGN KEY (puesto_id) REFERENCES puestos(puesto_id) ON DELETE SET NULL,
    CONSTRAINT fk_departamento_empleado
        FOREIGN KEY (departamento_id) REFERENCES departamentos(departamento_id) ON DELETE SET NULL
);

CREATE INDEX idx_empleados_nombre_apellido ON empleados (apellido, nombre);
CREATE INDEX idx_empleados_email ON empleados (email);
CREATE INDEX idx_empleados_puesto ON empleados (puesto_id);
CREATE INDEX idx_empleados_departamento ON empleados (departamento_id);

-- Trigger Function para fecha_actualizacion
CREATE OR REPLACE FUNCTION update_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_empleados_fecha_actualizacion
BEFORE UPDATE ON empleados
FOR EACH ROW
EXECUTE FUNCTION update_fecha_actualizacion();

-- Tabla: postulantes
CREATE TABLE postulantes (
    postulante_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    dni_nif VARCHAR(20) UNIQUE,
    experiencia_laboral TEXT,
    educacion TEXT,
    puesto_deseado_id INT,
    fecha_postulacion DATE NOT NULL DEFAULT CURRENT_DATE,
    estado_postulacion estado_postulacion DEFAULT 'recibido',
    url_curriculum VARCHAR(255),
    comentarios TEXT,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_puesto_deseado
        FOREIGN KEY (puesto_deseado_id) REFERENCES puestos(puesto_id) ON DELETE SET NULL
);

CREATE INDEX idx_postulantes_nombre_apellido ON postulantes (apellido, nombre);
CREATE INDEX idx_postulantes_email ON postulantes (email);
CREATE INDEX idx_postulantes_estado ON postulantes (estado_postulacion);

CREATE TRIGGER trg_postulantes_fecha_actualizacion
BEFORE UPDATE ON postulantes
FOR EACH ROW
EXECUTE FUNCTION update_fecha_actualizacion();

-- Tabla: candidaturas
CREATE TABLE candidaturas (
    candidatura_id SERIAL PRIMARY KEY,
    postulante_id INT NOT NULL,
    puesto_id INT NOT NULL,
    fecha_aplicacion DATE NOT NULL DEFAULT CURRENT_DATE,
    estado_candidatura estado_candidatura DEFAULT 'pendiente',
    notas_reclutador TEXT,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_candidatura_postulante
        FOREIGN KEY (postulante_id) REFERENCES postulantes(postulante_id) ON DELETE CASCADE,
    CONSTRAINT fk_candidatura_puesto
        FOREIGN KEY (puesto_id) REFERENCES puestos(puesto_id) ON DELETE CASCADE,
    CONSTRAINT uq_candidatura UNIQUE (postulante_id, puesto_id)
);

CREATE INDEX idx_candidaturas_postulante ON candidaturas (postulante_id);
CREATE INDEX idx_candidaturas_puesto ON candidaturas (puesto_id);
CREATE INDEX idx_candidaturas_estado ON candidaturas (estado_candidatura);

CREATE TRIGGER trg_candidaturas_fecha_actualizacion
BEFORE UPDATE ON candidaturas
FOR EACH ROW
EXECUTE FUNCTION update_fecha_actualizacion();

-- Tabla: proyectos
CREATE TABLE proyectos (
    proyecto_id SERIAL PRIMARY KEY,
    nombre_proyecto VARCHAR(255) NOT NULL,
    descripcion_proyecto TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_final DATE,
    manager_id INT,
    
    CONSTRAINT fk_manager
        FOREIGN KEY (manager_id) REFERENCES empleados(empleado_id) ON DELETE SET NULL
);
