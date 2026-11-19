# Cómo seguir solo con Codex

Escrito por Claude el 19 de noviembre de 2026, antes de quedarse sin créditos.
Leé también `AGENTS.md`, `TRASPASO.md` y `LEEME.md`.

## Dónde trabajar

- **Una sola carpeta:** `Proyectos/JUEGO EMI` (rama `main`). Todo lo de Claude
  ya está unido ahí.
- La carpeta `JUEGO EMI-claude` (rama `claude`) era la de Claude. Ya no hace
  falta: no la edites. Se puede borrar con `git worktree remove "../JUEGO EMI-claude"`.
- Hacé commit en `main` al terminar cada tarea. Para subir a GitHub:
  `git push origin main`.

## Qué dejó hecho Claude en esta sesión

- **Fauna Anómala** (`nucleo/fauna_anomala.gd`, `fauna/rasgo_anomalo.gd`,
  `fauna/aviso_anomalo.gd`). Probar con `-- --anomalia-forzada`.
- **Sonido provisional** (`nucleo/sonido.gd`, `sonido/`, generados con
  `herramientas/generar_sonidos.py`).
- **Viaje a Puerto Albor**: misión dorada *Desenmascara al impostor*, Sendero
  de los Faros, pueblo y muelle (`mundo/salbruma/mision_de_la_voz.gd`,
  `trazado_salbruma.gd`, `elementos_de_salbruma.gd`). Probado con
  `herramientas/prueba_albor.gd`.
- **Primera tanda de Puerto Albor — PROBADA DE PUNTA A PUNTA:**
  - `encargos/puerto_albor_gruta_olvidada.tres` (Habitante de Albor): la gruta
    del Sendero de los Faros, bloqueada hasta aceptar el encargo
    (`mundo/bloqueo_de_encargo.gd`); se cumple al llegar al fondo
    (`mundo/salbruma/fondo_de_la_gruta.gd`).
  - `encargos/puerto_albor_arena.tres` (Barquero): bote desde el muelle de
    Albor al Cayo de Salcristal (`mundo/bote_de_viaje.gd`) y 3 montículos de
    arena especial (`mundo/arena_especial.tscn`, `mundo/recolectable.gd`).
  - `encargos/puerto_albor_caparazones.tres` (Pescadora): 5 caparazones de
    Krabchio (`fauna/krabchio.tscn`, modelo provisional) en el cayo.
  - El cayo es un islote en el río (`_cayo` en `terreno_salbruma.gd`).

## Próximas tareas para Codex (en orden)

1. **Probar la primera tanda de Albor de punta a punta** y corregir lo que
   falle: escribir `herramientas/prueba_albor_encargos.gd` (podés copiar
   `prueba_albor.gd` y las funciones de combate de `captura.gd`). Revisar:
   que los tres habitantes ofrezcan sus encargos tras la misión dorada, que el
   bote lleve y traiga, que los Krabchio se puedan cazar y den caparazones,
   que la arena solo aparezca con el encargo activo, que la gruta se abra al
   aceptar y que el fondo cuente. Sacar capturas y mirar que el islote, el
   muelle del cayo y la gruta se vean bien.
2. **Segunda parte de Albor** (Documento Maestro, apartado 9.7): *Dudas
   razonables* (hablar con tres habitantes), *El testigo silenciado* (víctima en
   la isla, sicario, nota, acusación y huida a Junco), *Echa luz sobre tanta
   oscuridad* (en los tablones de ambos pueblos, con el jefe pesquero) y *El
   rostro del engaño* (confrontar al profeta; al derrotarlo se esfuma). Al
   terminar, la misión dorada pasa a *Desentraña los misterios de la montaña*.
   Usar solo lo que dice el documento; lo demás, como provisional.
3. Lo que quede de la ronda 2 de interfaz (`PEDIDO_CODEX.md`).

## Lo provisional que no hay que tomar como canon

Textos de los encargos de Albor (el documento no trae sus diálogos), cantidad
de arena (3), nombres "Barquero" y "Pescadora", modelo del Krabchio, la gruta,
los faros, las casas, el texto de La Voz y los sonidos. Todo eso está anotado
para reemplazarlo cuando el equipo lo defina.

## Avance de Codex — tarea 1 terminada, 19/11/2026

`herramientas/prueba_albor_encargos.gd` verifica ofertas simultáneas, viaje
ida y vuelta, bloqueo de controles durante la travesía, arena única tras
guardar/cargar, cinco cacerías y entregas, y entrada física a la gruta.
Se corrigieron el duplicado de arena al cargar y la posibilidad de repetir
la travesía durante su fundido. Importación sin errores ni advertencias,
movimiento y encargo de Junco comprobados. Las capturas del islote, muelle
y gruta se generaron con ventana y se revisaron. Sigue la tarea 2.
