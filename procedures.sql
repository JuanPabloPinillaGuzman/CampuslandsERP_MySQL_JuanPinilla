-- =============================================
-- PROCEDIMIENTOS ALMACENADOS PARA GESTIÓN DE INSCRIPCIONES
-- =============================================

DELIMITER //

-- 1. Procedimiento para procesar inscripciones y actualizar estado del camper
CREATE PROCEDURE sp_procesar_inscripcion(
    IN p_camper_id INT,
    IN p_ruta_id INT,
    IN p_fecha_inscripcion DATE,
    IN p_estado VARCHAR(20)
)
BEGIN
    DECLARE v_cupo_disponible INT;
    DECLARE v_existe_camper BOOLEAN;
    DECLARE v_existe_ruta BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del camper y la ruta
    SELECT EXISTS(SELECT 1 FROM campers WHERE id = p_camper_id) INTO v_existe_camper;
    SELECT EXISTS(SELECT 1 FROM rutas WHERE id = p_ruta_id) INTO v_existe_ruta;
    
    IF NOT v_existe_camper THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El camper no existe';
    END IF;
    
    IF NOT v_existe_ruta THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La ruta no existe';
    END IF;
    
    -- Verificar cupo disponible en la ruta
    SELECT cupo_maximo - COUNT(*) INTO v_cupo_disponible
    FROM rutas r
    LEFT JOIN inscripciones i ON r.id = i.ruta_id
    WHERE r.id = p_ruta_id
    GROUP BY r.id;
    
    IF v_cupo_disponible > 0 THEN
        -- Insertar nueva inscripción
        INSERT INTO inscripciones (camper_id, ruta_id, fecha_inscripcion, estado)
        VALUES (p_camper_id, p_ruta_id, p_fecha_inscripcion, p_estado);
        
        -- Actualizar estado del camper
        UPDATE campers 
        SET estado = 'Inscrito'
        WHERE id = p_camper_id;
        
        -- Confirmar transacción
        COMMIT;
        
        SELECT 'Inscripción procesada exitosamente' as mensaje;
    ELSE
        -- Revertir transacción
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay cupos disponibles en la ruta seleccionada';
    END IF;
END //

-- 2. Procedimiento para registrar evaluaciones y calcular notas finales
CREATE PROCEDURE sp_registrar_evaluacion(
    IN p_inscripcion_id INT,
    IN p_modulo_id INT,
    IN p_tipo_evaluacion_id INT,
    IN p_nota DECIMAL(5,2),
    IN p_fecha_evaluacion DATE
)
BEGIN
    DECLARE v_nota_final DECIMAL(5,2);
    DECLARE v_porcentaje DECIMAL(5,2);
    DECLARE v_existe_inscripcion BOOLEAN;
    DECLARE v_existe_modulo BOOLEAN;
    DECLARE v_existe_tipo_evaluacion BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de registros
    SELECT EXISTS(SELECT 1 FROM inscripciones WHERE id = p_inscripcion_id) INTO v_existe_inscripcion;
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    SELECT EXISTS(SELECT 1 FROM tipos_evaluacion WHERE id = p_tipo_evaluacion_id) INTO v_existe_tipo_evaluacion;
    
    IF NOT v_existe_inscripcion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La inscripción no existe';
    END IF;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    IF NOT v_existe_tipo_evaluacion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tipo de evaluación no existe';
    END IF;
    
    -- Validar rango de nota
    IF p_nota < 0 OR p_nota > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La nota debe estar entre 0 y 100';
    END IF;
    
    -- Obtener porcentaje del tipo de evaluación
    SELECT porcentaje INTO v_porcentaje
    FROM tipos_evaluacion
    WHERE id = p_tipo_evaluacion_id;
    
    -- Insertar evaluación
    INSERT INTO evaluaciones (inscripcion_id, modulo_id, tipo_evaluacion_id, nota, fecha_evaluacion)
    VALUES (p_inscripcion_id, p_modulo_id, p_tipo_evaluacion_id, p_nota, p_fecha_evaluacion);
    
    -- Calcular nota final del módulo
    SELECT SUM(e.nota * te.porcentaje / 100) INTO v_nota_final
    FROM evaluaciones e
    JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
    WHERE e.inscripcion_id = p_inscripcion_id
    AND e.modulo_id = p_modulo_id;
    
    -- Actualizar nota final en la tabla de inscripciones
    UPDATE inscripciones
    SET nota_final = v_nota_final
    WHERE id = p_inscripcion_id;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Evaluación registrada exitosamente' as mensaje, v_nota_final as nota_final;
END //

-- 3. Procedimiento para asignar campers aprobados a rutas
CREATE PROCEDURE sp_asignar_campers_a_rutas()
BEGIN
    DECLARE v_camper_id INT;
    DECLARE v_ruta_id INT;
    DECLARE v_cupo_disponible INT;
    DECLARE v_existe_asignacion BOOLEAN;
    
    -- Cursor para procesar campers aprobados
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR 
        SELECT c.id, r.id
        FROM campers c
        JOIN inscripciones i ON c.id = i.camper_id
        JOIN rutas r ON i.ruta_id = r.id
        WHERE c.estado = 'Aprobado'
        AND i.estado = 'Activa';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_camper_id, v_ruta_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si ya existe una asignación activa
        SELECT EXISTS(
            SELECT 1 
            FROM inscripciones 
            WHERE camper_id = v_camper_id 
            AND estado = 'Activa'
        ) INTO v_existe_asignacion;
        
        IF NOT v_existe_asignacion THEN
            -- Verificar cupo disponible
            SELECT cupo_maximo - COUNT(*) INTO v_cupo_disponible
            FROM rutas r
            LEFT JOIN inscripciones i ON r.id = i.ruta_id
            WHERE r.id = v_ruta_id
            GROUP BY r.id;
            
            IF v_cupo_disponible > 0 THEN
                -- Asignar camper a la ruta
                INSERT INTO inscripciones (camper_id, ruta_id, fecha_inscripcion, estado)
                VALUES (v_camper_id, v_ruta_id, CURDATE(), 'Activa');
            END IF;
        END IF;
    END LOOP;
    
    CLOSE cur;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Proceso de asignación completado' as mensaje;
END //

-- 4. Procedimiento para registrar nuevas rutas y módulos
CREATE PROCEDURE sp_registrar_ruta_modulos(
    IN p_nombre_ruta VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_cupo_maximo INT,
    IN p_modulos JSON
)
BEGIN
    DECLARE v_ruta_id INT;
    DECLARE v_modulo JSON;
    DECLARE v_modulo_count INT;
    DECLARE v_index INT DEFAULT 0;
    DECLARE v_existe_ruta BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar que no exista una ruta con el mismo nombre
    SELECT EXISTS(
        SELECT 1 
        FROM rutas 
        WHERE nombre = p_nombre_ruta
    ) INTO v_existe_ruta;
    
    IF v_existe_ruta THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe una ruta con este nombre';
    END IF;
    
    -- Validar cupo máximo
    IF p_cupo_maximo <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cupo máximo debe ser mayor a 0';
    END IF;
    
    -- Insertar nueva ruta
    INSERT INTO rutas (nombre, descripcion, cupo_maximo)
    VALUES (p_nombre_ruta, p_descripcion, p_cupo_maximo);
    
    SET v_ruta_id = LAST_INSERT_ID();
    
    -- Obtener cantidad de módulos
    SET v_modulo_count = JSON_LENGTH(p_modulos);
    
    -- Procesar cada módulo
    WHILE v_index < v_modulo_count DO
        SET v_modulo = JSON_EXTRACT(p_modulos, CONCAT('$[', v_index, ']'));
        
        -- Validar campos requeridos del módulo
        IF JSON_EXTRACT(v_modulo, '$.nombre') IS NULL OR
           JSON_EXTRACT(v_modulo, '$.orden') IS NULL OR
           JSON_EXTRACT(v_modulo, '$.categoria_id') IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Todos los módulos deben tener nombre, orden y categoría';
        END IF;
        
        INSERT INTO modulos (
            nombre, 
            descripcion, 
            ruta_id, 
            orden,
            categoria_id
        )
        VALUES (
            JSON_UNQUOTE(JSON_EXTRACT(v_modulo, '$.nombre')),
            JSON_UNQUOTE(JSON_EXTRACT(v_modulo, '$.descripcion')),
            v_ruta_id,
            JSON_EXTRACT(v_modulo, '$.orden'),
            JSON_EXTRACT(v_modulo, '$.categoria_id')
        );
        
        SET v_index = v_index + 1;
    END WHILE;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Ruta y módulos registrados exitosamente' as mensaje, v_ruta_id as ruta_id;
END //

-- 5. Procedimiento para actualizar estado de inscripción
CREATE PROCEDURE sp_actualizar_estado_inscripcion(
    IN p_inscripcion_id INT,
    IN p_nuevo_estado VARCHAR(20)
)
BEGIN
    DECLARE v_existe_inscripcion BOOLEAN;
    DECLARE v_estado_actual VARCHAR(20);
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de la inscripción
    SELECT EXISTS(SELECT 1 FROM inscripciones WHERE id = p_inscripcion_id) INTO v_existe_inscripcion;
    
    IF NOT v_existe_inscripcion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La inscripción no existe';
    END IF;
    
    -- Obtener estado actual
    SELECT estado INTO v_estado_actual
    FROM inscripciones
    WHERE id = p_inscripcion_id;
    
    -- Validar transición de estado
    IF v_estado_actual = 'Cancelada' AND p_nuevo_estado != 'Cancelada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede reactivar una inscripción cancelada';
    END IF;
    
    -- Actualizar estado
    UPDATE inscripciones
    SET estado = p_nuevo_estado,
        fecha_actualizacion = CURDATE()
    WHERE id = p_inscripcion_id;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Estado de inscripción actualizado exitosamente' as mensaje;
END //

-- 6. Procedimiento para registrar asistencia masiva
CREATE PROCEDURE sp_registrar_asistencia_masiva(
    IN p_fecha DATE,
    IN p_inscripciones JSON
)
BEGIN
    DECLARE v_inscripcion JSON;
    DECLARE v_inscripcion_count INT;
    DECLARE v_index INT DEFAULT 0;
    DECLARE v_existe_inscripcion BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    SET v_inscripcion_count = JSON_LENGTH(p_inscripciones);
    
    WHILE v_index < v_inscripcion_count DO
        SET v_inscripcion = JSON_EXTRACT(p_inscripciones, CONCAT('$[', v_index, ']'));
        
        -- Validar existencia de la inscripción
        SELECT EXISTS(
            SELECT 1 
            FROM inscripciones 
            WHERE id = JSON_EXTRACT(v_inscripcion, '$.inscripcion_id')
        ) INTO v_existe_inscripcion;
        
        IF NOT v_existe_inscripcion THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('La inscripción ', JSON_EXTRACT(v_inscripcion, '$.inscripcion_id'), ' no existe');
        END IF;
        
        -- Validar estado de asistencia
        IF JSON_UNQUOTE(JSON_EXTRACT(v_inscripcion, '$.estado')) NOT IN ('Presente', 'Ausente', 'Justificada') THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El estado de asistencia debe ser Presente, Ausente o Justificada';
        END IF;
        
        INSERT INTO asistencias (
            inscripcion_id,
            fecha,
            estado,
            observaciones
        )
        VALUES (
            JSON_EXTRACT(v_inscripcion, '$.inscripcion_id'),
            p_fecha,
            JSON_UNQUOTE(JSON_EXTRACT(v_inscripcion, '$.estado')),
            JSON_UNQUOTE(JSON_EXTRACT(v_inscripcion, '$.observaciones'))
        );
        
        SET v_index = v_index + 1;
    END WHILE;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Asistencias registradas exitosamente' as mensaje;
END //

-- 7. Procedimiento para procesar justificaciones
CREATE PROCEDURE sp_procesar_justificacion(
    IN p_asistencia_id INT,
    IN p_motivo TEXT,
    IN p_estado VARCHAR(20)
)
BEGIN
    DECLARE v_existe_asistencia BOOLEAN;
    DECLARE v_estado_asistencia VARCHAR(20);
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de la asistencia
    SELECT EXISTS(SELECT 1 FROM asistencias WHERE id = p_asistencia_id) INTO v_existe_asistencia;
    
    IF NOT v_existe_asistencia THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La asistencia no existe';
    END IF;
    
    -- Obtener estado actual de la asistencia
    SELECT estado INTO v_estado_asistencia
    FROM asistencias
    WHERE id = p_asistencia_id;
    
    -- Validar que la asistencia no esté ya justificada
    IF v_estado_asistencia = 'Justificada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La asistencia ya está justificada';
    END IF;
    
    -- Validar estado de la justificación
    IF p_estado NOT IN ('Aprobada', 'Rechazada') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estado de la justificación debe ser Aprobada o Rechazada';
    END IF;
    
    INSERT INTO justificaciones (
        asistencia_id,
        motivo,
        fecha_justificacion,
        estado
    )
    VALUES (
        p_asistencia_id,
        p_motivo,
        CURDATE(),
        p_estado
    );
    
    IF p_estado = 'Aprobada' THEN
        UPDATE asistencias
        SET estado = 'Justificada'
        WHERE id = p_asistencia_id;
    END IF;
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Justificación procesada exitosamente' as mensaje;
END //

-- 8. Procedimiento para registrar proyectos
CREATE PROCEDURE sp_registrar_proyecto(
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_modulo_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_existe_modulo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del módulo
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    INSERT INTO proyectos (
        nombre,
        descripcion,
        modulo_id,
        fecha_inicio,
        fecha_fin
    )
    VALUES (
        p_nombre,
        p_descripcion,
        p_modulo_id,
        p_fecha_inicio,
        p_fecha_fin
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Proyecto registrado exitosamente' as mensaje;
END //

-- 9. Procedimiento para registrar entregas de proyectos
CREATE PROCEDURE sp_registrar_entrega_proyecto(
    IN p_proyecto_id INT,
    IN p_inscripcion_id INT,
    IN p_fecha_entrega DATE,
    IN p_estado VARCHAR(20)
)
BEGIN
    DECLARE v_existe_proyecto BOOLEAN;
    DECLARE v_existe_inscripcion BOOLEAN;
    DECLARE v_fecha_fin DATE;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de registros
    SELECT EXISTS(SELECT 1 FROM proyectos WHERE id = p_proyecto_id) INTO v_existe_proyecto;
    SELECT EXISTS(SELECT 1 FROM inscripciones WHERE id = p_inscripcion_id) INTO v_existe_inscripcion;
    
    IF NOT v_existe_proyecto THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El proyecto no existe';
    END IF;
    
    IF NOT v_existe_inscripcion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La inscripción no existe';
    END IF;
    
    -- Obtener fecha fin del proyecto
    SELECT fecha_fin INTO v_fecha_fin
    FROM proyectos
    WHERE id = p_proyecto_id;
    
    -- Validar fecha de entrega
    IF p_fecha_entrega > v_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de entrega no puede ser posterior a la fecha de fin del proyecto';
    END IF;
    
    -- Validar estado
    IF p_estado NOT IN ('Entregado', 'En revisión', 'Aprobado', 'Rechazado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estado debe ser Entregado, En revisión, Aprobado o Rechazado';
    END IF;
    
    INSERT INTO entregas_proyectos (
        proyecto_id,
        inscripcion_id,
        fecha_entrega,
        estado
    )
    VALUES (
        p_proyecto_id,
        p_inscripcion_id,
        p_fecha_entrega,
        p_estado
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Entrega de proyecto registrada exitosamente' as mensaje;
END //

-- 10. Procedimiento para asignar trainers a rutas
CREATE PROCEDURE sp_asignar_trainer_ruta(
    IN p_trainer_id INT,
    IN p_ruta_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_existe_trainer BOOLEAN;
    DECLARE v_existe_ruta BOOLEAN;
    DECLARE v_asignacion_activa BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de registros
    SELECT EXISTS(SELECT 1 FROM trainers WHERE id = p_trainer_id) INTO v_existe_trainer;
    SELECT EXISTS(SELECT 1 FROM rutas WHERE id = p_ruta_id) INTO v_existe_ruta;
    
    IF NOT v_existe_trainer THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El trainer no existe';
    END IF;
    
    IF NOT v_existe_ruta THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La ruta no existe';
    END IF;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    -- Verificar si el trainer ya tiene una asignación activa en la misma ruta
    SELECT EXISTS(
        SELECT 1 
        FROM asignaciones_trainers 
        WHERE trainer_id = p_trainer_id 
        AND ruta_id = p_ruta_id
        AND estado = 'Activa'
    ) INTO v_asignacion_activa;
    
    IF v_asignacion_activa THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El trainer ya tiene una asignación activa en esta ruta';
    END IF;
    
    INSERT INTO asignaciones_trainers (
        trainer_id,
        ruta_id,
        fecha_inicio,
        fecha_fin,
        estado
    )
    VALUES (
        p_trainer_id,
        p_ruta_id,
        p_fecha_inicio,
        p_fecha_fin,
        'Activa'
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Trainer asignado exitosamente' as mensaje;
END //

-- 11. Procedimiento para registrar recursos de módulo
CREATE PROCEDURE sp_registrar_recurso_modulo(
    IN p_modulo_id INT,
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_tipo_recurso VARCHAR(50),
    IN p_url VARCHAR(255)
)
BEGIN
    DECLARE v_existe_modulo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del módulo
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    -- Validar tipo de recurso
    IF p_tipo_recurso NOT IN ('Video', 'Documento', 'Enlace', 'Imagen', 'Otro') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tipo de recurso debe ser Video, Documento, Enlace, Imagen u Otro';
    END IF;
    
    -- Validar URL
    IF p_url IS NOT NULL AND p_url NOT REGEXP '^https?://' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La URL debe comenzar con http:// o https://';
    END IF;
    
    INSERT INTO recursos_modulo (
        modulo_id,
        nombre,
        descripcion,
        tipo_recurso,
        url
    )
    VALUES (
        p_modulo_id,
        p_nombre,
        p_descripcion,
        p_tipo_recurso,
        p_url
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Recurso registrado exitosamente' as mensaje;
END //

-- 12. Procedimiento para registrar foros
CREATE PROCEDURE sp_registrar_foro(
    IN p_modulo_id INT,
    IN p_titulo VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_existe_modulo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del módulo
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    INSERT INTO foros (
        modulo_id,
        titulo,
        descripcion,
        fecha_inicio,
        fecha_fin
    )
    VALUES (
        p_modulo_id,
        p_titulo,
        p_descripcion,
        p_fecha_inicio,
        p_fecha_fin
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Foro registrado exitosamente' as mensaje;
END //

-- 13. Procedimiento para registrar comentarios
CREATE PROCEDURE sp_registrar_comentario(
    IN p_foro_id INT,
    IN p_camper_id INT,
    IN p_contenido TEXT,
    IN p_fecha_comentario DATETIME
)
BEGIN
    DECLARE v_existe_foro BOOLEAN;
    DECLARE v_existe_camper BOOLEAN;
    DECLARE v_foro_activo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de registros
    SELECT EXISTS(SELECT 1 FROM foros WHERE id = p_foro_id) INTO v_existe_foro;
    SELECT EXISTS(SELECT 1 FROM campers WHERE id = p_camper_id) INTO v_existe_camper;
    
    IF NOT v_existe_foro THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El foro no existe';
    END IF;
    
    IF NOT v_existe_camper THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El camper no existe';
    END IF;
    
    -- Verificar si el foro está activo
    SELECT EXISTS(
        SELECT 1 
        FROM foros 
        WHERE id = p_foro_id 
        AND fecha_inicio <= CURDATE() 
        AND fecha_fin >= CURDATE()
    ) INTO v_foro_activo;
    
    IF NOT v_foro_activo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El foro no está activo en este momento';
    END IF;
    
    INSERT INTO comentarios (
        foro_id,
        camper_id,
        contenido,
        fecha_comentario
    )
    VALUES (
        p_foro_id,
        p_camper_id,
        p_contenido,
        p_fecha_comentario
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Comentario registrado exitosamente' as mensaje;
END //

-- 14. Procedimiento para registrar soportes
CREATE PROCEDURE sp_registrar_soporte(
    IN p_inscripcion_id INT,
    IN p_tipo_soporte VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_estado VARCHAR(20)
)
BEGIN
    DECLARE v_existe_inscripcion BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de la inscripción
    SELECT EXISTS(SELECT 1 FROM inscripciones WHERE id = p_inscripcion_id) INTO v_existe_inscripcion;
    
    IF NOT v_existe_inscripcion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La inscripción no existe';
    END IF;
    
    -- Validar tipo de soporte
    IF p_tipo_soporte NOT IN ('Técnico', 'Académico', 'Administrativo', 'Otro') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tipo de soporte debe ser Técnico, Académico, Administrativo u Otro';
    END IF;
    
    -- Validar estado
    IF p_estado NOT IN ('Pendiente', 'En proceso', 'Resuelto', 'Cerrado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estado debe ser Pendiente, En proceso, Resuelto o Cerrado';
    END IF;
    
    INSERT INTO soportes (
        inscripcion_id,
        tipo_soporte,
        descripcion,
        fecha_solicitud,
        estado
    )
    VALUES (
        p_inscripcion_id,
        p_tipo_soporte,
        p_descripcion,
        CURDATE(),
        p_estado
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Soporte registrado exitosamente' as mensaje;
END //

-- 15. Procedimiento para registrar actividades
CREATE PROCEDURE sp_registrar_actividad(
    IN p_modulo_id INT,
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_existe_modulo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del módulo
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    INSERT INTO actividades (
        modulo_id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin
    )
    VALUES (
        p_modulo_id,
        p_nombre,
        p_descripcion,
        p_fecha_inicio,
        p_fecha_fin
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Actividad registrada exitosamente' as mensaje;
END //

-- 16. Procedimiento para registrar proyectos grupales
CREATE PROCEDURE sp_registrar_proyecto_grupal(
    IN p_modulo_id INT,
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_cantidad_maxima INT
)
BEGIN
    DECLARE v_existe_modulo BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia del módulo
    SELECT EXISTS(SELECT 1 FROM modulos WHERE id = p_modulo_id) INTO v_existe_modulo;
    
    IF NOT v_existe_modulo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El módulo no existe';
    END IF;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    -- Validar cantidad máxima
    IF p_cantidad_maxima < 2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad máxima de integrantes debe ser al menos 2';
    END IF;
    
    INSERT INTO proyectos_grupales (
        modulo_id,
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        cantidad_maxima
    )
    VALUES (
        p_modulo_id,
        p_nombre,
        p_descripcion,
        p_fecha_inicio,
        p_fecha_fin,
        p_cantidad_maxima
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Proyecto grupal registrado exitosamente' as mensaje;
END //

-- 17. Procedimiento para registrar hackathons
CREATE PROCEDURE sp_registrar_hackathon(
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_premio TEXT
)
BEGIN
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar fechas
    IF p_fecha_inicio > p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser posterior a la fecha de fin';
    END IF;
    
    -- Validar duración mínima (24 horas)
    IF DATEDIFF(p_fecha_fin, p_fecha_inicio) < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La duración mínima del hackathon debe ser de 24 horas';
    END IF;
    
    INSERT INTO hackathons (
        nombre,
        descripcion,
        fecha_inicio,
        fecha_fin,
        premio
    )
    VALUES (
        p_nombre,
        p_descripcion,
        p_fecha_inicio,
        p_fecha_fin,
        p_premio
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Hackathon registrado exitosamente' as mensaje;
END //

-- 18. Procedimiento para registrar workshops
CREATE PROCEDURE sp_registrar_workshop(
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha DATE,
    IN p_cupo_maximo INT
)
BEGIN
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar fecha
    IF p_fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha del workshop no puede ser anterior a la fecha actual';
    END IF;
    
    -- Validar cupo máximo
    IF p_cupo_maximo <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cupo máximo debe ser mayor a 0';
    END IF;
    
    INSERT INTO workshops (
        nombre,
        descripcion,
        fecha,
        cupo_maximo
    )
    VALUES (
        p_nombre,
        p_descripcion,
        p_fecha,
        p_cupo_maximo
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Workshop registrado exitosamente' as mensaje;
END //

-- 19. Procedimiento para registrar mentorías
CREATE PROCEDURE sp_registrar_mentoria(
    IN p_trainer_id INT,
    IN p_inscripcion_id INT,
    IN p_fecha DATE,
    IN p_hora TIME,
    IN p_duracion INT
)
BEGIN
    DECLARE v_existe_trainer BOOLEAN;
    DECLARE v_existe_inscripcion BOOLEAN;
    DECLARE v_hora_fin TIME;
    DECLARE v_solapamiento BOOLEAN;
    
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar existencia de registros
    SELECT EXISTS(SELECT 1 FROM trainers WHERE id = p_trainer_id) INTO v_existe_trainer;
    SELECT EXISTS(SELECT 1 FROM inscripciones WHERE id = p_inscripcion_id) INTO v_existe_inscripcion;
    
    IF NOT v_existe_trainer THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El trainer no existe';
    END IF;
    
    IF NOT v_existe_inscripcion THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La inscripción no existe';
    END IF;
    
    -- Validar fecha
    IF p_fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de la mentoría no puede ser anterior a la fecha actual';
    END IF;
    
    -- Validar duración
    IF p_duracion < 30 OR p_duracion > 120 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La duración debe estar entre 30 y 120 minutos';
    END IF;
    
    -- Calcular hora de fin
    SET v_hora_fin = ADDTIME(p_hora, SEC_TO_TIME(p_duracion * 60));
    
    -- Verificar solapamiento con otras mentorías del trainer
    SELECT EXISTS(
        SELECT 1 
        FROM mentorias 
        WHERE trainer_id = p_trainer_id 
        AND fecha = p_fecha
        AND (
            (p_hora BETWEEN hora AND ADDTIME(hora, SEC_TO_TIME(duracion * 60)))
            OR (v_hora_fin BETWEEN hora AND ADDTIME(hora, SEC_TO_TIME(duracion * 60)))
        )
    ) INTO v_solapamiento;
    
    IF v_solapamiento THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Existe un solapamiento con otra mentoría del trainer';
    END IF;
    
    INSERT INTO mentorias (
        trainer_id,
        inscripcion_id,
        fecha,
        hora,
        duracion
    )
    VALUES (
        p_trainer_id,
        p_inscripcion_id,
        p_fecha,
        p_hora,
        p_duracion
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Mentoría registrada exitosamente' as mensaje;
END //

-- 20. Procedimiento para registrar eventos especiales
CREATE PROCEDURE sp_registrar_evento_especial(
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_fecha DATE,
    IN p_tipo_evento VARCHAR(50),
    IN p_cupo_maximo INT
)
BEGIN
    -- Iniciar transacción
    START TRANSACTION;
    
    -- Validar fecha
    IF p_fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha del evento no puede ser anterior a la fecha actual';
    END IF;
    
    -- Validar tipo de evento
    IF p_tipo_evento NOT IN ('Conferencia', 'Taller', 'Networking', 'Presentación', 'Otro') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tipo de evento debe ser Conferencia, Taller, Networking, Presentación u Otro';
    END IF;
    
    -- Validar cupo máximo
    IF p_cupo_maximo <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cupo máximo debe ser mayor a 0';
    END IF;
    
    INSERT INTO eventos_especiales (
        nombre,
        descripcion,
        fecha,
        tipo_evento,
        cupo_maximo
    )
    VALUES (
        p_nombre,
        p_descripcion,
        p_fecha,
        p_tipo_evento,
        p_cupo_maximo
    );
    
    -- Confirmar transacción
    COMMIT;
    
    SELECT 'Evento especial registrado exitosamente' as mensaje;
END //

DELIMITER ; 