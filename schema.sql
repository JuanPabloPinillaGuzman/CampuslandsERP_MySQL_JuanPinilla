-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS campuslands_erp;
USE campuslands_erp;

-- Tabla de Tipos de Documento
CREATE TABLE tipos_documento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Ciudades
CREATE TABLE ciudades (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    codigo_dane VARCHAR(10),
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Campers
CREATE TABLE campers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_documento_id INT,
    identificacion VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(40) NOT NULL,
    apellidos VARCHAR(40) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    ciudad_id INT,
    direccion TEXT NOT NULL,
    acudiente VARCHAR(40) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    email VARCHAR(60) UNIQUE,
    estado ENUM('En proceso de ingreso', 'Inscrito', 'Aprobado', 'Cursando', 'Graduado', 'Expulsado', 'Retirado') NOT NULL,
    nivel_riesgo ENUM('Alto', 'Medio', 'Bajo') NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documento(id),
    FOREIGN KEY (ciudad_id) REFERENCES ciudades(id)
);

-- Tabla de Rutas de Entrenamiento
CREATE TABLE rutas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    duracion_meses INT NOT NULL,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Categorías de Módulos
CREATE TABLE categorias_modulos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Módulos
CREATE TABLE modulos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ruta_id INT,
    categoria_id INT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    duracion_horas INT NOT NULL,
    orden INT NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (ruta_id) REFERENCES rutas(id),
    FOREIGN KEY (categoria_id) REFERENCES categorias_modulos(id)
);

-- Tabla de Bases de Datos por Ruta
CREATE TABLE bases_datos_rutas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ruta_id INT,
    sgdb_principal ENUM('MySQL', 'MongoDB', 'PostgreSQL') NOT NULL,
    sgdb_alternativo ENUM('MySQL', 'MongoDB', 'PostgreSQL') NOT NULL,
    FOREIGN KEY (ruta_id) REFERENCES rutas(id)
);

-- Tabla de Áreas de Entrenamiento
CREATE TABLE areas_entrenamiento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    capacidad_maxima INT NOT NULL,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Tipos de Trainer
CREATE TABLE tipos_trainer (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Trainers
CREATE TABLE trainers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_documento_id INT,
    identificacion VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(40) NOT NULL,
    apellidos VARCHAR(40) NOT NULL,
    email VARCHAR(60) UNIQUE,
    telefono VARCHAR(20),
    tipo_trainer_id INT,
    especialidad VARCHAR(30) NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documento(id),
    FOREIGN KEY (tipo_trainer_id) REFERENCES tipos_trainer(id)
);

-- Tabla de Asignaciones de Trainers a Rutas
CREATE TABLE asignaciones_trainers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trainer_id INT,
    ruta_id INT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado ENUM('Activa', 'Finalizada', 'Cancelada') NOT NULL,
    FOREIGN KEY (trainer_id) REFERENCES trainers(id),
    FOREIGN KEY (ruta_id) REFERENCES rutas(id)
);

-- Tabla de Inscripciones
CREATE TABLE inscripciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    camper_id INT,
    ruta_id INT,
    fecha_inscripcion DATE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin_esperada DATE NOT NULL,
    estado ENUM('Activa', 'Finalizada', 'Cancelada') NOT NULL,
    FOREIGN KEY (camper_id) REFERENCES campers(id),
    FOREIGN KEY (ruta_id) REFERENCES rutas(id)
);

-- Tabla de Tipos de Evaluación
CREATE TABLE tipos_evaluacion (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    descripcion TEXT,
    porcentaje DECIMAL(5,2) NOT NULL,
    estado BOOLEAN DEFAULT TRUE
);

-- Tabla de Evaluaciones
CREATE TABLE evaluaciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    inscripcion_id INT,
    modulo_id INT,
    tipo_evaluacion_id INT,
    nota DECIMAL(5,2) NOT NULL,
    fecha_evaluacion DATE NOT NULL,
    observaciones TEXT,
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id),
    FOREIGN KEY (modulo_id) REFERENCES modulos(id),
    FOREIGN KEY (tipo_evaluacion_id) REFERENCES tipos_evaluacion(id)
);

-- Tabla de Horarios
CREATE TABLE horarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    area_id INT,
    trainer_id INT,
    dia_semana ENUM('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (area_id) REFERENCES areas_entrenamiento(id),
    FOREIGN KEY (trainer_id) REFERENCES trainers(id)
);

-- Tabla de Asignaciones de Áreas
CREATE TABLE asignaciones_areas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    inscripcion_id INT,
    area_id INT,
    fecha_asignacion DATE NOT NULL,
    fecha_fin DATE,
    estado ENUM('Activa', 'Finalizada') NOT NULL,
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id),
    FOREIGN KEY (area_id) REFERENCES areas_entrenamiento(id)
);

-- Tabla de Asistencias
CREATE TABLE asistencias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    inscripcion_id INT,
    fecha DATE NOT NULL,
    estado ENUM('Presente', 'Ausente', 'Justificado') NOT NULL,
    observaciones TEXT,
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id)
);

-- Tabla de Justificaciones
CREATE TABLE justificaciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    asistencia_id INT,
    motivo TEXT NOT NULL,
    documento_soporte VARCHAR(255),
    fecha_justificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente', 'Aprobada', 'Rechazada') NOT NULL,
    FOREIGN KEY (asistencia_id) REFERENCES asistencias(id)
);

-- Tabla de Proyectos
CREATE TABLE proyectos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    modulo_id INT,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (modulo_id) REFERENCES modulos(id)
);

-- Tabla de Entregas de Proyectos
CREATE TABLE entregas_proyectos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    proyecto_id INT,
    inscripcion_id INT,
    fecha_entrega TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nota DECIMAL(5,2),
    observaciones TEXT,
    estado ENUM('Pendiente', 'Entregado', 'Calificado') NOT NULL,
    FOREIGN KEY (proyecto_id) REFERENCES proyectos(id),
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id)
);

-- Tabla de Materiales de Apoyo
CREATE TABLE materiales_apoyo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    modulo_id INT,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    tipo ENUM('Documento', 'Video', 'Enlace', 'Otro') NOT NULL,
    url VARCHAR(255),
    fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (modulo_id) REFERENCES modulos(id)
);

-- Tabla de Comentarios
CREATE TABLE comentarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT,
    inscripcion_id INT,
    contenido TEXT NOT NULL,
    fecha_comentario TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (material_id) REFERENCES materiales_apoyo(id),
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id)
); 