extends Node3D

signal onSend(what, where);
signal onReceive(what);

@onready var _teleport: Node = $Area/Teleport;


var _tag: String = "";
@export var tag: String = "":
	get:
		return _tag;
	set(v):
		_tag = v;
		_assignTag();


var _dest: String = "";
@export var dest: String = "":
	get:
		return _dest;
	set(v):
		_dest = v;
		_assignDest();


func _ready() -> void:
	_assignTag();
	_assignDest();
	
	_teleport.onSend.connect(func (what, where) -> void: onSend.emit(what, where));
	_teleport.onReceive.connect(func (what) -> void: onReceive.emit(what));


func _assignTag() -> void:
	if _teleport:
		_teleport.tag = _tag;


func _assignDest() -> void:
	if _teleport:
		_teleport.dest = _dest;
