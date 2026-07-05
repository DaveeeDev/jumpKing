extends Node3D

var previewSkin
@onready var camera = $"/root/world/camera"
@onready var hud = $"/root/world/hudLayer/HUD"
@onready var map = $"/root/world/map"
# load skins into dictionary, use section as identifier, add path as entry, get rid of one skin set
@onready var default = $"/root/world/player/skinDefault"
@onready var previewDefault = $"/root/world/hudLayer/HUD/skinViewPort/player/skinDefault"
@onready var giraffe = $"/root/world/player/skinGiraffe"
@onready var previewGiraffe = $"/root/world/hudLayer/HUD/skinViewPort/player/skinGiraffe"
@onready var elephant = $"/root/world/player/skinElephant"
@onready var previewElephant = $"/root/world/hudLayer/HUD/skinViewPort/player/skinElephant"
@onready var cow = $"/root/world/player/skinCow"
@onready var previewCow = $"/root/world/hudLayer/HUD/skinViewPort/player/skinCow"


func moveLeft(moveCam):
	# if moveCam false, add cam movement to buffer and apply buffer with a chance
	self.position.z -= 1
	self.position.y += 0.5
	self.rotation.y = 0
	if moveCam:
		camera.position.z -= 1
		camera.position.y += 0.5
	if map.endlessMode and hud.taps > 10:
		map.generateBlock()

func moveRight(moveCam):
	# if moveCam false, add cam movement to buffer and apply buffer with a chance
	self.position.x += 1
	self.position.y += 0.5
	self.rotation.y = deg_to_rad(-90)
	if moveCam:
		camera.position.x += 1
		camera.position.y += 0.5
	if map.endlessMode and hud.taps > 10:
		map.generateBlock()

func updateSkin():
	# use dictionary to loop
	default.visible = false
	previewDefault.visible = false
	giraffe.visible = false
	previewGiraffe.visible = false
	elephant.visible = false
	previewElephant.visible = false
	cow.visible = false
	previewCow.visible = false
	# use parameter to unduplicate code, use loop instead of hardcoded variables
	match previewSkin:
		"default":
			previewDefault.visible = true
		"giraffe":
			previewGiraffe.visible = true
		"elephant":
			previewElephant.visible = true
		"cow":
			previewCow.visible = true
		_:
			print("Skin could not be found")
	match hud.scores.get_value("values", "currentSkin"):
		"default":
			default.visible = true
		"giraffe":
			giraffe.visible = true
		"elephant":
			elephant.visible = true
		"cow":
			cow.visible = true
		_:
			print("Skin could not be found")

func get_x():
	return self.position.x

func get_z():
	return self.position.z
