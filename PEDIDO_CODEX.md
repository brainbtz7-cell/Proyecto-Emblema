# Pedido para Codex: guardado de partida, parte visual e interfaz

Trabajás en la carpeta `JUEGO EMI`, rama `main`. Claude trabaja en paralelo
en `JUEGO EMI-claude` (rama `claude`). Leé primero `AGENTS.md`, `TRASPASO.md`
y `LEEME.md`.

## 1. Guardar y cargar partida

- Autoload nuevo `Guardado` en `nucleo/guardado.gd`, con `guardar()`,
  `cargar()` y `hay_partida()`. Archivo en `user://`, con número de versión.
- Guardar: estado y avance de cada encargo, posición segura del protagonista
  y el resto del progreso que ya exista. Para la Fauna Anómala, Claude deja
  `FaunaAnomala.a_diccionario()` y `FaunaAnomala.desde_diccionario(datos)`
  (funciones estáticas de la clase `FaunaAnomala`): guardalas y cargalas así.
- Guardado automático al aceptar, cumplir o entregar un encargo y al cerrar
  el juego; en el menú de pausa, "Guardar" y "Borrar partida".
- Cada sistema expone `a_diccionario()` / `desde_diccionario()`; el guardado
  no conoce sus detalles internos.

## 2. Parte visual e interfaz


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
