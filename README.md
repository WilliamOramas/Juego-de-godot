# Vital Pixel

**Vital Pixel** es un videojuego educativo interactivo en 2D desarrollado en el motor **Godot Engine 4**. Su propósito principal es la enseñanza y difusión de conceptos básicos de primeros auxilios de una manera dinámica, interactiva y gamificada.

Este proyecto está especialmente diseñado para estudiantes universitarios de la **UNEFA (Punto Fijo)**, buscando cerrar la brecha del aprendizaje puramente teórico ante situaciones de emergencia reales.

---

## 👥 Equipo de Desarrollo
* **William Oramas**
* **Enmanuel Bracho**
* **Oscar Petit**
* **Javier Garcia**
* **Jose Manzanares**

---

## 🎯 Contexto del Proyecto

### El Problema
A pesar de la importancia que tienen los primeros auxilios para la vida cotidiana, los estudiantes universitarios presentan deficiencias en este ámbito debido a que su enseñanza suele ser teórica, aburrida y con poca práctica. **Vital Pixel** propone el uso de la gamificación para mejorar la retención de información y preparar a los estudiantes para actuar ante emergencias reales.

### Objetivo
Desarrollar un videojuego interactivo con Inteligencia Artificial para enseñar conceptos básicos de primeros auxilios. Los objetivos específicos incluyen:
1. Diagnosticar las necesidades de los alumnos.
2. Definir los requerimientos del sistema.
3. Diseñar las mecánicas del juego (mini-juegos, toma de decisiones).
4. Crear un prototipo funcional (demo de ~25 minutos).

---

## 🛠️ Tecnologías y Requisitos
* **Motor:** Godot Engine 4.x
* **Lenguaje:** GDScript
* **Dimensión:** 2D
* **Plataforma:** PC / Web (Demo)

---

## 📚 Documentación

La documentación completa está dividida en partes en la carpeta [`docs/`](docs/README.md):

1. [Introducción](docs/01-introduccion.md)
2. [Instalación y configuración](docs/02-instalacion-y-configuracion.md)
3. [Arquitectura de software](docs/03-arquitectura-software.md)
4. [Base de datos](docs/04-base-de-datos.md)
5. [Integración Supabase](docs/05-integracion-supabase.md)
6. [Sistemas del juego](docs/06-sistemas-del-juego.md)
7. [Pruebas unitarias](docs/07-pruebas.md)
8. [Guía de presentación académica](docs/08-guia-presentacion.md)

---

## 🚀 Cómo Iniciar el Proyecto
1. Descarga e instala **Godot Engine 4** (versión recomendada: 4.2+ o compatible con GL Compatibility).
2. Clona este repositorio o descarga los archivos:
   ```bash
   git clone https://github.com/WilliamOramas/Juego-de-godot.git
   ```
3. Abre el **Godot Project Manager**, haz clic en **Import** (Importar) y selecciona el archivo `project.godot` en la carpeta raíz del proyecto.
4. Presiona **F5** (o el botón de reproducir en la esquina superior derecha) para ejecutar la demo del juego.

---

## 📐 Arquitectura del Proyecto

Este proyecto utiliza una **Arquitectura Orientada a Funcionalidades (Feature-Oriented Architecture)**, la cual está diseñada para optimizar la modularidad y escalabilidad en Godot Engine 4.

### Estructura de Carpetas

La estructura de directorios del proyecto se organiza de la siguiente manera:

```text
res://
├── src/                     # Código fuente y recursos del juego
│   ├── core/                # Sistemas centrales (managers, infraestructura, modelos)
│   ├── features/            # Funcionalidades del juego (niveles, minijuegos, menús, quests)
│   └── shared/              # Elementos compartidos (entidades, UI, componentes, assets, fuentes)
├── tests/                   # Pruebas unitarias en GDScript
├── tools/                   # Herramientas externas (scripts en Node.js, db)
├── config.cfg               # Configuración global (Supabase, IA)
├── project.godot            # Archivo de configuración del proyecto Godot
└── README.md                # Documentación del proyecto
```

### Ventajas de este Diseño
1. **Modularidad y Cohesión:** El código específico de una funcionalidad vive aislado en `features/`, mientras que la base sólida vive en `core/`. Esto asegura que los subsistemas no se entrelacen (cero "código espagueti").
2. **Reutilización Clara:** Todo lo que se repite en múltiples niveles o minijuegos (como NPCs, botones o utilidades) se centraliza en `shared/`.
3. **Escalabilidad:** Separar lógica de negocio, interfaz de usuario e infraestructura facilita que el proyecto crezca orgánicamente y que múltiples desarrolladores trabajen sin crear conflictos.

---

## 🤖 Habilidades de Asistencia de IA (Skills)

Para el desarrollo y mantenimiento de este código se han incorporado las siguientes herramientas de soporte en el agente de IA:
* **`godot-gdscript-patterns`**: Una guía de patrones de producción especializada en Godot 4.x (abarcando máquinas de estado, singletons, Event Bus, componentes de daño/vida y optimización).
* **`caveman-commit`**: Un generador optimizado y comprimido de mensajes de commit para registrar de forma clara y estricta el avance en el control de versiones.

