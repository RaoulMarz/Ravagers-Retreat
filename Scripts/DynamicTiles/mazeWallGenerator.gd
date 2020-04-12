extends Node2D

var xSize = 40
var ySize = 30
var rng = RandomNumberGenerator.new()

var dynImg = Image.new()

#Color.green
#Color.blue
#Color.red
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
	
	var ntdir = 0
	currentTilePos = start
	
	#while endTilePlaced == false:
	#	ntdir = rng.randi_range(0,3)
	#	place_tile(currentTilePos,ntdir, tilesPlaced >= tilesLimit)
	# save to file

#returns a array of ints that have the value of either 1 or 0
func readWallGeneratorImage(generator_image):
	var res = [ ]
	dynImg = Image.new()
	#dynImg.create(width, height, false, Image.FORMAT_RGBA8)
	dynImg.load('res://Assets/Images/Walls/' + generator_image)
	dynImg.lock()
	var width = dynImg.get_width()
	var height = dynImg.get_height()
	for xi in range(0, width):
		for yi in range(0, height):
			var pixel = dynImg.get_pixel(xi, yi)
			if pixel == Color.black:
				res.append(0)
			else:
				res.append(1)
			#dynImg.set_pixelv(np, PATH_COLOR)
			#dynImg.set_pixelv(np, END_COLOR)
	dynImg.unlock()
	return res

		
#dynImg.get_pixelv(currentTilePos)
#set_cellv(Vector2(currentTilePos.x * tilesX,currentTilePos.y * tilesY), endid)
#dynImg.unlock()
#update_dirty_quadrants()
