# CampusLands ERP - Sistema de Gestión Académica

Este proyecto implementa un sistema de gestión académica para el programa intensivo de programación de CampusLands. El sistema está diseñado para manejar todas las operaciones relacionadas con el seguimiento académico de los campers.

## Estructura del Proyecto

El proyecto está organizado en los siguientes archivos:

- `schema.sql`: Contiene la estructura de la base de datos
- `data.sql`: Contiene datos de ejemplo para todas las tablas
- `README.md`: Este archivo de documentación

## Requisitos del Sistema

- MySQL 8.0 o superior
- Espacio en disco: 1GB mínimo
- Memoria RAM: 4GB mínimo

## Instalación

1. Clonar el repositorio:
```bash
git clone [URL_DEL_REPOSITORIO]
```

2. Importar la base de datos:
```bash
mysql -u [usuario] -p < schema.sql
mysql -u [usuario] -p campuslands_erp < data.sql
```

## Estructura de la Base de Datos

### Tablas Principales

1. **campers**: Almacena la información de los estudiantes
2. **rutas**: Define las rutas de entrenamiento disponibles
3. **modulos**: Contiene los módulos de cada ruta
4. **areas_entrenamiento**: Gestiona las áreas físicas de entrenamiento
5. **trainers**: Almacena la información de los entrenadores
6. **inscripciones**: Registra las inscripciones de los campers
7. **evaluaciones**: Gestiona las evaluaciones de los módulos
8. **horarios**: Controla los horarios de las clases
9. **asignaciones_areas**: Gestiona la asignación de áreas a los campers

## Características Principales

- Gestión completa de campers (inscripción, seguimiento, evaluación)
- Control de rutas de entrenamiento y módulos
- Gestión de áreas de entrenamiento con capacidad máxima
- Sistema de evaluación con componentes teóricos, prácticos y trabajos
- Control de horarios y asignaciones de trainers
- Seguimiento del estado académico de los campers

## Mantenimiento

Para mantener la integridad de los datos:

1. Realizar copias de seguridad diarias
2. Monitorear el espacio en disco
3. Revisar periódicamente los índices de la base de datos
4. Actualizar los datos de contacto de campers y trainers

## Soporte

Para reportar problemas o solicitar soporte, por favor crear un issue en el repositorio del proyecto.

## Licencia

Este proyecto está bajo la licencia [ESPECIFICAR_LICENCIA].