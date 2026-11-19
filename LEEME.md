# Proyecto Emblema — prototipo en Godot

Base jugable con estilo "pixel 3D": un mundo 3D dibujado en baja resolución y
ampliado sin suavizado. Hecho en Godot 4.7.

## Cómo abrirlo

1. Abrir Godot.
2. En el gestor de proyectos, elegir **Importar** y seleccionar el archivo
   `project.godot` de esta carpeta.
3. Dentro del editor, pulsar **F5** para jugar el primer tramo de Salbruma.
   Para volver a la isla de pruebas, abrir `mundo/terreno_de_prueba.tscn`
   y pulsar **F6**.

## Controles

| Acción | Teclado y ratón | Mando |
| --- | --- | --- |
| Moverse | WASD o flechas | Palanca izquierda |
| Correr | Shift | Pulsar la palanca izquierda (L3) |
| Saltar | Espacio | Botón A |
| Interactuar (hablar, cazar) y pasar diálogos | E | Botón X |
| Elegir una acción de combate | 1 a 4, flechas y Enter, o clic | Cruceta y botón A |
| Girar la cámara | Clic y mover el ratón | Palanca derecha |
| Acercar o alejar | Rueda del ratón | — |
| Soltar el ratón | Esc | — |
| Abrir el mapa de Salbruma | M | Vista / Select |
| Píxel más grande / más chico | F2 / F3 | — |

Los controles se cambian en **Proyecto → Configuración del proyecto → Mapa de entrada**.

## Recorrer Salbruma

Desde la llegada al oeste, seguí el sendero por los Bajíos y cruzá la
pasarela para llegar a Puerto Junco. El pescador espera cerca del muelle.
El guardia está en el camino al entrar al pueblo. La Caleta de las Redes
Rotas queda río arriba, por el sendero que bordea el Gran Río. El sendero
que sale al noroeste del pueblo lleva a las Marismas del Caparazón.

Con **M** ves el plano del tramo y tu posición. Con **M** o **Esc** volvés
a explorar. Hay pasto bajo junto al camino y matas altas en las riberas.
Al acercarte, las hojas se apartan y vuelven a levantarse cuando pasás.
Al vadear o caer en el agua se abren ondas y saltan gotas donde toca el
protagonista. Las pasarelas mantienen los pies secos.
En tierra firme, mantené **Shift** para correr. El agua va frenando el
paso a medida que sube.

## Combate y encargos de prueba

- Acercate a una Uscita y pulsá **E** para cazarla. Un Asaltante Klaimyr de
  nivel igual o superior inicia el combate al acercarte.
- La iniciativa decide quién abre el encuentro. En cada turno, el panel
  anuncia si el rival ataca, carga una embestida o se cubre.
- **1 · Atacar** tira para golpear. **2 · Defender** reduce el daño y deja
  listo un contraataque cuando el rival embiste. **3 · Preparar** dedica el
  turno a asegurar el próximo golpe, que atraviesa la protección del rival.
  **4 · Huir** termina el encuentro.
- El pescador pide siete lomos de Uscita. Encontrás las manadas en los Bajíos.
  El guardia pide derrotar a siete Asaltantes Klaimyr en la Caleta.
- Al entregar esos dos encargos, el jefe pesquero pide levantar tres
  defensas. Con el encargo activo, **M** marca los acopios de la entrada,
  la ribera y el muelle. Acercate a cada uno y usá **E** para levantarlo.
- En esa misma tanda, el pescador pide siete cueros de lagarto armado.
  Buscá a los lagartos acorazados en las Marismas y pulsá **E** cerca de
  uno para iniciar el combate.
- Tras entregar la segunda tanda, el guardia te envía a investigar un
  punto marcado con **M**. La emboscada reúne a tres asaltantes.
- Después de volver con el guardia, leé el tablón de Junco con **E**.
  El mapa señala el rescate río arriba. Liberá al jefe y volvé al pueblo
  con él para que se habilite **La última marea** en el tablón.
- El capitán espera en la ribera. El encuentro tiene **15 turnos** y se
  puede volver a intentar. Durante el duelo, el pasto se inclina alrededor de
  ambos combatientes. Entregá la victoria en el tablón.

## Carpetas

- `nucleo/` — lo que funciona en todo el juego: el render en baja resolución
  (`pixelado.gd`), la cuenta de encargos (`encargos.gd`) y las zonas con las
  que se puede interactuar (`interactuable.gd`).
- `encargos/` — un archivo por encargo, con su texto y su objetivo.
- `personajes/` — habitantes que ofrecen encargos.
- `fauna/` — animales y las manadas que los reparten por el mundo.
- `arte_fuente/` — archivos editables de arte. La placa dorsal del lagarto
  se edita en Blender y el juego usa su exportación OBJ en `fauna/modelos/`.
  La prueba de personajes de Meshy está archivada en `arte_fuente/personajes/`
  con los modelos editables de Blender, los originales y las exportaciones.
- `efectos/` — partículas de un solo uso.
- `jugador/` — el protagonista y su cámara. Velocidad, altura de salto y
  doble salto se ajustan en el Inspector, sin tocar código. `figura.gd` es
  su aspecto y su animación; `jugador.gd`, cómo se mueve.
- `mundo/` — escenarios. `salbruma/salbruma.tscn` es la escena principal.
  `salbruma/trazado_salbruma.gd` define los senderos del tramo. También
  están la isla de pruebas, el árbol y la arboleda que reparte los árboles.
- `shaders/` — los materiales que dan el estilo: luz por bandas, suelo, agua,
  roca, cielo y el contorno oscuro de los personajes.
- `interfaz/` — caja de diálogo, encargos en curso, avisos, ayuda, mapa de
  Salbruma y panel de combate.

## Cómo agregar un encargo

1. En `encargos/`, duplicar un archivo `.tres` y cambiarle el `id`, los textos,
   la `clave_de_conteo` y la `cantidad` en el Inspector.
2. Arrastrarlo a la lista `encargos` del personaje que lo ofrece. Los ofrece
   en orden, de a uno.
3. Lo que se cuenta (un objeto, un enemigo) avisa con
   `Encargos.contar(&"la_clave")`. Si es un punto único, pasale además el ID
   del punto, por ejemplo `Encargos.contar(&"defensa_de_junco", &"muelle")`.
4. Para que un encargo espere la entrega de otros, poné sus IDs en
   `requisitos` en el Inspector.

## Árboles

El nodo `Arboleda` del nivel planta los árboles solo, en manchones, cada vez
que se carga la escena. En el Inspector se cambia cuántos hay (`cantidad`),
el reparto (`semilla`), qué tan agrupados crecen y a qué alturas. Deja libre
un claro alrededor de los nodos de la lista `dejar_libre`.

Para poner un árbol a mano, arrastrar `mundo/arbol.tscn` al nivel (fuera del
nodo `Arboleda`).

Cuando una copa tapa al protagonista, el follaje abre una ventana redonda
para que no se pierda de vista. El radio se ajusta en `ventana_en_el_follaje`,
en el nodo `Camara` del jugador.

## Sonido

Efectos provisionales sintetizados por código: pasos (pasto, arena, roca,
agua), salto, doble salto, aterrizaje, Ficha Anómala y ambiente de olas y
viento. Están en `sonido/` y se regeneran con
`python3 herramientas/generar_sonidos.py`. Se reproducen con `nucleo/sonido.gd`
(`Sonido.efecto(&"nombre")`, sin autoload). Volúmenes en
`Sonido.volumen_efectos` y `Sonido.volumen_ambiente`.

## Fauna Anómala

Regla del Documento Maestro (4.3): cada animal que aparece tiene un 0,25 % de
ser Anómalo. Se ve de otro color, con cristales en el lomo y destellos. Al
cazarlo da una Ficha Anómala y queda anotado en la colección.

- Reglas y datos: `nucleo/fauna_anomala.gd` (estático, sin autoload). Para el
  guardado: `FaunaAnomala.a_diccionario()` / `desde_diccionario(datos)`.
- Aspecto: `fauna/rasgo_anomalo.gd`. Cada especie puede tener su propio tono
  (`tono_anomalo`) y su propio rasgo (`rasgo_anomalo`) en el Inspector.
- Para probarlo, lanzar el juego con `-- --anomalia-forzada`: todos los
  animales salen Anómalos.
- **Provisional / pendiente:** la paleta y el rasgo de cada especie (hoy son
  genéricos), el canje de 10 fichas por el objeto que sube un atributo, y la
  experiencia y objetos ordinarios dobles: el juego todavía no tiene
  atributos, experiencia ni objetos ordinarios.

## Qué es provisional

- **El tramo de Salbruma es de prueba.** Sigue las ubicaciones del anexo
  cartográfico. El relieve a escala jugable, el arroyo, las distancias,
  los estanques, el trazado fino y las construcciones sirven para evaluar
  la exploración.
- **La isla de pruebas es un escenario técnico** generado con ruido para
  ajustar movimiento, cámara y estilo. Cambiar la `semilla` del nodo `Terreno`
  da otra isla.
- **Los árboles son genéricos:** el documento no describe la vegetación de
  Tierras de Salbruma.
- **El diseño del protagonista es de prueba.** Su figura low-poly lleva
  capucha y túnica cerrada hasta el suelo. Los brazos, la capa y el ruedo
  se mueven por fórmulas.
- **Los conceptos de personajes de Salbruma son propuestas visuales.**
  Las ilustraciones del protagonista, el jefe pesquero y el capitán Klaimyr
  se guardan como referencias en `arte_fuente/conceptos_personajes_v1/`.
- **El combate en el lugar es una prueba.** Los patrones, la preparación,
  el contraataque, la vida y los valores de daño sirven para probar el ritmo.
- **El guardia y los asaltantes son modelos de marcador.** Su apariencia
  y el movimiento en tierra de los Klaimyr son de prueba.
  El diálogo inicial del guardia y el objetivo de derrotar a siete asaltantes
  salen del Documento Maestro.
- **El pescador y los Uscita son modelos de marcador.** El Uscita sigue la
  descripción del Documento Maestro; el pescador es una figura genérica con
  pico, a la espera del diseño del pueblo aviario.
- **Las empalizadas y el modelo del jefe pesquero son de prueba.** Los tres
  puntos de obra y su construcción con E sirven para probar el encargo.
- **El lagarto acorazado es un modelo de marcador.** Su conducta neutral,
  estadísticas y obtención del cuero al ganar con el encargo activo son
  decisiones de esta prueba.
- **Los lugares de la emboscada y del rescate son de prueba.** También son
  provisionales el diálogo de los asaltantes, los duelos consecutivos, la
  forma de acompañar al jefe y el diseño y comportamiento del capitán.
- **Del encargo del pescador solo es canon lo que dice el documento:** su
  diálogo, el objetivo (7 lomos de Uscita) y que los lomos solo se consiguen
  con el encargo activo. El título "Encargo del pescador" y los avisos de
  avance y de entrega son textos del juego, no diálogo del personaje.
- **Las criaturas reaparecen al volver a Puerto Junco** o al poblado de la
  isla de pruebas.
- **El doble salto se prueba en la isla.** El protagonista empieza Salbruma
  con salto simple. En la historia, los Estribos del Risco habilitan el
  doble salto.

## Trabajo en paralelo (Git)

- `JUEGO EMI` → rama `main`: Codex (su proyecto de siempre) y la versión unida.
- `JUEGO EMI-claude` → rama `claude`: Claude.
- Para unir lo de Claude a la principal, desde `JUEGO EMI`: `git merge claude`.
  Para que Claude reciba lo nuevo, desde `JUEGO EMI-claude`: `git merge main`.
- Las reglas para las IA están en `AGENTS.md` (Claude las lee vía `CLAUDE.md`).
- Los modelos originales de `arte_fuente/personajes/originales/` no están en
  Git por su tamaño; el juego usa los de `exportaciones/`.
