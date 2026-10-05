extends Node
class_name SoundManager

var master_volume: float = 0.8
var sfx_volume: float = 0.9

func _ready() -> void:
	pass

func set_volumes(master: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)

func _play_tone(freq: float, duration: float, vol: float = 0.5) -> void:
	# Generates a simple beep via AudioStreamGenerator
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = duration
	player.stream = gen
	player.volume_db = linear_to_db(vol * master_volume * sfx_volume)
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames: int = int(gen.mix_rate * duration)
	for i in range(frames):
		var t: float = float(i) / gen.mix_rate
		var sample: float = sin(t * freq * PI * 2.0) * 0.5
		playback.push_frame(Vector2(sample, sample))

	await get_tree().create_timer(duration + 0.05).timeout
	player.queue_free()

func play_order_complete() -> void:
	# Rising chord
	_play_tone(440.0, 0.08, 0.4)
	await get_tree().create_timer(0.1).timeout
	_play_tone(550.0, 0.08, 0.4)
	await get_tree().create_timer(0.1).timeout
	_play_tone(660.0, 0.12, 0.5)

func play_game_over() -> void:
	_play_tone(220.0, 0.3, 0.45)
	await get_tree().create_timer(0.35).timeout
	_play_tone(180.0, 0.35, 0.45)
	await get_tree().create_timer(0.4).timeout
	_play_tone(140.0, 0.5, 0.45)

func play_victory() -> void:
	for note in [523.0, 659.0, 784.0, 1047.0]:
		_play_tone(note, 0.12, 0.4)
		await get_tree().create_timer(0.15).timeout

func play_hit() -> void:
	_play_tone(200.0, 0.1, 0.35)

func play_dash() -> void:
	_play_tone(600.0, 0.07, 0.25)

func play_knife() -> void:
	_play_tone(880.0, 0.05, 0.18)
