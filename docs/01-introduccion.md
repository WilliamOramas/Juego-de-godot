# Parte 1 — Introducción

## ¿Qué es Vital Pixel?

**Vital Pixel** es un videojuego educativo 2D desarrollado en **Godot Engine 4** para enseñar primeros auxilios de forma interactiva y gamificada. Está orientado a estudiantes universitarios de la **UNEFA (Punto Fijo)**.

El jugador recorre un entorno escolar, habla con NPCs, completa misiones y practica procedimientos médicos en minijuegos (desmayo, RCP, trivia).

## Problema que aborda

La enseñanza de primeros auxilios suele ser teórica y con poca práctica. El juego busca mejorar la retención mediante:

- Escenarios simulados con consecuencias (vidas, puntaje, desenlace del paciente).
- Minijuegos que reproducen pasos del protocolo de emergencia.
- Registro de progreso local y en la nube (Supabase).

## Objetivos del proyecto

1. Diagnosticar necesidades de aprendizaje en primeros auxilios.
2. Definir requerimientos del sistema (juego + base de datos).
3. Diseñar mecánicas: exploración, diálogos, misiones, minijuegos.
4. Entregar un prototipo jugable (~25 minutos) con persistencia y telemetría.

## Equipo de desarrollo

- William Oramas
- Enmanuel Bracho
- Oscar Petit
- Javier Garcia
- Jose Manzanares

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Motor | Godot 4.6 (GL Compatibility) |
| Lenguaje | GDScript (tipado estático) |
| Backend | Supabase (PostgreSQL + Auth + REST) |
| IA opcional | API externa vía `AiClient` (`ai.cfg`) |
| Demo BD local | SQLite + DB Browser (laboratorio académico) |

## Documentos relacionados

- [Parte 2 — Instalación](02-instalacion-y-configuracion.md)
- [Parte 4 — Base de datos](04-base-de-datos.md)
