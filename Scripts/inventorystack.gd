extends Node

var unique_flag : bool = true
var inventory_items : Array = [ ] # The dynamic items that are updated during game play
var available_inventory_map = { } # Map/catalogue of items that is initialised when level starts

func _init(inventory_start, unique):
	unique_flag = unique
	if not inventory_start == null and inventory_start.size() > 0:
		inventory_items += inventory_start

func add_to_inventory_catalogue(inventory_id, inventory_object):
	available_inventory_map[inventory_id] = inventory_object

func remove_from_inventory_catalogue(inventory_id):
	#if the item exists within the "available" inventory map
	available_inventory_map.erase(inventory_id)

func pickup_exists(inventory_id):
	var res = false
	if inventory_items.size() > 0:
		for itemv in inventory_items:
			if itemv == inventory_id:
				res = true
				break
	return res

func get_pickup_index(inventory_id):
	var res_index = -1
	for item_idx in range(0, inventory_items.size()):
		if inventory_items[item_idx] == inventory_id:
			res_index = item_idx
			break
	return res_index

func add_inventory_pickup(inventory_id):
	if not pickup_exists(inventory_id):
		inventory_items.append(inventory_id)

func list_inventory_pickups():
	return inventory_items

func remove_inventory_pickup(inventory_id):
	if pickup_exists(inventory_id):
		inventory_items.remove(get_pickup_index(inventory_id))

func print_info(detailed):
	var res = ""
	if detailed:
		for item_idx in range(0, inventory_items.size()):
			var inv_id = inventory_items[item_idx]
			var inv_item = available_inventory_map[inv_id]
			res += '\t\t id=' + str(inv_id) + ' ,object=' + str(inv_item) + '; '
	else:
		for item_idx in range(0, inventory_items.size()):
			var inv_id = inventory_items[item_idx]
			res += '\t\t id=' + str(inv_id) + '; '
	return res
