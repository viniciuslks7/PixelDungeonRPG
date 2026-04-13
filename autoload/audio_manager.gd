extends Node

const MIX_RATE: float = 44100.0
const BUFFER_PADDING_SECONDS: float = 0.08
const MASTER_GAIN: float = 0.45
const VOICE_COUNT: int = 6

const SFX_ATTACK_HIT: StringName = &"attack_hit"
const SFX_ENEMY_HIT: StringName = &"enemy_hit"
const SFX_PLAYER_HIT: StringName = &"player_hit"
const SFX_ITEM_PICKUP: StringName = &"item_pickup"
const SFX_CHEST_OPEN: StringName = &"chest_open"
const SFX_LEVEL_UP: StringName = &"level_up"
const SFX_GAME_OVER: StringName = &"game_over"

enum Waveform {
    SINE,
    SQUARE,
    TRIANGLE,
    NOISE,
}

var _voices: Array[AudioStreamPlayer] = []
var _next_voice_index: int = 0
var _player_actor_names: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_voices()
    _connect_event_bus()

func _setup_voices() -> void:
    _voices.clear()
    _next_voice_index = 0
    for index in range(VOICE_COUNT):
        var voice := AudioStreamPlayer.new()
        voice.name = "SfxVoice%d" % index
        voice.bus = "Master"
        add_child(voice)
        _voices.append(voice)

func _connect_event_bus() -> void:
    var event_bus: Node = get_node_or_null("/root/EventBus")
    if event_bus == null:
        push_warning("AudioManager: EventBus autoload nao encontrado.")
        return

    _connect_event_signal(event_bus, "player_spawned", Callable(self, "_on_player_spawned"))
    _connect_event_signal(event_bus, "actor_attacked", Callable(self, "_on_actor_attacked"))
    _connect_event_signal(event_bus, "actor_damaged", Callable(self, "_on_actor_damaged"))
    _connect_event_signal(event_bus, "item_picked_up", Callable(self, "_on_item_picked_up"))
    _connect_event_signal(event_bus, "chest_opened", Callable(self, "_on_chest_opened"))
    _connect_event_signal(event_bus, "level_up", Callable(self, "_on_level_up"))
    _connect_event_signal(event_bus, "player_died", Callable(self, "_on_player_died"))

func _connect_event_signal(event_bus: Node, signal_name: String, callable: Callable) -> void:
    var signal_id: StringName = StringName(signal_name)
    if not event_bus.has_signal(signal_id):
        return
    if event_bus.is_connected(signal_id, callable):
        return
    event_bus.connect(signal_id, callable)

func _on_player_spawned(player: Node2D) -> void:
    _player_actor_names.clear()
    if not is_instance_valid(player):
        return

    _player_actor_names[String(player.name)] = true
    var display_name_value: Variant = player.get("display_name")
    if display_name_value != null:
        var display_name: String = String(display_name_value)
        if not display_name.is_empty():
            _player_actor_names[display_name] = true

func _on_actor_attacked(_attacker_name: String, _target_name: String, damage: int, _is_critical: bool) -> void:
    if damage <= 0:
        return
    _play_sfx(SFX_ATTACK_HIT)

func _on_actor_damaged(actor_name: String, amount: int, _current_health: int, _max_health: int, _is_critical: bool) -> void:
    if amount <= 0:
        return
    if _is_player_actor_name(actor_name):
        _play_sfx(SFX_PLAYER_HIT)
    else:
        _play_sfx(SFX_ENEMY_HIT)

func _on_item_picked_up(_actor_name: String, _item_name: String, quantity: int) -> void:
    if quantity <= 0:
        return
    _play_sfx(SFX_ITEM_PICKUP)

func _on_chest_opened(_actor_name: String, _floor_level: int, _chest_tier: int, _item_name: String) -> void:
    _play_sfx(SFX_CHEST_OPEN)

func _on_level_up(level: int) -> void:
    if level <= 1:
        return
    _play_sfx(SFX_LEVEL_UP)

func _on_player_died() -> void:
    _play_sfx(SFX_GAME_OVER)

func _is_player_actor_name(actor_name: String) -> bool:
    if actor_name.is_empty():
        return false
    return _player_actor_names.has(actor_name)

func _play_sfx(sfx_id: StringName) -> void:
    var sequence: Array[Dictionary] = _build_sfx_sequence(sfx_id)
    if sequence.is_empty():
        return
    _play_sequence(sequence)

func _build_sfx_sequence(sfx_id: StringName) -> Array[Dictionary]:
    match sfx_id:
        SFX_ATTACK_HIT:
            return [
                {"freq": 760.0, "duration": 0.035, "gain": 0.95, "wave": Waveform.SQUARE},
                {"freq": 520.0, "duration": 0.045, "gain": 0.70, "wave": Waveform.TRIANGLE},
            ]
        SFX_ENEMY_HIT:
            return [
                {"freq": 280.0, "duration": 0.03, "gain": 0.80, "wave": Waveform.NOISE},
                {"freq": 220.0, "duration": 0.055, "gain": 0.70, "wave": Waveform.SINE},
            ]
        SFX_PLAYER_HIT:
            return [
                {"freq": 180.0, "duration": 0.035, "gain": 0.85, "wave": Waveform.NOISE},
                {"freq": 130.0, "duration": 0.07, "gain": 0.80, "wave": Waveform.TRIANGLE},
            ]
        SFX_ITEM_PICKUP:
            return [
                {"freq": 990.0, "duration": 0.03, "gain": 0.75, "wave": Waveform.SINE},
                {"freq": 1320.0, "duration": 0.04, "gain": 0.80, "wave": Waveform.SINE},
            ]
        SFX_CHEST_OPEN:
            return [
                {"freq": 330.0, "duration": 0.045, "gain": 0.75, "wave": Waveform.SQUARE},
                {"freq": 495.0, "duration": 0.05, "gain": 0.72, "wave": Waveform.SQUARE},
                {"freq": 660.0, "duration": 0.07, "gain": 0.68, "wave": Waveform.SINE},
            ]
        SFX_LEVEL_UP:
            return [
                {"freq": 523.25, "duration": 0.06, "gain": 0.65, "wave": Waveform.SINE},
                {"freq": 659.25, "duration": 0.06, "gain": 0.70, "wave": Waveform.SINE},
                {"freq": 783.99, "duration": 0.08, "gain": 0.75, "wave": Waveform.SINE},
                {"freq": 1046.5, "duration": 0.10, "gain": 0.80, "wave": Waveform.TRIANGLE},
            ]
        SFX_GAME_OVER:
            return [
                {"freq": 392.0, "duration": 0.09, "gain": 0.70, "wave": Waveform.TRIANGLE},
                {"freq": 329.63, "duration": 0.09, "gain": 0.68, "wave": Waveform.TRIANGLE},
                {"freq": 261.63, "duration": 0.14, "gain": 0.72, "wave": Waveform.SINE},
            ]
        _:
            return []

func _play_sequence(sequence: Array[Dictionary]) -> void:
    var total_duration: float = 0.0
    for step in sequence:
        total_duration += maxf(float(step.get("duration", 0.0)), 0.0)
    if total_duration <= 0.0:
        return

    var stream := AudioStreamGenerator.new()
    stream.mix_rate = MIX_RATE
    stream.buffer_length = total_duration + BUFFER_PADDING_SECONDS

    var voice: AudioStreamPlayer = _acquire_voice()
    voice.stop()
    voice.stream = stream
    voice.play()

    var playback := voice.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return

    for step in sequence:
        _push_step_frames(playback, step)

func _acquire_voice() -> AudioStreamPlayer:
    if _voices.is_empty():
        _setup_voices()
    var voice: AudioStreamPlayer = _voices[_next_voice_index]
    _next_voice_index = (_next_voice_index + 1) % _voices.size()
    return voice

func _push_step_frames(playback: AudioStreamGeneratorPlayback, step: Dictionary) -> void:
    var frequency: float = maxf(float(step.get("freq", 440.0)), 20.0)
    var duration: float = maxf(float(step.get("duration", 0.01)), 0.005)
    var gain: float = clampf(float(step.get("gain", 1.0)), 0.0, 1.0)
    var waveform: int = int(step.get("wave", Waveform.SINE))
    var frames: int = maxi(int(round(duration * MIX_RATE)), 1)

    var phase: float = 0.0
    var phase_step: float = TAU * frequency / MIX_RATE
    for frame_index in range(frames):
        var normalized_time: float = float(frame_index) / float(frames)
        var envelope: float = _step_envelope(normalized_time)
        var sample: float = _sample_waveform(waveform, phase) * gain * envelope * MASTER_GAIN
        playback.push_frame(Vector2(sample, sample))
        phase += phase_step

func _step_envelope(normalized_time: float) -> float:
    var attack_ratio: float = 0.12
    var release_ratio: float = 0.30
    var attack_gain: float = 1.0
    var release_gain: float = 1.0

    if normalized_time < attack_ratio:
        attack_gain = normalized_time / attack_ratio
    if normalized_time > 1.0 - release_ratio:
        release_gain = (1.0 - normalized_time) / release_ratio

    return clampf(minf(attack_gain, release_gain), 0.0, 1.0)

func _sample_waveform(waveform: int, phase: float) -> float:
    match waveform:
        Waveform.SQUARE:
            return 1.0 if sin(phase) >= 0.0 else -1.0
        Waveform.TRIANGLE:
            var normalized_phase: float = fposmod(phase / TAU, 1.0)
            return 1.0 - (4.0 * absf(normalized_phase - 0.5))
        Waveform.NOISE:
            return randf_range(-1.0, 1.0)
        _:
            return sin(phase)
