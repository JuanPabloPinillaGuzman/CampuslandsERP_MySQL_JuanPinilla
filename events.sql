-- =============================================
-- EVENTOS SQL PARA AUTOMATIZACIÓN DE TAREAS
-- =============================================

DELIMITER //

-- 1. Evento para actualizar estado de campers al finalizar módulo
CREATE EVENT evt_actualizar_estado_campers
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Actualizar estado de campers que completaron módulo
    UPDATE inscripciones i
    JOIN (
        SELECT i.id, m.id as modulo_id, fn_calcular_promedio_ponderado(i.id, m.id) as promedio
        FROM inscripciones i
        JOIN modulos m ON i.ruta_id = m.ruta_id
        WHERE i.estado = 'Activa'
    ) v ON i.id = v.id
    SET i.estado = CASE 
        WHEN v.promedio >= 70 THEN 'Aprobado'
        WHEN v.promedio < 70 THEN 'Reprobado'
        ELSE i.estado
    END
    WHERE i.estado = 'Activa';
END //

-- 2. Evento para generar reporte diario de rendimiento por ruta
CREATE EVENT evt_reporte_rendimiento_rutas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
DO
BEGIN
    INSERT INTO reportes_rendimiento (
        tipo_reporte,
        fecha_generacion,
        datos
    )
    SELECT 
        'Rendimiento por Ruta',
        CURDATE(),
        JSON_OBJECT(
            'ruta_id', r.id,
            'nombre_ruta', r.nombre,
            'promedio_rendimiento', fn_calcular_rendimiento_ruta(r.id),
            'indice_retencion', fn_calcular_indice_retencion(r.id),
            'indice_diversidad', fn_calcular_indice_diversidad(r.id)
        )
    FROM rutas r;
END //

-- 3. Evento para verificar ocupación diaria de áreas
CREATE EVENT evt_verificar_ocupacion_areas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 2 HOUR
DO
BEGIN
    INSERT INTO reportes_ocupacion (
        fecha,
        area_id,
        cupo_disponible,
        porcentaje_ocupacion
    )
    SELECT 
        CURDATE(),
        a.id,
        fn_verificar_capacidad_area(a.id),
        (a.cupo_maximo - fn_verificar_capacidad_area(a.id)) * 100.0 / a.cupo_maximo
    FROM areas a;
END //

-- 4. Evento para actualizar estado de inscripciones vencidas
CREATE EVENT evt_actualizar_inscripciones_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 3 HOUR
DO
BEGIN
    UPDATE inscripciones
    SET estado = 'Vencida'
    WHERE estado = 'Activa'
    AND fecha_fin < CURDATE();
END //

-- 5. Evento para generar reporte semanal de asistencia
CREATE EVENT evt_reporte_asistencia_semanal
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 4 HOUR
DO
BEGIN
    INSERT INTO reportes_asistencia (
        fecha_inicio,
        fecha_fin,
        ruta_id,
        total_sesiones,
        promedio_asistencia
    )
    SELECT 
        DATE_SUB(CURDATE(), INTERVAL 7 DAY),
        CURDATE(),
        i.ruta_id,
        COUNT(DISTINCT a.fecha),
        AVG(CASE WHEN a.estado IN ('Presente', 'Justificada') THEN 100 ELSE 0 END)
    FROM inscripciones i
    JOIN asistencias a ON i.id = a.inscripcion_id
    WHERE a.fecha BETWEEN DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND CURDATE()
    GROUP BY i.ruta_id;
END //

-- 6. Evento para actualizar estado de proyectos vencidos
CREATE EVENT evt_actualizar_proyectos_vencidos
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 5 HOUR
DO
BEGIN
    UPDATE proyectos p
    SET estado = 'Vencido'
    WHERE estado = 'Activo'
    AND fecha_fin < CURDATE();
END //

-- 7. Evento para generar reporte mensual de rendimiento por área
CREATE EVENT evt_reporte_rendimiento_areas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 6 HOUR
DO
BEGIN
    INSERT INTO reportes_rendimiento (
        tipo_reporte,
        fecha_generacion,
        datos
    )
    SELECT 
        'Rendimiento por Área',
        CURDATE(),
        JSON_OBJECT(
            'area_id', a.id,
            'nombre_area', a.nombre,
            'promedio_rendimiento', AVG(e.nota),
            'total_evaluaciones', COUNT(e.id),
            'evaluaciones_aprobadas', SUM(CASE WHEN e.nota >= 70 THEN 1 ELSE 0 END)
        )
    FROM areas a
    JOIN asignaciones_areas aa ON a.id = aa.area_id
    JOIN inscripciones i ON aa.inscripcion_id = i.id
    JOIN evaluaciones e ON i.id = e.inscripcion_id
    WHERE e.fecha BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY a.id;
END //

-- 8. Evento para actualizar estado de mentorías
CREATE EVENT evt_actualizar_estado_mentorias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 7 HOUR
DO
BEGIN
    UPDATE mentorias
    SET estado = 'Completada'
    WHERE estado = 'Programada'
    AND fecha < CURDATE();
END //

-- 9. Evento para generar reporte de soportes pendientes
CREATE EVENT evt_reporte_soportes_pendientes
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 8 HOUR
DO
BEGIN
    INSERT INTO reportes_soporte (
        fecha,
        tipo_soporte,
        total_pendientes,
        tiempo_promedio_espera
    )
    SELECT 
        CURDATE(),
        tipo_soporte,
        COUNT(*),
        AVG(TIMESTAMPDIFF(HOUR, fecha_solicitud, CURDATE()))
    FROM soportes
    WHERE estado = 'Pendiente'
    GROUP BY tipo_soporte;
END //

-- 10. Evento para actualizar estado de hackathons
CREATE EVENT evt_actualizar_estado_hackathons
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 9 HOUR
DO
BEGIN
    UPDATE hackathons
    SET estado = CASE
        WHEN fecha_fin < CURDATE() THEN 'Finalizado'
        WHEN fecha_inicio <= CURDATE() AND fecha_fin >= CURDATE() THEN 'En Curso'
        ELSE estado
    END;
END //

-- 11. Evento para generar reporte de participación en foros
CREATE EVENT evt_reporte_participacion_foros
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 10 HOUR
DO
BEGIN
    INSERT INTO reportes_participacion (
        fecha_inicio,
        fecha_fin,
        modulo_id,
        total_foros,
        total_comentarios,
        campers_participantes
    )
    SELECT 
        DATE_SUB(CURDATE(), INTERVAL 7 DAY),
        CURDATE(),
        f.modulo_id,
        COUNT(DISTINCT f.id),
        COUNT(c.id),
        COUNT(DISTINCT c.camper_id)
    FROM foros f
    LEFT JOIN comentarios c ON f.id = c.foro_id
    WHERE c.fecha BETWEEN DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND CURDATE()
    GROUP BY f.modulo_id;
END //

-- 12. Evento para actualizar estado de workshops
CREATE EVENT evt_actualizar_estado_workshops
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 11 HOUR
DO
BEGIN
    UPDATE workshops
    SET estado = CASE
        WHEN fecha < CURDATE() THEN 'Finalizado'
        WHEN fecha = CURDATE() THEN 'En Curso'
        ELSE estado
    END;
END //

-- 13. Evento para generar reporte de rendimiento por trainer
CREATE EVENT evt_reporte_rendimiento_trainers
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 12 HOUR
DO
BEGIN
    INSERT INTO reportes_rendimiento (
        tipo_reporte,
        fecha_generacion,
        datos
    )
    SELECT 
        'Rendimiento por Trainer',
        CURDATE(),
        JSON_OBJECT(
            'trainer_id', t.id,
            'nombre_trainer', t.nombre,
            'eficiencia', fn_calcular_eficiencia_trainer(t.id),
            'indice_satisfaccion', fn_calcular_indice_satisfaccion(t.id),
            'total_campers', COUNT(DISTINCT i.camper_id)
        )
    FROM trainers t
    JOIN asignaciones_trainers at ON t.id = at.trainer_id
    JOIN inscripciones i ON at.ruta_id = i.ruta_id
    WHERE i.fecha BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY t.id;
END //

-- 14. Evento para actualizar estado de eventos especiales
CREATE EVENT evt_actualizar_estado_eventos
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 13 HOUR
DO
BEGIN
    UPDATE eventos_especiales
    SET estado = CASE
        WHEN fecha < CURDATE() THEN 'Finalizado'
        WHEN fecha = CURDATE() THEN 'En Curso'
        ELSE estado
    END;
END //

-- 15. Evento para generar reporte de proyectos entregados
CREATE EVENT evt_reporte_proyectos_entregados
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 14 HOUR
DO
BEGIN
    INSERT INTO reportes_proyectos (
        fecha_inicio,
        fecha_fin,
        modulo_id,
        total_proyectos,
        proyectos_entregados,
        tiempo_promedio_entrega
    )
    SELECT 
        DATE_SUB(CURDATE(), INTERVAL 7 DAY),
        CURDATE(),
        p.modulo_id,
        COUNT(DISTINCT p.id),
        COUNT(DISTINCT ep.proyecto_id),
        fn_calcular_tiempo_entrega_proyectos(p.modulo_id)
    FROM proyectos p
    LEFT JOIN entregas_proyectos ep ON p.id = ep.proyecto_id
    WHERE ep.fecha_entrega BETWEEN DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND CURDATE()
    GROUP BY p.modulo_id;
END //

-- 16. Evento para actualizar estado de inscripciones inactivas
CREATE EVENT evt_actualizar_inscripciones_inactivas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 15 HOUR
DO
BEGIN
    UPDATE inscripciones i
    SET estado = 'Inactiva'
    WHERE estado = 'Activa'
    AND NOT EXISTS (
        SELECT 1 FROM asistencias a 
        WHERE a.inscripcion_id = i.id 
        AND a.fecha >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    );
END //

-- 17. Evento para generar reporte de participación en actividades
CREATE EVENT evt_reporte_participacion_actividades
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 16 HOUR
DO
BEGIN
    INSERT INTO reportes_participacion (
        fecha_inicio,
        fecha_fin,
        modulo_id,
        total_actividades,
        actividades_completadas,
        promedio_participacion
    )
    SELECT 
        DATE_SUB(CURDATE(), INTERVAL 7 DAY),
        CURDATE(),
        a.modulo_id,
        COUNT(DISTINCT a.id),
        COUNT(DISTINCT ea.actividad_id),
        AVG(fn_calcular_participacion_actividades(i.camper_id))
    FROM actividades a
    JOIN inscripciones i ON a.modulo_id = i.modulo_id
    LEFT JOIN entregas_actividades ea ON a.id = ea.actividad_id
    WHERE ea.fecha_entrega BETWEEN DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND CURDATE()
    GROUP BY a.modulo_id;
END //

-- 18. Evento para actualizar estado de mentorías programadas
CREATE EVENT evt_actualizar_mentorias_programadas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 17 HOUR
DO
BEGIN
    UPDATE mentorias m
    SET estado = 'En Curso'
    WHERE estado = 'Programada'
    AND fecha = CURDATE();
END //

-- 19. Evento para generar reporte de rendimiento por ciudad
CREATE EVENT evt_reporte_rendimiento_ciudades
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 18 HOUR
DO
BEGIN
    INSERT INTO reportes_rendimiento (
        tipo_reporte,
        fecha_generacion,
        datos
    )
    SELECT 
        'Rendimiento por Ciudad',
        CURDATE(),
        JSON_OBJECT(
            'ciudad', c.ciudad,
            'total_campers', COUNT(DISTINCT c.id),
            'promedio_rendimiento', AVG(e.nota),
            'indice_asistencia', AVG(fn_calcular_indice_asistencia(c.id)),
            'indice_participacion', AVG(fn_calcular_indice_participacion(c.id))
        )
    FROM campers c
    JOIN inscripciones i ON c.id = i.camper_id
    JOIN evaluaciones e ON i.id = e.inscripcion_id
    WHERE e.fecha BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY c.ciudad;
END //

-- 20. Evento para actualizar estado de inscripciones completadas
CREATE EVENT evt_actualizar_inscripciones_completadas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 19 HOUR
DO
BEGIN
    UPDATE inscripciones i
    SET estado = 'Completada'
    WHERE estado = 'Activa'
    AND NOT EXISTS (
        SELECT 1 FROM modulos m
        JOIN evaluaciones e ON m.id = e.modulo_id
        WHERE m.ruta_id = i.ruta_id
        AND e.inscripcion_id = i.id
        AND e.nota < 70
    );
END //

DELIMITER ; 