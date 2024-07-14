extends Control

signal switched_character(character_kind: String)
signal switched_controller(controller_kind: String)
signal switched_team(team_name: String)
signal teleported(dest: Vector3)


var _TP_LIST: PackedStringArray = [
	"gdtricks-hub",
	"gdtricks-agtricks-1", "gdtricks-agtricks-2", "gdtricks-agtricks-3",
	"gdtricks-agtricks-4", "gdtricks-agtricks-5",
	"gdtricks-destructo-1", "gdtricks-destructo-2", "gdtricks-destructo-3",
	"gdtricks-destructo-4", "gdtricks-destructo-5", "gdtricks-destructo-6",
	"gdtricks-destructo-7", "gdtricks-destructo-8", "gdtricks-destructo-9",
	"gdtricks-destructo-10",
]

## Use "fps" or "rts" to fine-tune the UI
@export var controller_kind: String = "fps"
@export var controller_team: String = "team1"

var _current_tp_index: int = 0

@onready var _fullscreen: Button = $CenterContainer/Column/RowMain/Fullscreen
@onready var _windowed: Button = $CenterContainer/Column/RowMain/Windowed
@onready var _quit: Button = $CenterContainer/Column/RowMain/Quit
@onready var _button_next: Button = $CenterContainer/Column/ButtonNext
@onready var _button_prev: Button = $CenterContainer/Column/ButtonPrev
@onready var _button_human: Button = $CenterContainer/Column/RowCharacters/Human
@onready var _button_vtol: Button = $CenterContainer/Column/RowCharacters/Vtol
@onready var _button_spec: Button = $CenterContainer/Column/RowCharacters/Spec
@onready var _button_fps: Button = $CenterContainer/Column/RowControllers/Fps
@onready var _button_rts: Button = $CenterContainer/Column/RowControllers/Rts
@onready var _label_characters: Control = $CenterContainer/Column/LabelCharacters
@onready var _label_teams: Control = $CenterContainer/Column/LabelTeams
@onready var _row_characters: Control = $CenterContainer/Column/RowCharacters
@onready var _row_teams: Control = $CenterContainer/Column/RowTeams
@onready var _button_team_1: Button = $CenterContainer/Column/RowTeams/Team1
@onready var _button_team_2: Button = $CenterContainer/Column/RowTeams/Team2


func _ready() -> void:
	var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
	_fullscreen.visible = !is_full
	_windowed.visible = is_full
	_fullscreen.pressed.connect(func () -> void: _set_fullscreen(true))
	_windowed.pressed.connect(func () -> void: _set_fullscreen(false))
	_quit.pressed.connect(func () -> void: get_tree().quit())
	
	_button_next.pressed.connect(_tp_delta.bind(1))
	_button_prev.pressed.connect(_tp_delta.bind(-1))
	
	_button_human.pressed.connect(func () -> void: switched_character.emit("human"))
	_button_vtol.pressed.connect(func () -> void: switched_character.emit("vtol"))
	_button_spec.pressed.connect(func () -> void: switched_character.emit("spec"))
	
	_button_team_1.pressed.connect(func () -> void: switched_team.emit("team1"))
	_button_team_2.pressed.connect(func () -> void: switched_team.emit("team2"))
	
	_button_next.visible = controller_kind == "fps"
	_button_prev.visible = controller_kind == "fps"
	_label_characters.visible = controller_kind == "fps"
	_row_characters.visible = controller_kind == "fps"
	_label_teams.visible = controller_kind == "rts"
	_row_teams.visible = controller_kind == "rts"
	
	_button_fps.visible = controller_kind != "fps"
	_button_rts.visible = controller_kind != "rts"
	
	_button_fps.pressed.connect(func () -> void: switched_controller.emit("fps"))
	_button_rts.pressed.connect(func () -> void: switched_controller.emit("rts"))


func _set_fullscreen(is_full: bool) -> void:
	_fullscreen.visible = !is_full
	_windowed.visible = is_full
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _tp_delta(plus_minus_one: int) -> void:
	var next: int = _current_tp_index + plus_minus_one
	_current_tp_index = (next + _TP_LIST.size()) % _TP_LIST.size()
	var teleports: Array[Node] = get_tree().get_nodes_in_group("Teleport")
	var wanted_tag: String = _TP_LIST[_current_tp_index]
	for teleport: Node in teleports:
		if teleport.tag != wanted_tag:
			continue
		var tp_parent := teleport.get_parent() as Node3D
		if tp_parent:
			teleported.emit(tp_parent.global_position)
