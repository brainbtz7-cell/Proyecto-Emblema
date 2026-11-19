"""Genera los marcos pixel art de la interfaz (paneles, botones, teclas y barras).

Cada imagen es chica (un píxel de textura = un píxel de interfaz) y el tema la
estira en nueve partes (StyleBoxTexture). Ejecutar desde la raíz del proyecto:

    python3 herramientas/generar_marcos.py

Necesita Pillow. Escribe en interfaz/marcos/. PROVISIONAL: paleta y forma son una
propuesta de estilo "minimalista pixel" (referencias: A Short Hike y Sea of Stars).
"""

from pathlib import Path

from PIL import Image

SALIDA = Path("interfaz/marcos")

# Paleta (RGBA).
OSCURO = (8, 12, 15, 235)
FONDO_HUD = (16, 25, 31, 214)
FONDO_MENU = (19, 28, 34, 246)
LINEA_ALTA = (206, 194, 160, 170)
LINEA = (128, 140, 128, 140)
LINEA_BAJA = (62, 72, 70, 150)
ORO_ALTO = (247, 218, 152, 245)
ORO = (226, 184, 100, 230)
ORO_BAJO = (146, 106, 52, 220)
FONDO_VOZ = (36, 27, 18, 238)
ACENTO = (125, 183, 157, 235)
PERGAMINO_ALTO = (246, 226, 182, 255)
PERGAMINO = (221, 193, 139, 255)
PERGAMINO_BAJO = (158, 126, 80, 255)
BORDE_PERGAMINO = (44, 33, 20, 255)


def marco(ancho, alto, borde, fondo, alta=None, lados=None, baja=None, acento=None, ancho_acento=2, esquinas=True):
    """Marco con borde de un píxel, esquinas recortadas y líneas interiores opcionales."""
    imagen = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    px = imagen.load()
    for y in range(alto):
        for x in range(ancho):
            borde_x = x in (0, ancho - 1)
            borde_y = y in (0, alto - 1)
            if borde_x and borde_y and esquinas:
                continue  # esquina recortada
            if borde_x or borde_y:
                px[x, y] = borde
            else:
                px[x, y] = fondo
    if esquinas:
        # El borde dobla hacia adentro en las esquinas: queda un chaflán de un píxel.
        for x, y in ((1, 1), (ancho - 2, 1), (1, alto - 2), (ancho - 2, alto - 2)):
            px[x, y] = borde
    interior_x = range(2 if esquinas else 1, ancho - (2 if esquinas else 1))
    interior_y = range(2 if esquinas else 1, alto - (2 if esquinas else 1))
    if alta:
        for x in interior_x:
            px[x, 1] = alta
    if baja:
        for x in interior_x:
            px[x, alto - 2] = baja
    if lados:
        for y in interior_y:
            px[1, y] = lados
            px[ancho - 2, y] = lados
    if acento:
        for y in range(1 if not esquinas else 2, alto - (1 if not esquinas else 2)):
            for x in range(1, 1 + ancho_acento):
                px[x, y] = acento
    return imagen


def anillo(ancho, alto, exterior, interior):
    """Anillo de foco de dos píxeles con esquinas recortadas y centro transparente."""
    imagen = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    px = imagen.load()
    for y in range(alto):
        for x in range(ancho):
            en_borde = x in (0, ancho - 1) or y in (0, alto - 1)
            en_segundo = x in (1, ancho - 2) or y in (1, alto - 2)
            esquina = x in (0, ancho - 1) and y in (0, alto - 1)
            if en_borde and not esquina:
                px[x, y] = exterior
            elif en_segundo and not en_borde:
                px[x, y] = interior
    return imagen


def tecla():
    """Tecla clara con cara, canto inferior y brillo arriba a la izquierda."""
    ancho, alto = 11, 12
    imagen = marco(ancho, alto, (11, 15, 18, 255), (236, 228, 207, 255))
    px = imagen.load()
    for x in range(2, ancho - 2):
        px[x, alto - 2] = (150, 140, 116, 255)
        px[x, alto - 3] = (186, 176, 150, 255)
    for x in range(2, ancho - 2):
        px[x, 1] = (255, 251, 240, 255)
    return imagen


def barra(color, brillo):
    imagen = Image.new("RGBA", (4, 4), color)
    px = imagen.load()
    for x in range(4):
        px[x, 0] = brillo
    return imagen


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    imagenes = {
        "panel": marco(12, 12, OSCURO, FONDO_MENU, LINEA_ALTA, LINEA, LINEA_BAJA),
        "panel_hud": marco(12, 12, OSCURO, FONDO_HUD, (190, 180, 150, 120), (110, 122, 112, 105), (52, 62, 60, 120)),
        "panel_voz": marco(12, 12, OSCURO, FONDO_VOZ, ORO_ALTO, ORO, ORO_BAJO),
        "seguimiento": marco(12, 12, OSCURO, FONDO_HUD, (190, 180, 150, 110), None, (52, 62, 60, 120), ACENTO),
        "seguimiento_voz": marco(12, 12, OSCURO, (30, 24, 17, 220), (226, 190, 120, 130), None, (90, 66, 34, 140), ORO),
        "boton": marco(12, 12, OSCURO, (29, 42, 49, 246), (124, 138, 130, 220), (84, 98, 95, 200), (44, 54, 54, 230)),
        "boton_sobre": marco(12, 12, OSCURO, (38, 54, 60, 250), ORO_ALTO, ORO, ORO_BAJO),
        "boton_presionado": marco(12, 12, OSCURO, (22, 33, 38, 250), (44, 54, 54, 230), (84, 98, 95, 200), (124, 138, 130, 220)),
        "boton_inactivo": marco(12, 12, (8, 12, 15, 150), (20, 28, 33, 190), (58, 68, 68, 120), (50, 60, 60, 110), (36, 44, 44, 120)),
        "foco": anillo(12, 12, ORO_ALTO, (170, 128, 62, 200)),
        "boton_principal": marco(12, 12, BORDE_PERGAMINO, PERGAMINO, PERGAMINO_ALTO, PERGAMINO, PERGAMINO_BAJO),
        "boton_principal_sobre": marco(12, 12, BORDE_PERGAMINO, (238, 213, 162, 255), (255, 240, 206, 255), (238, 213, 162, 255), (176, 142, 92, 255)),
        "boton_principal_presionado": marco(12, 12, BORDE_PERGAMINO, (192, 160, 110, 255), PERGAMINO_BAJO, (192, 160, 110, 255), PERGAMINO_ALTO),
        "bitacora": marco(12, 12, (10, 15, 18, 220), (26, 37, 43, 240), (88, 100, 94, 150), (60, 72, 70, 130), (40, 50, 50, 150)),
        "bitacora_voz": marco(12, 12, (10, 15, 18, 220), (40, 32, 22, 240), (200, 160, 96, 190), (140, 108, 60, 160), (86, 64, 34, 170)),
        "senal": marco(12, 12, OSCURO, (30, 41, 46, 250), (100, 112, 106, 160), None, (44, 54, 54, 200), (205, 172, 112, 235)),
        "tecla": tecla(),
        "barra_fondo": marco(6, 6, OSCURO, (9, 15, 19, 235), esquinas=False),
        "barra_llena": barra((125, 183, 157, 255), (176, 220, 196, 255)),
        "barra_voz": barra((238, 189, 104, 255), (255, 226, 162, 255)),
        "barra_rival": barra((216, 140, 112, 255), (242, 186, 160, 255)),
        "barra_desplazamiento": marco(6, 6, OSCURO, (118, 136, 129, 255), (160, 176, 168, 255), esquinas=False),
    }
    for nombre, imagen in imagenes.items():
        imagen.save(SALIDA / f"{nombre}.png")
    print(f"{len(imagenes)} marcos en {SALIDA}/")


if __name__ == "__main__":
    main()
