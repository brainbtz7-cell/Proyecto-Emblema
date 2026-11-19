import math, pathlib

def n(v):
    v = round(v, 3)
    return str(int(v)) if v == int(v) else str(v)

def tr(x=0, y=0, z=0, rx=0):
    a = math.radians(rx); c, s_ = math.cos(a), math.sin(a)
    return "Transform3D(%s)" % ", ".join(n(v) for v in [1, 0, 0, 0, c, -s_, 0, s_, c, x, y, z])

def toon(ident, color, contorno=True, luz=0.15):
    t = '[sub_resource type="ShaderMaterial" id="%s"]\n' % ident
    if contorno:
        t += 'next_pass = SubResource("mat_contorno")\n'
    t += 'shader = ExtResource("3_toon")\nshader_parameter/color = Color(%s, %s, %s, 1)\n' % tuple(n(c) for c in color)
    if luz:
        t += 'shader_parameter/luz_propia = %s\n' % n(luz)
    return t

def cono(ident, mat, arriba, abajo, alto, lados=10):
    return ('[sub_resource type="CylinderMesh" id="%s"]\nmaterial = SubResource("%s")\ntop_radius = %s\nbottom_radius = %s\nheight = %s\nradial_segments = %d\nrings = 1\n'
            % (ident, mat, n(arriba), n(abajo), n(alto), lados))

def esfera(ident, mat, radio, lados=10, anillos=5):
    return ('[sub_resource type="SphereMesh" id="%s"]\nmaterial = SubResource("%s")\nradius = %s\nheight = %s\nradial_segments = %d\nrings = %d\n'
            % (ident, mat, n(radio), n(radio * 2), lados, anillos))

def caja(ident, mat, tam):
    return '[sub_resource type="BoxMesh" id="%s"]\nmaterial = SubResource("%s")\nsize = Vector3(%s, %s, %s)\n' % (ident, mat, *[n(t) for t in tam])

def prisma(ident, mat, tam):
    return '[sub_resource type="PrismMesh" id="%s"]\nmaterial = SubResource("%s")\nsize = Vector3(%s, %s, %s)\n' % (ident, mat, *[n(t) for t in tam])

def nodo(nombre, padre, **t):
    return '[node name="%s" type="Node3D" parent="%s"]\ntransform = %s\n' % (nombre, padre, tr(**t))

def malla(nombre, padre, mesh, **t):
    return '[node name="%s" type="MeshInstance3D" parent="%s"]\ntransform = %s\nmesh = SubResource("%s")\n' % (nombre, padre, tr(**t), mesh)

G = "Modelo/Inclinacion/Giro"
F = G + "/Falda"
T = G + "/Torso"
C = T + "/Capa"
partes = [
    '[gd_scene format=3]\n',
    '[ext_resource type="Script" path="res://jugador/jugador.gd" id="1_jugador"]\n'
    '[ext_resource type="Script" path="res://jugador/camara_orbital.gd" id="2_camara"]\n'
    '[ext_resource type="Shader" path="res://shaders/toon.gdshader" id="3_toon"]\n'
    '[ext_resource type="Script" path="res://jugador/alcance.gd" id="4_alcance"]\n'
    '[ext_resource type="Script" path="res://jugador/figura.gd" id="5_figura"]\n'
    '[ext_resource type="Shader" path="res://shaders/contorno.gdshader" id="6_contorno"]\n',
    '[sub_resource type="CapsuleShape3D" id="forma_cuerpo"]\nradius = 0.3\nheight = 1.5\n',
    '[sub_resource type="ShaderMaterial" id="mat_contorno"]\nshader = ExtResource("6_contorno")\n',
    toon("mat_tunica", (0.78, 0.41, 0.28)),
    toon("mat_tunica_clara", (0.9, 0.55, 0.37), contorno=False),
    toon("mat_capucha", (0.23, 0.29, 0.54)),
    toon("mat_capa", (0.16, 0.2, 0.41)),
    toon("mat_ocre", (0.89, 0.71, 0.36)),
    toon("mat_guante", (0.34, 0.25, 0.21)),
    toon("mat_rostro", (0.05, 0.05, 0.09), contorno=False, luz=0),
    '[sub_resource type="StandardMaterial3D" id="mat_ojos"]\nshading_mode = 0\nalbedo_color = Color(0.86, 0.98, 0.94, 1)\n',
    toon("mat_polvo", (0.95, 0.93, 0.86), contorno=False, luz=0),
    cono("malla_falda", "mat_tunica", 0.19, 0.4, 0.79),
    cono("malla_ruedo", "mat_ocre", 0.4, 0.42, 0.07),
    caja("malla_panel", "mat_tunica_clara", (0.14, 0.76, 0.02)),
    cono("malla_pecho", "mat_tunica", 0.2, 0.19, 0.36),
    cono("malla_faja", "mat_ocre", 0.205, 0.205, 0.07),
    caja("malla_lazo", "mat_ocre", (0.06, 0.2, 0.03)),
    cono("malla_manga", "mat_tunica", 0.065, 0.095, 0.4, 8),
    cono("malla_puno", "mat_ocre", 0.098, 0.106, 0.05, 8),
    caja("malla_mano", "mat_guante", (0.09, 0.09, 0.09)),
    cono("malla_manto", "mat_capucha", 0.12, 0.3, 0.22),
    esfera("malla_capucha", "mat_capucha", 0.23),
    prisma("malla_pico", "mat_capucha", (0.2, 0.3, 0.12)),
    esfera("malla_rostro", "mat_rostro", 0.165, 8, 4),
    caja("malla_ojo", "mat_ojos", (0.06, 0.07, 0.03)),
    caja("malla_capa_alta", "mat_capa", (0.38, 0.27, 0.035)),
    caja("malla_capa_media", "mat_capa", (0.44, 0.27, 0.035)),
    caja("malla_capa_baja", "mat_capa", (0.5, 0.27, 0.035)),
    caja("malla_polvo", "mat_polvo", (0.14, 0.14, 0.14)),
    '[sub_resource type="Curve" id="curva_polvo"]\n_data = [Vector2(0, 1), 0.0, 0.0, 0, 0, Vector2(1, 0), -2.0, 0.0, 0, 0]\npoint_count = 2\n',
    '[sub_resource type="SphereShape3D" id="forma_camara"]\nradius = 0.25\n',
    '[sub_resource type="SphereShape3D" id="forma_alcance"]\nradius = 1.5\n',

    '[node name="Jugador" type="CharacterBody3D"]\ncollision_layer = 2\ncollision_mask = 25\nscript = ExtResource("1_jugador")\n',
    '[node name="Colision" type="CollisionShape3D" parent="."]\ntransform = %s\nshape = SubResource("forma_cuerpo")\n' % tr(y=0.75),

    '[node name="Modelo" type="Node3D" parent="."]\nscript = ExtResource("5_figura")\n',
    '[node name="Inclinacion" type="Node3D" parent="Modelo"]\n',
    '[node name="Giro" type="Node3D" parent="Modelo/Inclinacion"]\n',
    # La falda cuelga de la cintura para poder mecerse.
    nodo("Falda", G, y=0.86),
    malla("Tela", F, "malla_falda", y=-0.395),
    malla("Ruedo", F, "malla_ruedo", y=-0.825),
    malla("PanelFrontal", F, "malla_panel", y=-0.4, z=-0.312, rx=14.9),
    nodo("Torso", G, y=0.84),
    malla("Pecho", T, "malla_pecho", y=0.18),
    malla("Faja", T, "malla_faja", y=0.02),
    malla("Lazo", T, "malla_lazo", x=-0.1, y=-0.1, z=-0.215),
    malla("Manto", T, "malla_manto", y=0.3),
    nodo("BrazoIzquierdo", T, x=-0.22, y=0.3),
    malla("Manga", T + "/BrazoIzquierdo", "malla_manga", y=-0.19),
    malla("Puno", T + "/BrazoIzquierdo", "malla_puno", y=-0.385),
    malla("Mano", T + "/BrazoIzquierdo", "malla_mano", y=-0.44),
    nodo("BrazoDerecho", T, x=0.22, y=0.3),
    malla("Manga", T + "/BrazoDerecho", "malla_manga", y=-0.19),
    malla("Puno", T + "/BrazoDerecho", "malla_puno", y=-0.385),
    malla("Mano", T + "/BrazoDerecho", "malla_mano", y=-0.44),
    nodo("Cabeza", T, y=0.5),
    malla("Capucha", T + "/Cabeza", "malla_capucha", y=0.02),
    malla("PicoDeCapucha", T + "/Cabeza", "malla_pico", y=-0.03, z=0.23, rx=150),
    malla("Rostro", T + "/Cabeza", "malla_rostro", y=-0.01, z=-0.1),
    nodo("Ojos", T + "/Cabeza"),
    malla("OjoIzquierdo", T + "/Cabeza/Ojos", "malla_ojo", x=-0.075, y=0.01, z=-0.262),
    malla("OjoDerecho", T + "/Cabeza/Ojos", "malla_ojo", x=0.075, y=0.01, z=-0.262),
    # La capa cuelga del borde del manto, en tres tramos que se doblan.
    nodo("Capa", T, y=0.2, z=0.27),
    malla("PanoAlto", C, "malla_capa_alta", y=-0.13),
    nodo("CapaMedia", C, y=-0.26),
    malla("PanoMedio", C + "/CapaMedia", "malla_capa_media", y=-0.13),
    nodo("CapaBaja", C + "/CapaMedia", y=-0.26),
    malla("PanoBajo", C + "/CapaMedia/CapaBaja", "malla_capa_baja", y=-0.13),

    '[node name="Alcance" type="Area3D" parent="."]\nscript = ExtResource("4_alcance")\n',
    '[node name="Forma" type="CollisionShape3D" parent="Alcance"]\ntransform = %s\nshape = SubResource("forma_alcance")\n' % tr(y=0.8),
    '[node name="Polvo" type="CPUParticles3D" parent="."]\ntop_level = true\nemitting = false\namount = 8\nlifetime = 0.4\none_shot = true\nexplosiveness = 1.0\nmesh = SubResource("malla_polvo")\ndirection = Vector3(1, 0, 0)\nspread = 180.0\nflatness = 1.0\ngravity = Vector3(0, 0.6, 0)\ninitial_velocity_min = 1.6\ninitial_velocity_max = 2.6\ndamping_min = 3.0\ndamping_max = 3.0\nscale_amount_curve = SubResource("curva_polvo")\n',
    '[node name="Camara" type="Node3D" parent="."]\ntop_level = true\nphysics_interpolation_mode = 2\nscript = ExtResource("2_camara")\n',
    '[node name="Brazo" type="SpringArm3D" parent="Camara"]\ntransform = Transform3D(1, 0, 0, 0, 0.951, 0.309, 0, -0.309, 0.951, 0, 0, 0)\nshape = SubResource("forma_camara")\nspring_length = 8.0\nmargin = 0.1\n',
    '[node name="Lente" type="Camera3D" parent="Camara/Brazo"]\ncurrent = true\nfov = 42.0\nfar = 600.0\n',
]
pathlib.Path("jugador/jugador.tscn").write_text("\n".join(partes))
print("escena generada")
