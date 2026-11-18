class_name UiFonts
extends RefCounted
## Centralized tiered font stack and typography scale for 2D HUD and 3D labels.

const FONT_LATIN_SYMBOLS := "res://assets/fonts/yozai_latin_symbols.ttf"
const FONT_CJK_PRIMARY := "res://assets/fonts/lemi_zhixia_qianfeng.ttf"
const FONT_CJK_FALLBACK := "res://assets/fonts/yozai_regular.ttf"

## Ordered fallback stack:
## 1. Yozai Latin & Symbols subset (ASCII, tabular digits, '-', arrows, math)
## 2. Lemi Zhixia Qianfeng (primary handwritten Chinese characters & punctuation)
## 3. Full Yozai Regular (complete CJK BMP superset + exotic symbol fallback)
const FONT_TIERS: Array[String] = [
	FONT_LATIN_SYMBOLS,
	FONT_CJK_PRIMARY,
	FONT_CJK_FALLBACK,
]

const SYSTEM_FALLBACK_NAMES: PackedStringArray = [
	"PingFang SC",
	"Microsoft YaHei UI",
	"Microsoft YaHei",
	"Noto Sans CJK SC",
	"Segoe UI",
	"sans-serif",
]

const SIZE_HUD := 16
const SIZE_CARD_EFFECT := 36
const SIZE_CARD_ACTION := 40
const SIZE_DIE_COST := 48
const COLOR_INK := Color(0.27, 0.18, 0.12, 1.0)


## Returns the primary Font configured with the full multi-tier fallback chain.
static func get_font() -> Font:
	var loaded: Array[Font] = []
	for path in FONT_TIERS:
		if not ResourceLoader.exists(path):
			continue
		var font := ResourceLoader.load(path) as Font
		if font != null:
			loaded.append(font)
	if loaded.is_empty():
		var system_only := SystemFont.new()
		system_only.font_names = SYSTEM_FALLBACK_NAMES
		return system_only

	var primary := loaded[0]
	var expected_fallbacks := loaded.size()  # remaining tiers + 1 SystemFont safety net
	if primary.fallbacks.size() != expected_fallbacks:
		var tail: Array[Font] = []
		for i in range(1, loaded.size()):
			tail.append(loaded[i])
		var system_fallback := SystemFont.new()
		system_fallback.font_names = SYSTEM_FALLBACK_NAMES
		tail.append(system_fallback)
		primary.fallbacks = tail
	return primary


## Builds a 2D UI Theme bound to the tiered handwriting font stack.
static func build_ui_theme(base_size: int = SIZE_HUD) -> Theme:
	var theme := Theme.new()
	theme.default_font = get_font()
	theme.default_font_size = base_size
	return theme


## Applies the tiered handwriting font and typographic scale to a RichTextLabel.
static func apply_richtext_tier(
	label: RichTextLabel,
	font_size: int,
	default_color: Color = COLOR_INK,
) -> void:
	var font := get_font()
	if font != null:
		label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", default_color)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
