class_name Soundscape
extends Node

var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var volume: float = 0.58

func _ready() -> void:
	music = AudioStreamPlayer.new(); add_child(music)
	effect = AudioStreamPlayer.new(); add_child(effect)
	music.stream = _wave([82.41, 123.47, 164.81], 6.0, 0.055, true)
	music.play()
	_apply_volume()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()

func cue(kind: String) -> void:
	var notes: Array[float] = [660.0]
	match kind:
		"action": notes = [490.0, 660.0]
		"warning": notes = [270.0, 220.0]
		"success": notes = [440.0, 554.0, 660.0]
		"failure": notes = [210.0, 174.0]
		"click": notes = [720.0]
	effect.stream = _wave(notes, 0.25, 0.2, false)
	effect.play()

func _apply_volume() -> void:
	if music: music.volume_db = linear_to_db(maxf(volume * 0.52, 0.001))
	if effect: effect.volume_db = linear_to_db(maxf(volume, 0.001))

func _wave(notes: Array[float], duration: float, amplitude: float, looped: bool) -> AudioStreamWAV:
	var rate: int = 22050
	var count: int = int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var time: float = float(i) / float(rate)
		var value: float = 0.0
		for n in notes:
			value += sin(TAU * n * time) / float(notes.size())
		var fade: float = 1.0 if looped else minf(1.0, minf(time * 22.0, (duration - time) * 16.0))
		var sample: int = int(clampf(value * amplitude * fade, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample & 255
		bytes[i * 2 + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.data = bytes; stream.mix_rate = rate; stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	stream.loop_end = count
	return stream
