-- =============================================
-- FUNCIONES SQL PARA CÁLCULOS PERSONALIZADOS
-- =============================================

DELIMITER //

-- 1. Función para calcular el promedio ponderado de evaluaciones
CREATE FUNCTION fn_calcular_promedio_ponderado(
    p_inscripcion_id INT,
    p_modulo_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_promedio DECIMAL(5,2);
    
    SELECT COALESCE(SUM(e.nota * te.porcentaje / 100), 0) INTO v_promedio
    FROM evaluaciones e
    JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
    WHERE e.inscripcion_id = p_inscripcion_id
    AND e.modulo_id = p_modulo_id;
    
    RETURN v_promedio;
END //

-- 2. Función para determinar el nivel de riesgo del camper
CREATE FUNCTION fn_determinar_nivel_riesgo(
    p_camper_id INT
) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_promedio DECIMAL(5,2);
    DECLARE v_ausencias INT;
    DECLARE v_nivel_riesgo VARCHAR(20);
    
    -- Calcular promedio de evaluaciones
    SELECT COALESCE(AVG(e.nota), 0) INTO v_promedio
    FROM evaluaciones e
    JOIN inscripciones i ON e.inscripcion_id = i.id
    WHERE i.camper_id = p_camper_id;
    
    -- Contar ausencias no justificadas
    SELECT COUNT(*) INTO v_ausencias
    FROM asistencias a
    JOIN inscripciones i ON a.inscripcion_id = i.id
    WHERE i.camper_id = p_camper_id
    AND a.estado = 'Ausente';
    
    -- Determinar nivel de riesgo
    IF v_promedio < 60 OR v_ausencias > 3 THEN
        SET v_nivel_riesgo = 'Alto';
    ELSEIF v_promedio < 70 OR v_ausencias > 2 THEN
        SET v_nivel_riesgo = 'Medio';
    ELSE
        SET v_nivel_riesgo = 'Bajo';
    END IF;
    
    RETURN v_nivel_riesgo;
END //

-- 3. Función para verificar capacidad disponible en áreas
CREATE FUNCTION fn_verificar_capacidad_area(
    p_area_id INT
) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_cupo_maximo INT;
    DECLARE v_cupo_ocupado INT;
    DECLARE v_cupo_disponible INT;
    
    -- Obtener cupo máximo del área
    SELECT cupo_maximo INTO v_cupo_maximo
    FROM areas
    WHERE id = p_area_id;
    
    -- Calcular cupo ocupado
    SELECT COUNT(*) INTO v_cupo_ocupado
    FROM asignaciones_areas
    WHERE area_id = p_area_id
    AND estado = 'Activa';
    
    -- Calcular cupo disponible
    SET v_cupo_disponible = v_cupo_maximo - v_cupo_ocupado;
    
    RETURN v_cupo_disponible;
END //

-- 4. Función para calcular el porcentaje de aprobación de un módulo
CREATE FUNCTION fn_calcular_porcentaje_aprobacion(
    p_modulo_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_evaluaciones INT;
    DECLARE v_evaluaciones_aprobadas INT;
    DECLARE v_porcentaje DECIMAL(5,2);
    
    -- Contar total de evaluaciones
    SELECT COUNT(*) INTO v_total_evaluaciones
    FROM evaluaciones
    WHERE modulo_id = p_modulo_id;
    
    -- Contar evaluaciones aprobadas
    SELECT COUNT(*) INTO v_evaluaciones_aprobadas
    FROM evaluaciones
    WHERE modulo_id = p_modulo_id
    AND nota >= 70;
    
    -- Calcular porcentaje
    IF v_total_evaluaciones > 0 THEN
        SET v_porcentaje = (v_evaluaciones_aprobadas * 100.0) / v_total_evaluaciones;
    ELSE
        SET v_porcentaje = 0;
    END IF;
    
    RETURN v_porcentaje;
END //

-- 5. Función para calcular el tiempo promedio de respuesta a soportes
CREATE FUNCTION fn_calcular_tiempo_respuesta_soporte(
    p_tipo_soporte VARCHAR(50)
) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_tiempo_promedio INT;
    
    SELECT COALESCE(AVG(TIMESTAMPDIFF(HOUR, fecha_solicitud, fecha_resolucion)), 0)
    INTO v_tiempo_promedio
    FROM soportes
    WHERE tipo_soporte = p_tipo_soporte
    AND estado = 'Resuelto';
    
    RETURN v_tiempo_promedio;
END //

-- 6. Función para calcular el índice de participación en foros
CREATE FUNCTION fn_calcular_indice_participacion(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_foros INT;
    DECLARE v_foros_participados INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de foros activos
    SELECT COUNT(*) INTO v_total_foros
    FROM foros f
    JOIN inscripciones i ON f.modulo_id = i.modulo_id
    WHERE i.camper_id = p_camper_id
    AND f.fecha_inicio <= CURDATE()
    AND f.fecha_fin >= CURDATE();
    
    -- Contar foros con participación
    SELECT COUNT(DISTINCT f.id) INTO v_foros_participados
    FROM foros f
    JOIN inscripciones i ON f.modulo_id = i.modulo_id
    JOIN comentarios c ON f.id = c.foro_id
    WHERE i.camper_id = p_camper_id
    AND c.camper_id = p_camper_id;
    
    -- Calcular índice
    IF v_total_foros > 0 THEN
        SET v_indice = (v_foros_participados * 100.0) / v_total_foros;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 7. Función para calcular el rendimiento por ruta
CREATE FUNCTION fn_calcular_rendimiento_ruta(
    p_ruta_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_promedio_rendimiento DECIMAL(5,2);
    
    SELECT COALESCE(AVG(e.nota), 0) INTO v_promedio_rendimiento
    FROM evaluaciones e
    JOIN inscripciones i ON e.inscripcion_id = i.id
    WHERE i.ruta_id = p_ruta_id;
    
    RETURN v_promedio_rendimiento;
END //

-- 8. Función para calcular el índice de asistencia
CREATE FUNCTION fn_calcular_indice_asistencia(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_sesiones INT;
    DECLARE v_asistencias INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de sesiones
    SELECT COUNT(*) INTO v_total_sesiones
    FROM asistencias a
    JOIN inscripciones i ON a.inscripcion_id = i.id
    WHERE i.camper_id = p_camper_id;
    
    -- Contar asistencias y justificaciones
    SELECT COUNT(*) INTO v_asistencias
    FROM asistencias a
    JOIN inscripciones i ON a.inscripcion_id = i.id
    WHERE i.camper_id = p_camper_id
    AND a.estado IN ('Presente', 'Justificada');
    
    -- Calcular índice
    IF v_total_sesiones > 0 THEN
        SET v_indice = (v_asistencias * 100.0) / v_total_sesiones;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 9. Función para calcular el progreso del camper
CREATE FUNCTION fn_calcular_progreso_camper(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_modulos INT;
    DECLARE v_modulos_completados INT;
    DECLARE v_progreso DECIMAL(5,2);
    
    -- Contar total de módulos en la ruta
    SELECT COUNT(*) INTO v_total_modulos
    FROM modulos m
    JOIN inscripciones i ON m.ruta_id = i.ruta_id
    WHERE i.camper_id = p_camper_id;
    
    -- Contar módulos completados
    SELECT COUNT(DISTINCT m.id) INTO v_modulos_completados
    FROM modulos m
    JOIN inscripciones i ON m.ruta_id = i.ruta_id
    JOIN evaluaciones e ON m.id = e.modulo_id
    WHERE i.camper_id = p_camper_id
    AND e.nota >= 70;
    
    -- Calcular progreso
    IF v_total_modulos > 0 THEN
        SET v_progreso = (v_modulos_completados * 100.0) / v_total_modulos;
    ELSE
        SET v_progreso = 0;
    END IF;
    
    RETURN v_progreso;
END //

-- 10. Función para calcular el índice de satisfacción
CREATE FUNCTION fn_calcular_indice_satisfaccion(
    p_trainer_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_promedio_satisfaccion DECIMAL(5,2);
    
    SELECT COALESCE(AVG(e.nota), 0) INTO v_promedio_satisfaccion
    FROM evaluaciones e
    JOIN inscripciones i ON e.inscripcion_id = i.id
    JOIN asignaciones_trainers at ON i.ruta_id = at.ruta_id
    WHERE at.trainer_id = p_trainer_id
    AND at.estado = 'Activa';
    
    RETURN v_promedio_satisfaccion;
END //

-- 11. Función para calcular el tiempo promedio de entrega de proyectos
CREATE FUNCTION fn_calcular_tiempo_entrega_proyectos(
    p_modulo_id INT
) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_tiempo_promedio INT;
    
    SELECT COALESCE(AVG(TIMESTAMPDIFF(DAY, p.fecha_inicio, ep.fecha_entrega)), 0)
    INTO v_tiempo_promedio
    FROM proyectos p
    JOIN entregas_proyectos ep ON p.id = ep.proyecto_id
    WHERE p.modulo_id = p_modulo_id;
    
    RETURN v_tiempo_promedio;
END //

-- 12. Función para calcular el índice de participación en proyectos grupales
CREATE FUNCTION fn_calcular_participacion_proyectos(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_proyectos INT;
    DECLARE v_proyectos_participados INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de proyectos grupales
    SELECT COUNT(*) INTO v_total_proyectos
    FROM proyectos_grupales pg
    JOIN inscripciones i ON pg.modulo_id = i.modulo_id
    WHERE i.camper_id = p_camper_id;
    
    -- Contar proyectos con participación
    SELECT COUNT(DISTINCT pg.id) INTO v_proyectos_participados
    FROM proyectos_grupales pg
    JOIN inscripciones i ON pg.modulo_id = i.modulo_id
    JOIN entregas_proyectos ep ON pg.id = ep.proyecto_id
    WHERE i.camper_id = p_camper_id
    AND ep.inscripcion_id = i.id;
    
    -- Calcular índice
    IF v_total_proyectos > 0 THEN
        SET v_indice = (v_proyectos_participados * 100.0) / v_total_proyectos;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 13. Función para calcular el índice de retención por ruta
CREATE FUNCTION fn_calcular_indice_retencion(
    p_ruta_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_inscritos INT;
    DECLARE v_inscritos_activos INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de inscritos
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE ruta_id = p_ruta_id;
    
    -- Contar inscritos activos
    SELECT COUNT(*) INTO v_inscritos_activos
    FROM inscripciones
    WHERE ruta_id = p_ruta_id
    AND estado = 'Activa';
    
    -- Calcular índice
    IF v_total_inscritos > 0 THEN
        SET v_indice = (v_inscritos_activos * 100.0) / v_total_inscritos;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 14. Función para calcular el índice de diversidad por ruta
CREATE FUNCTION fn_calcular_indice_diversidad(
    p_ruta_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_ciudades INT;
    DECLARE v_ciudades_unicas INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de campers
    SELECT COUNT(*) INTO v_total_ciudades
    FROM inscripciones i
    JOIN campers c ON i.camper_id = c.id
    WHERE i.ruta_id = p_ruta_id;
    
    -- Contar ciudades únicas
    SELECT COUNT(DISTINCT c.ciudad) INTO v_ciudades_unicas
    FROM inscripciones i
    JOIN campers c ON i.camper_id = c.id
    WHERE i.ruta_id = p_ruta_id;
    
    -- Calcular índice
    IF v_total_ciudades > 0 THEN
        SET v_indice = (v_ciudades_unicas * 100.0) / v_total_ciudades;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 15. Función para calcular el índice de eficiencia del trainer
CREATE FUNCTION fn_calcular_eficiencia_trainer(
    p_trainer_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_promedio_rendimiento DECIMAL(5,2);
    DECLARE v_indice_asistencia DECIMAL(5,2);
    DECLARE v_eficiencia DECIMAL(5,2);
    
    -- Calcular promedio de rendimiento
    SELECT COALESCE(AVG(e.nota), 0) INTO v_promedio_rendimiento
    FROM evaluaciones e
    JOIN inscripciones i ON e.inscripcion_id = i.id
    JOIN asignaciones_trainers at ON i.ruta_id = at.ruta_id
    WHERE at.trainer_id = p_trainer_id
    AND at.estado = 'Activa';
    
    -- Calcular índice de asistencia
    SELECT COALESCE(AVG(
        CASE 
            WHEN a.estado IN ('Presente', 'Justificada') THEN 100
            ELSE 0
        END
    ), 0) INTO v_indice_asistencia
    FROM asistencias a
    JOIN inscripciones i ON a.inscripcion_id = i.id
    JOIN asignaciones_trainers at ON i.ruta_id = at.ruta_id
    WHERE at.trainer_id = p_trainer_id
    AND at.estado = 'Activa';
    
    -- Calcular eficiencia (promedio de rendimiento y asistencia)
    SET v_eficiencia = (v_promedio_rendimiento + v_indice_asistencia) / 2;
    
    RETURN v_eficiencia;
END //

-- 16. Función para calcular el índice de participación en actividades
CREATE FUNCTION fn_calcular_participacion_actividades(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_actividades INT;
    DECLARE v_actividades_participadas INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de actividades
    SELECT COUNT(*) INTO v_total_actividades
    FROM actividades a
    JOIN inscripciones i ON a.modulo_id = i.modulo_id
    WHERE i.camper_id = p_camper_id
    AND a.fecha_inicio <= CURDATE()
    AND a.fecha_fin >= CURDATE();
    
    -- Contar actividades con participación
    SELECT COUNT(DISTINCT a.id) INTO v_actividades_participadas
    FROM actividades a
    JOIN inscripciones i ON a.modulo_id = i.modulo_id
    JOIN entregas_actividades ea ON a.id = ea.actividad_id
    WHERE i.camper_id = p_camper_id
    AND ea.inscripcion_id = i.id;
    
    -- Calcular índice
    IF v_total_actividades > 0 THEN
        SET v_indice = (v_actividades_participadas * 100.0) / v_total_actividades;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 17. Función para calcular el índice de participación en hackathons
CREATE FUNCTION fn_calcular_participacion_hackathons(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_hackathons INT;
    DECLARE v_hackathons_participados INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de hackathons activos
    SELECT COUNT(*) INTO v_total_hackathons
    FROM hackathons
    WHERE fecha_inicio <= CURDATE()
    AND fecha_fin >= CURDATE();
    
    -- Contar hackathons con participación
    SELECT COUNT(DISTINCT h.id) INTO v_hackathons_participados
    FROM hackathons h
    JOIN participaciones_hackathon ph ON h.id = ph.hackathon_id
    WHERE ph.camper_id = p_camper_id;
    
    -- Calcular índice
    IF v_total_hackathons > 0 THEN
        SET v_indice = (v_hackathons_participados * 100.0) / v_total_hackathons;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 18. Función para calcular el índice de participación en workshops
CREATE FUNCTION fn_calcular_participacion_workshops(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_workshops INT;
    DECLARE v_workshops_participados INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de workshops futuros
    SELECT COUNT(*) INTO v_total_workshops
    FROM workshops
    WHERE fecha >= CURDATE();
    
    -- Contar workshops con participación
    SELECT COUNT(DISTINCT w.id) INTO v_workshops_participados
    FROM workshops w
    JOIN participaciones_workshop pw ON w.id = pw.workshop_id
    WHERE pw.camper_id = p_camper_id;
    
    -- Calcular índice
    IF v_total_workshops > 0 THEN
        SET v_indice = (v_workshops_participados * 100.0) / v_total_workshops;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 19. Función para calcular el índice de participación en mentorías
CREATE FUNCTION fn_calcular_participacion_mentorias(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_mentorias INT;
    DECLARE v_mentorias_participadas INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de mentorías programadas
    SELECT COUNT(*) INTO v_total_mentorias
    FROM mentorias m
    JOIN inscripciones i ON m.inscripcion_id = i.id
    WHERE i.camper_id = p_camper_id
    AND m.fecha >= CURDATE();
    
    -- Contar mentorías con participación
    SELECT COUNT(DISTINCT m.id) INTO v_mentorias_participadas
    FROM mentorias m
    JOIN inscripciones i ON m.inscripcion_id = i.id
    JOIN asistencia_mentorias am ON m.id = am.mentoria_id
    WHERE i.camper_id = p_camper_id
    AND am.estado = 'Presente';
    
    -- Calcular índice
    IF v_total_mentorias > 0 THEN
        SET v_indice = (v_mentorias_participadas * 100.0) / v_total_mentorias;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

-- 20. Función para calcular el índice de participación en eventos especiales
CREATE FUNCTION fn_calcular_participacion_eventos(
    p_camper_id INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_eventos INT;
    DECLARE v_eventos_participados INT;
    DECLARE v_indice DECIMAL(5,2);
    
    -- Contar total de eventos futuros
    SELECT COUNT(*) INTO v_total_eventos
    FROM eventos_especiales
    WHERE fecha >= CURDATE();
    
    -- Contar eventos con participación
    SELECT COUNT(DISTINCT ee.id) INTO v_eventos_participados
    FROM eventos_especiales ee
    JOIN participaciones_eventos pe ON ee.id = pe.evento_id
    WHERE pe.camper_id = p_camper_id;
    
    -- Calcular índice
    IF v_total_eventos > 0 THEN
        SET v_indice = (v_eventos_participados * 100.0) / v_total_eventos;
    ELSE
        SET v_indice = 0;
    END IF;
    
    RETURN v_indice;
END //

DELIMITER ; 