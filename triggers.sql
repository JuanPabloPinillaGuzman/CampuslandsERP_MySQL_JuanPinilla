-- =============================================
-- TRIGGERS SQL PARA AUTOMATIZACIÓN DE RESPUESTAS
-- =============================================

DELIMITER //

-- 1. Trigger para actualizar estado de camper al aprobar evaluación
CREATE TRIGGER trg_actualizar_estado_camper
AFTER INSERT ON evaluaciones
FOR EACH ROW
BEGIN
    DECLARE v_promedio DECIMAL(5,2);
    
    -- Calcular promedio ponderado
    SELECT fn_calcular_promedio_ponderado(NEW.inscripcion_id, NEW.modulo_id)
    INTO v_promedio;
    
    -- Actualizar estado si aprueba
    IF v_promedio >= 70 THEN
        UPDATE inscripciones
        SET estado = 'Aprobado'
        WHERE id = NEW.inscripcion_id;
    END IF;
END //

-- 2. Trigger para registrar cambios en asignaciones de trainers
CREATE TRIGGER trg_registrar_cambios_trainer
AFTER UPDATE ON asignaciones_trainers
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_trainer (
        trainer_id,
        ruta_id,
        fecha_cambio,
        cambio_realizado,
        estado_anterior,
        estado_nuevo
    )
    VALUES (
        NEW.trainer_id,
        NEW.ruta_id,
        NOW(),
        'Actualización de asignación',
        OLD.estado,
        NEW.estado
    );
END //

-- 3. Trigger para validar capacidad de áreas
CREATE TRIGGER trg_validar_capacidad_area
BEFORE INSERT ON asignaciones_areas
FOR EACH ROW
BEGIN
    DECLARE v_cupo_disponible INT;
    
    -- Verificar cupo disponible
    SELECT fn_verificar_capacidad_area(NEW.area_id)
    INTO v_cupo_disponible;
    
    -- Validar capacidad
    IF v_cupo_disponible <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El área ha alcanzado su capacidad máxima';
    END IF;
END //

-- 4. Trigger para actualizar estado de inscripción al completar módulo
CREATE TRIGGER trg_actualizar_estado_inscripcion
AFTER UPDATE ON inscripciones
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Aprobado' AND OLD.estado = 'Activa' THEN
        INSERT INTO historial_estados_inscripcion (
            inscripcion_id,
            estado_anterior,
            estado_nuevo,
            fecha_cambio
        )
        VALUES (
            NEW.id,
            OLD.estado,
            NEW.estado,
            NOW()
        );
    END IF;
END //

-- 5. Trigger para validar fechas de proyectos
CREATE TRIGGER trg_validar_fechas_proyecto
BEFORE INSERT ON proyectos
FOR EACH ROW
BEGIN
    IF NEW.fecha_inicio > NEW.fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
END //

-- 6. Trigger para registrar cambios en horarios
CREATE TRIGGER trg_registrar_cambios_horario
AFTER UPDATE ON horarios
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_horario (
        horario_id,
        fecha_cambio,
        hora_inicio_anterior,
        hora_inicio_nueva,
        hora_fin_anterior,
        hora_fin_nueva
    )
    VALUES (
        NEW.id,
        NOW(),
        OLD.hora_inicio,
        NEW.hora_inicio,
        OLD.hora_fin,
        NEW.hora_fin
    );
END //

-- 7. Trigger para validar notas de evaluación
CREATE TRIGGER trg_validar_nota_evaluacion
BEFORE INSERT ON evaluaciones
FOR EACH ROW
BEGIN
    IF NEW.nota < 0 OR NEW.nota > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La nota debe estar entre 0 y 100';
    END IF;
END //

-- 8. Trigger para actualizar estado de mentoría
CREATE TRIGGER trg_actualizar_estado_mentoria
AFTER INSERT ON asistencia_mentorias
FOR EACH ROW
BEGIN
    UPDATE mentorias
    SET estado = 'Completada'
    WHERE id = NEW.mentoria_id;
END //

-- 9. Trigger para validar fechas de inscripción
CREATE TRIGGER trg_validar_fechas_inscripcion
BEFORE INSERT ON inscripciones
FOR EACH ROW
BEGIN
    IF NEW.fecha_inicio > NEW.fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
END //

-- 10. Trigger para registrar cambios en módulos
CREATE TRIGGER trg_registrar_cambios_modulo
AFTER UPDATE ON modulos
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_modulo (
        modulo_id,
        fecha_cambio,
        nombre_anterior,
        nombre_nuevo,
        descripcion_anterior,
        descripcion_nueva
    )
    VALUES (
        NEW.id,
        NOW(),
        OLD.nombre,
        NEW.nombre,
        OLD.descripcion,
        NEW.descripcion
    );
END //

-- 11. Trigger para validar capacidad de rutas
CREATE TRIGGER trg_validar_capacidad_ruta
BEFORE INSERT ON inscripciones
FOR EACH ROW
BEGIN
    DECLARE v_cupo_actual INT;
    
    -- Contar inscripciones activas
    SELECT COUNT(*) INTO v_cupo_actual
    FROM inscripciones
    WHERE ruta_id = NEW.ruta_id
    AND estado = 'Activa';
    
    -- Validar capacidad
    IF v_cupo_actual >= (
        SELECT cupo_maximo FROM rutas WHERE id = NEW.ruta_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La ruta ha alcanzado su capacidad máxima';
    END IF;
END //

-- 12. Trigger para actualizar estado de soporte
CREATE TRIGGER trg_actualizar_estado_soporte
AFTER UPDATE ON soportes
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Resuelto' AND OLD.estado = 'Pendiente' THEN
        INSERT INTO historial_soportes (
            soporte_id,
            estado_anterior,
            estado_nuevo,
            fecha_cambio
        )
        VALUES (
            NEW.id,
            OLD.estado,
            NEW.estado,
            NOW()
        );
    END IF;
END //

-- 13. Trigger para validar fechas de eventos
CREATE TRIGGER trg_validar_fechas_evento
BEFORE INSERT ON eventos_especiales
FOR EACH ROW
BEGIN
    IF NEW.fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha del evento no puede ser anterior a la fecha actual';
    END IF;
END //

-- 14. Trigger para registrar cambios en áreas
CREATE TRIGGER trg_registrar_cambios_area
AFTER UPDATE ON areas
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_area (
        area_id,
        fecha_cambio,
        nombre_anterior,
        nombre_nuevo,
        cupo_maximo_anterior,
        cupo_maximo_nuevo
    )
    VALUES (
        NEW.id,
        NOW(),
        OLD.nombre,
        NEW.nombre,
        OLD.cupo_maximo,
        NEW.cupo_maximo
    );
END //

-- 15. Trigger para validar estado de inscripción
CREATE TRIGGER trg_validar_estado_inscripcion
BEFORE UPDATE ON inscripciones
FOR EACH ROW
BEGIN
    IF NEW.estado NOT IN ('Activa', 'Aprobado', 'Reprobado', 'Vencida', 'Inactiva', 'Completada') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estado de inscripción no válido';
    END IF;
END //

-- 16. Trigger para registrar cambios en trainers
CREATE TRIGGER trg_registrar_cambios_trainer_info
AFTER UPDATE ON trainers
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_trainer_info (
        trainer_id,
        fecha_cambio,
        nombre_anterior,
        nombre_nuevo,
        email_anterior,
        email_nuevo
    )
    VALUES (
        NEW.id,
        NOW(),
        OLD.nombre,
        NEW.nombre,
        OLD.email,
        NEW.email
    );
END //

-- 17. Trigger para validar fechas de mentorías
CREATE TRIGGER trg_validar_fechas_mentoria
BEFORE INSERT ON mentorias
FOR EACH ROW
BEGIN
    IF NEW.fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de la mentoría no puede ser anterior a la fecha actual';
    END IF;
END //

-- 18. Trigger para actualizar estado de proyectos grupales
CREATE TRIGGER trg_actualizar_estado_proyecto_grupal
AFTER INSERT ON entregas_proyectos
FOR EACH ROW
BEGIN
    DECLARE v_total_entregas INT;
    DECLARE v_total_requeridas INT;
    
    -- Contar entregas realizadas
    SELECT COUNT(*) INTO v_total_entregas
    FROM entregas_proyectos
    WHERE proyecto_id = NEW.proyecto_id;
    
    -- Obtener total requerido
    SELECT COUNT(*) INTO v_total_requeridas
    FROM proyectos_grupales pg
    JOIN inscripciones i ON pg.modulo_id = i.modulo_id
    WHERE pg.id = NEW.proyecto_id;
    
    -- Actualizar estado si todas las entregas están completas
    IF v_total_entregas = v_total_requeridas THEN
        UPDATE proyectos_grupales
        SET estado = 'Completado'
        WHERE id = NEW.proyecto_id;
    END IF;
END //

-- 19. Trigger para validar fechas de hackathons
CREATE TRIGGER trg_validar_fechas_hackathon
BEFORE INSERT ON hackathons
FOR EACH ROW
BEGIN
    IF NEW.fecha_inicio > NEW.fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    IF NEW.fecha_inicio < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser anterior a la fecha actual';
    END IF;
END //

-- 20. Trigger para registrar cambios en rutas
CREATE TRIGGER trg_registrar_cambios_ruta
AFTER UPDATE ON rutas
FOR EACH ROW
BEGIN
    INSERT INTO historial_cambios_ruta (
        ruta_id,
        fecha_cambio,
        nombre_anterior,
        nombre_nuevo,
        cupo_maximo_anterior,
        cupo_maximo_nuevo
    )
    VALUES (
        NEW.id,
        NOW(),
        OLD.nombre,
        NEW.nombre,
        OLD.cupo_maximo,
        NEW.cupo_maximo
    );
END //

DELIMITER ; 