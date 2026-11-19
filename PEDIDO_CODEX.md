# Pedido para Codex (ronda 2): interfaz y aspecto visual

Trabajás en la carpeta `JUEGO EMI`, rama `main`. Claude trabaja en paralelo
en `JUEGO EMI-claude` (rama `claude`). Leé primero `AGENTS.md`, `TRASPASO.md`
y `LEEME.md`. Tu trabajo de la ronda 1 (guardado y pulido) ya está en `main`.

## Tareas

1. **Menú principal** al abrir el juego: Continuar (si hay partida), Nueva
   partida (avisando que borra la actual), Controles y Salir. Mismo estilo que
   el menú de pausa.
2. **Plano (tecla M):** agregar Puerto Albor, el Sendero de los Faros y el
   camino nuevo (`HACIA_ALBOR`, `FAROS`, `PUERTO_ALBOR` en
   `mundo/salbruma/trazado_salbruma.gd`).
3. **Ubicación en el seguimiento:** que el título y el primer paso cambien
   según la zona donde está el protagonista (Puerto Junco, Bajíos, Marismas,
   Sendero de los Faros, Puerto Albor). Hoy en Albor dice "Seguí el sendero
   hasta Puerto Junco".
4. **Misiones de La Voz en dorado:** la misión dorada
   (`encargos/la_voz_desenmascara_al_impostor.tres`) y el diálogo de "La Voz"
   tienen que verse distintos (dorado), como pide el Documento Maestro.
   Si hace falta, agregá un campo `de_la_voz := false` a `nucleo/encargo.gd`.
5. **Revisión gráfica:** abrí el juego con ventana, sacá capturas de cada
   pantalla de la interfaz y corregí lo que se vea mal (textos cortados,
   paneles superpuestos, contraste).

## Fuera de tu área (lo hace Claude ahora)

- `mundo/salbruma/` (terreno, elementos, trazado: solo leerlo), `fauna/`,
  `encargos/` nuevos de Puerto Albor, `nucleo/sonido.gd`, `sonido/`.

## Cómo trabajar

- No toques las escenas grandes de `mundo/` salvo lo mínimo.
- Verificá con los comandos de `AGENTS.md` y con tus pruebas de `herramientas/`.
- Si no podés hacer commit, dejá los cambios sin guardar: Claude los guarda.
  No subas a GitHub.
- Al final resumí en español qué hiciste y qué no pudiste.

## Estado (actualizado por Claude)

La ronda 2 está terminada y la rama `claude` ya está unida a `main`.
Las próximas tareas están en `CONTINUAR_CON_CODEX.md`. Desde ahora Codex
trabaja solo, siempre en esta carpeta (`JUEGO EMI`, rama `main`).
