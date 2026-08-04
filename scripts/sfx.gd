extends Node

# Autoloaded as `Sfx`. The project ships no audio files, so every sound is
# synthesised into an AudioStreamWAV at startup and played from a small pool
# of players.

const RATE := 22050

var _bank := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

	_bank["chop"]    = _wav(_chop())
	_bank["crack"]   = _wav(_crack())
	_bank["fall"]    = _wav(_fall())
	_bank["pickup"]  = _wav(_pickup())
	_bank["open"]    = _wav(_knock(0.10, 190.0))
	_bank["empty"]   = _wav(_knock(0.14, 96.0))
	_bank["pour"]    = _wav(_pour())
	_bank["mix_ok"]  = _wav(_chord([523.0, 659.0, 784.0], 0.5))
	_bank["mix_bad"] = _wav(_buzz())
	_bank["whoosh"]  = _wav(_whoosh())
	_bank["choke"]   = _wav(_choke())


func play(name: String, db := -6.0, pitch := 1.0) -> void:
	if not _bank.has(name):
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _bank[name]
	p.volume_db = db
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.play()


# ── synthesis ────────────────────────────────────────────────────────────
func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


func _len(sec: float) -> int:
	return int(RATE * sec)


# Axe into wet wood: a filtered noise thwack over a low body thump.
func _chop() -> PackedFloat32Array:
	var n := _len(0.20)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var env: float = exp(-t * 26.0)
		lp += (randf_range(-1.0, 1.0) - lp) * 0.35
		var body: float = sin(TAU * 88.0 * t) * exp(-t * 18.0) * 0.6
		out[i] = (lp * 1.4 + body) * env
	return out


# A dry fibre snapping.
func _crack() -> PackedFloat32Array:
	var n := _len(0.12)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.75
		out[i] = lp * exp(-t * 48.0) * 1.2
	return out


# The limb giving way and hitting the floor.
func _fall() -> PackedFloat32Array:
	var n := _len(0.75)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.12
		var thud: float = sin(TAU * lerpf(120.0, 46.0, minf(t * 3.0, 1.0)) * t)
		out[i] = (lp * 0.9 + thud * 0.8) * exp(-t * 5.0)
	return out


func _pickup() -> PackedFloat32Array:
	var n := _len(0.24)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var f: float = 660.0 if t < 0.08 else 990.0
		out[i] = sin(TAU * f * t) * exp(-t * 11.0) * 0.5
	return out


func _knock(dur: float, freq: float) -> PackedFloat32Array:
	var n := _len(dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.3
		out[i] = (sin(TAU * freq * t) * 0.8 + lp * 0.5) * exp(-t * 30.0)
	return out


func _pour() -> PackedFloat32Array:
	var n := _len(0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.22
		var env: float = minf(t * 8.0, 1.0) * exp(-t * 3.2)
		out[i] = lp * env * 0.9
	return out


func _chord(freqs: Array, dur: float) -> PackedFloat32Array:
	var n := _len(dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in freqs.size():
			var start: float = k * 0.09
			if t >= start:
				v += sin(TAU * freqs[k] * (t - start)) * exp(-(t - start) * 5.0)
		out[i] = v * 0.28
	return out


func _buzz() -> PackedFloat32Array:
	var n := _len(0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (fposmod(t * 104.0, 1.0) * 2.0 - 1.0) * exp(-t * 6.0) * 0.35
	return out


func _whoosh() -> PackedFloat32Array:
	var n := _len(0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * lerpf(0.5, 0.08, minf(t * 1.4, 1.0))
		out[i] = lp * minf(t * 14.0, 1.0) * exp(-t * 2.6) * 1.1
	return out


func _choke() -> PackedFloat32Array:
	var n := _len(0.8)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.1
		var tone: float = sin(TAU * lerpf(300.0, 70.0, minf(t * 1.3, 1.0)) * t)
		out[i] = (lp * 0.7 + tone * 0.5) * exp(-t * 3.0) * 0.8
	return out
