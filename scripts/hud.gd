extends Node2D

var scores = ConfigFile.new()
var quests = ConfigFile.new()
var skins = ConfigFile.new()
var thread = Thread.new()
var rng = RandomNumberGenerator.new()
var questArray = []
var taps = 0
var stopLoop = true
@onready var map = $"../../map"
@onready var player = $"../../player"
@onready var playerSkin = $"skinViewPort/player"
@onready var view = $"buttons"
@onready var menus = $"menus"
@onready var steering = $"steering"
@onready var fpsLabel = $"buttons/buttonsVBox/top/topHBox/fps"
@onready var currencyLabel = $"buttons/buttonsVBox/top/topHBox/currency"
@onready var scoreNumber = $"buttons/buttonsVBox/top/topHBox/scoreVBox/scoreNumber"
@onready var mapProgressBar = $"buttons/buttonsVBox/top/topHBox/scoreVBox/mapProgressBar"
@onready var highScoreText = $"../../highScoreDisplay"
@onready var tapsPerSecond = $"../../highScoreDisplay"
@onready var modeButton = $"buttons/buttonsVBox/middle/middleHBox/middleVBox/middleHBox/modeButton"
@onready var skinSelectButton = $"menus/skinMenu/elementContainerVertical/elementContainerHorizontal/skinSelect/skinSelectButton"
@onready var volumeButton = $"menus/settingsMenu/settingsContainer/paddingVolumeButton/VBoxContainer/volumeButton"
@onready var vibrateButton = $"menus/settingsMenu/settingsContainer/paddingVibrateButton/vibrateButton"
@onready var questDesc1 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer1/questButton1"
@onready var questDesc2 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer2/questButton2"
@onready var questDesc3 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer3/questButton3"
@onready var questProgressBar1 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer1/progressBarQuest1"
@onready var questProgressBar2 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer2/progressBarQuest2"
@onready var questProgressBar3 = $"menus/questMenu/questContainerHorizontal/questContainerVertical/questContainer3/progressBarQuest3"


func _ready():
	# set view box to top half of the screen
	view.size.x = DisplayServer.window_get_size().x
	view.size.y = float(DisplayServer.window_get_size().y) * 2 / 3
	menus.size = DisplayServer.window_get_size()
	steering.size = DisplayServer.window_get_size()
	
	# load quests and throw error if unreadable or missing
	var errorQuestsLoad = quests.load("res://config/quests.cfg")
	if errorQuestsLoad != OK:
		print("failed to load quests")
	# load quest descriptions
	
	# load scores and throw error if unreadable or missing
	var errorScoresLoad = scores.load("res://config/scores.cfg")
	if errorScoresLoad != OK:
		print("failed to load scores")
		highScoreText.text = "Loading scores failed"
	
	# load skins and throw error if unreadable or missing
	var errorSkinsLoad = skins.load("res://config/skins.cfg")
	if errorSkinsLoad != OK:
		print("failed to load skins")
	
	loadQuestDesc()
	
	if scores.get_value("values", "highScoreNumber") > 0:
		displayHighScore(scores.get_value("values", "highScoreNumber"))
	
	player.previewSkin = scores.get_value("values", "currentSkin")
	player.updateSkin()
	
	var timeString = Time.get_date_string_from_system().to_int()
	if timeString > scores.get_value("values", "date"):
		if timeString + 1 == scores.get_value("values", "date"):
			scores.set_value("values", "logInStreak", scores.get_value("values", "logInStreak") + 1)
		else:
			scores.set_value("values", "logInStreak", 1)
			loadQuestDesc()
		scores.set_value("values", "date", timeString)
	
	match [scores.get_value("values", "endlessMode"), scores.get_value("values", "extremeMode")]:
		[false, false]:
			setNormalMode()
		[false, true]:
			setNormalExtremeMode()
		[true, false]:
			setInfiniteMode()
		[true, true]:
			setInfiniteExtremeMode()


	DiscordRPC.app_id = 728621303480713227
	DiscordRPC.large_image = "jumpKing"
	DiscordRPC.large_image_text = "Jump King"
	#DiscordRPC.small_image = ""
	#DiscordRPC.small_image_text = ""
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
	
	updateCurrency()
	updateQuestProgress()


func _process(_delta):
	fpsLabel.text = str(Engine.get_frames_per_second())
	scoreNumber.text = "%.3f" % map.timeTaken
	if !map.endlessMode:
		mapProgressBar.value = taps
	if scores.get_value("values", "highScoreNumber") != 0:
		DiscordRPC.details = str(" High Score: %.3f" % scores.get_value("values", "highScoreNumber"))
		DiscordRPC.refresh()
	else:
		DiscordRPC.details = "Started Playing"
		DiscordRPC.refresh()



func _on_left_pressed():
	if map.endlessMode and map.extremeMode:
		player.moveLeft(false)
	else:
		player.moveLeft(true)
	taps += 1

func _on_right_pressed():
	if map.endlessMode and map.extremeMode:
		player.moveRight(false)
	else:
		player.moveRight(true)
	taps += 1


func _on_quest_button_1_pressed():
	if quests.get_value(questArray[0], "questClaimable") and !quests.get_value(questArray[0], "questClaimed"):
		quests.set_value(questArray[0], "questClaimed", true)
		updateQuestProgress()
		scores.set_value("values", "currency", scores.get_value("values", "currency") + 125)
		updateCurrency()
		autoSave()

func _on_quest_button_2_pressed():
	if quests.get_value(questArray[1], "questClaimable") and !quests.get_value(questArray[1], "questClaimed"):
		quests.set_value(questArray[1], "questClaimed", true)
		updateQuestProgress()
		scores.set_value("values", "currency", scores.get_value("values", "currency") + 125)
		updateCurrency()
		autoSave()

func _on_quest_button_3_pressed():
	if quests.get_value(questArray[2], "questClaimable") and !quests.get_value(questArray[2], "questClaimed"):
		quests.set_value(questArray[2], "questClaimed", true)
		updateQuestProgress()
		scores.set_value("values", "currency", scores.get_value("values", "currency") + 125)
		updateCurrency()
		autoSave()


func _on_settings_button_pressed():
	$"menus/settingsMenu".visible = true
	$"menus/behindMenuButton".visible = true

func _on_skin_button_pressed():
	updateSelectButton()
	player.updateSkin()
	$"menus/skinMenu".visible = true
	$"menus/behindMenuButton".visible = true

func _on_quest_button_pressed():
	updateQuestProgress()
	$"menus/questMenu".visible = true
	$"menus/behindMenuButton".visible = true

func _on_mode_button_pressed():
	$"menus/modeMenu".visible = true
	$"menus/behindMenuButton".visible = true

func _on_behind_menu_button_pressed():
	$"menus/behindMenuButton".visible = false
	$"menus/onDeathMenu".visible = false
	$"menus/settingsMenu".visible = false
	$"menus/skinMenu".visible = false
	$"menus/questMenu".visible = false
	$"menus/modeMenu".visible = false
	player.previewSkin = scores.get_value("values", "currentSkin")


func _on_reset_button_pressed():
	scores.set_value("values", "highScoreNumber", -1)
	scores.set_value("values", "highScoreNumbers", {
		"normal": -1,
		"normalExtreme": -1,
		"infinite": -1,
		"infiniteExtreme": -1
	})
	scores.set_value("values", "currency", 0)
	scores.set_value("values", "date", Time.get_date_string_from_system().to_int())
	scores.set_value("values", "jumpBlock", 0)
	scores.set_value("values", "playTime", 0)
	scores.set_value("values", "logInStreak", 1)
	scores.set_value("values", "currentSkin", "default")
	scores.set_value("values", "hue", 0)
	for skin in skins.get_sections():
		skins.set_value(skin, "owned", false)
	skins.set_value("default", "owned", true)
	for quest in quests.get_sections():
		quests.set_value(quest, "questClaimable", false)
		quests.set_value(quest, "questClaimed", false)
	taps = 0
	map.alive = false
	map.timeTaken = 0
	highScoreText.text = ""
	updateCurrency()
	loadQuestDesc()
	updateQuestProgress()
	autoSave()


func _on_right_button_pressed():
	player.previewSkin = skins.get_sections()[(skins.get_sections().find(player.previewSkin) + 1) % len(skins.get_sections())]
	player.updateSkin()
	updateSelectButton()


func _on_left_button_pressed():
	player.previewSkin = skins.get_sections()[(skins.get_sections().find(player.previewSkin) - 1) % len(skins.get_sections())]
	player.updateSkin()
	updateSelectButton()


func _on_skin_select_button_pressed():
	# if not owned, buy
	if !skins.get_value(player.previewSkin, "owned") and scores.get_value("values", "currency") >= skins.get_value(player.previewSkin, "cost"):
		scores.set_value("values", "currency", scores.get_value("values", "currency") - skins.get_value(player.previewSkin, "cost"))
		skins.set_value(player.previewSkin, "owned", true)
	# if owned, equip
	if skins.get_value(player.previewSkin, "owned"):
		scores.set_value("values", "currentSkin", player.previewSkin)
	player.updateSkin()
	updateSelectButton()
	updateCurrency()
	autoSave()


func updateSelectButton():
	if player.previewSkin == scores.get_value("values", "currentSkin"):
		# selected
		skinSelectButton.text = "Selected"
	elif skins.get_value(player.previewSkin, "owned"):
		# select
		skinSelectButton.text = "Select"
	else:
		# display price
		skinSelectButton.text = str(skins.get_value(player.previewSkin, "cost"))


func displayHighScore(highScoreParameter):
	if highScoreParameter <= 0:
		highScoreText.text = ""
	elif scores.get_value("values", "endlessMode"):
		highScoreText.text = str(int(scores.get_value("values", "highScoreNumber")))
	else:
		highScoreText.text = "%.3f" % scores.get_value("values", "highScoreNumber")


func displayTapsPerSecond(timeTaken):
	$"menus/onDeathMenu/statsContainer/tapsPerSecond".text = "%.2f" % (taps / timeTaken) + " taps/s"


func _exit_tree():
	thread.wait_to_finish()


func loadQuestDesc():
	questArray = Array(quests.get_sections())
	questArray.shuffle()
	
	questDesc1.text = quests.get_value(questArray[0], "questDescription")
	questDesc2.text = quests.get_value(questArray[1], "questDescription")
	questDesc3.text = quests.get_value(questArray[2], "questDescription")


func updateQuestProgress():
	var value
	for quest in range(1, 4):
		if "logInStreak" in quests.get_value("quest" + str(quest), "questCondition"):
			value = scores.get_value("values", "logInStreak")
		elif "playTime" in quests.get_value("quest" + str(quest), "questCondition"):
			value = scores.get_value("values", "playTime")
		elif "jumpBlock" in quests.get_value("quest" + str(quest), "questCondition"):
			value = scores.get_value("values", "jumpBlock")
		
		if quests.get_value("quest" + str(quest), "questDescription") == questDesc1.text:
			questProgressBar1.set_value(value * 100 / int(quests.get_value("quest" + str(quest), "questCondition").split("=")[1]))
		if quests.get_value("quest" + str(quest), "questDescription") == questDesc2.text:
			questProgressBar2.set_value(value * 100 / int(quests.get_value("quest" + str(quest), "questCondition").split("=")[1]))
		if quests.get_value("quest" + str(quest), "questDescription") == questDesc3.text:
			questProgressBar3.set_value(value * 100 / int(quests.get_value("quest" + str(quest), "questCondition").split("=")[1]))
		
		if questProgressBar1.value >= 100:
			quests.set_value(questArray[0], "questClaimable", true)
		if questProgressBar2.value >= 100:
			quests.set_value(questArray[1], "questClaimable", true)
		if questProgressBar3.value >= 100:
			quests.set_value(questArray[2], "questClaimable", true)
	
	autoSave()

func autoSave():
	quests.save("res://config/quests.cfg")
	scores.save("res://config/scores.cfg")
	skins.save("res://config/skins.cfg")


func updateCurrency():
	currencyLabel.text = str(scores.get_value("values", "currency"))


func _on_volume_button_pressed():
	if volumeButton.text == "Volume On":
		volumeButton.text = "Volume Off"
	else:
		volumeButton.text = "Volume On"


func _on_vibrate_button_pressed():
	if vibrateButton.text == "Vibration On":
		vibrateButton.text = "Vibration Off"
	else:
		vibrateButton.text = "Vibration On"


func _on_normal_mode_button_pressed():
	if map.alive:
		map.alive = false
	map.resetMap()
	setNormalMode()
	map.generateMap()
	mapProgressBar.value = 0

func setNormalMode():
	map.endlessMode = false
	map.extremeMode = false
	map.reward = 15
	map.mapLength = 50
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalModeButton.texture_normal.width = 300
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalExtremeModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteExtremeModeButton.texture_normal.width = 200
	scores.set_value("values", "endlessMode", false)
	scores.set_value("values", "extremeMode", false)
	scores.set_value("values", "highScoreNumber", scores.get_value("values", "highScoreNumbers")["normal"])
	displayHighScore(scores.get_value("values", "highScoreNumber"))
	autoSave()


func _on_normal_extreme_mode_button_pressed():
	if map.alive:
		map.alive = false
	map.resetMap()
	setNormalExtremeMode()
	map.generateMap()
	mapProgressBar.value = 0

func setNormalExtremeMode():
	# activate map deletion
	map.endlessMode = false
	map.extremeMode = true
	map.reward = 30
	map.mapLength = 70
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalExtremeModeButton.texture_normal.width = 300
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteExtremeModeButton.texture_normal.width = 200
	scores.set_value("values", "endlessMode", false)
	scores.set_value("values", "extremeMode", true)
	scores.set_value("values", "highScoreNumber", scores.get_value("values", "highScoreNumbers")["normalExtreme"])
	displayHighScore(scores.get_value("values", "highScoreNumber"))
	autoSave()


func _on_infinite_mode_button_pressed():
	if map.alive:
		map.alive = false
	map.resetMap()
	setInfiniteMode()
	map.generateMap()
	mapProgressBar.value = 0

func setInfiniteMode():
	# infinite map, less coins
	map.endlessMode = true
	map.extremeMode = false
	map.reward = 0
	map.mapLength = 50
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalExtremeModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteModeButton.texture_normal.width = 300
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteExtremeModeButton.texture_normal.width = 200
	scores.set_value("values", "endlessMode", true)
	scores.set_value("values", "extremeMode", false)
	scores.set_value("values", "highScoreNumber", scores.get_value("values", "highScoreNumbers")["infinite"])
	displayHighScore(scores.get_value("values", "highScoreNumber"))
	autoSave()


func _on_infinite_extreme_mode_button_pressed():
	if map.alive:
		map.alive = false
	map.resetMap()
	setInfiniteExtremeMode()
	map.generateMap()
	mapProgressBar.value = 0

func setInfiniteExtremeMode():
	# infinite map, invisible skin, random camera movement, more coins
	# set camera attribute top level to true and randomly decide whether it follows or not
	map.endlessMode = true
	map.extremeMode = true
	map.reward = 0
	map.mapLength = 50
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/normalModeContainerHorizontal/normalExtremeModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteModeButton.texture_normal.width = 200
	$menus/modeMenu/modeMenuBackground/modeContainerVertical/infiniteModeContainerHorizontal/infiniteExtremeModeButton.texture_normal.width = 300
	scores.set_value("values", "endlessMode", true)
	scores.set_value("values", "extremeMode", true)
	scores.set_value("values", "highScoreNumber", scores.get_value("values", "highScoreNumbers")["infiniteExtreme"])
	displayHighScore(scores.get_value("values", "highScoreNumber"))
	autoSave()
