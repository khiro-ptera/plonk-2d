# UI.gd
extends CanvasLayer

@onready var plinks_label: Label = $MainRightSidebar/PlinksLabel
@onready var plonk_list: VBoxContainer = $MainRightSidebar/PlonkShopScroll/PlonkList

func _ready() -> void:
	_build_top_panel()
	_build_sidebar()
	GameState.plinks_changed.connect(_on_plinks_changed)
	#_populate_shop()

func _build_top_panel() -> void:
	var panel := $TopPanel
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	var label := $TopPanel/TopLabel
	label.text = "Plonk!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_sidebar() -> void:
	var sidebar := $MainRightSidebar
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -200.0  # sidebar width
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
		print(GameState.plinks)
		print(price)
		print(PlonkManager.get_current_price(data))
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
