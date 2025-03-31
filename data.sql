-- Insertar Tipos de Documento
INSERT INTO tipos_documento (nombre, descripcion) VALUES
('Cédula de Ciudadanía', 'Documento de identidad colombiano'),
('Tarjeta de Identidad', 'Documento de identidad para menores'),
('Cédula de Extranjería', 'Documento para extranjeros');

-- Insertar Ciudades
INSERT INTO ciudades (nombre, codigo_dane) VALUES
('Bogotá', '11001'),
('Medellín', '05001'),
('Cali', '76001'),
('Barranquilla', '08001');

-- Insertar Rutas de Entrenamiento
INSERT INTO rutas (nombre, descripcion, duracion_meses) VALUES
('Fundamentos de Programación', 'Ruta de introducción a la programación', 2),
('Programación Web', 'Ruta de desarrollo web frontend', 3),
('Programación Formal', 'Ruta de programación orientada a objetos', 3),
('Bases de Datos', 'Ruta de gestión de bases de datos', 2),
('Backend Development', 'Ruta de desarrollo backend', 4);

-- Insertar Categorías de Módulos
INSERT INTO categorias_modulos (nombre, descripcion) VALUES
('Fundamentos', 'Conceptos básicos y fundamentales'),
('Frontend', 'Desarrollo de interfaz de usuario'),
('Backend', 'Desarrollo del lado del servidor'),
('Bases de Datos', 'Gestión y manipulación de datos');

-- Insertar Módulos
INSERT INTO modulos (ruta_id, categoria_id, nombre, descripcion, duracion_horas, orden) VALUES
(1, 1, 'Introducción a la Algoritmia', 'Conceptos básicos de algoritmos', 40, 1),
(1, 1, 'PSeInt', 'Programación estructurada con PSeInt', 40, 2),
(1, 1, 'Python Básico', 'Fundamentos de Python', 40, 3),
(2, 2, 'HTML5', 'Estructura y semántica web', 40, 1),
(2, 2, 'CSS3', 'Estilos y diseño web', 40, 2),
(2, 2, 'Bootstrap', 'Framework CSS', 40, 3),
(3, 3, 'Java', 'Programación en Java', 60, 1),
(3, 3, 'JavaScript', 'Programación en JavaScript', 60, 2),
(3, 3, 'C#', 'Programación en C#', 60, 3);

-- Insertar Bases de Datos por Ruta
INSERT INTO bases_datos_rutas (ruta_id, sgdb_principal, sgdb_alternativo) VALUES
(4, 'MySQL', 'PostgreSQL'),
(4, 'MongoDB', 'MySQL'),
(4, 'PostgreSQL', 'MongoDB');

-- Insertar Áreas de Entrenamiento
INSERT INTO areas_entrenamiento (nombre, descripcion, capacidad_maxima) VALUES
('Área 1', 'Sala de programación básica', 33),
('Área 2', 'Sala de desarrollo web', 33),
('Área 3', 'Sala de bases de datos', 33),
('Área 4', 'Sala de programación avanzada', 33);

-- Insertar Tipos de Trainer
INSERT INTO tipos_trainer (nombre, descripcion) VALUES
('Trainer Principal', 'Trainer con experiencia completa'),
('Trainer Asistente', 'Trainer en formación'),
('Trainer Especialista', 'Trainer experto en área específica');

-- Insertar Trainers
INSERT INTO trainers (tipo_documento_id, identificacion, nombres, apellidos, email, telefono, tipo_trainer_id, especialidad) VALUES
(1, 'T001', 'Juan', 'Pérez', 'juan.perez@campuslands.com', '3001234567', 1, 'Frontend Development'),
(1, 'T002', 'María', 'González', 'maria.gonzalez@campuslands.com', '3002345678', 1, 'Backend Development'),
(1, 'T003', 'Carlos', 'Rodríguez', 'carlos.rodriguez@campuslands.com', '3003456789', 1, 'Bases de Datos'),
(1, 'T004', 'Ana', 'Martínez', 'ana.martinez@campuslands.com', '3004567890', 2, 'Programación Formal');

-- Insertar Campers
INSERT INTO campers (tipo_documento_id, identificacion, nombres, apellidos, fecha_nacimiento, ciudad_id, direccion, acudiente, telefono_contacto, email, estado, nivel_riesgo) VALUES
(1, 'C001', 'Pedro', 'Ramírez', '2000-01-15', 1, 'Calle 123 #45-67', 'María Ramírez', '3001234567', 'pedro.ramirez@email.com', 'Inscrito', 'Bajo'),
(1, 'C002', 'Laura', 'Sánchez', '2001-03-20', 2, 'Avenida 89 #12-34', 'Juan Sánchez', '3002345678', 'laura.sanchez@email.com', 'Cursando', 'Medio'),
(1, 'C003', 'Diego', 'López', '1999-07-10', 3, 'Carrera 56 #78-90', 'Ana López', '3003456789', 'diego.lopez@email.com', 'Aprobado', 'Bajo');

-- Insertar Asignaciones de Trainers
INSERT INTO asignaciones_trainers (trainer_id, ruta_id, fecha_inicio, fecha_fin, estado) VALUES
(1, 2, '2024-01-01', '2024-06-30', 'Activa'),
(2, 5, '2024-01-01', '2024-06-30', 'Activa'),
(3, 4, '2024-01-01', '2024-06-30', 'Activa');

-- Insertar Inscripciones
INSERT INTO inscripciones (camper_id, ruta_id, fecha_inscripcion, fecha_inicio, fecha_fin_esperada, estado) VALUES
(1, 1, '2024-01-15', '2024-02-01', '2024-03-31', 'Activa'),
(2, 2, '2024-01-15', '2024-02-01', '2024-04-30', 'Activa'),
(3, 3, '2024-01-15', '2024-02-01', '2024-04-30', 'Activa');

-- Insertar Tipos de Evaluación
INSERT INTO tipos_evaluacion (nombre, descripcion, porcentaje) VALUES
('Evaluación Teórica', 'Prueba de conocimientos teóricos', 30.00),
('Evaluación Práctica', 'Prueba de habilidades prácticas', 60.00),
('Trabajos y Quizzes', 'Evaluación continua', 10.00);

-- Insertar Evaluaciones
INSERT INTO evaluaciones (inscripcion_id, modulo_id, tipo_evaluacion_id, nota, fecha_evaluacion, observaciones) VALUES
(1, 1, 1, 85.00, '2024-02-15', 'Excelente rendimiento'),
(1, 1, 2, 90.00, '2024-02-15', 'Muy bueno en la práctica'),
(2, 4, 1, 75.00, '2024-02-15', 'Necesita reforzar conceptos');

-- Insertar Horarios
INSERT INTO horarios (area_id, trainer_id, dia_semana, hora_inicio, hora_fin, estado) VALUES
(1, 1, 'Lunes', '08:00:00', '12:00:00', TRUE),
(1, 1, 'Martes', '08:00:00', '12:00:00', TRUE),
(2, 2, 'Lunes', '13:00:00', '17:00:00', TRUE);

-- Insertar Asignaciones de Áreas
INSERT INTO asignaciones_areas (inscripcion_id, area_id, fecha_asignacion, fecha_fin, estado) VALUES
(1, 1, '2024-01-15', '2024-03-31', 'Activa'),
(2, 2, '2024-01-15', '2024-04-30', 'Activa'),
(3, 3, '2024-01-15', '2024-04-30', 'Activa');

-- Insertar Asistencias
INSERT INTO asistencias (inscripcion_id, fecha, estado, observaciones) VALUES
(1, '2024-02-15', 'Presente', NULL),
(2, '2024-02-15', 'Ausente', 'No se presentó'),
(3, '2024-02-15', 'Presente', NULL);

-- Insertar Justificaciones
INSERT INTO justificaciones (asistencia_id, motivo, documento_soporte, estado) VALUES
(2, 'Cita médica', 'certificado_medico.pdf', 'Aprobada');

-- Insertar Proyectos
INSERT INTO proyectos (modulo_id, nombre, descripcion, fecha_inicio, fecha_fin, estado) VALUES
(1, 'Calculadora Básica', 'Desarrollo de una calculadora en Python', '2024-02-01', '2024-02-15', TRUE),
(4, 'Portfolio Personal', 'Creación de un portfolio web', '2024-02-01', '2024-02-28', TRUE);

-- Insertar Entregas de Proyectos
INSERT INTO entregas_proyectos (proyecto_id, inscripcion_id, fecha_entrega, nota, observaciones, estado) VALUES
(1, 1, '2024-02-15', 95.00, 'Excelente implementación', 'Calificado'),
(2, 2, '2024-02-28', NULL, NULL, 'Pendiente');

-- Insertar Materiales de Apoyo
INSERT INTO materiales_apoyo (modulo_id, nombre, descripcion, tipo, url, estado) VALUES
(1, 'Guía de Algoritmos', 'Documento guía para algoritmos básicos', 'Documento', 'docs/algoritmos.pdf', TRUE),
(4, 'Tutorial HTML5', 'Video tutorial de HTML5', 'Video', 'videos/html5.mp4', TRUE);

-- Insertar Comentarios
INSERT INTO comentarios (material_id, inscripcion_id, contenido, estado) VALUES
(1, 1, 'Muy útil el material, gracias', TRUE),
(2, 2, '¿Podrían subir más ejemplos?', TRUE); 