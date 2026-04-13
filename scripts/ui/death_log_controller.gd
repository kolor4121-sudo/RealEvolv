class_name DeathLogController
extends RefCounted

var _panel: PanelContainer
var _label: Label
var _entries: Array[String] = []


func build(canvas_layer: CanvasLayer) -> void:
	if canvas_layer == null:
		return

	_panel = PanelContainer.new()
	_panel.name = "DeathLog"
	_panel.visible = false
	_panel.offset_left = 760.0
	_panel.offset_top = 16.0
	_panel.offset_right = 1190.0
	_panel.offset_bottom = 520.0
	canvas_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.set("theme_override_constants/margin_left", 12)
	margin.set("theme_override_constants/margin_top", 10)
	margin.set("theme_override_constants/margin_right", 12)
	margin.set("theme_override_constants/margin_bottom", 10)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Журнал смертей"
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(380.0, 0.0)
	scroll.add_child(content)

	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.text = "Пока никто не умер."
	content.add_child(_label)


func toggle() -> void:
	if _panel == null:
		return
	_panel.visible = not _panel.visible


func hide() -> void:
	if _panel != null:
		_panel.visible = false


func clear() -> void:
	_entries.clear()
	if _label != null:
		_label.text = "Пока никто не умер."


func append(entry: String) -> void:
	_entries.push_front(entry)
	if _entries.size() > 60:
		_entries.resize(60)
	if _label != null:
		_label.text = "\n\n".join(_entries) if not _entries.is_empty() else "Пока никто не умер."


func is_visible() -> bool:
	return _panel != null and _panel.visible
