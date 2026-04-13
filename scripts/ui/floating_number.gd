extends Label

const LIFETIME_SECONDS: float = 0.5
const RISE_DISTANCE: float = 18.0
const DAMAGE_COLOR := Color(0.92, 0.22, 0.22, 1.0)
const CRITICAL_COLOR := Color(0.98, 0.88, 0.24, 1.0)

func _ready() -> void:
    top_level = true
    z_index = 1000
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false

func setup(amount: int, is_critical: bool = false) -> void:
    text = str(maxi(amount, 0))
    modulate = CRITICAL_COLOR if is_critical else DAMAGE_COLOR
    visible = true

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "global_position:y", global_position.y - RISE_DISTANCE, LIFETIME_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate:a", 0.0, LIFETIME_SECONDS).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
    tween.finished.connect(queue_free)
