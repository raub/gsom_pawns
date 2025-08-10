extends Control
class_name EscOverlay

signal switched_character(character_kind: String)
signal switched_controller(controller_kind: String)
signal switched_team(team_name: String)
signal teleported(dest: Vector3)


var __TP_LIST: PackedStringArray = [
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

var __current_tp_index: int = 0

@onready var __fullscreen: Button = $CenterContainer/Column/RowMain/Fullscreen
@onready var __windowed: Button = $CenterContainer/Column/RowMain/Windowed
@onready var __quit: Button = $CenterContainer/Column/RowMain/Quit
@onready var __button_next: Button = $CenterContainer/Column/RowTeleport/ButtonNext
@onready var __button_prev: Button = $CenterContainer/Column/RowTeleport/ButtonPrev
@onready var __button_human: Button = $CenterContainer/Column/RowCharacters/Human
@onready var __button_vtol: Button = $CenterContainer/Column/RowCharacters/Vtol
@onready var __button_spec: Button = $CenterContainer/Column/RowCharacters/Spec
@onready var __button_fps: Button = $CenterContainer/Column/RowControllers/Fps
@onready var __button_rts: Button = $CenterContainer/Column/RowControllers/Rts
@onready var __label_characters: Control = $CenterContainer/Column/LabelCharacters
@onready var __label_teams: Control = $CenterContainer/Column/LabelTeams
@onready var __row_characters: Control = $CenterContainer/Column/RowCharacters
@onready var __row_teams: Control = $CenterContainer/Column/RowTeams
@onready var __row_teleport: Control = $CenterContainer/Column/RowTeleport
@onready var __button_team_1: Button = $CenterContainer/Column/RowTeams/Team1
@onready var __button_team_2: Button = $CenterContainer/Column/RowTeams/Team2


func _ready() -> void:
	var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
	__fullscreen.visible = !is_full
	__windowed.visible = is_full
	__fullscreen.pressed.connect(func () -> void: __set_fullscreen(true))
	__windowed.pressed.connect(func () -> void: __set_fullscreen(false))
	__quit.pressed.connect(func () -> void: get_tree().quit())
	
	__button_next.pressed.connect(__tp_delta.bind(1))
	__button_prev.pressed.connect(__tp_delta.bind(-1))
	
	__button_human.pressed.connect(func () -> void: switched_character.emit("human"))
	__button_vtol.pressed.connect(func () -> void: switched_character.emit("vtol"))
	__button_spec.pressed.connect(func () -> void: switched_character.emit("spec"))
	
	__button_team_1.pressed.connect(func () -> void: switched_team.emit("team1"))
	__button_team_2.pressed.connect(func () -> void: switched_team.emit("team2"))
	
	__row_teleport.visible = controller_kind == "fps"
	__label_characters.visible = controller_kind == "fps"
	__row_characters.visible = controller_kind == "fps"
	__label_teams.visible = controller_kind == "rts"
	__row_teams.visible = controller_kind == "rts"
	
	__button_fps.visible = controller_kind != "fps"
	__button_rts.visible = controller_kind != "rts"
	
	__button_fps.pressed.connect(func () -> void: switched_controller.emit("fps"))
	__button_rts.pressed.connect(func () -> void: switched_controller.emit("rts"))


func __set_fullscreen(is_full: bool) -> void:
	__fullscreen.visible = !is_full
	__windowed.visible = is_full
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func __tp_delta(plus_minus_one: int) -> void:
	var next: int = __current_tp_index + plus_minus_one
	__current_tp_index = (next + __TP_LIST.size()) % __TP_LIST.size()
	var wanted_tag: String = __TP_LIST[__current_tp_index]
	
	var parent_3d: Node3D = Teleport.find_target_by_tag(wanted_tag)
	if parent_3d:
		teleported.emit(parent_3d.global_position)
