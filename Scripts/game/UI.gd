extends CanvasLayer

@onready var plinks_label: Label = $MainRightSidebar/PlinksLabel
@onready var plonk_list: VBoxContainer = $MainRightSidebar/PlonkShopScroll/PlonkList

@onready var info_icon_container: Control = $LeftSidebar/InfoPanel/InfoScroll/InfoContent/InfoIconContainer
@onready var info_icon: TextureRect = $LeftSidebar/InfoPanel/InfoScroll/InfoContent/InfoIconContainer/InfoIcon
@onready var info_title: Label = $LeftSidebar/InfoPanel/InfoScroll/InfoContent/InfoTitle
@onready var info_description: Label = $LeftSidebar/InfoPanel/InfoScroll/InfoContent/InfoDescription
@onready var info_stats: VBoxContainer = $LeftSidebar/InfoPanel/InfoScroll/InfoContent/InfoStats
@onready var weather_label: Label = $LeftSidebar/WeatherPanel/WeatherScroll/WeatherContent/WeatherLabel

@onready var legendary_panel: PanelContainer = $LeftSidebar/LegendaryPanel
@onready var lock_overlay: Control = $LeftSidebar/LegendaryPanel/LockOverlay
@onready var legendary_list: VBoxContainer = $LeftSidebar/LegendaryPanel/LegendaryContent/LegendaryScroll/LegendaryList

var _hovered_data: PlonkData = null
var _stats_refresh_timer: Timer

func _ready() -> void:
	_build_top_panel()
	_build_sidebar()
	_build_left_sidebar()
	GameState.plinks_changed.connect(_on_plinks_changed)
	WeatherManager.weather_started.connect(_on_weather_started)
	WeatherManager.weather_ended.connect(_on_weather_ended)
	#_populate_shop()
	GameState.legendary_unlocked.connect(_on_legendary_unlocked)
	_update_legendary_lock_state()
	_stats_refresh_timer = Timer.new()
	_stats_refresh_timer.wait_time = 0.3
	_stats_refresh_timer.timeout.connect(_on_stats_refresh)
	add_child(_stats_refresh_timer)
	_stats_refresh_timer.start()

func _build_top_panel() -> void:
	var panel := $TopPanel
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	var label := $TopPanel/TopLabel
	label.text = "Plonk!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# right side

func _build_sidebar() -> void:
	var sidebar := $MainRightSidebar
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -240.0  
	sidebar.offset_top = 0.0

	plinks_label.text = "Plinks: " + str(GameState.plinks)

func _on_plinks_changed(new_amount: float) -> void:
	plinks_label.text = "Plinks: " + GameState.format_number(new_amount)
	_check_unlocks(new_amount)
	_update_button_prices()
	# _populate_shop()

func _check_unlocks(current_plinks: float) -> void:
	var any_new := false
	for id in PlonkManager.definitions:
		var data: PlonkData = PlonkManager.definitions[id]
		if data.unlock_plinks_threshold > 0.0 and current_plinks >= data.unlock_plinks_threshold:
			if not GameState.unlocked_plonk_ids.has(id):
				GameState.unlock_plonk(id)
				any_new = true
	if any_new:
		_populate_shop()

func _update_button_prices() -> void:
	for row in plonk_list.get_children():
		if row is HBoxContainer:
			var buy_btn := row.get_child(0) as Button
			if not buy_btn:
				continue
			var plonk_id: String = buy_btn.get_meta("plonk_id")
			var data := PlonkManager.definitions.get(plonk_id) as PlonkData
			if data:
				var price := PlonkManager.get_current_price(data)
				buy_btn.text = data.display_name + "\n" + GameState.format_number(price) + " plinks"

func _populate_shop() -> void:
	for child in plonk_list.get_children():
		child.queue_free()
	for data in PlonkManager.get_unlocked_definitions():
		_add_shop_button(data)

func _add_shop_button(data: PlonkData) -> void:
	var price := PlonkManager.get_current_price(data)
	var row := HBoxContainer.new()
	plonk_list.add_child(row)

	var buy_btn := Button.new()
	buy_btn.set_meta("plonk_id", data.id)
	buy_btn.text = data.display_name + "\n" + GameState.format_number(price) + " plinks"
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.pressed.connect(_on_buy_pressed.bind(data.id))
	buy_btn.mouse_entered.connect(_show_plonk_info.bind(data))
	# buy_btn.mouse_exited.connect(_clear_plonk_info)
	row.add_child(buy_btn)

	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.pressed.connect(_on_sell_pressed.bind(data.id))
	row.add_child(sell_btn)

func _on_buy_pressed(plonk_id: String) -> void:
	var data := PlonkManager.definitions.get(plonk_id) as PlonkData
	if not data:
		return
	if PlonkManager.active.size() >= GameState.max_plonks:
		return
	var price := PlonkManager.get_current_price(data)
	if GameState.plinks < price:
		# print(GameState.plinks)
		# print(price)
		# print(PlonkManager.get_current_price(data))
		return
	var pa: Node2D = GameState.play_area
	var center: Vector2 = pa.position + Vector2(pa.get("box_size")) / 2.0
	PlonkManager.spawn_plonk(plonk_id, center)
	GameState.spend_plinks(price)
	_populate_shop.call_deferred()

func _on_sell_pressed(plonk_id: String) -> void:
	if PlonkManager.active.size() == 1:
		return
	PlonkManager.sell_plonk(plonk_id)
	_populate_shop()

# left side

func _build_left_sidebar() -> void:
	var left := $LeftSidebar
	left.anchor_left = 0.0
	left.anchor_top = 0.0
	left.anchor_bottom = 1.0
	left.offset_left = 12.0
	left.offset_top = 60.0
	left.offset_right = 252.0

	var info_panel := $LeftSidebar/InfoPanel
	info_panel.custom_minimum_size = Vector2(0, 300)
	info_panel.size_flags_vertical = Control.SIZE_FILL

	var weather_panel := $LeftSidebar/WeatherPanel
	weather_panel.custom_minimum_size = Vector2(0, 150)
	weather_panel.size_flags_vertical = Control.SIZE_FILL
	
	legendary_panel.custom_minimum_size = Vector2(0, 200)
	legendary_panel.size_flags_vertical = Control.SIZE_FILL
	
	info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	info_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_description.autowrap_mode = TextServer.AUTOWRAP_WORD

	weather_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weather_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	weather_label.text = "A Normal Day In Plonkland"
	
	info_icon_container.custom_minimum_size = Vector2(128, 128)
	info_icon_container.size = Vector2(128, 128)
	info_icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info_icon_container.clip_contents = true

	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	
	lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lock_sprite = lock_overlay.get_node_or_null("LockSprite")
	if lock_sprite:
		lock_sprite.play("default")
		# wait one frame for lock_overlay's size to be finalized, then center
		lock_overlay.resized.connect(func():
			lock_sprite.position = lock_overlay.size / 2.0
		)
	
	var legendary_content := $LeftSidebar/LegendaryPanel/LegendaryContent
	legendary_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	legendary_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var legendary_scroll := $LeftSidebar/LegendaryPanel/LegendaryContent/LegendaryScroll
	legendary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	legendary_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	legendary_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	legendary_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	

func _show_plonk_info(data: PlonkData) -> void:
	_hovered_data = data
	info_icon.texture = data.shop_icon
	if data.shop_icon:
		var tex_size: Vector2 = data.shop_icon.get_size()
		var canvas_size: float = 300.0
		var display_scale: float = 128.0 / canvas_size
		info_icon.custom_minimum_size = tex_size * display_scale
		info_icon.size = tex_size * display_scale
		info_icon.scale = Vector2(display_scale, display_scale)
		var scaled_size: Vector2 = tex_size * display_scale
		info_icon.position = (Vector2(128, 128) - scaled_size) / 2.0
	info_title.text = data.display_name
	info_description.text = data.description
	_update_info_stats(data)

func _clear_plonk_info() -> void:
	_hovered_data = null
	info_icon.texture = null
	info_title.text = ""
	info_description.text = ""

func _on_stats_refresh() -> void:
	# print("ref")
	if _hovered_data:
		# print("refresh")
		_update_info_stats(_hovered_data)

func _update_info_stats(data: PlonkData) -> void:
	for child in info_stats.get_children():
		child.queue_free()

	var owned_count: int = PlonkManager.get_count_in_play(data.id)
	var per_window: float = StatsManager.get_plinks_per_window(data.id)
	var total: float = StatsManager.get_plinks_total(data.id)

	_add_stat_label("Owned: " + str(owned_count))
	_add_stat_label("Plinks (last 10s): " + GameState.format_number(per_window))
	_add_stat_label("Total plinks: " + GameState.format_number(total))
	_add_stat_label("Start Speed: " + GameState.format_number(data.spawn_linear_speed))
	_add_stat_label("Plinks/bounce: " + GameState.format_number(data.base_plinks_per_bounce))
	_add_stat_label("Radius: " + GameState.format_number(data.radius))

	var custom: Dictionary = StatsManager.get_custom_stats(data.id)
	for stat_name in custom:
		var label_name: String = stat_name.replace("_", " ").capitalize()
		_add_stat_label(label_name + ": " + str(custom[stat_name]))

func _add_stat_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_stats.add_child(label)

func _on_weather_started(weather_id: String) -> void:
	weather_label.text = "Current weather: " + weather_id.capitalize()

func _on_weather_ended(_weather_id: String) -> void:
	weather_label.text = "A Normal Day In Plonkland"

func _update_legendary_lock_state() -> void:
	lock_overlay.visible = GameState.unlocked_legendary_ids.size() == 0
	if not lock_overlay.visible:
		_populate_legendary_shop()

func _on_legendary_unlocked(_id: String) -> void:
	_update_legendary_lock_state()
	_populate_legendary_shop()

func _populate_legendary_shop() -> void:
	for child in legendary_list.get_children():
		child.queue_free()
	# print("populating legendary shop, unlocked ids: ", GameState.unlocked_legendary_ids)
	for id in GameState.unlocked_legendary_ids:
		var data := PlonkManager.definitions.get(id) as PlonkData
		# print("found data for ", id, ": ", data)
		if data:
			_add_legendary_shop_button(data)

func _add_legendary_shop_button(data: PlonkData) -> void:
	var row := HBoxContainer.new()
	legendary_list.add_child(row)

	var btn := Button.new()
	btn.set_meta("plonk_id", data.id)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_entered.connect(_show_plonk_info.bind(data))
	# btn.mouse_exited.connect(_clear_plonk_info)
	row.add_child(btn)

	_refresh_legendary_button(btn, data)
	# print("button added: ", btn.text, " visible: ", btn.visible, " size: ", btn.size, " global_pos: ", btn.global_position)

func _refresh_legendary_button(btn: Button, data: PlonkData) -> void:
	for connection in btn.pressed.get_connections():
		btn.pressed.disconnect(connection.callable)

	if GameState.owned_legendary_ids.has(data.id):
		var sell_value := _get_legendary_sell_value(data)
		btn.text = "Sell " + data.display_name + "\n" + GameState.format_number(sell_value) + " plinks"
		btn.pressed.connect(_on_legendary_sell_pressed.bind(data.id))
	else:
		var price := PlonkManager.get_current_price(data)
		btn.text = data.display_name + "\n" + GameState.format_number(price) + " plinks"
		btn.pressed.connect(_on_legendary_buy_pressed.bind(data.id))

func _get_legendary_sell_value(data: PlonkData) -> float:
	for ap in PlonkManager.active:
		if ap.definition.id == data.id:
			return ap.paid * ap.definition.sell_value_fraction
	return 0.0

func _on_legendary_buy_pressed(plonk_id: String) -> void:
	var data := PlonkManager.definitions.get(plonk_id) as PlonkData
	if not data:
		return
	if GameState.owned_legendary_ids.has(plonk_id):
		return
	var price := PlonkManager.get_current_price(data)
	if GameState.plinks < price:
		return
	var pa: Node2D = GameState.play_area
	var center: Vector2 = pa.position + Vector2(pa.get("box_size")) / 2.0
	PlonkManager.spawn_plonk(plonk_id, center)
	GameState.spend_plinks(price)
	_populate_legendary_shop.call_deferred()

func _on_legendary_sell_pressed(plonk_id: String) -> void:
	PlonkManager.sell_plonk(plonk_id)
	_populate_legendary_shop()
