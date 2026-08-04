extends Node

# Autoloaded as `Music`. Plays looping background music under the SFX layer.

const STREAM_PATH := "res://audio/existence.mp3"
const VOLUME_DB := -8.0

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	# Sample playback ignores the loop flag on some platforms (notably web).
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_player.volume_db = VOLUME_DB
	add_child(_player)

	var stream := load(STREAM_PATH) as AudioStream
	if stream == null:
		push_warning("Music: failed to load %s" % STREAM_PATH)
		return

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_player.stream = stream
	_player.finished.connect(_on_finished)
	_player.play()


func _on_finished() -> void:
	_player.play()


func set_volume_db(db: float) -> void:
	if _player:
		_player.volume_db = db


func stop() -> void:
	if _player:
		_player.stop()
