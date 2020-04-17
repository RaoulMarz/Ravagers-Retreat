extends Node

#Use a dictionary construct for global_cache_path_datapoints, the key will be a path descriptor (string)
var global_cache_path_datapoints = { }

func json_readfile(json_file, append_user_path_flag = false):
	var res = null
	if (json_file != null):
		var fullfilepath
		if append_user_path_flag:
			fullfilepath = "" + json_file
		else:
			fullfilepath = json_file
		var data_file = File.new()
		if data_file.open(fullfilepath, File.READ) != OK:
			return ""
		var data_text = data_file.get_as_text()
		data_file.close()
		res = JSON.parse(data_text)
	return res

func json_read_movement_path(json_pathdata, append_user_path_flag = false):
	var value = json_readfile(json_pathdata, append_user_path_flag)
	if (value != null):
		pass

func remove_file_extension(filename):
	var res = filename
	if (filename != null) and not str(filename).empty():
		res = filename.get_basename()
	return res

func check_valid_curvedata(curve_datapoints):
	var res = false
	if (curve_datapoints != null):
		return res
	return false

func global_create_path2d_datapoints(path_descriptor, data_points, beziercurve = false):
	if (path_descriptor != null) and (data_points != null):
		if beziercurve and check_valid_curvedata(data_points):
			if global_cache_path_datapoints.has(path_descriptor) == false:
				global_cache_path_datapoints[path_descriptor] = data_points
		else:
			if global_cache_path_datapoints.has(path_descriptor) == false:
				global_cache_path_datapoints[path_descriptor] = data_points

func global_create_segmentshape_path(path_descriptor, segmentshape_coordinates, beziercurve = false):
	if (path_descriptor != null) and (segmentshape_coordinates != null):
		#Create the U shape data points from the coordinates
		var resultdata = []
		for coord in segmentshape_coordinates:
			#Create data points for curve objects
			#if coord is Vector2:
			if typeof(coord) == TYPE_VECTOR2:
				resultdata.append(coord[0])
				resultdata.append(coord[1])
		global_create_path2d_datapoints(path_descriptor, resultdata, beziercurve)

func create_random_sequence(minlimit, maxlimit, arrsize, sort = false):
	var res = []
	if (minlimit >= 0) and (maxlimit > 0) and (arrsize > 0):
		var valuerange = maxlimit - minlimit
		for item in range(arrsize):
			res.append( (randi() % valuerange) + minlimit)
	if res != null and sort:
		res.sort()
	return res

func create_random_w_path(path_descriptor):
	if (path_descriptor != null) and not str(path_descriptor).empty():
		var lineseg1 = create_random_sequence(40, 300, 4, true)
		var lineseg2 = create_random_sequence(120, 800, 8, true)
		var lineseg3 = create_random_sequence(200, 800, 8, true)
		#print("lineseg1 : ", lineseg1)
		#if (lineseg1 is Array) and (lineseg2 is Array):
		if (typeof(lineseg1) == TYPE_ARRAY) and (typeof(lineseg2) == TYPE_ARRAY):
			print_debug("lineseg1 : ", lineseg1)
			print_debug("lineseg2 : ", lineseg2)
			var point1 = Vector2(lineseg1[0], lineseg1[1])
			var point2 = Vector2(lineseg1[2], lineseg1[3])
			var point3 = Vector2(lineseg2[3], lineseg2[0])
			var path_w_data = [ point1, point2, point2, point3 ]
			print_debug("path_w_data : ", path_w_data)
			global_create_segmentshape_path(path_descriptor, path_w_data)
#Path2D parent with 1 or many PathFollower2D child
#Each PathFollower2D will contain a sprite object to animate

#This function will read an array of sprites_list containing sprite file names
#and the following parameter sprites_unit_positions contain the unit positions for each sprite
func create_path_for_sprites(folderspec, sprites_list, sprites_unit_positions, path_descriptor, visible = false):
	var pre_path = ""
	if folderspec != null:
		pre_path = folderspec
	var newPathObject = Path2D.new()
	#Add the data points for the path
	if newPathObject != null:
		newPathObject.set_name(path_descriptor)
		create_random_w_path(path_descriptor)
		var sprites_curve = $"/root/test_graphics".create_curve2d(global_cache_path_datapoints[path_descriptor])
		newPathObject.curve = sprites_curve
		for sprite_res in sprites_list:
			var sprite_resource_file = sprite_res
			if (pre_path != null):
				sprite_resource_file = pre_path + "/" + sprite_resource_file
			var newPathFollower = PathFollow2D.new()
			newPathObject.add_child(newPathFollower)
			var newSpriteObject = Sprite.new()
			newSpriteObject.set_name(remove_file_extension(sprite_res))
			newSpriteObject.centered = false
			newSpriteObject.visible = visible
			var sprite_Image = load(sprite_resource_file)
			newSpriteObject.texture = sprite_Image
			newSpriteObject.position = Vector2(1, 1)
			newPathFollower.add_child(newSpriteObject)
	if newPathObject != null:
		return newPathObject
	else:
		return null
