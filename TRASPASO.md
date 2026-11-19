# Traspaso — Proyecto Emblema (prototipo en Godot)

Estado actualizado al 19 de noviembre de 2026. Este documento es para quien continúe el
trabajo, sea persona o IA. Para uso diario del proyecto (controles, carpetas,
cómo agregar un encargo o un árbol) está `LEEME.md`.

## 1. Qué es

Prototipo de un RPG por turnos con exploración en tercera persona, hecho por
dos amigos. El diseño vive en el **Documento Maestro**, fuera de esta carpeta:

    /Users/brianbenitez/Downloads/Proyecto_Emblema_Documento_Maestro.docx

Se lee con `textutil -convert txt -stdout <ruta>`. La versión leída fue la 35
(12 de septiembre de 2026); conviene releerlo antes de trabajo de contenido,
porque puede haber una más nueva.

- Motor: **Godot 4.7.2**, en `/Applications/Godot.app`. Render Forward+, física Jolt.
- Estilo: **"pixel 3D"**: mundo 3D dibujado a unos 270 píxeles de alto y
  ampliado sin suavizado, con luz por bandas y colores decididos por téxel.
- Idioma: todo en español (nodos, scripts, variables, comentarios), sin
  acentos ni ñ en los identificadores.
- Hay repositorio Git: Codex trabaja en `main` y Claude en su carpeta y rama `claude`.

## 2. Reglas del canon (obligatorias)

Las impone el propio Documento Maestro:

1. No completar huecos por inferencia: lo "pendiente" sigue pendiente.
2. No registrar como canon nada que el usuario no haya aceptado.
3. Ante una contradicción, frenar y preguntarle al usuario.
4. Actualizar el Documento Maestro solo si el usuario lo pide expresamente.

En la práctica: todo lo que se cree sin respaldo del documento se nombra y se
presenta como **marcador de posición** o **prueba**, y se anota en la sección
"Qué es provisional" del `LEEME.md`.

**Decisión ya tomada por el usuario:** el documento dice que los Neptunos
conservan siempre la cola, pero el juego transcurre en tierra y con saltos.
Consultado, el usuario eligió "túnica larga, sin decidir". El protagonista
**no debe mostrar piernas ni cola** hasta que el usuario lo resuelva.

## 3. Qué está hecho

| Área | Estado |
| --- | --- |
| Render pixel 3D | Autoload `Pixelado`; F2/F3 cambian el tamaño del píxel. |
| Protagonista | Movimiento relativo a la cámara, carrera con Shift, velocidad que baja al vadear, salto con margen "coyote", doble salto en la isla y retorno desde agua honda. |
| Figura del protagonista | Figura low-poly con túnica cerrada, capa en tres tramos, ojos que parpadean y contorno de un píxel. Animación por fórmulas. |
| Cámara | Orbital con brazo que evita el terreno, zoom, ratón y mando. |
| Primer tramo de Salbruma | Escena principal. Llegada al oeste, Bajíos, Puerto Junco con muelle, Caleta río arriba y Marismas del Caparazón al noroeste. Plano con la posición del jugador en M. |
| Isla de prueba | Terreno generado con ruido, agua con espuma, cielo en bandas, nubes, rocas con recorrido de doble salto. **No es canon.** |
| Vegetación | Árboles por manchones con ventana en la copa. En Salbruma, pasto bajo y alto que ondea y se aparta al paso del protagonista. |
| Interacción | Zonas `Interactuable` + detector en el jugador; aviso "E · acción". |
| Diálogo | Caja con texto letra por letra y opciones. |
| Encargos | Autoload `Encargos`; cada encargo es un `.tres`. |
| Primer encargo | Pescador de Puerto Junco: 7 lomos de Uscita, con el diálogo textual del documento. Jugable de punta a punta. |
| Segundo encargo | Guardia de Puerto Junco: derrotar 7 Asaltantes Klaimyr en la Caleta. Los dos encargos de la primera tanda se juegan en Salbruma y en la isla. |
| Segunda tanda | Disponible al entregar los dos primeros encargos. El jefe pesquero pide levantar tres defensas, y el pescador siete cueros de lagarto armado. |
| Tercera tanda | Emboscada con tres asaltantes, rescate y regreso a pie con el jefe pesquero, y defensa de Junco contra el capitán. El tablón ofrece los dos últimos encargos. |
| Fauna | Uscita en los Bajíos y lagarto acorazado en las Marismas. Las manadas se reponen al volver al poblado. |
| Combate de prueba | En el lugar, 1 contra 1. El rival anuncia una intención según su patrón. Atacar, defender, preparar y huir. Defender una embestida habilita un golpe certero. |
| Agua | Ondas de pisadas y salpicaduras al vadear o caer. La física de las pasarelas y del agua honda se conserva. |

## 4. Qué falta y qué está esperando al usuario

- Queda por definir el formato definitivo del combate y lo que el documento
  deja pendiente: estadísticas, habilidades y las cinco clases. El encuentro
  en el lugar se implementó para ver y probar el flujo.
- La localización definitiva de la emboscada y los detalles del
  enfrentamiento final siguen pendientes en el Documento Maestro.
- Ampliar el recorte jugable a las 16 SubZonas de Tierras de Salbruma y
  dividirlo en etapas. El primer tramo es un escenario continuo.
- Viaje a Puerto Albor para la misión de La Voz que anuncia el cierre de
  La última marea. El tablón de Junco ya sirve para los dos últimos encargos.
  Quedan pendientes la tienda, la forja y la posada.
- Fauna Anómala y guardado implementados. Sonido a cargo de Claude; no tocar
  `sonido/` ni `nucleo/sonido.gd` durante ese trabajo.
- Los jefes deben tener un tope de 15 turnos cuando se implementen.

## 5. Arquitectura

Autoloads, en este orden (`project.godot`):

- `Pixelado` (`nucleo/pixelado.gd`): fija el escalado 3D con vecino más cercano.
- `Encargos` (`nucleo/encargos.gd`): estados DISPONIBLE → ACTIVO → CUMPLIDO → COMPLETADO.
  Los IDs de `requisitos` deben estar COMPLETADO para ofrecer el encargo.
  El segundo argumento de `contar` admite el ID de un punto único.
- `Guardado` (`nucleo/guardado.gd`): JSON versionado en `user://`, respaldo,
  carga con Continuar y guardado al avanzar en encargos o cerrar el juego
  durante una partida. Cada sistema
  expone `a_diccionario()` / `desde_diccionario()`. Los nodos del grupo
  `persistentes` se identifican por su ruta dentro de cada escena. La carga
  en una escena abierta la reconstruye; el rescate retoma junto al protagonista.
- `Interfaz` (`interfaz/interfaz.tscn`): ayuda, seguimiento, aviso,
  `Interfaz.dialogo` e `Interfaz.combate`.

Capas de física 3D: 1 mundo · 2 jugador · 3 interactuables · 4 criaturas ·
5 vegetación. La cámara solo choca con la 1, por eso ignora troncos y animales.

Datos globales de shader (declarados en `project.godot`, sección `shader_globals`):

- `terreno_mapa_altura`, `terreno_origen`, `terreno_paso`, `terreno_puntos`:
  los publica `mundo/terreno.gd`; los usan los shaders de suelo y agua.
- `protagonista` (vec4: posición + radio): lo publica la cámara; lo usa el
  follaje para abrir la ventana.
- `rival_de_combate` (vec4 con la posición de los pies y el radio del claro)
  permite que el shader incline el pasto entre ambos combatientes durante el duelo.

Piezas principales:

- `jugador/jugador.gd` mueve; `jugador/figura.gd` dibuja y anima. Se hablan
  con `animar(...)`, `al_saltar()`, `al_doble_salto()` y `al_aterrizar()`.
- `personajes/aldeano.tscn` aporta la figura low-poly del jefe pesquero en
  Junco y en el rescate. `personajes/capitan_klaimyr.tscn` deriva su figura
  del asaltante Klaimyr. La prueba de Meshy quedó en `arte_fuente/personajes/`.
- `mundo/terreno.gd` (`@tool`): malla, colisión y mapa de altura. Emite
  `generado`. `altura_en(x, z)` da la altura sin usar física.
- `interfaz/menu_principal.tscn` abre `mundo/salbruma/salbruma.tscn` al
  continuar o empezar una partida. El trazado fija
  los hitos y senderos. `terreno_salbruma.gd` crea el relieve y la máscara
  de suelo, y `elementos_de_salbruma.gd` añade puentes, casas y muelle.
  `interfaz/mapa_de_salbruma.gd` dibuja el plano a partir de ese relieve.
- `pasto_de_salbruma.gd` agrupa las matas en lotes `MultiMesh` sin colisión.
  `shaders/pasto.gdshader` usa la posición del protagonista para doblar
  las puntas. Las raíces quedan en su lugar.
- `defensa_de_junco.tscn` es el acopio reutilizable. Cada instancia tiene
  una `clave` distinta. Al construir cambia de modelo, queda sólida y deja
  de aparecer en el plano de M. El estado de cada punto se conserva en la partida.
- `encuentro_de_junco.gd` activa los rivales de la emboscada y del ataque
  final solo con su encargo en curso. El capitán usa `limite_de_turnos`.
  `rescate_de_junco.gd` alterna la presencia del jefe y lo guía por las
  huellas del protagonista de vuelta a Junco.
- `mundo/agua_con_pisadas.gd` toma la posición de los pies y la altura real
  del suelo. Publica ocho impactos a `agua.gdshader` y emite las gotas.
- `mundo/arboleda.gd` (`@tool`): planta árboles usando `terreno.altura_en`.
- `nucleo/suelo.gd`: altura del suelo por rayo de física (solo en juego).
- `personajes/dador_de_encargos.gd`: ofrece su lista de encargos en orden.
- `fauna/criatura_de_prueba.gd`: paseo e inicio del combate por interacción
  (Uscita) o por cercanía y nivel (Klaimyr). La victoria avisa a
  `Encargos` antes de retirar a la criatura. `Manada` reparte y repone al
  regresar a la zona de `mundo/poblado.gd`.
- `nucleo/maniobras_de_combate.gd`: patrones por rival y reglas de daño.
  `interfaz/combate_de_prueba.gd`: turnos, pronóstico, vida y resultados.
  `efectos/gestos_de_combate.gd`: postura, embestidas, chispas y números.
- La placa dorsal del lagarto está en `arte_fuente/placa_dorsal_lagarto.blend`.
  Godot carga la exportación OBJ desde `fauna/modelos/`.
- `shaders/luz_toon.gdshaderinc`: la luz por bandas que incluyen todos los materiales.

## 6. Cómo ejecutar y verificar

    G=/Applications/Godot.app/Contents/MacOS/Godot
    P="/Users/brianbenitez/Downloads/Proyectos/JUEGO EMI"

    # Revisar que el editor carga sin errores (debe imprimir 0)
    "$G" --headless --path "$P" --import 2>&1 | grep -c -E "ERROR|WARNING"

    # Pruebas con entradas simuladas y capturas (abre una ventana unos segundos)
    "$G" --path "$P" -s "$P/herramientas/captura.gd" -- <carpeta_de_salida> <modo>

F5 abre el menú principal. Para jugar la isla, abrir `mundo/terreno_de_prueba.tscn`
y pulsar F6. Los modos de `herramientas/captura.gd` usan la isla.

- `vista`: una captura del inicio.
- `prueba`: caminar, salto (1,57 m), doble salto (2,91 m), cámara, recorrido
  de rocas y regreso desde el agua.
- `encargo`: el encargo del pescador completo, con combate, defensa y huida.
- `guardia`: la hostilidad por nivel y el encargo de los Asaltantes Klaimyr.
- `retrato`: el protagonista de cerca en siete poses.
- `arboles`: cantidad, claros, choque con el tronco, ventana en el follaje.
- `pixel`, `escalas`, `arranque`: miden el tamaño real del píxel.
- `cenital`: la isla desde arriba, con una tabla de alturas.

Las pruebas imprimen sus resultados por consola. Los modos `encargo` y
`guardia` también devuelven un código de error si falla alguna comprobación.
Las capturas se guardan reducidas a 1600 píxeles de ancho. Con `--headless`,
los modos de movimiento y encargos ejecutan sus comprobaciones sin capturas.
Las herramientas `-s` tienen el guardado automático desactivado.

Prueba aislada de guardado (no toca la partida real):

    "$G" --headless --path "$P" -s herramientas/prueba_guardado.gd -- /tmp/emblema_guardado

Verifica avance parcial, historial, puntos únicos, apoyo seguro, Fauna Anómala,
rescate, respaldo, versión incompatible, fallo de escritura y borrado.
Los argumentos finales `cerrar` y `reabrir`, ejecutados en ese orden con la
misma carpeta temporal, comprueban el cierre y la recuperación entre procesos.

Validación del 19/11/2026 desde el entorno de Codex: guardado, cierre/reapertura,
movimiento, encargo completo e interfaz pasaron sin ventana. La importación no
informó errores de scripts; sí tres errores del entorno de macOS: certificados
del sistema y escritura de preferencias del editor. Las ejecuciones con ventana
abortaron y el control de escritorio para Godot no fue aprobado, por lo que
queda pendiente la revisión visual mediante capturas. El entorno también
rechazó escribir `.git/index.lock`: los commits no se pudieron crear.

`herramientas/generar_jugador.py` regenera `jugador/jugador.tscn` (ejecutar
desde la raíz del proyecto). Es opcional: la escena también se puede editar
a mano o en el editor, pero entonces el generador queda desactualizado.

Prueba de tamaños de interfaz:

    "$G" --headless --path "$P" -s herramientas/prueba_interfaz.gd

La prueba recorre también pausa, guardado manual, cancelación y confirmación
del borrado, diario, controles, mapa y tamaños del diálogo.

El seguimiento mantiene su ancho y ajusta solo el alto al cambiar su mínimo.
No usar `reset_size()` allí: achica el ancho antes de envolver el texto y deja
un alto obsoleto que puede llegar al borde inferior de la pantalla.

## 7. Cosas que no son obvias

- **El píxel no pasa de 10 píxeles de pantalla.** Godot limita
  `scaling_3d_scale` a 0,1. En ventanas muy altas, F2 puede no hacer nada.
- **Ratón:** usar `screen_relative`, no `relative`, que cambia con el tamaño
  de la ventana por el modo de estiramiento `canvas_items`.
- **Interpolación de física activada.** Lo que se mueve en `_process`
  (cámara, nubes, globo del personaje) lleva `physics_interpolation_mode`
  apagado. La figura del protagonista se anima en `_physics_process`.
- **Tras cerrar un diálogo o combate hay 200 ms de bloqueo**
  (`Interfaz.ocupada()`), para que la pulsación no haga saltar ni interactuar.
  Una prueba que interactúe antes de ese margen falla sin motivo real.
- **Los scripts `@tool` crean hijos sin dueño** (terreno, árboles): se ven en
  el editor pero no se guardan en la escena. `Arboleda` borra a todos sus
  hijos cada vez que reparte.
- **No escalar cuerpos de física:** a los árboles se les escala solo el nodo `Modelo`.
- **Controles y datos globales de shader** se agregaron con scripts que usan
  `ProjectSettings.set_setting(...)` y `save()`, para que Godot los escriba en
  su formato. Los eventos de entrada llevan `device = -1` (todos los dispositivos).
- **GDScript:** `:=` no infiere tipo desde valores sin tipo (por ejemplo,
  propiedades de un `InputEvent` genérico o el resultado de un `if` en línea
  con arreglos); en esos casos, declarar el tipo.
- **Nubes sin sombra a propósito:** sus sombras rectas parecían otro tipo de suelo.
- En el shader de follaje, la ventana y los huecos se saltan con
  `IN_SHADOW_PASS`, para que las sombras salgan enteras.

## 8. Lo que no se probó

- Clic real del ratón (captura del cursor y botones del diálogo) y mando físico.
- Fluidez de las animaciones y del viento en movimiento: solo se revisaron
  cuadros sueltos.
- Exportar el juego y correrlo en otra máquina o sistema.

## 9. Cómo trabaja el usuario

- Escribe en español rioplatense, con pedidos breves ("dale", "continúa").
- Prefiere que se avance y se le muestre el resultado con capturas antes que
  responder preguntas; solo preguntarle lo que de verdad sea decisión suya.
- Sigue la sesión también desde el teléfono (Remote Control activado).
