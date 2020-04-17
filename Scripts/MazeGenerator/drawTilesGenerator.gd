extends Node2D

var drawroutines_class = preload("res://Scripts/MazeGenerator/drawroutines.gd")
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
	var tile_height = 64
	var tile_width = 64
	var draw_wall : bool = false
	var w_autoselect : bool = false
	var w_tileset_image : String
	var w_bit_data : Array
	var w_height : int
	var w_width : int
	var x_prevpos = 0
	var y_prevpos = 0
	var tileset_path : String = "res://Assets/Tiles/MazeWalls"
	var timestamp_class = preload("res://Scripts/timestamp.gd")
	var global_sprite_cache = { }
	var gridcoord : Vector2 = Vector2(0, 0)
	var sprite_dimension : Vector2 = Vector2(1, 1)
	var map_dimension : Vector2 = Vector2(1, 1)
	var map_screen_tile_dimension : Vector2 = Vector2(60, 45)
	var animation_started : bool = false
	var infinite_loop : bool = false
	var test_mode : bool = false
	var currentindex = 0
	var max_index = 10
	var updateTicks = 200
	var last_drawtime = null
	var wallMapCreated = false
	var wallMapCreated2 = false
	var wall_continuous_draw = false
	var maze_static_objects = []
	var place_wall_offset : Vector2 = Vector2(0, 0)
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

	func draw_sprite_imagepath(image_path_res, sprite_position):
		if image_path_res != null and image_path_res.length() >= 2:
			#var folder = image_path_res.get_basename()
			var idx = image_path_res.find_last("/")
			var folder = image_path_res.substr(0, idx)
			var sprite_file = image_path_res.get_file()
			draw_sprite_image(folder, sprite_file, sprite_position)

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

	func set_tile_size(tile_wd, tile_hg):
		tile_width = tile_wd
		tile_height = tile_hg
		var screensize = get_viewport().size
		map_screen_tile_dimension = Vector2(int(screensize.x / tile_width), int(screensize.y / tile_height))

	func determine_tile_orientation(walls_bit_data, width, height, xt, yt):
		var res : Vector2 = Vector2.ZERO
		var cells_anterior_used = [ ]
		var empty_count = 0
		var orientation_found : bool = false
		if xt > 0 and xt < width - 1:
			if yt > 0 and yt < height - 1:
				var row1 = walls_bit_data.slice ((xt - 1) + ((yt - 1) * width),\
				(xt + 1) + ( (yt - 1) * width), 1, true)
				var row2 = walls_bit_data.slice ((xt - 1) + (yt * width),\
				(xt + 1) + (yt * width), 1, true)
				var row3 = walls_bit_data.slice ((xt - 1) + ((yt + 1) * width),\
				(xt + 1) + ( (yt + 1) * width), 1, true)
				cells_anterior_used = row1 + row2 + row3
				for cell in cells_anterior_used:
					if cell <= 0:
						empty_count += 1
		if xt == 0 or xt == width - 1:
			pass
		if yt == 0 or yt == height - 1:
			pass
		#if X amount of anterior cells of the tested cell are filled, then revert to the default tile
		if empty_count == 0:
			return res
		if empty_count == 4: # cross junction
			if cells_anterior_used[0] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[6] == 0 and cells_anterior_used[8] == 0:
				res = Vector2(2, 2)
				return res
			if (cells_anterior_used[0] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[3] == 0 and cells_anterior_used[5] == 0)\
			or (cells_anterior_used[3] == 0 and cells_anterior_used[5] == 0\
			and cells_anterior_used[6] == 0 and cells_anterior_used[8] == 0):
				res = Vector2(1, 2) # vertical
				return res
		else: # the 4 t-junction sections
			if empty_count == 5:
				if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[3] == 0\
				and cells_anterior_used[6] == 0 and cells_anterior_used[7] == 0:   #left t
					res = Vector2(2, 2)
					return res
				if cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0 and cells_anterior_used[5] == 0\
				and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0:   #right t
					res = Vector2(3, 2)
					return res
				if (cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0)\
				or (cells_anterior_used[6] == 0 and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0):
					res = Vector2(0, 0) # horizontal
					return res
				if (cells_anterior_used[0] == 0 and cells_anterior_used[3] == 0 and cells_anterior_used[6] == 0)\
				or (cells_anterior_used[2] == 0 and cells_anterior_used[5] == 0 and cells_anterior_used[8] == 0):
					res = Vector2(1, 2) # vertical
					return res
		if empty_count == 6:
			###### line segments section
			######
			if (cells_anterior_used[6] == 0 and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0)\
			and (cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0):
				res = Vector2(0, 0) # horizontal
				return res
			if (cells_anterior_used[0] == 0 and cells_anterior_used[3] == 0 and cells_anterior_used[6] == 0)\
			and (cells_anterior_used[2] == 0 and cells_anterior_used[5] == 0 and cells_anterior_used[8] == 0):
				res = Vector2(1, 2) # vertical
				return res
			##############3
			## Corner sections
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[3] == 0 and cells_anterior_used[6] == 0: #topleft
				res = Vector2(1, 0)
				orientation_found = true
				#print('topleft wall-tile at [%d,%d]' % [xt, yt])
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[5] == 0 and cells_anterior_used[8] == 0: #topright
				res = Vector2(2, 0) #3,0
				orientation_found = true
				#print('topright wall-tile at [%d,%d]' % [xt, yt])
			if cells_anterior_used[0] == 0 and cells_anterior_used[3] == 0 and cells_anterior_used[6] == 0\
			and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0: #bottomleft
				res = Vector2(3, 0)
				orientation_found = true
				#print('bottomleft wall-tile at [%d,%d]' % [xt, yt])
			if cells_anterior_used[2] == 0 and cells_anterior_used[5] == 0 and cells_anterior_used[6] == 0\
			and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0: #bottomright
				res = Vector2(0, 1)
				orientation_found = true
				#print('bottomright wall-tile at [%d,%d]' % [xt, yt])
			if orientation_found:
				return res
		if empty_count == 7: # the stubs
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[3] == 0 and cells_anterior_used[6] == 0\
			and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0:
				res = Vector2(2, 1)  # left horiz stub
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[5] == 0 and cells_anterior_used[6] == 0\
			and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0:
				res = Vector2(1, 1) # right horiz stub
			if cells_anterior_used[0] == 0 and cells_anterior_used[1] == 0 and cells_anterior_used[2] == 0\
			and cells_anterior_used[3] == 0 and cells_anterior_used[5] == 0\
			and cells_anterior_used[6] == 0 and cells_anterior_used[8] == 0:
				res = Vector2(3, 1)  # top stub
			if cells_anterior_used[0] == 0 and cells_anterior_used[2] == 0 and cells_anterior_used[3] == 0\
			and cells_anterior_used[5] == 0 and cells_anterior_used[6] == 0\
			and cells_anterior_used[7] == 0 and cells_anterior_used[8] == 0:
				res = Vector2(0, 2) # bottom stub
		return res

	func get_line_segments(walls_bit_data, width, height):
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

	func create_polygon_shape(vector_tile, xt, yt):
		var res : PoolVector2Array = []
		# Most tiles will produce regular rectangular boundaries, horizontal & vertical
		var half_width = tile_width * 0.5
		var half_height = tile_height * 0.5
		var not_assigned = true
		var xplace = xt * tile_width
		var yplace = yt * tile_height
		match vector_tile:
			Vector2(0, 0):
				res.append(Vector2(xplace, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + (0.75 * tile_height)))
				res.append(Vector2(xplace, yplace + (0.75 * tile_height)))
				not_assigned = false
			Vector2(1, 0):
				res.append(Vector2(xplace, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + tile_height))
				res.append(Vector2(xplace, yplace + tile_height))
				not_assigned = false
			Vector2(2, 0):
				res.append(Vector2(xplace, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + (0.5 * half_width)))
				res.append(Vector2(xplace + tile_width, yplace + tile_height))
				res.append(Vector2(xplace, yplace + tile_height))
				not_assigned = false
		if not_assigned:
			res.append(Vector2(xplace, yplace + (0.5 * half_width)))
			res.append(Vector2(xplace + tile_width, yplace + (0.5 * half_width)))
			res.append(Vector2(xplace + tile_width, yplace + tile_height))
			res.append(Vector2(xplace, yplace + tile_height))
		return res

	func create_wall_collision_partitions(vec_offset, walls_bit_data, width, height):
		var x_offpos = 0
		var y_offpos = 0
		var res = []
		if vec_offset.x >= tile_width or vec_offset.y >= tile_height:
			x_offpos = int(vec_offset.x / tile_width)
			y_offpos = int(vec_offset.y / tile_height)
		var effective_width = width
		var effective_height = height
#		var effective_width = x_offpos + map_screen_tile_dimension.x
#		var effective_height = y_offpos + map_screen_tile_dimension.y
#		if effective_width > width:
#			effective_width = width
#		if effective_height > height:
#			effective_height = height
		for ix in range(x_offpos, effective_width):
			for iy in range(y_offpos, effective_height):
				if walls_bit_data[ix + (iy * width)] >= 1:
					var tile_select_vector = determine_tile_orientation(walls_bit_data, width, height, ix, iy)
					var polygon_vertices = create_polygon_shape(tile_select_vector, ix, iy)
					if not polygon_vertices == null:
						res.append(polygon_vertices)
		return res

	func writeWallMonochrome(map_data, width, height, scale, image_file):
		if wallMapCreated2:
			return
		wallMapCreated2 = true
		var dynImg : Image = Image.new()
		dynImg.create(width * scale, height * scale, false, Image.FORMAT_RGBA8)
		print('writeWallMonochrome() height=%d, width=%d, map size=%d' % [height, width, map_data.size()])
		dynImg.lock()
		for ix in range(0, width):
			for iy in range(0, height):
				var val = map_data[ix + (iy * width)]
				if (val > 0):
					for ipx in range(0, scale * scale):
						dynImg.set_pixel(ix * scale + (ipx % scale), iy * scale + (ipx / scale), Color(255, 255, 255))
		dynImg.unlock()
		dynImg.save_png("res://Assets/Images/Testpics/" + image_file)

	func writeWallMapImage(png_map_data, width, height, scale, image_file):
		if wallMapCreated:
			return
#		wallMapCreated = true
#		var dynImg : Image = Image.new()
#		dynImg.create(width * scale, height * scale, false, Image.FORMAT_RGBA8)
#		print('writeWallMapImage() height=%d, width=%d, map size=%d' % [height, width, png_map_data.size()])
#		dynImg.lock()
#		for ix in range(0, width):
#			for iy in range(0, height):
#				var val2 = png_map_data[ix + (iy * width)].x * 9
#				var val1 = png_map_data[ix + (iy * width)].y * 22 + val2
#				#dynImg.set_pixel(ix, iy, Color(val1, val1, val2))
#				for ipx in range(0, scale * scale):
#					dynImg.set_pixel(ix * scale + (ipx % scale), iy * scale + (ipx / scale), Color(val1, val1, val2))
#		dynImg.unlock()
#		dynImg.save_png("res://Assets/Images/Testpics/" + image_file)

	func get_selectedtile_boundary(xt, yt, walls_bit_data, width, height):
		var res = []
		var empty_count = 0
		if xt > 0 and xt < width - 1:
			if yt > 0 and yt < height - 1:
				#check which surrounding cells are lit
				var row1 = walls_bit_data.slice ((xt - 1) + ((yt - 1) * width),\
				(xt + 1) + ( (yt - 1) * width), 1, true)
				var row2 = walls_bit_data.slice ((xt - 1) + (yt * width),\
				(xt + 1) + (yt * width), 1, true)
				var row3 = walls_bit_data.slice ((xt - 1) + ((yt + 1) * width),\
				(xt + 1) + ( (yt + 1) * width), 1, true)
				res = row1 + row2 + row3
				for cell in res:
					if cell <= 0:
						empty_count += 1
		else:
			if xt == 0 or xt == width - 1:
				pass
			if yt == 0 or yt == height - 1:
				pass
#		print('get_selectedtile_boundary(), bit data = ')
#		if empty_count == 6:
#			if res[0] == 0 and res[1] == 0 and res[2] == 0\
#			and res[3] == 0 and res[6] == 0: #topleft
#				print('get_selectedtile_boundary(), topleft wall-tile at [%d,%d]' % [xt, yt])
#			if res[0] == 0 and res[1] == 0 and res[2] == 0\
#			and res[5] == 0 and res[8] == 0: #topright
#				print('get_selectedtile_boundary(), topright wall-tile at [%d,%d]' % [xt, yt])
		return res

	func draw_wall_data(vec_offset, walls_tileset_image, walls_bit_data, width, height, autoselect):
		var sprite_info
		#print('draw_wall_data() height=%d, width=%d' % [height, width])
		if vec_offset.x < 0 or vec_offset.y < 0:
			vec_offset = Vector2(0, 0)
		var smooth_tolerance = 3.0
		if walls_bit_data.size() < (width * height):
			return
		#writeWallMonochrome(walls_bit_data, width, height, 5, "test_walls_expo1.png")
		var x_offpos = 0
		var y_offpos = 0
		if vec_offset.x >= tile_width or vec_offset.y >= tile_height:
			x_offpos = int(vec_offset.x / tile_width)
			y_offpos = int(vec_offset.y / tile_height)
		var effective_width = x_offpos + map_screen_tile_dimension.x + 2
		var effective_height = y_offpos + map_screen_tile_dimension.y + 2
		if effective_width > width:
			effective_width = width
		if effective_height > height:
			effective_height = height
		
		var walls_cells_drawn = 0
		for ix in range(0, effective_width):
			for iy in range(0, effective_height):
				if walls_bit_data[ix + (iy * width)] >= 1:
					walls_cells_drawn += 1
					var xdrawpos = -(vec_offset.x - (ix * tile_width))
					var ydrawpos = -(vec_offset.y - (iy * tile_height))
					if xdrawpos < -tile_width or ydrawpos < -tile_height:
						continue
					if autoselect:
						var tile_select_vector = determine_tile_orientation(walls_bit_data, width, height, ix, iy)
						sprite_info = tileset_image.new("tile1", -1, tile_select_vector, Vector2(1, 1))
					else:
						sprite_info = tileset_image.new("tile1", -1, Vector2(0, 0), Vector2(1, 1))
					if wall_continuous_draw:
						var adjust_position = Vector2(xdrawpos,ydrawpos)
						draw_tileset_image(tileset_path, walls_tileset_image, 4, 4,\
						[sprite_info], adjust_position)
					else:
						var adjust_position = Vector2(xdrawpos,ydrawpos)
						draw_tileset_image(tileset_path, walls_tileset_image, 4, 4,\
						[sprite_info], adjust_position)
		#print("draw_wall_data, #wall-cells=%s, x-smooth=%d" % [walls_cells_drawn, x_smoothfraction])

	func set_wall_data(walls_tileset_image, walls_bit_data, width, height, autoselect):
		draw_wall = true
		w_tileset_image = walls_tileset_image
		w_bit_data = walls_bit_data
		w_height = height
		w_width = width
		w_autoselect = autoselect

	func set_wall_offset(wall_offset, continuous_draw):
		place_wall_offset = wall_offset
		wall_continuous_draw = continuous_draw

	func set_maze_static(draw_maze_objects):
		if draw_maze_objects != null:
			maze_static_objects = draw_maze_objects

	func _draw():
		var screensize = get_viewport().size
		if draw_wall:
			test_mode = false
		if test_mode:
			draw_sprites_layout("res://Assets/Images/Testpics", ["peashoot_round_start.png", "pew_ball_peashoot_stage2.png"], [Vector2(20, 40), Vector2(450, 50)])
			draw_sprites_layout_extended("res://Assets/Images/Testpics", ["pew_ball_peashoot_stage1.png", "pew_ball_peashoot_stage2.png"], [Vector2(20, 180), Vector2(200, 180)], [Vector2(20, 10), Vector2(200, 10)])
		if draw_wall:
			draw_wall_data(place_wall_offset, w_tileset_image, w_bit_data, w_width, w_height, w_autoselect)
		if maze_static_objects != null and maze_static_objects.size() > 0:
			for static_obj in maze_static_objects:
				var objkey = static_obj.keys()
				var sloc = objkey[0]
				if sloc != null:
					var object_path = static_obj[sloc]
					var xdrawpos = -(place_wall_offset.x - (sloc.x * tile_width))
					var ydrawpos = -(place_wall_offset.y - (sloc.y * tile_height))
					if xdrawpos <= screensize.x and ydrawpos <= screensize.y:
						draw_sprite_imagepath(object_path, Vector2(xdrawpos, ydrawpos))
		
	func _ready():
		set_process(true)
	func _process(delta):
		update()

var drawDemoTileWalls
var draw_refresh_cycle = 0.015 # 0.025
var tile_width
var tile_height
var place_wall_offset : Vector2 = Vector2(0, 0)

func _ready():
	if ($SceneTimer.is_stopped()):
		$SceneTimer.wait_time = draw_refresh_cycle    #0.025
		$SceneTimer.start()
		$SceneTimer.connect("timeout", self, "_on_timer_timeout")
	drawDemoTileWalls = animation_sprite.new()
	$Sprite.visible = false
	$Sprite2.visible = false
	if (drawDemoTileWalls != null):
		add_child(drawDemoTileWalls)
	set_process(true)

func get_selectedtile_boundary(mouse_pos, walls_bit_data, width, height, zero_value, fill_value):
	var res = []
	if not mouse_pos == null:
		# determine the tile coordinate position
		var tx = int(mouse_pos.x / tile_width)
		var ty = int(mouse_pos.y / tile_height)
		var temp = drawDemoTileWalls.get_selectedtile_boundary(tx, ty, walls_bit_data, width, height)
		for ix in range(0, temp.size()):
			var val = temp[ix]
			if val > 0:
				res.append(fill_value)
			else:
				res.append(zero_value)
	return res

func set_wall_data(walls_tileset_image, walls_bit_data, width, height, autoselect):
	if drawDemoTileWalls != null:
		drawDemoTileWalls.set_wall_data(walls_tileset_image, walls_bit_data, width, height, autoselect)

func set_tile_size(tile_wd, tile_hg):
	if drawDemoTileWalls != null:
		drawDemoTileWalls.set_tile_size(tile_wd, tile_hg)
		tile_width = tile_wd
		tile_height = tile_hg

func set_draw_period(draw_period):
	draw_refresh_cycle = draw_period
	$SceneTimer.wait_time = draw_refresh_cycle

func set_wall_offset(wall_offset, continuous_draw = false):
	place_wall_offset = wall_offset
	if drawDemoTileWalls != null:
		drawDemoTileWalls.set_wall_offset(wall_offset, continuous_draw)

func create_wall_collision_partitions(vec_offset, walls_bit_data, width, height):
	var res = null
	if drawDemoTileWalls != null:
		res = drawDemoTileWalls.create_wall_collision_partitions(vec_offset, walls_bit_data, width, height)
	return res

func set_maze_static(draw_maze_objects):
	if draw_maze_objects != null and drawDemoTileWalls != null:
		drawDemoTileWalls.set_maze_static(draw_maze_objects)

func _on_timer_timeout():
	timer_counter += 1
	if (timer_counter > intro_expired_ticks):
		$SceneTimer.stop()

func _process(delta):
#	get_input()
	update()
