-- =============================================
-- CONSULTAS RELACIONADAS CON CAMPERS
-- =============================================

-- 1. Listar todos los campers inscritos con su información básica
SELECT 
    c.identificacion,
    c.nombres,
    c.apellidos,
    c.email,
    c.estado,
    c.nivel_riesgo,
    td.nombre as tipo_documento,
    ci.nombre as ciudad
FROM campers c
JOIN tipos_documento td ON c.tipo_documento_id = td.id
JOIN ciudades ci ON c.ciudad_id = ci.id;

-- 2. Contar campers por estado
SELECT 
    estado,
    COUNT(*) as total_campers
FROM campers
GROUP BY estado;

-- 3. Campers en riesgo alto con su información de contacto
SELECT 
    c.nombres,
    c.apellidos,
    c.telefono_contacto,
    c.email,
    c.acudiente,
    r.nombre as ruta_actual
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
WHERE c.nivel_riesgo = 'Alto'
AND i.estado = 'Activa';

-- 4. Campers aprobados por ruta
SELECT 
    r.nombre as ruta,
    COUNT(DISTINCT c.id) as total_aprobados
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
WHERE c.estado = 'Aprobado'
GROUP BY r.id, r.nombre;

-- 5. Campers que han completado todas las evaluaciones de un módulo
SELECT 
    c.nombres,
    c.apellidos,
    m.nombre as modulo,
    COUNT(e.id) as total_evaluaciones,
    AVG(e.nota) as promedio
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
GROUP BY c.id, c.nombres, c.apellidos, m.id, m.nombre
HAVING COUNT(e.id) >= 3; -- Asumiendo 3 tipos de evaluación por módulo

-- 6. Campers con mejor rendimiento por ruta
SELECT 
    r.nombre as ruta,
    c.nombres,
    c.apellidos,
    AVG(e.nota) as promedio
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre, c.id, c.nombres, c.apellidos
HAVING AVG(e.nota) >= 80
ORDER BY r.nombre, promedio DESC;

-- 7. Campers que han faltado más de 3 veces
SELECT 
    c.nombres,
    c.apellidos,
    r.nombre as ruta,
    COUNT(a.id) as total_faltas
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
JOIN asistencias a ON i.id = a.inscripcion_id
WHERE a.estado = 'Ausente'
GROUP BY c.id, c.nombres, c.apellidos, r.id, r.nombre
HAVING COUNT(a.id) > 3;

-- 8. Campers que han entregado todos los proyectos de un módulo
SELECT 
    c.nombres,
    c.apellidos,
    m.nombre as modulo,
    COUNT(ep.id) as proyectos_entregados
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN entregas_proyectos ep ON i.id = ep.inscripcion_id
JOIN proyectos p ON ep.proyecto_id = p.id
JOIN modulos m ON p.modulo_id = m.id
WHERE ep.estado = 'Calificado'
GROUP BY c.id, c.nombres, c.apellidos, m.id, m.nombre;

-- 9. Campers por ciudad y nivel de riesgo
SELECT 
    ci.nombre as ciudad,
    c.nivel_riesgo,
    COUNT(*) as total_campers
FROM campers c
JOIN ciudades ci ON c.ciudad_id = ci.id
GROUP BY ci.id, ci.nombre, c.nivel_riesgo
ORDER BY ci.nombre, c.nivel_riesgo;

-- 10. Campers que han comentado en materiales de apoyo
SELECT 
    c.nombres,
    c.apellidos,
    ma.nombre as material,
    COUNT(cm.id) as total_comentarios
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN comentarios cm ON i.id = cm.inscripcion_id
JOIN materiales_apoyo ma ON cm.material_id = ma.id
GROUP BY c.id, c.nombres, c.apellidos, ma.id, ma.nombre;

-- 11. Campers con justificaciones pendientes
SELECT 
    c.nombres,
    c.apellidos,
    j.motivo,
    j.fecha_justificacion,
    j.estado
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN asistencias a ON i.id = a.inscripcion_id
JOIN justificaciones j ON a.id = j.asistencia_id
WHERE j.estado = 'Pendiente';

-- 12. Campers que han aprobado todos los módulos de una ruta
SELECT 
    c.nombres,
    c.apellidos,
    r.nombre as ruta,
    COUNT(DISTINCT m.id) as modulos_aprobados
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
JOIN modulos m ON r.id = m.ruta_id
JOIN evaluaciones e ON m.id = e.modulo_id AND i.id = e.inscripcion_id
WHERE e.nota >= 60
GROUP BY c.id, c.nombres, c.apellidos, r.id, r.nombre
HAVING COUNT(DISTINCT m.id) = (
    SELECT COUNT(*) 
    FROM modulos 
    WHERE ruta_id = r.id
);

-- 13. Campers con mejor asistencia por ruta
SELECT 
    r.nombre as ruta,
    c.nombres,
    c.apellidos,
    COUNT(CASE WHEN a.estado = 'Presente' THEN 1 END) as asistencias,
    COUNT(CASE WHEN a.estado = 'Ausente' THEN 1 END) as ausencias,
    ROUND(COUNT(CASE WHEN a.estado = 'Presente' THEN 1 END) * 100.0 / COUNT(*), 2) as porcentaje_asistencia
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
JOIN asistencias a ON i.id = a.inscripcion_id
GROUP BY r.id, r.nombre, c.id, c.nombres, c.apellidos
HAVING porcentaje_asistencia >= 90
ORDER BY r.nombre, porcentaje_asistencia DESC;

-- 14. Campers que han entregado proyectos tarde
SELECT 
    c.nombres,
    c.apellidos,
    p.nombre as proyecto,
    ep.fecha_entrega,
    p.fecha_fin as fecha_limite
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN entregas_proyectos ep ON i.id = ep.inscripcion_id
JOIN proyectos p ON ep.proyecto_id = p.id
WHERE ep.fecha_entrega > p.fecha_fin;

-- 15. Campers con mejor promedio por módulo
SELECT 
    m.nombre as modulo,
    c.nombres,
    c.apellidos,
    AVG(e.nota) as promedio
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
GROUP BY m.id, m.nombre, c.id, c.nombres, c.apellidos
HAVING AVG(e.nota) >= 90
ORDER BY m.nombre, promedio DESC;

-- 16. Campers que han participado en todos los tipos de evaluación
SELECT 
    c.nombres,
    c.apellidos,
    m.nombre as modulo,
    COUNT(DISTINCT te.id) as tipos_evaluacion_completados
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY c.id, c.nombres, c.apellidos, m.id, m.nombre
HAVING COUNT(DISTINCT te.id) = (SELECT COUNT(*) FROM tipos_evaluacion);

-- 17. Campers por edad y ruta
SELECT 
    r.nombre as ruta,
    TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) as edad,
    COUNT(*) as total_campers
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
GROUP BY r.id, r.nombre, TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE())
ORDER BY r.nombre, edad;

-- 18. Campers que han aprobado módulos sin faltas
SELECT 
    c.nombres,
    c.apellidos,
    m.nombre as modulo,
    AVG(e.nota) as promedio,
    COUNT(CASE WHEN a.estado = 'Presente' THEN 1 END) as asistencias
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
JOIN asistencias a ON i.id = a.inscripcion_id
WHERE e.nota >= 60
GROUP BY c.id, c.nombres, c.apellidos, m.id, m.nombre
HAVING COUNT(CASE WHEN a.estado = 'Ausente' THEN 1 END) = 0;

-- 19. Campers con proyectos pendientes
SELECT 
    c.nombres,
    c.apellidos,
    p.nombre as proyecto,
    p.fecha_fin as fecha_limite
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN proyectos p ON i.ruta_id = p.modulo_id
LEFT JOIN entregas_proyectos ep ON p.id = ep.proyecto_id AND i.id = ep.inscripcion_id
WHERE ep.id IS NULL
AND p.fecha_fin >= CURDATE();

-- 20. Campers con mejor rendimiento general
SELECT 
    c.nombres,
    c.apellidos,
    r.nombre as ruta,
    AVG(e.nota) as promedio_general,
    COUNT(DISTINCT m.id) as modulos_completados,
    COUNT(CASE WHEN a.estado = 'Presente' THEN 1 END) as asistencias
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN rutas r ON i.ruta_id = r.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
JOIN asistencias a ON i.id = a.inscripcion_id
GROUP BY c.id, c.nombres, c.apellidos, r.id, r.nombre
HAVING AVG(e.nota) >= 85
ORDER BY promedio_general DESC;

-- =============================================
-- CONSULTAS RELACIONADAS CON EVALUACIONES
-- =============================================

-- 21. Promedio de evaluaciones por módulo
SELECT 
    m.nombre as modulo,
    te.nombre as tipo_evaluacion,
    ROUND(AVG(e.nota), 2) as promedio
FROM evaluaciones e
JOIN modulos m ON e.modulo_id = m.id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY m.id, m.nombre, te.id, te.nombre
ORDER BY m.nombre, te.nombre;

-- 22. Rendimiento por ruta y tipo de evaluación
SELECT 
    r.nombre as ruta,
    te.nombre as tipo_evaluacion,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    MIN(e.nota) as nota_minima,
    MAX(e.nota) as nota_maxima
FROM evaluaciones e
JOIN inscripciones i ON e.inscripcion_id = i.id
JOIN rutas r ON i.ruta_id = r.id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY r.id, r.nombre, te.id, te.nombre
ORDER BY r.nombre, te.nombre;

-- 23. Trainers con mejor rendimiento de sus estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    r.nombre as ruta,
    ROUND(AVG(e.nota), 2) as promedio_estudiantes
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN rutas r ON at.ruta_id = r.id
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos, r.id, r.nombre
HAVING AVG(e.nota) >= 80
ORDER BY promedio_estudiantes DESC;

-- 24. Módulos con mayor tasa de aprobación
SELECT 
    m.nombre as modulo,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(e.id) as total_evaluaciones,
    ROUND(COUNT(CASE WHEN e.nota >= 60 THEN 1 END) * 100.0 / COUNT(e.id), 2) as tasa_aprobacion
FROM modulos m
JOIN evaluaciones e ON m.id = e.modulo_id
GROUP BY m.id, m.nombre
ORDER BY tasa_aprobacion DESC;

-- 25. Rendimiento por categoría de módulo
SELECT 
    cm.nombre as categoria,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados
FROM categorias_modulos cm
JOIN modulos m ON cm.id = m.categoria_id
JOIN evaluaciones e ON m.id = e.modulo_id
GROUP BY cm.id, cm.nombre
ORDER BY promedio DESC;

-- 26. Evolución del rendimiento por camper
SELECT 
    c.nombres,
    c.apellidos,
    m.nombre as modulo,
    e.fecha_evaluacion,
    e.nota,
    LAG(e.nota) OVER (PARTITION BY c.id, m.id ORDER BY e.fecha_evaluacion) as nota_anterior
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN modulos m ON e.modulo_id = m.id
ORDER BY c.id, m.id, e.fecha_evaluacion;

-- 27. Promedio de evaluaciones por tipo y ruta
SELECT 
    r.nombre as ruta,
    te.nombre as tipo_evaluacion,
    te.porcentaje,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(e.id) as total_evaluaciones
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY r.id, r.nombre, te.id, te.nombre, te.porcentaje
ORDER BY r.nombre, te.porcentaje DESC;

-- 28. Campers con mejor rendimiento por tipo de evaluación
SELECT 
    c.nombres,
    c.apellidos,
    te.nombre as tipo_evaluacion,
    ROUND(AVG(e.nota), 2) as promedio
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY c.id, c.nombres, c.apellidos, te.id, te.nombre
HAVING AVG(e.nota) >= 90
ORDER BY te.nombre, promedio DESC;

-- 29. Rendimiento por área de entrenamiento
SELECT 
    ae.nombre as area,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY promedio DESC;

-- 30. Módulos que requieren más atención
SELECT 
    m.nombre as modulo,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados,
    COUNT(e.id) as total_evaluaciones,
    ROUND(COUNT(CASE WHEN e.nota < 60 THEN 1 END) * 100.0 / COUNT(e.id), 2) as tasa_reprobacion
FROM modulos m
JOIN evaluaciones e ON m.id = e.modulo_id
GROUP BY m.id, m.nombre
HAVING tasa_reprobacion > 20
ORDER BY tasa_reprobacion DESC;

-- 31. Rendimiento por período
SELECT 
    DATE_FORMAT(e.fecha_evaluacion, '%Y-%m') as periodo,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM evaluaciones e
GROUP BY DATE_FORMAT(e.fecha_evaluacion, '%Y-%m')
ORDER BY periodo;

-- 32. Comparación de rendimiento entre rutas
SELECT 
    r1.nombre as ruta_1,
    r2.nombre as ruta_2,
    ROUND(AVG(e1.nota), 2) as promedio_ruta_1,
    ROUND(AVG(e2.nota), 2) as promedio_ruta_2
FROM rutas r1
CROSS JOIN rutas r2
JOIN inscripciones i1 ON r1.id = i1.ruta_id
JOIN inscripciones i2 ON r2.id = i2.ruta_id
JOIN evaluaciones e1 ON i1.id = e1.inscripcion_id
JOIN evaluaciones e2 ON i2.id = e2.inscripcion_id
WHERE r1.id < r2.id
GROUP BY r1.id, r1.nombre, r2.id, r2.nombre;

-- 33. Rendimiento por nivel de riesgo
SELECT 
    c.nivel_riesgo,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM campers c
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY c.nivel_riesgo
ORDER BY c.nivel_riesgo;

-- 34. Módulos con mayor variación en calificaciones
SELECT 
    m.nombre as modulo,
    ROUND(STDDEV(e.nota), 2) as desviacion_estandar,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(e.id) as total_evaluaciones
FROM modulos m
JOIN evaluaciones e ON m.id = e.modulo_id
GROUP BY m.id, m.nombre
HAVING desviacion_estandar > 10
ORDER BY desviacion_estandar DESC;

-- 35. Rendimiento por tipo de trainer
SELECT 
    tt.nombre as tipo_trainer,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM tipos_trainer tt
JOIN trainers t ON tt.id = t.tipo_trainer_id
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY tt.id, tt.nombre
ORDER BY promedio DESC;

-- 36. Rendimiento por ciudad
SELECT 
    ci.nombre as ciudad,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM ciudades ci
JOIN campers c ON ci.id = c.ciudad_id
JOIN inscripciones i ON c.id = i.camper_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ci.id, ci.nombre
ORDER BY promedio DESC;

-- 37. Rendimiento por módulo y tipo de evaluación
SELECT 
    m.nombre as modulo,
    te.nombre as tipo_evaluacion,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados
FROM modulos m
JOIN evaluaciones e ON m.id = e.modulo_id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY m.id, m.nombre, te.id, te.nombre
ORDER BY m.nombre, te.nombre;

-- 38. Rendimiento por ruta y módulo
SELECT 
    r.nombre as ruta,
    m.nombre as modulo,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados
FROM rutas r
JOIN modulos m ON r.id = m.ruta_id
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id AND m.id = e.modulo_id
GROUP BY r.id, r.nombre, m.id, m.nombre
ORDER BY r.nombre, m.nombre;

-- 39. Rendimiento por período y tipo de evaluación
SELECT 
    DATE_FORMAT(e.fecha_evaluacion, '%Y-%m') as periodo,
    te.nombre as tipo_evaluacion,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio
FROM evaluaciones e
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
GROUP BY DATE_FORMAT(e.fecha_evaluacion, '%Y-%m'), te.id, te.nombre
ORDER BY periodo, te.nombre;

-- 40. Rendimiento por trainer y tipo de evaluación
SELECT 
    t.nombres,
    t.apellidos,
    te.nombre as tipo_evaluacion,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN tipos_evaluacion te ON e.tipo_evaluacion_id = te.id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos, te.id, te.nombre
ORDER BY t.nombres, te.nombre;

-- =============================================
-- CONSULTAS RELACIONADAS CON RUTAS
-- =============================================

-- 41. Capacidad y ocupación por ruta
SELECT 
    r.nombre as ruta,
    r.cupo_maximo as capacidad,
    COUNT(i.id) as inscritos,
    ROUND(COUNT(i.id) * 100.0 / r.cupo_maximo, 2) as ocupacion_porcentaje
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
GROUP BY r.id, r.nombre, r.cupo_maximo
ORDER BY ocupacion_porcentaje DESC;

-- 42. Rutas con mayor demanda
SELECT 
    r.nombre as ruta,
    COUNT(i.id) as total_inscritos,
    COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) as inscritos_activos,
    COUNT(CASE WHEN i.estado = 'Inactiva' THEN 1 END) as inscritos_inactivos
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
GROUP BY r.id, r.nombre
ORDER BY total_inscritos DESC;

-- 43. Módulos por ruta
SELECT 
    r.nombre as ruta,
    COUNT(m.id) as total_modulos,
    GROUP_CONCAT(m.nombre ORDER BY m.orden SEPARATOR ', ') as modulos
FROM rutas r
LEFT JOIN modulos m ON r.id = m.ruta_id
GROUP BY r.id, r.nombre
ORDER BY r.nombre;

-- 44. Trainers asignados por ruta
SELECT 
    r.nombre as ruta,
    COUNT(at.id) as total_trainers,
    GROUP_CONCAT(
        CONCAT(t.nombres, ' ', t.apellidos) 
        ORDER BY t.nombres 
        SEPARATOR ', '
    ) as trainers
FROM rutas r
LEFT JOIN asignaciones_trainers at ON r.id = at.ruta_id
LEFT JOIN trainers t ON at.trainer_id = t.id
WHERE at.estado = 'Activa'
GROUP BY r.id, r.nombre
ORDER BY r.nombre;

-- 45. Rendimiento promedio por ruta
SELECT 
    r.nombre as ruta,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
LEFT JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY promedio DESC;

-- 46. Rutas con mayor tasa de aprobación
SELECT 
    r.nombre as ruta,
    COUNT(e.id) as total_evaluaciones,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    ROUND(COUNT(CASE WHEN e.nota >= 60 THEN 1 END) * 100.0 / COUNT(e.id), 2) as tasa_aprobacion
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
LEFT JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre
HAVING tasa_aprobacion >= 80
ORDER BY tasa_aprobacion DESC;

-- 47. Distribución de campers por ruta y ciudad
SELECT 
    r.nombre as ruta,
    ci.nombre as ciudad,
    COUNT(c.id) as total_campers
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN campers c ON i.camper_id = c.id
JOIN ciudades ci ON c.ciudad_id = ci.id
GROUP BY r.id, r.nombre, ci.id, ci.nombre
ORDER BY r.nombre, total_campers DESC;

-- 48. Rutas con mayor deserción
SELECT 
    r.nombre as ruta,
    COUNT(i.id) as total_inscritos,
    COUNT(CASE WHEN i.estado = 'Inactiva' THEN 1 END) as desertores,
    ROUND(COUNT(CASE WHEN i.estado = 'Inactiva' THEN 1 END) * 100.0 / COUNT(i.id), 2) as tasa_desercion
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
GROUP BY r.id, r.nombre
HAVING tasa_desercion > 10
ORDER BY tasa_desercion DESC;

-- 49. Rutas con mejor rendimiento por módulo
SELECT 
    r.nombre as ruta,
    m.nombre as modulo,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio
FROM rutas r
JOIN modulos m ON r.id = m.ruta_id
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id AND m.id = e.modulo_id
GROUP BY r.id, r.nombre, m.id, m.nombre
HAVING promedio >= 80
ORDER BY r.nombre, promedio DESC;

-- 50. Rutas con mayor participación en proyectos
SELECT 
    r.nombre as ruta,
    COUNT(p.id) as total_proyectos,
    COUNT(DISTINCT p.inscripcion_id) as campers_con_proyectos,
    ROUND(AVG(p.nota), 2) as promedio_proyectos
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN proyectos p ON i.id = p.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY total_proyectos DESC;

-- 51. Rutas con mayor asistencia
SELECT 
    r.nombre as ruta,
    COUNT(a.id) as total_asistencias,
    COUNT(DISTINCT a.inscripcion_id) as campers_con_asistencia,
    ROUND(AVG(CASE WHEN a.estado = 'Presente' THEN 1 ELSE 0 END) * 100, 2) as tasa_asistencia
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN asistencias a ON i.id = a.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY tasa_asistencia DESC;

-- 52. Rutas con mayor participación en foros
SELECT 
    r.nombre as ruta,
    COUNT(f.id) as total_foros,
    COUNT(c.id) as total_comentarios,
    COUNT(DISTINCT c.camper_id) as campers_participantes
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN foros f ON i.id = f.inscripcion_id
JOIN comentarios c ON f.id = c.foro_id
GROUP BY r.id, r.nombre
ORDER BY total_comentarios DESC;

-- 53. Rutas con mayor uso de recursos
SELECT 
    r.nombre as ruta,
    COUNT(rm.id) as total_recursos,
    COUNT(DISTINCT rm.inscripcion_id) as campers_utilizando,
    GROUP_CONCAT(DISTINCT rm.tipo_recurso) as tipos_recursos
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN recursos_modulo rm ON i.id = rm.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY total_recursos DESC;

-- 54. Rutas con mayor satisfacción
SELECT 
    r.nombre as ruta,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 80 THEN 1 END) as excelentes,
    COUNT(CASE WHEN e.nota BETWEEN 60 AND 79 THEN 1 END) as buenos,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as deficientes
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY promedio DESC;

-- 55. Rutas con mayor progreso
SELECT 
    r.nombre as ruta,
    COUNT(DISTINCT i.camper_id) as total_campers,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as campers_aprobados,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as tasa_progreso
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY tasa_progreso DESC;

-- 56. Rutas con mayor retención
SELECT 
    r.nombre as ruta,
    COUNT(i.id) as total_inscritos,
    COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) as inscritos_activos,
    ROUND(COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) * 100.0 / 
          COUNT(i.id), 2) as tasa_retencion
FROM rutas r
LEFT JOIN inscripciones i ON r.id = i.ruta_id
GROUP BY r.id, r.nombre
ORDER BY tasa_retencion DESC;

-- 57. Rutas con mayor diversidad de campers
SELECT 
    r.nombre as ruta,
    COUNT(DISTINCT c.ciudad_id) as total_ciudades,
    COUNT(DISTINCT c.id) as total_campers,
    GROUP_CONCAT(DISTINCT ci.nombre) as ciudades
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN campers c ON i.camper_id = c.id
JOIN ciudades ci ON c.ciudad_id = ci.id
GROUP BY r.id, r.nombre
ORDER BY total_ciudades DESC;

-- 58. Rutas con mayor participación en actividades
SELECT 
    r.nombre as ruta,
    COUNT(a.id) as total_actividades,
    COUNT(DISTINCT a.inscripcion_id) as campers_participantes,
    ROUND(AVG(a.nota), 2) as promedio_actividades
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN actividades a ON i.id = a.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY total_actividades DESC;

-- 59. Rutas con mayor uso de soporte
SELECT 
    r.nombre as ruta,
    COUNT(s.id) as total_soportes,
    COUNT(DISTINCT s.inscripcion_id) as campers_solicitantes,
    GROUP_CONCAT(DISTINCT s.tipo_soporte) as tipos_soporte
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN soportes s ON i.id = s.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY total_soportes DESC;

-- 60. Rutas con mayor eficiencia
SELECT 
    r.nombre as ruta,
    COUNT(DISTINCT i.camper_id) as total_campers,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as campers_aprobados,
    ROUND(AVG(e.nota), 2) as promedio,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as eficiencia
FROM rutas r
JOIN inscripciones i ON r.id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY r.id, r.nombre
ORDER BY eficiencia DESC;

-- =============================================
-- CONSULTAS RELACIONADAS CON ÁREAS
-- =============================================

-- 61. Capacidad y ocupación por área
SELECT 
    ae.nombre as area,
    ae.capacidad_maxima as capacidad,
    COUNT(aa.id) as asignados,
    ROUND(COUNT(aa.id) * 100.0 / ae.capacidad_maxima, 2) as ocupacion_porcentaje
FROM areas_entrenamiento ae
LEFT JOIN asignaciones_areas aa ON ae.id = aa.area_id
GROUP BY ae.id, ae.nombre, ae.capacidad_maxima
ORDER BY ocupacion_porcentaje DESC;

-- 62. Áreas con mayor demanda
SELECT 
    ae.nombre as area,
    COUNT(aa.id) as total_asignaciones,
    COUNT(DISTINCT aa.inscripcion_id) as campers_asignados,
    COUNT(DISTINCT aa.trainer_id) as trainers_asignados
FROM areas_entrenamiento ae
LEFT JOIN asignaciones_areas aa ON ae.id = aa.area_id
GROUP BY ae.id, ae.nombre
ORDER BY total_asignaciones DESC;

-- 63. Distribución de campers por área
SELECT 
    ae.nombre as area,
    COUNT(DISTINCT aa.inscripcion_id) as total_campers,
    COUNT(DISTINCT CASE WHEN i.estado = 'Activa' THEN aa.inscripcion_id END) as campers_activos,
    COUNT(DISTINCT CASE WHEN i.estado = 'Inactiva' THEN aa.inscripcion_id END) as campers_inactivos
FROM areas_entrenamiento ae
LEFT JOIN asignaciones_areas aa ON ae.id = aa.area_id
LEFT JOIN inscripciones i ON aa.inscripcion_id = i.id
GROUP BY ae.id, ae.nombre
ORDER BY total_campers DESC;

-- 64. Áreas con mejor rendimiento
SELECT 
    ae.nombre as area,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY promedio DESC;

-- 65. Áreas con mayor asistencia
SELECT 
    ae.nombre as area,
    COUNT(a.id) as total_asistencias,
    COUNT(DISTINCT a.inscripcion_id) as campers_con_asistencia,
    ROUND(AVG(CASE WHEN a.estado = 'Presente' THEN 1 ELSE 0 END) * 100, 2) as tasa_asistencia
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN asistencias a ON i.id = a.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY tasa_asistencia DESC;

-- 66. Áreas con mayor participación en proyectos
SELECT 
    ae.nombre as area,
    COUNT(p.id) as total_proyectos,
    COUNT(DISTINCT p.inscripcion_id) as campers_con_proyectos,
    ROUND(AVG(p.nota), 2) as promedio_proyectos
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN proyectos p ON i.id = p.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_proyectos DESC;

-- 67. Áreas con mayor uso de recursos
SELECT 
    ae.nombre as area,
    COUNT(rm.id) as total_recursos,
    COUNT(DISTINCT rm.inscripcion_id) as campers_utilizando,
    GROUP_CONCAT(DISTINCT rm.tipo_recurso) as tipos_recursos
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN recursos_modulo rm ON i.id = rm.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_recursos DESC;

-- 68. Áreas con mayor participación en foros
SELECT 
    ae.nombre as area,
    COUNT(f.id) as total_foros,
    COUNT(c.id) as total_comentarios,
    COUNT(DISTINCT c.camper_id) as campers_participantes
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN foros f ON i.id = f.inscripcion_id
JOIN comentarios c ON f.id = c.foro_id
GROUP BY ae.id, ae.nombre
ORDER BY total_comentarios DESC;

-- 69. Áreas con mayor satisfacción
SELECT 
    ae.nombre as area,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 80 THEN 1 END) as excelentes,
    COUNT(CASE WHEN e.nota BETWEEN 60 AND 79 THEN 1 END) as buenos,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as deficientes
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY promedio DESC;

-- 70. Áreas con mayor progreso
SELECT 
    ae.nombre as area,
    COUNT(DISTINCT i.camper_id) as total_campers,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as campers_aprobados,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as tasa_progreso
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY tasa_progreso DESC;

-- 71. Áreas con mayor retención
SELECT 
    ae.nombre as area,
    COUNT(i.id) as total_inscritos,
    COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) as inscritos_activos,
    ROUND(COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) * 100.0 / 
          COUNT(i.id), 2) as tasa_retencion
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
GROUP BY ae.id, ae.nombre
ORDER BY tasa_retencion DESC;

-- 72. Áreas con mayor diversidad de campers
SELECT 
    ae.nombre as area,
    COUNT(DISTINCT c.ciudad_id) as total_ciudades,
    COUNT(DISTINCT c.id) as total_campers,
    GROUP_CONCAT(DISTINCT ci.nombre) as ciudades
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN campers c ON i.camper_id = c.id
JOIN ciudades ci ON c.ciudad_id = ci.id
GROUP BY ae.id, ae.nombre
ORDER BY total_ciudades DESC;

-- 73. Áreas con mayor participación en actividades
SELECT 
    ae.nombre as area,
    COUNT(a.id) as total_actividades,
    COUNT(DISTINCT a.inscripcion_id) as campers_participantes,
    ROUND(AVG(a.nota), 2) as promedio_actividades
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN actividades a ON i.id = a.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_actividades DESC;

-- 74. Áreas con mayor uso de soporte
SELECT 
    ae.nombre as area,
    COUNT(s.id) as total_soportes,
    COUNT(DISTINCT s.inscripcion_id) as campers_solicitantes,
    GROUP_CONCAT(DISTINCT s.tipo_soporte) as tipos_soporte
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN soportes s ON i.id = s.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_soportes DESC;

-- 75. Áreas con mayor eficiencia
SELECT 
    ae.nombre as area,
    COUNT(DISTINCT i.camper_id) as total_campers,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as campers_aprobados,
    ROUND(AVG(e.nota), 2) as promedio,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as eficiencia
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN evaluaciones e ON i.id = e.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY eficiencia DESC;

-- 76. Áreas con mayor participación en proyectos grupales
SELECT 
    ae.nombre as area,
    COUNT(pg.id) as total_proyectos_grupales,
    COUNT(DISTINCT pg.inscripcion_id) as campers_participantes,
    ROUND(AVG(pg.nota), 2) as promedio_proyectos
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN proyectos_grupales pg ON i.id = pg.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_proyectos_grupales DESC;

-- 77. Áreas con mayor participación en hackathons
SELECT 
    ae.nombre as area,
    COUNT(h.id) as total_hackathons,
    COUNT(DISTINCT h.inscripcion_id) as campers_participantes,
    ROUND(AVG(h.nota), 2) as promedio_hackathons
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN hackathons h ON i.id = h.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_hackathons DESC;

-- 78. Áreas con mayor participación en workshops
SELECT 
    ae.nombre as area,
    COUNT(w.id) as total_workshops,
    COUNT(DISTINCT w.inscripcion_id) as campers_participantes,
    ROUND(AVG(w.nota), 2) as promedio_workshops
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN workshops w ON i.id = w.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_workshops DESC;

-- 79. Áreas con mayor participación en mentorías
SELECT 
    ae.nombre as area,
    COUNT(m.id) as total_mentorias,
    COUNT(DISTINCT m.inscripcion_id) as campers_participantes,
    ROUND(AVG(m.nota), 2) as promedio_mentorias
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN mentorias m ON i.id = m.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_mentorias DESC;

-- 80. Áreas con mayor participación en eventos especiales
SELECT 
    ae.nombre as area,
    COUNT(ee.id) as total_eventos,
    COUNT(DISTINCT ee.inscripcion_id) as campers_participantes,
    ROUND(AVG(ee.nota), 2) as promedio_eventos
FROM areas_entrenamiento ae
JOIN asignaciones_areas aa ON ae.id = aa.area_id
JOIN inscripciones i ON aa.inscripcion_id = i.id
JOIN eventos_especiales ee ON i.id = ee.inscripcion_id
GROUP BY ae.id, ae.nombre
ORDER BY total_eventos DESC;

-- =============================================
-- CONSULTAS RELACIONADAS CON TRAINERS
-- =============================================

-- 81. Trainers con mayor número de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(DISTINCT i.camper_id) as total_estudiantes,
    COUNT(DISTINCT CASE WHEN i.estado = 'Activa' THEN i.camper_id END) as estudiantes_activos,
    COUNT(DISTINCT CASE WHEN i.estado = 'Inactiva' THEN i.camper_id END) as estudiantes_inactivos
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_estudiantes DESC;

-- 82. Rendimiento de estudiantes por trainer
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as reprobados
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY promedio DESC;

-- 83. Trainers con mejor tasa de aprobación
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(e.id) as total_evaluaciones,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    ROUND(COUNT(CASE WHEN e.nota >= 60 THEN 1 END) * 100.0 / COUNT(e.id), 2) as tasa_aprobacion
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
HAVING tasa_aprobacion >= 80
ORDER BY tasa_aprobacion DESC;

-- 84. Trainers con mayor asistencia de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(a.id) as total_asistencias,
    COUNT(DISTINCT a.inscripcion_id) as estudiantes_con_asistencia,
    ROUND(AVG(CASE WHEN a.estado = 'Presente' THEN 1 ELSE 0 END) * 100, 2) as tasa_asistencia
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN asistencias a ON i.id = a.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY tasa_asistencia DESC;

-- 85. Trainers con mayor participación en proyectos
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(p.id) as total_proyectos,
    COUNT(DISTINCT p.inscripcion_id) as estudiantes_con_proyectos,
    ROUND(AVG(p.nota), 2) as promedio_proyectos
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN proyectos p ON i.id = p.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_proyectos DESC;

-- 86. Trainers con mayor participación en foros
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(f.id) as total_foros,
    COUNT(c.id) as total_comentarios,
    COUNT(DISTINCT c.camper_id) as estudiantes_participantes
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN foros f ON i.id = f.inscripcion_id
JOIN comentarios c ON f.id = c.foro_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_comentarios DESC;

-- 87. Trainers con mayor uso de recursos
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(rm.id) as total_recursos,
    COUNT(DISTINCT rm.inscripcion_id) as estudiantes_utilizando,
    GROUP_CONCAT(DISTINCT rm.tipo_recurso) as tipos_recursos
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN recursos_modulo rm ON i.id = rm.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_recursos DESC;

-- 88. Trainers con mayor satisfacción de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 80 THEN 1 END) as excelentes,
    COUNT(CASE WHEN e.nota BETWEEN 60 AND 79 THEN 1 END) as buenos,
    COUNT(CASE WHEN e.nota < 60 THEN 1 END) as deficientes
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY promedio DESC;

-- 89. Trainers con mayor progreso de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(DISTINCT i.camper_id) as total_estudiantes,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as estudiantes_aprobados,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as tasa_progreso
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY tasa_progreso DESC;

-- 90. Trainers con mayor retención de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(i.id) as total_inscritos,
    COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) as inscritos_activos,
    ROUND(COUNT(CASE WHEN i.estado = 'Activa' THEN 1 END) * 100.0 / 
          COUNT(i.id), 2) as tasa_retencion
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY tasa_retencion DESC;

-- 91. Trainers con mayor diversidad de estudiantes
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(DISTINCT c.ciudad_id) as total_ciudades,
    COUNT(DISTINCT c.id) as total_estudiantes,
    GROUP_CONCAT(DISTINCT ci.nombre) as ciudades
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN campers c ON i.camper_id = c.id
JOIN ciudades ci ON c.ciudad_id = ci.id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_ciudades DESC;

-- 92. Trainers con mayor participación en actividades
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(a.id) as total_actividades,
    COUNT(DISTINCT a.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(a.nota), 2) as promedio_actividades
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN actividades a ON i.id = a.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_actividades DESC;

-- 93. Trainers con mayor uso de soporte
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(s.id) as total_soportes,
    COUNT(DISTINCT s.inscripcion_id) as estudiantes_solicitantes,
    GROUP_CONCAT(DISTINCT s.tipo_soporte) as tipos_soporte
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN soportes s ON i.id = s.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_soportes DESC;

-- 94. Trainers con mayor eficiencia
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(DISTINCT i.camper_id) as total_estudiantes,
    COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) as estudiantes_aprobados,
    ROUND(AVG(e.nota), 2) as promedio,
    ROUND(COUNT(DISTINCT CASE WHEN e.nota >= 60 THEN i.camper_id END) * 100.0 / 
          COUNT(DISTINCT i.camper_id), 2) as eficiencia
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY eficiencia DESC;

-- 95. Trainers con mayor participación en proyectos grupales
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(pg.id) as total_proyectos_grupales,
    COUNT(DISTINCT pg.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(pg.nota), 2) as promedio_proyectos
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN proyectos_grupales pg ON i.id = pg.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_proyectos_grupales DESC;

-- 96. Trainers con mayor participación en hackathons
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(h.id) as total_hackathons,
    COUNT(DISTINCT h.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(h.nota), 2) as promedio_hackathons
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN hackathons h ON i.id = h.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_hackathons DESC;

-- 97. Trainers con mayor participación en workshops
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(w.id) as total_workshops,
    COUNT(DISTINCT w.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(w.nota), 2) as promedio_workshops
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN workshops w ON i.id = w.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_workshops DESC;

-- 98. Trainers con mayor participación en mentorías
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(m.id) as total_mentorias,
    COUNT(DISTINCT m.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(m.nota), 2) as promedio_mentorias
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN mentorias m ON i.id = m.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_mentorias DESC;

-- 99. Trainers con mayor participación en eventos especiales
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(ee.id) as total_eventos,
    COUNT(DISTINCT ee.inscripcion_id) as estudiantes_participantes,
    ROUND(AVG(ee.nota), 2) as promedio_eventos
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN eventos_especiales ee ON i.id = ee.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY total_eventos DESC;

-- 100. Trainers con mejor rendimiento general
SELECT 
    t.nombres,
    t.apellidos,
    COUNT(DISTINCT i.camper_id) as total_estudiantes,
    COUNT(e.id) as total_evaluaciones,
    ROUND(AVG(e.nota), 2) as promedio,
    COUNT(CASE WHEN e.nota >= 60 THEN 1 END) as aprobados,
    ROUND(COUNT(CASE WHEN e.nota >= 60 THEN 1 END) * 100.0 / COUNT(e.id), 2) as tasa_aprobacion,
    ROUND(AVG(CASE WHEN a.estado = 'Presente' THEN 1 ELSE 0 END) * 100, 2) as tasa_asistencia
FROM trainers t
JOIN asignaciones_trainers at ON t.id = at.trainer_id
JOIN inscripciones i ON at.ruta_id = i.ruta_id
JOIN evaluaciones e ON i.id = e.inscripcion_id
JOIN asistencias a ON i.id = a.inscripcion_id
WHERE at.estado = 'Activa'
GROUP BY t.id, t.nombres, t.apellidos
ORDER BY promedio DESC, tasa_aprobacion DESC, tasa_asistencia DESC; 