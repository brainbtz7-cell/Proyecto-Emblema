"""Genera los efectos de sonido provisionales del juego en sonido/*.wav.

Todos se sintetizan con código (ruido filtrado y tonos), sin archivos
externos. Son marcadores de posición hasta tener sonido definitivo.
Uso, desde la raíz del proyecto:  python3 herramientas/generar_sonidos.py
"""
import math
import random
import struct
import wave
from pathlib import Path

FRECUENCIA = 44100
CARPETA = Path("sonido")


def guardar(nombre, muestras, volumen=0.8):
    pico = max(1e-9, max(abs(m) for m in muestras))
    escala = volumen / pico
    CARPETA.mkdir(exist_ok=True)
    with wave.open(str(CARPETA / f"{nombre}.wav"), "wb") as archivo:
        archivo.setnchannels(1)
        archivo.setsampwidth(2)
        archivo.setframerate(FRECUENCIA)
        archivo.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, m * escala)) * 32767)) for m in muestras))
    print("sonido/%s.wav  %.2f s" % (nombre, len(muestras) / FRECUENCIA))


def ruido(segundos, semilla):
    azar = random.Random(semilla)
    return [azar.uniform(-1, 1) for _ in range(int(segundos * FRECUENCIA))]


def pasabajos(muestras, corte):
    """Filtro de un polo: deja pasar lo grave."""
    alfa = 1 - math.exp(-2 * math.pi * corte / FRECUENCIA)
    salida, previo = [], 0.0
    for m in muestras:
        previo += alfa * (m - previo)
        salida.append(previo)
    return salida


def pasaaltos(muestras, corte):
    graves = pasabajos(muestras, corte)
    return [m - g for m, g in zip(muestras, graves)]


def envolvente(muestras, ataque, caida):
    n = len(muestras)
    salida = []
    for i, m in enumerate(muestras):
        t = i / FRECUENCIA
        subida = min(1.0, t / ataque) if ataque > 0 else 1.0
        salida.append(m * subida * math.exp(-t / caida))
    return salida


def tono(segundos, frecuencia, caida, armonicos=(1.0,)):
    n = int(segundos * FRECUENCIA)
    return [
        sum(a * math.sin(2 * math.pi * frecuencia * (k + 1) * i / FRECUENCIA) for k, a in enumerate(armonicos))
        * math.exp(-i / FRECUENCIA / caida)
        for i in range(n)
    ]


def mezclar(*pistas):
    largo = max(len(p) for p in pistas)
    return [sum(p[i] if i < len(p) else 0.0 for p in pistas) for i in range(largo)]


def bucle_suave(muestras, cruce):
    """Funde el final con el principio para que el sonido se repita sin corte."""
    n = int(cruce * FRECUENCIA)
    cuerpo = muestras[:-n]
    for i in range(n):
        t = i / n
        cuerpo[i] = cuerpo[i] * t + muestras[len(muestras) - n + i] * (1 - t)
    return cuerpo


# Pasos: tres variantes por superficie para que no suenen todos iguales.
for i in range(3):
    pasto = envolvente(pasabajos(pasaaltos(ruido(0.16, 10 + i), 900), 4200), 0.004, 0.035)
    guardar(f"paso_pasto_{i + 1}", pasto, 0.5)
    arena = envolvente(pasabajos(ruido(0.2, 20 + i), 1800), 0.01, 0.05)
    guardar(f"paso_arena_{i + 1}", arena, 0.5)
    roca = mezclar(envolvente(pasaaltos(ruido(0.1, 30 + i), 2500), 0.001, 0.012),
                   [m * 0.6 for m in tono(0.1, 180 + 25 * i, 0.02)])
    guardar(f"paso_roca_{i + 1}", roca, 0.45)
    agua = envolvente(pasabajos(pasaaltos(ruido(0.3, 40 + i), 400), 2500), 0.02, 0.08)
    guardar(f"paso_agua_{i + 1}", agua, 0.55)

# Salto: soplido que sube.
n = int(0.28 * FRECUENCIA)
soplido = ruido(0.28, 50)
soplido = [m * math.sin(math.pi * i / n) for i, m in enumerate(pasaaltos(pasabajos(soplido, 3000), 600))]
guardar("salto", soplido, 0.45)

# Doble salto: soplido y un destello de campanitas.
destello = mezclar(*[[0.0] * int(k * 0.05 * FRECUENCIA) + tono(0.4, f, 0.12, (1.0, 0.3)) for k, f in enumerate((988, 1319, 1760))])
guardar("doble_salto", mezclar(soplido, [m * 0.35 for m in destello]), 0.5)

# Aterrizaje: golpe sordo.
golpe = mezclar(envolvente(pasabajos(ruido(0.25, 60), 500), 0.002, 0.06), [m * 0.8 for m in tono(0.25, 70, 0.07)])
guardar("aterrizaje", golpe, 0.6)

# Ficha Anómala: arpegio brillante.
arpegio = mezclar(*[[0.0] * int(k * 0.09 * FRECUENCIA) + tono(0.9, f, 0.35, (1.0, 0.4, 0.15)) for k, f in enumerate((659, 831, 988, 1319))])
guardar("ficha_anomala", arpegio, 0.55)

# Ambiente de olas: ruido grave que crece y baja cada pocos segundos.
segundos = 12.0
base = pasabajos(ruido(segundos + 1.0, 70), 700)
olas = []
for i, m in enumerate(base):
    t = i / FRECUENCIA
    marea = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * t / 4.0 - math.pi / 2)) ** 2
    olas.append(m * marea)
guardar("ambiente_olas", bucle_suave(olas, 1.0), 0.5)

# Ambiente de viento: soplido agudo y suave que ondula.
viento = pasabajos(pasaaltos(ruido(segundos + 1.0, 80), 300), 1500)
viento = [m * (0.6 + 0.4 * math.sin(2 * math.pi * i / FRECUENCIA / 7.0)) for i, m in enumerate(viento)]
guardar("ambiente_viento", bucle_suave(viento, 1.0), 0.3)
