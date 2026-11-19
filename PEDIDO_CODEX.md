# Pedido para Codex: guardar y cargar partida

Trabajás en la carpeta `JUEGO EMI`, rama `main` (Claude trabaja aparte en `JUEGO EMI-claude`). Leé primero
`AGENTS.md`, `TRASPASO.md` y `LEEME.md`.

## Objetivo

Que la partida se guarde y se pueda continuar al volver a abrir el juego.

## Qué guardar

- Estado y avance de cada encargo (autoload `Encargos`).
- Posición del protagonista (el último lugar seguro, no en el aire ni en el agua).
- Cualquier otro progreso que ya exista en el juego (revisá los autoloads).

## Cómo

- Un autoload nuevo `Guardado` en `nucleo/guardado.gd`, con `guardar()`,
  `cargar()` y `hay_partida()`. Archivo en `user://partida.cfg` o JSON, con un
  número de versión para poder migrarlo en el futuro.
- Guardado automático al aceptar, cumplir o entregar un encargo y al cerrar el
  juego. Si el menú de pausa lo permite sin rehacerlo, agregá "Guardar" y
  "Borrar partida".
- Cada sistema expone sus datos con `a_diccionario()` y `desde_diccionario()`;
  el guardado no debe conocer sus detalles internos.

## Límites (otra IA trabaja en paralelo)

- Claude está haciendo la **Fauna Anómala** en su carpeta (`fauna/`, `nucleo/fauna_anomala.gd`).
  No edites `fauna/`. Si necesitás tocar `nucleo/encargos.gd`, que sea solo
  para agregar `a_diccionario()`/`desde_diccionario()`.
- Evitá tocar `mundo/terreno_de_prueba.tscn`. El registro del autoload en
  `project.godot` sí hace falta: mantené ese cambio mínimo.
- Al terminar: verificá con los comandos de `AGENTS.md`, hacé commit en `main`
  y avisale a la persona. No subas a GitHub sin que te lo pida.
