-- =============================================
-- ROLES Y PERMISOS DE USUARIO
-- =============================================

-- Crear roles
CREATE ROLE rol_coordinador_academico;
CREATE ROLE rol_trainer;
CREATE ROLE rol_encargado_inscripciones;
CREATE ROLE rol_administrador_rutas;
CREATE ROLE rol_encargado_areas;

-- 1. Permisos para Coordinador Académico (Acceso total)
GRANT ALL PRIVILEGES ON campuslands_erp.* TO rol_coordinador_academico;
GRANT CREATE USER ON *.* TO rol_coordinador_academico;
GRANT GRANT OPTION ON campuslands_erp.* TO rol_coordinador_academico;

-- 2. Permisos para Trainer
GRANT SELECT ON campuslands_erp.campers TO rol_trainer;
GRANT SELECT ON campuslands_erp.inscripciones TO rol_trainer;
GRANT SELECT ON campuslands_erp.rutas TO rol_trainer;
GRANT SELECT ON campuslands_erp.modulos TO rol_trainer;
GRANT SELECT ON campuslands_erp.areas TO rol_trainer;
GRANT SELECT ON campuslands_erp.horarios TO rol_trainer;
GRANT SELECT ON campuslands_erp.asistencias TO rol_trainer;
GRANT SELECT ON campuslands_erp.evaluaciones TO rol_trainer;
GRANT SELECT ON campuslands_erp.tipos_evaluacion TO rol_trainer;
GRANT SELECT ON campuslands_erp.proyectos TO rol_trainer;
GRANT SELECT ON campuslands_erp.entregas_proyectos TO rol_trainer;
GRANT SELECT ON campuslands_erp.proyectos_grupales TO rol_trainer;
GRANT SELECT ON campuslands_erp.foros TO rol_trainer;
GRANT SELECT ON campuslands_erp.comentarios TO rol_trainer;
GRANT SELECT ON campuslands_erp.actividades TO rol_trainer;
GRANT SELECT ON campuslands_erp.entregas_actividades TO rol_trainer;
GRANT SELECT ON campuslands_erp.mentorias TO rol_trainer;
GRANT SELECT ON campuslands_erp.asistencia_mentorias TO rol_trainer;
GRANT SELECT ON campuslands_erp.soportes TO rol_trainer;
GRANT SELECT ON campuslands_erp.hackathons TO rol_trainer;
GRANT SELECT ON campuslands_erp.participaciones_hackathon TO rol_trainer;
GRANT SELECT ON campuslands_erp.workshops TO rol_trainer;
GRANT SELECT ON campuslands_erp.participaciones_workshop TO rol_trainer;
GRANT SELECT ON campuslands_erp.eventos_especiales TO rol_trainer;
GRANT SELECT ON campuslands_erp.participaciones_eventos TO rol_trainer;

GRANT INSERT, UPDATE ON campuslands_erp.evaluaciones TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.asistencias TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.entregas_proyectos TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.entregas_actividades TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.asistencia_mentorias TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.comentarios TO rol_trainer;
GRANT INSERT, UPDATE ON campuslands_erp.soportes TO rol_trainer;

-- 3. Permisos para Encargado de Inscripciones
GRANT SELECT ON campuslands_erp.campers TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.rutas TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.modulos TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.areas TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.horarios TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.inscripciones TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.asignaciones_areas TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.asignaciones_trainers TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.trainers TO rol_encargado_inscripciones;

GRANT INSERT, UPDATE ON campuslands_erp.campers TO rol_encargado_inscripciones;
GRANT INSERT, UPDATE ON campuslands_erp.inscripciones TO rol_encargado_inscripciones;
GRANT INSERT, UPDATE ON campuslands_erp.asignaciones_areas TO rol_encargado_inscripciones;
GRANT INSERT, UPDATE ON campuslands_erp.asignaciones_trainers TO rol_encargado_inscripciones;

-- 4. Permisos para Administrador de Rutas
GRANT SELECT ON campuslands_erp.rutas TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.modulos TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.evaluaciones TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.tipos_evaluacion TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.proyectos TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.proyectos_grupales TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.actividades TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.foros TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.inscripciones TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.trainers TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.asignaciones_trainers TO rol_administrador_rutas;

GRANT INSERT, UPDATE ON campuslands_erp.rutas TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.modulos TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.evaluaciones TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.tipos_evaluacion TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.proyectos TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.proyectos_grupales TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.actividades TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.foros TO rol_administrador_rutas;
GRANT INSERT, UPDATE ON campuslands_erp.asignaciones_trainers TO rol_administrador_rutas;

-- 5. Permisos para Encargado de Áreas
GRANT SELECT ON campuslands_erp.areas TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.horarios TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.asignaciones_areas TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.inscripciones TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.campers TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.trainers TO rol_encargado_areas;
GRANT SELECT ON campuslands_erp.asignaciones_trainers TO rol_encargado_areas;

GRANT INSERT, UPDATE ON campuslands_erp.areas TO rol_encargado_areas;
GRANT INSERT, UPDATE ON campuslands_erp.horarios TO rol_encargado_areas;
GRANT INSERT, UPDATE ON campuslands_erp.asignaciones_areas TO rol_encargado_areas;

-- Crear vistas para proteger datos sensibles
CREATE VIEW v_campers_publica AS
SELECT 
    id,
    nombre,
    apellido,
    email,
    ciudad,
    estado,
    fecha_nacimiento
FROM campers;

CREATE VIEW v_trainers_publica AS
SELECT 
    id,
    nombre,
    apellido,
    email,
    especialidad,
    estado
FROM trainers;

-- Asignar permisos a las vistas
GRANT SELECT ON campuslands_erp.v_campers_publica TO rol_trainer;
GRANT SELECT ON campuslands_erp.v_campers_publica TO rol_administrador_rutas;
GRANT SELECT ON campuslands_erp.v_trainers_publica TO rol_encargado_inscripciones;
GRANT SELECT ON campuslands_erp.v_trainers_publica TO rol_encargado_areas;

-- Crear procedimientos almacenados para operaciones seguras
DELIMITER //

-- Procedimiento para registrar nuevo camper
CREATE PROCEDURE sp_registrar_camper(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_ciudad VARCHAR(100),
    IN p_estado VARCHAR(50),
    IN p_fecha_nacimiento DATE,
    IN p_documento VARCHAR(20),
    IN p_telefono VARCHAR(20),
    IN p_direccion TEXT
)
BEGIN
    -- Validar datos
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email no válido';
    END IF;
    
    -- Insertar camper
    INSERT INTO campers (
        nombre, apellido, email, ciudad, estado,
        fecha_nacimiento, documento, telefono, direccion
    )
    VALUES (
        p_nombre, p_apellido, p_email, p_ciudad, p_estado,
        p_fecha_nacimiento, p_documento, p_telefono, p_direccion
    );
END //

-- Procedimiento para actualizar datos de camper
CREATE PROCEDURE sp_actualizar_camper(
    IN p_id INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_ciudad VARCHAR(100),
    IN p_estado VARCHAR(50),
    IN p_telefono VARCHAR(20),
    IN p_direccion TEXT
)
BEGIN
    -- Validar datos
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email no válido';
    END IF;
    
    -- Actualizar camper
    UPDATE campers
    SET 
        nombre = p_nombre,
        apellido = p_apellido,
        email = p_email,
        ciudad = p_ciudad,
        estado = p_estado,
        telefono = p_telefono,
        direccion = p_direccion
    WHERE id = p_id;
END //

DELIMITER ;

-- Asignar permisos a los procedimientos
GRANT EXECUTE ON PROCEDURE campuslands_erp.sp_registrar_camper TO rol_encargado_inscripciones;
GRANT EXECUTE ON PROCEDURE campuslands_erp.sp_actualizar_camper TO rol_encargado_inscripciones;

-- Crear políticas de seguridad
CREATE POLICY pol_campers ON campers
    FOR ALL
    USING (
        CASE
            WHEN CURRENT_USER() LIKE 'rol_coordinador_academico%' THEN TRUE
            WHEN CURRENT_USER() LIKE 'rol_encargado_inscripciones%' THEN TRUE
            WHEN CURRENT_USER() LIKE 'rol_trainer%' THEN 
                EXISTS (
                    SELECT 1 FROM inscripciones i
                    JOIN asignaciones_trainers at ON i.ruta_id = at.ruta_id
                    WHERE i.camper_id = campers.id
                    AND at.trainer_id = SUBSTRING_INDEX(CURRENT_USER(), '@', 1)
                )
            ELSE FALSE
        END
    );

CREATE POLICY pol_evaluaciones ON evaluaciones
    FOR ALL
    USING (
        CASE
            WHEN CURRENT_USER() LIKE 'rol_coordinador_academico%' THEN TRUE
            WHEN CURRENT_USER() LIKE 'rol_trainer%' THEN 
                EXISTS (
                    SELECT 1 FROM inscripciones i
                    JOIN asignaciones_trainers at ON i.ruta_id = at.ruta_id
                    WHERE i.id = evaluaciones.inscripcion_id
                    AND at.trainer_id = SUBSTRING_INDEX(CURRENT_USER(), '@', 1)
                )
            ELSE FALSE
        END
    );

-- Crear índices para mejorar rendimiento
CREATE INDEX idx_campers_email ON campers(email);
CREATE INDEX idx_inscripciones_estado ON inscripciones(estado);
CREATE INDEX idx_evaluaciones_inscripcion ON evaluaciones(inscripcion_id);
CREATE INDEX idx_asistencias_fecha ON asistencias(fecha);
CREATE INDEX idx_proyectos_estado ON proyectos(estado); 