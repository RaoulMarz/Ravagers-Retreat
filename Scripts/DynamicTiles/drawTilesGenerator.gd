extends Node2D

var drawroutines_class = preload("res://Scripts/DynamicTiles/drawroutines.gd")
const HALF_PI = PI / 2.0
var timer_counter = 0
const intro_expired_ticks = 800

class tileset_image:
	var tile_id = ""
	var index = 0
	var gridcoord = Vector2(0, 0)
	var spansize = Vector2(1, 1)
	func _init(id, tindex, tcoord, tspan):
		tile_id = id
		if (tindex >= 0):
			index = tindex
		gridcoord = tcoord
		spansize = tspan
	func get_tileid():
		return tile_id
	func get_index():
		return index
	func get_coordinate():
		return gridcoord
	func get_spansize():
		return spansize

class animation_sprite:
	extends Node2D
	const nb_points = 48
	var draw_wall : bool = false
	var w_autoselect : bool = false
	var w_tileset_image : String
	var w_bit_data : Array
	var w_height : int
	var w_width : int
	var timestamp_class = preload("res://Scripts/timestamp.gd")
	var global_sprite_cache = { }
	var gridcoord : Vector2 = Vector2(0, 0)
	var sprite_dimension : Vector2  = Vector2(1, 1)
	var map_dimension : Vector2  = Vector2(1, 1)
	var animation_started : bool = false
	var infinite_loop : bool = false
	var test_mode : bool = false
	var currentindex = 0
	var max_index = 10
	var updateTicks = 200
	var last_drawtime = null
	func _init(tcoord = Vector2(0, 0), tmapdimension = Vector2(1, 1), tdimension = Vector2(1, 1), index = 0, started = false):
		gridcoord = tcoord
		map_dimension = tmapdimension
		sprite_dimension = tdimension
		currentindex = index
		animation_started = started
	func set_coordinate(tcoord : Vector2):
		gridcoord = tcoord
	func set_dimension(tdimension : Vector2):
		sprite_dimension = tdimension
	func set_mapdimension(tmapdimension : Vector2):
		map_dimension = tmapdimension
	func set_drawtime(newtime):
		last_drawtime = newtime
	func set_update(period : int):
		updateTicks = period
	func set_started(started):
		animation_started = started
	func set_infiniteloop(repeatinfinite):
		infinite_loop = repeatinfinite
	func has_started():
		return animation_started
	func get_coordinate():
		return gridcoord
	func get_dimension():
		return sprite_dimension
	func get_mapdimension():
		return map_dimension
	func calculate_index():
		var res : int = 0
		if (gridcoord != null):
			var vector_effective_dim = map_dimension - sprite_dimension + Vector2(1, 1)
			var rowpos = (gridcoord.x + 1) - sprite_dimension.x
			res = ( ((gridcoord.y + 1) - sprite_dimension.y) * vector_effective_dim.x) + rowpos
		return res
	func increment_index():
		var vector_effective_dim = map_dimension - sprite_dimension + Vector2(1, 1)
		var max_index = vector_effective_dim.x * vector_effective_dim.y
		currentindex = calculate_index()
		var debug_text = "increment_index() effective-w=%d, effective-h=%d, max_index=%d, currentidx=%d, gridcoord.x=%d, gridcoord.y=%d" 
		debug_text = debug_text % [ vector_effective_dim.x, vector_effective_dim.y, max_index, currentindex, gridcoord.x, gridcoord.y]
		print(debug_text)
		if (currentindex < (max_index - 1) ):
			currentindex = currentindex + 1
			#update the gridcoord
			if (gridcoord.x < (vector_effective_dim.x - 1) ):
				gridcoord = gridcoord + Vector2(1, 0)
			else:
				gridcoord.x = 0
				gridcoord = gridcoord + Vector2(0, 1)
		else:
			if (infinite_loop):
				currentindex = 0
				gridcoord = Vector2(0, 0)
		debug_text = "increment_index() gridcoord.x=%d, gridcoord.y=%d" 
		debug_text = debug_text % [ gridcoord.x, gridcoord.y]
		print(debug_text)
	func update_animation(checktime):
		var res : bool = false
		if (last_drawtime == null):
			last_drawtime = timestamp_class.timestamp.new()
			last_drawtime.reset_time()
			return true
		if (checktime != null) and (last_drawtime != null):
			var updatediff = checktime.subtract_ticks(last_drawtime)
			if (updatediff >= updateTicks):
				res = true
				set_drawtime(checktime)
		return res
	func draw_tileset_image(folderspec, sprite_res, columns, rows, image_draw_sequence, sprite_position):
		if (image_draw_sequence == null) or (image_draw_sequence.size() <= 0):
			return
		var pre_path = ""
		if folderspec != null:
			pre_path = folderspec
		var sprite_cache_image = load_sprite_fromcache(pre_path, sprite_res)
		if (sprite_cache_image != null):
			var sprite_height = sprite_cache_image.get_height() / rows
			var sprite_width = sprite_cache_image.get_width() / columns
			for image_spec in image_draw_sequence:
				var unit_width = image_spec.get_spansize().x
				var unit_height = image_spec.get_spansize().y
				var origin_x = image_spec.get_coordinate().x
				var origin_y = image_spec.get_coordinate().y
				var placement_rect = Rect2(sprite_position, Vector2(sprite_width * unit_width, sprite_height * unit_height))
				var image_rect = Rect2(Vector2(origin_x * sprite_width, origin_y * sprite_height), Vector2(sprite_width * unit_width, sprite_height * unit_height))
				draw_texture_rect_region(sprite_cache_image, placement_rect, image_rect)
				return [folderspec, sprite_res, columns, rows, image_draw_sequence, sprite_position]
	func draw_cached_tile(stored_tile_parameters):
		#var folder, sprite, cols, rows, imgdrawseq, spritepos = stored_tile_parameters
		pass
	func draw_cached_tile_array(stored_tile_parameters):
		for cachedtile in stored_tile_parameters:
			draw_cached_tile(cachedtile)
	func draw_circle_arc(center, radius, angle_from, angle_to, draw_color, line_thickness = 4.0):
		var points_arc = PoolVector2Array()
		for i in range(nb_points + 1):
			var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
			points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
		for index_point in range(nb_points):
			draw_line(points_arc[index_point], points_arc[index_point + 1], draw_color, line_thickness)

	func draw_arc_and_saw(center, offset, segments, separation, draw_color = Color(0.825, 0.535, 0.495)):
		for i in range(segments):
			var arc_begin = deg2rad(i * separation);
			var arc_end = arc_begin + HALF_PI;
			draw_circle_arc(center, i + offset, arc_begin, arc_end, draw_color)

	func draw_glow_spiral(center, total_sweeps, degree_separation, dotradius = 15, radius = 100, radius_grow = 20, draw_color = Color(0.825, 0.535, 0.495)):
		var new_radius = radius
		for i in range(total_sweeps * (360 / degree_separation)):
			var angle_point = deg2rad( (i * degree_separation) % 360)
			var cx = center.x + (cos(angle_point) * new_radius)
			var cy = center.y + (sin(angle_point) * new_radius)
			var ball_centre = Vector2(cx, cy)
			draw_circle(ball_centre, dotradius, draw_color)
			new_radius = new_radius + radius_grow

	func load_sprite_fromcache(folderspec, sprite_resource):
		if global_sprite_cache.has(sprite_resource):
			return global_sprite_cache[sprite_resource]
		var res = null
		var pre_path = ""
		if folderspec != null:
			pre_path = folderspec
		var sprite_resource_file = sprite_resource
		if (pre_path != null):
			sprite_resource_file = pre_path + "/" + sprite_resource_file
			var sprite_Image = load(sprite_resource_file)
			global_sprite_cache[sprite_resource] = sprite_Image
			res = global_sprite_cache[sprite_resource]
		return res

	func draw_sprite_image(folderspec, sprite_res, sprite_position):
		var pre_path = ""
		if folderspec != null:
			pre_path = folderspec
		var sprite_cache_image = load_sprite_fromcache(pre_path, sprite_res)
		if (sprite_cache_image != null):
			#var sprite_position = coordinate_placements[idx]
			draw_texture(sprite_cache_image, sprite_position)

	func draw_sprite_image_offset(folderspec, sprite_res, sprite_position, sprite_offset):
		var pre_path = ""
		if folderspec != null:
			pre_path = folderspec
		var sprite_cache_image = load_sprite_fromcache(pre_path, sprite_res)
		if (sprite_cache_image != null):
			draw_texture(sprite_cache_image, sprite_position - sprite_offset)

	func draw_sprites_layout(folderspec, spriteslist, coordinate_placements, centre_image = false, selection_list = null):
		if (spriteslist == null) and (typeof(spriteslist) == TYPE_ARRAY):
			return
		var sprite_objects = []
		var idx = -1
		if (selection_list != null) and (typeof(selection_list) == TYPE_ARRAY):
			draw_sprite_image(folderspec, spriteslist[0], coordinate_placements[0])
		else:
			for sprite_res in spriteslist:
				idx = idx + 1
				var sprite_position = coordinate_placements[idx]
				draw_sprite_image(folderspec, sprite_res, sprite_position)

	func draw_sprites_layout_extended(folderspec, spriteslist, coordinate_placements, sprite_offsets, centre_image = false):
		if (spriteslist == null):
			return
		var pre_path = ""
		if folderspec != null:
			pre_path = folderspec
			var sprite_objects = []
			var idx = -1
			for sprite_res in spriteslist:
				idx = idx + 1
				if (sprite_offsets != null) and (typeof(sprite_offsets) == TYPE_ARRAY):
					var sprite_position = coordinate_placements[idx]
					var draw_offset = sprite_offsets[idx]
					draw_sprite_image_offset(folderspec, sprite_res, sprite_position, draw_offset)

	func determine_tile_orientation(walls_bit_data, height, width, xt, yt):
		var res : Vector2 = Vector2.ZERO
		var cells_anterior_used = [ ]
		var empty_count = 0
		if xt == 0 and walls_bit_data[xt + (yt * width)] == 1:
			res = Vector2(1, 2)
			return res
		if xt == width - 1 and walls_bit_data[xt + (yt * width)] == 1:
			res = Vector2(1, 2)
			return res
		if xt > 0 and xt < width - 1:
			if yt > 0 and yt < height - 1:
				for ix in range(xt - 1, xt + 2):
					for iy in range(yt - 1, yt + 2):
						#check which surrounding cells are lit
						if ix == xt and iy == yt:
							pass
						else:
							cells_anterior_used.append(walls_bit_data[ix + (iy * width)])
							if walls_bit_data[ix + (iy * width)] <= 0:
								empty_count += 1
		#if X amount of anterior cells of the tested cell are filled, then revert to the default tile
		if empty_count == 0:
			return res
		if empty_count >= 5 and empty_count <= 6:
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[3] == 0 and cells_anterior_used[5] == 0: #topleft
				res = Vector2(1, 0)
			if cells_anterior_used[0] == 0 and cells_anterior_used[3] == 0 and cells_anterior_used[5] == 0\
			and cells_anterior_used[6] == 0 and cells_anterior_used[7] == 0: #bottomleft
				res = Vector2(3, 0)
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[4] == 0 and cells_anterior_used[7] == 0: #topright
				res = Vector2(2, 0)
			if cells_anterior_used[2] == 0 and cells_anterior_used[4] == 0 and cells_anterior_used[5] == 0\
			and cells_anterior_used[6] == 0 and cells_anterior_used[7] == 0: #bottomright
				res = Vector2(0, 1)
			###### line segments section
			if cells_anterior_used[0] == 0 and cells_anterior_used[2] == 0 and cells_anterior_used[3] == 0\
			and cells_anterior_used[4] == 0 and cells_anterior_used[5] == 0 and cells_anterior_used[7] == 0: #leftvertical
				res = Vector2(1, 2)
		if empty_count == 7: # the stubs
			pass
		return res

	func get_line_segments(walls_bit_data, height, width):
		#returns an array with 2 coordinate records which represent a line segment
		var res = [ ]
		var line_cell_count = 0
		for ix in range(0, width):
			for iy in range(0, height):
				if walls_bit_data[ix + (iy * width)] > 0:
					line_cell_count += 1
					if line_cell_count > 1:
						pass
		return res

	func draw_wall_data(walls_tileset_image, walls_bit_data, height, width, autoselect):
		var sprite_info
		for ix in range(0, width):
			for iy in range(0, height):
				if walls_bit_data[ix + (iy * width)] >= 1:
					if autoselect:
						var tile_select_vector = determine_tile_orientation(walls_bit_data, height, width, ix, iy)
						sprite_info = tileset_image.new("tile1", -1, tile_select_vector, Vector2(1, 1))
					else:
						sprite_info = tileset_image.new("tile1", -1, Vector2(0, 0), Vector2(1, 1))
					draw_tileset_image("res://Assets/Images/Walls", walls_tileset_image, 4, 4, [sprite_info], Vector2(iy * 64, ix * 64) )

	func draw_static_tilesets():
		var sprite_info = tileset_image.new("tile1", -1, Vector2(0, 0), Vector2(1, 1))
		draw_tileset_image("res://Assets/Images/Testpics", "pew_ball_spritesheet_w40.png", 4, 3, [sprite_info], Vector2(250, 450) )
		sprite_info = tileset_image.new("tile2", -1, Vector2(0, 0), Vector2(2, 2))
		draw_tileset_image("res://Assets/Images/Testpics", "pew_ball_spritesheet_w40.png", 4, 3, [sprite_info], Vector2(550, 350) )
		var sprite_info3 = tileset_image.new("tile3", -1, Vector2(1, 1), Vector2(2, 2))
		draw_tileset_image("res://Assets/Images/Testpics", "pew_ball_spritesheet_w40.png", 4, 3, [sprite_info3], Vector2(750, 150) )

	func set_wall_data(walls_tileset_image, walls_bit_data, height, width, autoselect):
		draw_wall = true
		w_tileset_image = walls_tileset_image
		w_bit_data = walls_bit_data
		w_height = height
		w_width = width
		w_autoselect = autoselect

	func _draw():
		if test_mode:
			draw_sprites_layout("res://Assets/Images/Testpics", ["peashoot_round_start.png", "pew_ball_peashoot_stage2.png"], [Vector2(20, 40), Vector2(450, 50)])
			draw_sprites_layout_extended("res://Assets/Images/Testpics", ["pew_ball_peashoot_stage1.png", "pew_ball_peashoot_stage2.png"], [Vector2(20, 180), Vector2(200, 180)], [Vector2(20, 10), Vector2(200, 10)])
			draw_static_tilesets()
		if draw_wall:
			draw_wall_data(w_tileset_image, w_bit_data, w_height, w_width, w_autoselect)
		
	func _ready():
		set_process(true)
	func _process(delta):
		update()

var drawDemoTileWalls

func _ready():
	if ($SceneTimer.is_stopped()):
		$SceneTimer.wait_time = 0.025
		$SceneTimer.start()
		$SceneTimer.connect("timeout", self, "_on_timer_timeout")
	drawDemoTileWalls = animation_sprite.new()
	$Sprite.visible = false
	$Sprite2.visible = false
	if (drawDemoTileWalls != null):
		add_child(drawDemoTileWalls)
	set_process(true)

func set_wall_data(walls_tileset_image, walls_bit_data, height, width, autoselect):
	if drawDemoTileWalls != null:
		drawDemoTileWalls.set_wall_data(walls_tileset_image, walls_bit_data, height, width, autoselect)

func _on_timer_timeout():
	timer_counter += 1
	if (timer_counter > intro_expired_ticks):
		$SceneTimer.stop()

func _process(delta):
#	get_input()
	update()
