# Reglas para agentes de IA (Codex, Claude y otros)

Este proyecto es **Proyecto Emblema**, un RPG en Godot 4.7. Lo trabajan dos
personas con ayuda de varias IA a la vez. Estas reglas valen para todas.

## Antes de empezar

1. Leer `TRASPASO.md` (estado, arquitectura, trampas conocidas) y `LEEME.md`.
2. El diseño vive en el Documento Maestro, fuera del repositorio:
   `/Users/brianbenitez/Downloads/Proyecto_Emblema_Documento_Maestro.docx`
   (se lee con `textutil -convert txt -stdout <ruta>`). Si no está en esta
   máquina, pedírselo a la persona.

## Reglas del canon (obligatorias)

- No completar huecos del diseño por inferencia: lo "pendiente" sigue pendiente.
- Lo que se cree sin respaldo del documento es un **marcador de posición** y se
  anota en "Qué es provisional" del `LEEME.md`.
- Ante una contradicción del documento, frenar y preguntarle a la persona.
- No modificar el Documento Maestro salvo pedido expreso.
- El protagonista no muestra piernas ni cola (decisión pendiente del equipo).

## Trabajo en paralelo con Git

- Cada IA trabaja en **su propia carpeta y su propia rama**:
  - `JUEGO EMI` (rama `main`): Codex y la versión unida.
  - `JUEGO EMI-claude` (rama `claude`): Claude.
- No editar archivos de la carpeta de otra IA.
- Antes de empezar una tarea, traer lo último de `main`
  (`git merge main` desde la rama propia).
- Una tarea = un commit (o pocos) con mensaje claro en español.
- **Evitar tocar a la vez** los archivos que se mezclan mal:
  `project.godot`, `mundo/terreno_de_prueba.tscn` y cualquier `.tscn` grande.
  Si una tarea los necesita, avisarlo en el mensaje del commit.
- No subir a GitHub ni unir ramas sin que la persona lo pida.
- Antes de unir, cada una hace commit de su trabajo.

## Estilo de código

- Todo en español: nodos, scripts, variables, señales y comentarios. Sin
  acentos ni ñ en los identificadores; sí en comentarios y textos.
- GDScript con tipos (`:=` o anotaciones). Comentarios `##` en lo exportado.
- Valores ajustables con `@export` para que se editen en el Inspector.

## Verificar antes de dar algo por terminado

    G=/Applications/Godot.app/Contents/MacOS/Godot
    "$G" --headless --path . --import 2>&1 | grep -c -E "ERROR|WARNING"   # debe dar 0
    "$G" --path . -s herramientas/captura.gd -- <carpeta_salida> prueba   # movimiento
    "$G" --path . -s herramientas/captura.gd -- <carpeta_salida> encargo  # encargos

Los modos y lo que imprime cada uno están en `TRASPASO.md`.
