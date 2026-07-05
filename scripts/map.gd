extends Node3D

var noise = FastNoiseLite.new()
var dictOfCubes = {}
var blockPositions = {}
var yCoordinate = 0
var previousX = 0
var previousZ = 0
var alive = true
var timeTaken = 0
var tapsPerSecond
var endlessMode = false
var extremeMode = false
var mapLength = 50
var reward = 15
var deletionDelta = 0.8
var lowestDeletionDelta = 0.2
var deleteBlockIndex = 0
@onready var player = $"../player"
@onready var camera = $"../camera"
@onready var hud = $"../hudLayer/HUD"
@onready var blockMesh = $"block/body/mesh"

func _ready():
	noise.seed = randi()
	generateMap()

func _process(delta):
	if hud.taps == 0:
		pass
	elif (blockPositions["blockX" + str(hud.taps)] != player.position.x or blockPositions["blockZ" + str(hud.taps)] != player.position.z) and not player.position.y == 0.5:
		alive = false
	else: 
		timeTaken += delta
	
	
	if hud.taps > 0 and (endlessMode or extremeMode):
		deletionDelta -= delta
		if deletionDelta <= 0:
			if endlessMode:
				deletionDelta += 0.8 - int(hud.taps / 10) * 0.01
			elif extremeMode:
				deletionDelta += 0.6 - int(hud.taps / 10) * 0.01
			if deletionDelta <= lowestDeletionDelta:
				deletionDelta = lowestDeletionDelta
			#deleteBlock(deleteBlockIndex)
			deleteBlockIndex += 1
	
	
	if not alive or (hud.taps > (mapLength - 1) and not endlessMode):
		# updating playtime, total blocks jumped, resetting map
		hud.scores.set_value("values", "playTime", hud.scores.get_value("values", "playTime") + timeTaken)
		hud.scores.set_value("values", "jumpBlock", hud.scores.get_value("values", "jumpBlock") + hud.taps)
		resetMap()
		generateMap()
		alive = true
		
		# if finished race, display taps/s
		if hud.taps > (mapLength - 1):
			$"../hudLayer/HUD/menus/behindMenuButton".visible = true
			$"../hudLayer/HUD/menus/onDeathMenu".visible = true
			hud.displayTapsPerSecond(timeTaken)
			hud.scores.set_value("values", "currency", hud.scores.get_value("values", "currency") + reward)
			hud.updateCurrency()
		
		
		# update high score sign and save high score value to file
		if (hud.scores.get_value("values", "highScoreNumber") < 0 or timeTaken < hud.scores.get_value("values", "highScoreNumber")):
			if endlessMode and hud.taps > hud.scores.get_value("values", "highScoreNumber") and hud.taps - 1 != 0:
				hud.scores.set_value("values", "highScoreNumber", hud.taps - 1)
			elif hud.taps > (mapLength - 1):
				hud.scores.set_value("values", "highScoreNumber", timeTaken)
			hud.displayHighScore(hud.scores.get_value("values", "highScoreNumber"))
		
			match [hud.scores.get_value("values", "endlessMode"), hud.scores.get_value("values", "extremeMode")]:
				[false, false]:
					var highScore = hud.scores.get_value("values", "highScoreNumbers")
					highScore["normal"] = hud.scores.get_value("values", "highScoreNumber")
					hud.scores.set_value("values", "highScoreNumbers", highScore)
				[false, true]:
					var highScore = hud.scores.get_value("values", "highScoreNumbers")
					highScore["normalExtreme"] = hud.scores.get_value("values", "highScoreNumber")
					hud.scores.set_value("values", "highScoreNumbers", highScore)
				[true, false]:
					var highScore = hud.scores.get_value("values", "highScoreNumbers")
					highScore["infinite"] = hud.scores.get_value("values", "highScoreNumber")
					hud.scores.set_value("values", "highScoreNumbers", highScore)
				[true, true]:
					var highScore = hud.scores.get_value("values", "highScoreNumbers")
					highScore["infiniteExtreme"] = hud.scores.get_value("values", "highScoreNumber")
					hud.scores.set_value("values", "highScoreNumbers", highScore)
	
		hud.taps = 0
		timeTaken = 0
		deleteBlockIndex = 0
		deletionDelta = 0.8
		
		# saving all values upon death
		hud.autoSave()
	
	# add delta timer that increments and replace (taps - 10) with actual blocks until
	#if endlessMode and hud.taps > 0 or extremeMode:
		#deleteBlock(hud.taps - 10)
		#if extremeMode:
			# add faster deletion
			#pass


func noiseAt(coordinateX):
	var noiseY = noise.get_noise_1d(coordinateX * 20) * 10
	return noiseY

func moveBlock(nodeName, noiseValue, prevNoiseValue):
	if noiseValue >= prevNoiseValue:
		nodeName.position.x += 1 + previousX
		nodeName.position.z += previousZ
		previousX = nodeName.position.x
	else:
		nodeName.position.z += -1 + previousZ
		nodeName.position.x += previousX
		previousZ = nodeName.position.z

func generateMap():
	if hud.scores.get_value("values", "hue") >= 360:
		hud.scores.set_value("values", "hue", 0)
	blockMesh.get_surface_override_material(0).albedo_color = Color.from_hsv(hud.scores.get_value("values", "hue")/360.0, 0.35, 1)
	hud.scores.set_value("values", "hue", hud.scores.get_value("values", "hue") + 1)
	for blockNumber in range(mapLength + 1):
		var blockInstanceNumber = "blockInstance" + str(blockNumber)
		var blockInstance = preload("res://scenes/block.tscn").instantiate()
		dictOfCubes[blockInstanceNumber] = blockInstance
		add_child(blockInstance)
		blockInstance.visible = true
		blockInstance.position.y = 0.25 + yCoordinate
		blockInstance.name = "block" + str(blockNumber)
		if blockNumber != 0:
			moveBlock(blockInstance, noiseAt(blockNumber), noiseAt(blockNumber - 1))
		blockPositions["blockX" + str(blockNumber)] = blockInstance.position.x
		blockPositions["blockZ" + str(blockNumber)] = blockInstance.position.z
		yCoordinate += 0.5

func generateBlock():
	var blockNumber = int(dictOfCubes.keys()[-1].split("e")[1]) + 1
	var blockInstanceNumber = "blockInstance" + str(blockNumber)
	var blockInstance = preload("res://scenes/block.tscn").instantiate()
	dictOfCubes[blockInstanceNumber] = blockInstance
	add_child(blockInstance)
	blockInstance.visible = true
	blockInstance.position.y = 0.25 + yCoordinate
	blockInstance.name = "block" + str(blockNumber)
	if blockNumber != 0:
		moveBlock(blockInstance, noiseAt(blockNumber), noiseAt(blockNumber - 1))
	blockPositions["blockX" + str(blockNumber)] = blockInstance.position.x
	blockPositions["blockZ" + str(blockNumber)] = blockInstance.position.z
	yCoordinate += 0.5

func deleteMap():
	for iteration in range(dictOfCubes.size()):
		deleteBlock(iteration)
	dictOfCubes = {}

func deleteBlock(blockIndex):
	var instance = dictOfCubes["blockInstance" + str(blockIndex)]
	print(blockIndex, " ", instance)
	self.remove_child(instance)
	instance.queue_free()
 
func resetMap():
	# wiping map, resetting positions and parameters, generating new map
	deleteMap()
	player.position.x = 0
	camera.position.x = -15
	player.position.y = 0.5
	camera.position.y = 15.5
	player.position.z = 0
	camera.position.z = 15
	previousX = 0
	previousZ = 0
	yCoordinate = 0
	noise.seed = randi()
