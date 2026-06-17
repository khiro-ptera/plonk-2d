extends Node

signal weather_started(weather_id: String)
signal weather_ended(weather_id: String)

var _unlocked_weathers: Array[String] = []
var _active_weather: String = ""
var _weather_timer: Timer
var _duration_timer: Timer
var _weather_unlocked: bool = false

# threshold -> array of weathers unlocked at that threshold
const WEATHER_THRESHOLDS: Dictionary = {
	10000.0: ["rain", "snow"],
	20000.0: ["earthquake"],
}

func _ready() -> void:
	_weather_timer = Timer.new()
	_weather_timer.one_shot = true
	_weather_timer.timeout.connect(_roll_weather)
	add_child(_weather_timer)

	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_end_weather)
	add_child(_duration_timer)

	GameState.plinks_changed.connect(_on_plinks_changed)

func _on_plinks_changed(amount: float) -> void:
	for threshold: float in WEATHER_THRESHOLDS.keys():
		if amount >= threshold:
			for weather: String in WEATHER_THRESHOLDS[threshold]:
				if not _unlocked_weathers.has(weather):
					_unlocked_weathers.append(weather)
	if not _weather_unlocked and _unlocked_weathers.size() > 0:
		_weather_unlocked = true
		_schedule_next()

func _schedule_next() -> void:
	if _unlocked_weathers.size() == 0:
		return
	var wait: float = randf_range(30.0, 90.0)
	_weather_timer.start(wait)

func _roll_weather() -> void:
	if _unlocked_weathers.size() == 0:
		return
	var idx := randi() % _unlocked_weathers.size()
	_active_weather = _unlocked_weathers[idx]
	weather_started.emit(_active_weather)
	_duration_timer.start(10.0)  # each weather lasts 10 seconds total

func _end_weather() -> void:
	weather_ended.emit(_active_weather)
	_active_weather = ""
	_schedule_next()
