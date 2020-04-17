extends Node2D

var xSize = 40
var ySize = 30
var rng = RandomNumberGenerator.new()

var dynImg = Image.new()

const START_COLOR = Color.black

var currentTilePos = Vector2.ZERO
var start = Vector2.ZERO
var tilesPlaced = 0

func _ready():
	call_deferred("generate")

func generateMaze(wall_min, wall_max, start_pos):
	dynImg = Image.new()
	tilesPlaced = 0
	#endTilePlaced = false
	rng.randomize()
	start.x = (xSize -1) / 2
	start.y = (ySize-1) / 2
	#var tilesXSize = tilesX * (cell_size.x * scale.x)
	#var tilesYSize = tilesY * (cell_size.y * scale.y)
	#position = Vector2((-start.x * tilesXSize) - tilesXSize/2, (-start.y * tilesYSize) - tilesYSize/2)
	
	dynImg.create(xSize, ySize, false, Image.FORMAT_RGBA8)
	dynImg.fill(Color.black)
	
	dynImg.lock()
	dynImg.set_pixelv(start, START_COLOR)
	dynImg.unlock()
	
	print(start)
	
#	var ntdir = 0
#	currentTilePos = start

#returns a array of ints that have the value of either 1 or 0
func readWallGeneratorImage(generator_image):
	var res = [ ]
	var resTexture = load('res://Assets/Maze/' + generator_image)
	var dynImg = resTexture.get_data() #Image.new()
	dynImg.lock()
	var width = dynImg.get_width()
	var height = dynImg.get_height()
	for yi in range(0, height):
		for xi in range(0, width):
			var pixel = dynImg.get_pixel(xi, yi)
			if pixel == Color.black or pixel.a8 == 0:
				res.append(0)
			else:
				if pixel.a8 >= 255 and pixel.g8 >= 255 and pixel.b8 >= 255:
					res.append(1)
				else:
					res.append(0)
	dynImg.unlock()
	return res

# put data in array with a record being the pixel location and pixel color
func pullMazeObjects(generator_image):
	var res = [ ]
	var resTexture = load('res://Assets/Maze/' + generator_image)
	var dynImg = resTexture.get_data() #Image.new()
	dynImg.lock()
	var width = dynImg.get_width()
	var height = dynImg.get_height()
	for yi in range(0, height):
		for xi in range(0, width):
			var pixel = dynImg.get_pixel(xi, yi)
			if pixel.a8 >= (0.1 * 255) and pixel.a8 <= (0.9 * 255):
				res.append({ Vector2(xi, yi) : pixel})
	dynImg.unlock()
	return res

#update_dirty_quadrants()
