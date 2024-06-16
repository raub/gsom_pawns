extends Node

signal onChangeDayTime(value);
signal onStartDay();
signal onStartNight();

var dayLength: float = 0.0;
var dayTick: float = 0.1;
var dayPart: float = 0.5;


var _day: int = 1;
@export var day: int = 1:
	get:
		return _day;
	set(value):
		if value == _day:
			return;
		_day = value;


var _dayTime: float = 0;
@export var dayTime: float = 0:
	get:
		return _dayTime;
	set(value):
		_dayTime = value;
		emit_signal("onChangeDayTime", _dayTime);


@onready var _timerDay: Timer = $TimerDay;

func _ready() -> void:
	_timerDay.timeout.connect(_tickDay);


func _tickDay() -> void:
	if !dayLength:
		emit_signal("onChangeDayTime", _dayTime);
		return;
	
	var _oldTime: float = _dayTime;
	_dayTime += (1.0 / (1.0 / dayTick)) / dayLength;
	
	if _dayTime > 1:
		_day += 1;
		emit_signal("onStartDay");
		_dayTime -= 1.0;
	
	if _oldTime < dayPart && _dayTime > dayPart:
		emit_signal("onStartNight");
	
	emit_signal("onChangeDayTime", _dayTime);


func findBestSpawnTarget() -> Transform3D:
	if !is_inside_tree():
		return Transform3D.IDENTITY;
	
	var startNodes: Array = get_tree().get_nodes_in_group("Start");
	
	if startNodes.is_empty():
		return Transform3D.IDENTITY;
	
	var mobileNodes: Array = get_tree().get_nodes_in_group("Player");
	var freeStarts: Array[Node] = [];
	
	for startNode in startNodes:
		var start: Node = startNode;
		if !start:
			continue;
		var startPos: Vector3 = start.pos;
		var isFree = true;
		for mobileNode in mobileNodes:
			var mobile: Node = mobileNode;
			if !mobile:
				continue;
			var mobilePos: Vector3 = mobile.pos;
			var dist: float = startPos.distance_to(mobilePos);
			if dist < 1:
				isFree = false;
				break;
		if isFree:
			freeStarts.append(start);
	
	if !freeStarts.is_empty():
		var parent: Node3D = freeStarts[0].get_parent() as Node3D;
		if !parent:
			return Transform3D.IDENTITY;
		return parent.global_transform;
	
	var firstStart: Node = startNodes[0];
	if !firstStart:
		return Transform3D.IDENTITY;
	
	var startParent: Node3D = firstStart.get_parent() as Node3D;
	if !startParent:
		return Transform3D.IDENTITY;
	return startParent.global_transform;


func findBestSpawnPos() -> Vector3:
	if !is_inside_tree():
		return Vector3.ZERO;
	
	var startNodes: Array = get_tree().get_nodes_in_group("Start");
	
	if startNodes.is_empty():
		return Vector3.ZERO;
	
	var mobileNodes: Array = get_tree().get_nodes_in_group("Player");
	var freeStarts: Array[Node] = [];
	
	for startNode in startNodes:
		var start: Node = startNode;
		if !start:
			continue;
		var startPos: Vector3 = start.pos;
		var isFree = true;
		for mobileNode in mobileNodes:
			var mobile: Node = mobileNode;
			if !mobile:
				continue;
			var mobilePos: Vector3 = mobile.pos;
			var dist: float = startPos.distance_to(mobilePos);
			if dist < 1:
				isFree = false;
				break;
		if isFree:
			freeStarts.append(start);
	
	if !freeStarts.is_empty():
		return freeStarts[0].pos;
	
	var firstStart: Node = startNodes[0];
	if !firstStart:
		return Vector3.ZERO;
	
	return firstStart.pos;
