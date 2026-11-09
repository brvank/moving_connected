extends StaticBody2D

@export var width = 20
@export var height = 50

func _ready() -> void:
	var sprite2d = $Sprite2D
	if sprite2d:
		sprite2d.visible = false

	var cs2d = $CollisionShape2D
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

func _draw() -> void:
	var hw = width / 2.0
	var hh = height / 2.0
	var rect = Rect2(-hw, -hh, width, height)

	# Colors
	var col_base = Color(0.07, 0.11, 0.20, 1.0)
	var col_inner = Color(0.10, 0.16, 0.28, 0.8)
	var col_border = Color(0.0, 0.75, 1.0, 0.65)
	var col_highlight = Color(0.3, 0.6, 0.9, 0.5)
	var col_shadow = Color(0.02, 0.04, 0.08, 0.8)
	var col_rivet = Color(0.0, 0.9, 1.0, 0.85)

	# 1. Main Bulkhead Alloy Plate
	draw_rect(rect, col_base, true)

	# 2. Outer Neon Perimeter
	draw_rect(rect, col_border, false, 1.5)

	# 3. Metallic Light/Shadow Bevel
	draw_line(Vector2(-hw, -hh), Vector2(hw, -hh), col_highlight, 1.5)
	draw_line(Vector2(-hw, -hh), Vector2(-hw, hh), col_highlight, 1.5)
	draw_line(Vector2(hw, -hh), Vector2(hw, hh), col_shadow, 1.5)
	draw_line(Vector2(-hw, hh), Vector2(hw, hh), col_shadow, 1.5)

	# 4. Modular Panel Seam Dividers (for long spans)
	var seam_spacing = 50.0
	if width >= 70.0:
		var x = -hw + seam_spacing
		while x < hw - 10.0:
			draw_line(Vector2(x, -hh + 3.0), Vector2(x, hh - 3.0), Color(0.0, 0.75, 1.0, 0.3), 1.0)
			# Seam rivets
			draw_circle(Vector2(x, -hh + 5.0), 1.5, col_rivet)
			draw_circle(Vector2(x, hh - 5.0), 1.5, col_rivet)
			x += seam_spacing

	if height >= 70.0:
		var y = -hh + seam_spacing
		while y < hh - 10.0:
			draw_line(Vector2(-hw + 3.0, y), Vector2(hw - 3.0, y), Color(0.0, 0.75, 1.0, 0.3), 1.0)
			# Seam rivets
			draw_circle(Vector2(-hw + 5.0, y), 1.5, col_rivet)
			draw_circle(Vector2(hw - 5.0, y), 1.5, col_rivet)
			y += seam_spacing

	# 5. Corner Reinforced Rivet Bolts
	if width >= 16.0 and height >= 16.0:
		var inset = 4.0
		draw_circle(Vector2(-hw + inset, -hh + inset), 1.8, col_rivet)
		draw_circle(Vector2(hw - inset, -hh + inset), 1.8, col_rivet)
		draw_circle(Vector2(hw - inset, hh - inset), 1.8, col_rivet)
		draw_circle(Vector2(-hw + inset, hh - inset), 1.8, col_rivet)
