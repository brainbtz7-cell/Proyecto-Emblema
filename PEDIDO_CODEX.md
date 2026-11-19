# Pedido para Codex: parte visual e interfaz

Trabajás en la carpeta `JUEGO EMI`, rama `main`. Claude trabaja en paralelo
en `JUEGO EMI-claude` (rama `claude`). Leé primero `AGENTS.md`, `TRASPASO.md`
y `LEEME.md`.

## Tu área

Todo lo visual y la interfaz:

- `interfaz/` (HUD, seguimiento, diálogos, combate, menú de pausa, mapa,
  `tema.tres`, fuentes).
- Pulido visual: menús, transiciones, legibilidad, íconos, animaciones de la
  interfaz, consistencia del estilo pixel 3D.
- Shaders y aspecto de escenarios si hace falta (`shaders/`, materiales).

## Fuera de tu área (lo hace Claude)

- **Fauna Anómala**: `fauna/`, `nucleo/fauna_anomala.gd` y su propio aviso en
  pantalla. No edites esos archivos.
- Lógica de juego (`nucleo/encargos.gd`, `jugador/jugador.gd`): si un cambio
  visual la necesita, que sea mínimo y avisalo en el commit.

## Cómo trabajar

- Evitá tocar `project.godot` y las escenas grandes de `mundo/` salvo que sea
  imprescindible.
- Verificá con los comandos de `AGENTS.md` y hacé commit en `main` al terminar
  cada mejora. No subas a GitHub sin que la persona lo pida.
