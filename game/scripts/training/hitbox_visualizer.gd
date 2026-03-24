extends Node2D

## Hitbox Visualizer (F70)
## Toggle to show/hide hitbox and hurtbox areas as colored overlays
## Hitboxes in red, hurtboxes in green (standard fighting game convention)
## Only available in training mode
## Draws rectangles over actual hitbox/hurtbox CollisionShape2D areas

class_name HitboxVisualizer

## Whether visualization is enabled
var enabled: bool = false

## References to fighters to visualize
var fighters: Array[BaseFighter] = []

## Colors
var hitbox_color: Color = Color(1.0, 0.0, 0.0, 0.35)
var hitbox_border_color: Color = Color(1.0, 0.0, 0.0, 0.8)
var hurtbox_color: Color = Color(0.0, 1.0, 0.0, 0.25)
var hurtbox_border_color: Color = Color(0.0, 1.0, 0.0, 0.7)
var hitbox_active_color: Color = Color(1.0, 0.2, 0.0, 0.6)
var hitbox_active_border: Color = Color(1.0, 0.3, 0.0, 1.0)


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		queue_redraw()


func set_fighters(fighter_list: Array) -> void:
	fighters.clear()
	for f in fighter_list:
		if f is BaseFighter:
			fighters.append(f)


func _draw() -> void:
	if not enabled:
		return

	for fighter in fighters:
		if not is_instance_valid(fighter):
			continue
		_draw_fighter_boxes(fighter)


func _draw_fighter_boxes(fighter: BaseFighter) -> void:
	# Draw hurtboxes (green) - check all Area2D children
	_draw_area_boxes(fighter, true)

	# Draw hitboxes (red) - check all Area2D children
	_draw_area_boxes(fighter, false)


func _draw_area_boxes(fighter: BaseFighter, is_hurtbox: bool) -> void:
	var areas = _find_areas(fighter, is_hurtbox)

	for area in areas:
		if not is_instance_valid(area):
			continue

		# Find collision shapes within the area
		for child in area.get_children():
			if child is CollisionShape2D:
				_draw_collision_shape(child, area, is_hurtbox)


func _find_areas(node: Node, find_hurtboxes: bool) -> Array:
	var results: Array = []
	_find_areas_recursive(node, find_hurtboxes, results)
	return results


func _find_areas_recursive(node: Node, find_hurtboxes: bool, results: Array) -> void:
	if find_hurtboxes and node is Hurtbox:
		results.append(node)
	elif not find_hurtboxes and node is Hitbox:
		results.append(node)

	for child in node.get_children():
		_find_areas_recursive(child, find_hurtboxes, results)


func _draw_collision_shape(shape_node: CollisionShape2D, area: Area2D, is_hurtbox: bool) -> void:
	var shape = shape_node.shape
	if shape == null:
		return

	# Convert shape position to our local coordinates
	var shape_global_pos = shape_node.global_position
	var local_pos = to_local(shape_global_pos)

	var fill_color: Color
	var border_color: Color

	if is_hurtbox:
		fill_color = hurtbox_color
		border_color = hurtbox_border_color
	else:
		# Check if hitbox is active (monitoring)
		var is_active = area.monitoring if area is Hitbox else false
		if is_active:
			fill_color = hitbox_active_color
			border_color = hitbox_active_border
		else:
			fill_color = hitbox_color
			border_color = hitbox_border_color

	if shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape
		var half_size = rect_shape.size * 0.5
		var rect = Rect2(local_pos - half_size, rect_shape.size)
		draw_rect(rect, fill_color)
		draw_rect(rect, border_color, false, 2.0)

	elif shape is CircleShape2D:
		var circle_shape: CircleShape2D = shape
		draw_circle(local_pos, circle_shape.radius, fill_color)
		# Draw circle border as segments
		var segments = 32
		for i in range(segments):
			var angle_from = (float(i) / segments) * TAU
			var angle_to = (float(i + 1) / segments) * TAU
			draw_line(
				local_pos + Vector2(cos(angle_from), sin(angle_from)) * circle_shape.radius,
				local_pos + Vector2(cos(angle_to), sin(angle_to)) * circle_shape.radius,
				border_color, 2.0
			)

	elif shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape
		var half_height = capsule.height * 0.5
		var radius = capsule.radius
		var rect = Rect2(
			local_pos - Vector2(radius, half_height),
			Vector2(radius * 2, capsule.height)
		)
		draw_rect(rect, fill_color)
		draw_rect(rect, border_color, false, 2.0)
