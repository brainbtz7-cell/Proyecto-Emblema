# Cómo seguir solo con Codex

Escrito por Claude el 19 de noviembre de 2026, antes de quedarse sin créditos.
Leé también `AGENTS.md`, `TRASPASO.md` y `LEEME.md`.

## Dónde trabajar

- **Codex:** `Proyectos/JUEGO EMI` (rama `main`).
- **Claude volvió a trabajar** en `JUEGO EMI-claude` (rama `claude`): no la
  edites ni la borres. La persona decide cuándo unir `claude` a `main`.
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

Las tareas 1 (prueba de la primera tanda) y 2 (investigación de Albor) están
terminadas; ver los avances al final.

1. **Plano y diario con lo de Albor** (lo que encontró la auditoría de interfaz
   de Codex): `interfaz/mapa_de_salbruma.gd` manda a Junco todos los encargos
   cumplidos, también los de Albor; el centro del Cayo queda fuera del borde
   norte del plano; faltan los destinos de la gruta, la arena, los Krabchio y
   los pasos de la investigación (cuerpo en el cayo, portón del líder).
   `herramientas/prueba_interfaz.gd` informa cuatro instancias ObjectDB sin
   liberar al cerrar.
2. **Lo que sigue en la historia** (trayecto a Riscabruna, el bardo y la ciudad
   minera) tiene muchos pendientes en el Documento Maestro: nombre y diseño del
   bardo y los siete encargos de la ciudad minera. Preguntarle a la persona
   antes de construirlo.

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

## Tarea 2 terminada — 19/11/2026 (empezada por Codex, terminada por Claude)

Codex dejó armada la investigación sin commit cuando se le acabó el cupo; Claude
la terminó en la rama `claude`. Detalle en `LEEME.md`, sección "Investigación
de Puerto Albor".

- Lógica en `mundo/salbruma/intriga_de_albor.gd`; figuras en
  `personajes/personaje_de_intriga.gd`; cinco encargos nuevos en `encargos/`.
- La misión dorada *Desenmascara al impostor* ya no se cierra al llegar a Albor:
  se cierra al vencer al profeta. Los tres encargos de la primera tanda ahora
  piden *La última marea* en vez de la misión dorada.
- Arreglos de Claude sobre lo de Codex: el jefe acompañante ya no choca con la
  cámara ni tapa las conversaciones; el patio del líder se movió para no pisar
  el camino ni el cartel, sus muros siguen la pendiente (no flotan) y tienen
  portón con los tres habitantes delante; el líder se ve desde el principio y no
  repite frases equivocadas; la víctima y la nota no giran ni bloquean.
- Interfaz: `Encargo.indicaciones_por_paso` (pista distinta en cada paso), el
  seguimiento muestra el encargo local antes que la misión dorada, y el
  seguimiento reconoce el Cayo de Salcristal.
- `herramientas/prueba_intriga_albor.gd` pasa sin ventana y con ventana; todas
  las pruebas anteriores también.
