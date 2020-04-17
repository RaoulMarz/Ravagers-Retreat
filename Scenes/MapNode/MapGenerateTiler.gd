extends Node2D

var timestamp_class = preload("res://Scripts/timestamp.gd")
var inventorystack_class = preload("res://Scripts/inventorystack.gd")
var wallmaze_class = preload("res://Scripts/MazeGenerator/mazeWallGenerator.gd")
var drawtiles_scene = preload("res://Scripts/MazeGenerator/drawTilesGenerator.tscn")

export var image_map_template : String = ""
export var tile_type_count : int = 32

var generator_tilewalls
var tile_walls_painter = null
var walls_bit_grid = null
var my_test_inventory = null
var tile_path = "res://Assets/Tiles/MazeWalls/"
var maze_path = "res://Assets/Maze/"
var map_path = "res://Assets/Maps/"
export var walls_outline_image = "mazewalls_start.png"
export var walls_outline_choice = "mazewalls_choice{%d}.png"
export var walls_tileset_image = "walls1tileset.png"
export var tilemap_image = "heightmap_start.png"
export var walls_autoselect = true
export var test_camera_mode = false
export var continuous_draw = true
export var use_tilemap_image = true
var imgMapTexture : ImageTexture = null
var timer_ticks = 0
var gen_width = 0
var gen_height = 0
var draw_period = 0.05
var individual_collision_areas = false
var camera_horizontal_move = 64
var screensize : Vector2
var maze_camera = null
var maze_placement_structures = [ ]
var draw_maze_objects = [ ]
var tile_dimension : Vector2 = Vector2(64, 64)
var maze_wall_topleft_offset : Vector2 = Vector2(0, 0)

func get_image_size(path, image_file):
	var rdImg = Image.new()
	rdImg.load(path + image_file)
	return rdImg.get_size()

func loadImage(workpath, image_resource): # "res://dynamic/minimap.png"
	imgMapTexture.load(workpath + image_resource) #"res://Assets/Images/Testpics/" 
	$Sprite.texture = imgMapTexture

func drawMapImage(map_data, width, height, scale, workpath, image_file):
	imgMapTexture = ImageTexture.new()
	var dynImg : Image = Image.new()
	dynImg.create(width * scale, height * scale, false, Image.FORMAT_RGBA8)
	print('drawMapImage() height=%d, width=%d, map size=%d' % [height, width, map_data.size()])
	dynImg.lock()
	for ix in range(0, width):
		for iy in range(0, height):
			var val_pixel = map_data[ix + (iy * width)]
			var drawColor = Color.blue
			if val_pixel > 3 and val_pixel <= 5:
				drawColor = Color.green
			if val_pixel > 5:
				drawColor = Color.burlywood
			for ipx in range(0, scale * scale):
				dynImg.set_pixel(ix * scale + (ipx % scale), iy * scale + (ipx / scale), drawColor)
	dynImg.unlock()
	dynImg.save_png("res://Assets/Images/Testpics/" + image_file)
	loadImage(workpath, image_file)

func pan_camera_left(move):
	if maze_camera.position.x > 0 and maze_wall_topleft_offset.x > 0:
		maze_wall_topleft_offset -= Vector2(move, 0)
		maze_camera.position -= Vector2(move, 0)
		tile_walls_painter.set_wall_offset(maze_wall_topleft_offset)

func pan_camera_right(move):
	if maze_camera.position.x < 3500:
		maze_wall_topleft_offset += Vector2(move, 0)
		maze_camera.position += Vector2(move, 0)
		tile_walls_painter.set_wall_offset(maze_wall_topleft_offset)

func pan_camera_bottom(move):
	if maze_camera.position.y < 3000:
		maze_wall_topleft_offset += Vector2(0, move)
		maze_camera.position += Vector2(0, move)
		tile_walls_painter.set_wall_offset(maze_wall_topleft_offset)

func pan_camera_top(move):
	if maze_camera.position.y > 0 and maze_wall_topleft_offset.y > 0:
		maze_wall_topleft_offset -= Vector2(0, move)
		maze_camera.position -= Vector2(0, move)
		tile_walls_painter.set_wall_offset(maze_wall_topleft_offset)

func _input(event):
	var mouse_pos = get_viewport().get_mouse_position()
	
	if event is InputEventKey:
		if test_camera_mode:
			if Input.is_action_pressed("ui_left"):
				pan_camera_left(camera_horizontal_move)
			if Input.is_action_pressed("ui_right"):
				pan_camera_right(camera_horizontal_move)
			if Input.is_action_pressed("ui_down"):
				pan_camera_bottom(camera_horizontal_move)
			if Input.is_action_pressed("ui_up"):
				pan_camera_top(camera_horizontal_move)
	
	if event is InputEventMouseButton:
		var map_Cell = $TileMap.world_to_map($KinematicBody2D.position)
		var cam_current = $KinematicBody2D/Camera2D.get_camera_position()
		print("current camera position=%s", cam_current)
		print("player on cell=%s, screen position=%s", map_Cell, $KinematicBody2D.position)
		#var bounding_cells = tile_walls_painter.get_selectedtile_boundary(mouse_pos, walls_bit_grid, gen_width, gen_height, 2, 5)

func create_maze_draw_objects(maze_placement_structs):
	var res = []
	if maze_placement_structs != null:
		var asset_static_path = "res://Assets/Tiles/MazeStatic/"
		for struct in maze_placement_structs:
			var mapstructkey = struct.keys()
			var sloc = mapstructkey[0]
			if sloc != null:
				var res_tile = ""
				var object_pixel = struct[sloc]
				if object_pixel.a8 >= 127 and object_pixel.a8 <= 127 + 32:
					print("maze object at %s" % [sloc])
					if object_pixel.g8 >= 48 and object_pixel.g8 < 64:
						 res_tile = asset_static_path + "cavern_pillar#1.png"
					if object_pixel.g8 >= 64 and object_pixel.g8 < 80:
						 res_tile = asset_static_path + "cavern_pillar#2.png"
					if object_pixel.g8 >= 80 and object_pixel.g8 < 96:
						 res_tile = asset_static_path + "cavern_pillar#3.png"
				if res_tile.length() >= 2:
					res.append({ sloc : res_tile })
	return res

func _ready():
	set_process(true)
	maze_camera = $"TileMap/Camera-Map-Viewer"
	if not test_camera_mode:
		maze_camera = $"TileMap/Player/Camera2D_Player"
	$"Timer-Level".start()
	print('_ready() called')
	generator_tilewalls = wallmaze_class.new()
	tile_walls_painter = drawtiles_scene.instance()
	screensize = get_viewport().size
	my_test_inventory = inventorystack_class.new([], true)
	my_test_inventory.add_to_inventory_catalogue(1, "red")
	my_test_inventory.add_to_inventory_catalogue(2, "green")
	my_test_inventory.add_to_inventory_catalogue(3, "blue")
	my_test_inventory.add_to_inventory_catalogue(4, "apple")
	my_test_inventory.add_inventory_pickup(1)
	my_test_inventory.add_inventory_pickup(3)
	my_test_inventory.add_inventory_pickup(3)
	print("My inventory [1] = " + my_test_inventory.print_info(true))
	my_test_inventory.add_inventory_pickup(4)
	print("My inventory [2] = " + my_test_inventory.print_info(true))
	my_test_inventory.remove_inventory_pickup(3)
	my_test_inventory.remove_inventory_pickup(2)
	my_test_inventory.add_inventory_pickup(1)
	print("My inventory [3] = " + my_test_inventory.print_info(true))
	tile_dimension = get_image_size(tile_path, walls_tileset_image)
	tile_dimension = Vector2(tile_dimension.x / 4, tile_dimension.y / 4)
	var imgsize = get_image_size(maze_path, walls_outline_image)
	gen_width = imgsize.x
	gen_height = imgsize.y
	var wall_cell_count = 0
	walls_bit_grid = generator_tilewalls.readWallGeneratorImage(walls_outline_image)
	maze_placement_structures = generator_tilewalls.pullMazeObjects(walls_outline_image)
	#create_maze_draw_objects(maze_placement_structures)
	if use_tilemap_image:
		create_tilemap_from_image(map_path, tilemap_image)
	if walls_bit_grid != null and walls_bit_grid.size() > 2:
		for wall_cell in walls_bit_grid:
			if wall_cell > 0:
				wall_cell_count += 1
	print('wall #cells = ' + str(wall_cell_count))
	#print('_ready() walls data=%s, size=%d' % [walls_bit_grid, walls_bit_grid.size()])
	if walls_bit_grid != null and walls_bit_grid.size() > 1:
		pass
		# Fix -- determine the height and width from the walk generate image ...
		#tile_walls_painter.set_wall_data(walls_tileset_image, walls_bit_grid, gen_width, gen_height, walls_autoselect)
	$"Canvas-Overlay".add_child(tile_walls_painter)


func load_image_map(image_file):
	pass

func create_tilemap_from_image(path, map_image):
	var resTexture = load(path + map_image)
	var dynImg = resTexture.get_data() #Image.new()
	dynImg.lock()
	var width = dynImg.get_width()
	var height = dynImg.get_height()
	for yi in range(0, height):
		for xi in range(0, width):
			var pixel = dynImg.get_pixel(xi, yi)
			var disc_green = pixel.g8 / 16
			if disc_green > 10:
				disc_green = 10
			if disc_green > 0:
				$TileMap.set_cellv(Vector2(xi, yi), disc_green)

func populate_level(full_tiles):
	pass
	# 2d list
	#clear()
#	var cell
#	for r in range(60):
#		for c in range(80):
#			cell = full_tiles[r][c]
#			if typeof(cell) != TYPE_INT:
#				set_cell(c, r, 0, false, false, false, cell)

func _on_body_enter(body):
	print('collision with body= %s' % [body])

func _on_Area2DMaze_body_entered(body):
	print('collision with body= %s' % [body])

func _on_Timer_timeout():
	timer_ticks += 1
	if timer_ticks == 15:
		draw_maze_objects = create_maze_draw_objects(maze_placement_structures)
		if draw_maze_objects != null:
			tile_walls_painter.set_maze_static(draw_maze_objects)
		tile_walls_painter.set_tile_size(tile_dimension.x, tile_dimension.y)
		tile_walls_painter.set_draw_period(draw_period)
		tile_walls_painter.set_wall_data(walls_tileset_image, walls_bit_grid, gen_width, gen_height, walls_autoselect)
		var walls_collision_polys = tile_walls_painter.create_wall_collision_partitions(Vector2.ZERO,\
		walls_bit_grid, gen_width, gen_height)
		if walls_collision_polys != null:
			var num_wall_collision_areas = walls_collision_polys.size()
			var area_index = 0
			for poly_points in walls_collision_polys:
				area_index += 1
				var collision_area = CollisionPolygon2D.new()
				collision_area.polygon = poly_points
				#body_enter ( Object body )
				#connect("body_enter")
				if individual_collision_areas:
					var collide_area_zone = Area2D.new()
					var colAreaName = "area#" + str(area_index)
					collide_area_zone.name = colAreaName
					collide_area_zone.add_child(collision_area)
					collide_area_zone.connect("body_entered", self, "_on_body_enter", [colAreaName])
					$TileMap.add_child(collide_area_zone)
				else:
					#$"TileMap/Area2D-MazeWall".add_child(collision_area)
					$"TileMap/StaticBody2D".add_child(collision_area)
		if individual_collision_areas == false:
			#$"TileMap/Area2D-MazeWall".connect("body_entered", self, "_on_body_enter", [colAreaName])
			pass
	if timer_ticks > 20:
		var player_position = $TileMap.global_position
		var centered_camera_position = maze_camera.get_camera_position()
		maze_camera.current = true
		centered_camera_position -= Vector2(screensize.x / 2, screensize.y / 2)
		if centered_camera_position.x <= 0:
			centered_camera_position.x = 0
		if centered_camera_position.y <= 0:
			centered_camera_position.y = 0
		tile_walls_painter.set_wall_offset(centered_camera_position, continuous_draw) # (pos, true)
		#if draw_maze_objects != null:
		#	tile_walls_painter.set_maze_static()

