class_name Encargo
extends Resource
## Un encargo: qué se pide, cuánto y a quién hay que volver.
##
## Cada encargo es un archivo .tres de la carpeta encargos/ y se edita en el
## Inspector, sin tocar código.

## Identificador único, sin espacios. No se muestra al jugador.
@export var id: StringName
## Nombre con el que aparece en pantalla.
@export var titulo := ""
## Distingue en dorado las misiones de La Voz.
@export var de_la_voz := false
## Lo que dice quien lo ofrece.
@export_multiline var oferta := ""
## Qué se está contando, por ejemplo "Lomos de Uscita".
@export var objetivo := ""
## Indicación opcional para encontrar el objetivo durante la exploración.
@export var indicacion := ""
## Clave de lo que hay que contar para cumplirlo: un objeto reunido o un
## enemigo vencido. El mundo avisa con Encargos.contar(clave).
@export var clave_de_conteo: StringName
## Cuántos hacen falta.
@export var cantidad := 1
## A quién hay que volver al cumplirlo, tal como se lee en pantalla.
@export var entregar_a := ""
## Aviso opcional que aparece después de entregar el encargo.
@export var cierre := ""
## Identificadores de los encargos que se tienen que haber entregado.
@export var requisitos: Array[StringName] = []
