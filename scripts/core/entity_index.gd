class_name EntityIndex
extends RefCounted

var _npc_cells: Dictionary = {}
var _worm_cells: Dictionary = {}
var _npc_cells_by_id: Dictionary = {}
var _worm_cells_by_id: Dictionary = {}


func clear() -> void:
	_npc_cells.clear()
	_worm_cells.clear()
	_npc_cells_by_id.clear()
	_worm_cells_by_id.clear()


func register_npc(npc_id: int, cell: Vector2i) -> void:
	if _npc_cells_by_id.has(npc_id):
		var old_cell: Vector2i = _npc_cells_by_id[npc_id]
		_npc_cells.erase(old_cell)
	_npc_cells[cell] = npc_id
	_npc_cells_by_id[npc_id] = cell


func update_npc(npc_id: int, old_cell: Vector2i, new_cell: Vector2i) -> void:
	if old_cell == new_cell:
		return
	if _npc_cells.get(old_cell, -1) == npc_id:
		_npc_cells.erase(old_cell)
	_npc_cells[new_cell] = npc_id
	_npc_cells_by_id[npc_id] = new_cell


func unregister_npc(npc_id: int) -> void:
	var cell: Vector2i = _npc_cells_by_id.get(npc_id, Vector2i(-1, -1))
	if cell != Vector2i(-1, -1) and _npc_cells.get(cell, -1) == npc_id:
		_npc_cells.erase(cell)
	_npc_cells_by_id.erase(npc_id)


func is_npc_on_cell(cell: Vector2i, ignore_npc_id: int = -1) -> bool:
	if not _npc_cells.has(cell):
		return false
	return int(_npc_cells[cell]) != ignore_npc_id


func get_npc_id_on_cell(cell: Vector2i, ignore_npc_id: int = -1) -> int:
	if not _npc_cells.has(cell):
		return -1
	var npc_id := int(_npc_cells[cell])
	return -1 if npc_id == ignore_npc_id else npc_id


func register_worm(worm_id: int, cell: Vector2i) -> void:
	if _worm_cells_by_id.has(worm_id):
		var old_cell: Vector2i = _worm_cells_by_id[worm_id]
		_worm_cells.erase(old_cell)
	_worm_cells[cell] = worm_id
	_worm_cells_by_id[worm_id] = cell


func update_worm(worm_id: int, old_cell: Vector2i, new_cell: Vector2i) -> void:
	if old_cell == new_cell:
		return
	if _worm_cells.get(old_cell, -1) == worm_id:
		_worm_cells.erase(old_cell)
	_worm_cells[new_cell] = worm_id
	_worm_cells_by_id[worm_id] = new_cell


func unregister_worm(worm_id: int) -> void:
	var cell: Vector2i = _worm_cells_by_id.get(worm_id, Vector2i(-1, -1))
	if cell != Vector2i(-1, -1) and _worm_cells.get(cell, -1) == worm_id:
		_worm_cells.erase(cell)
	_worm_cells_by_id.erase(worm_id)


func is_worm_on_cell(cell: Vector2i, ignore_worm_id: int = -1) -> bool:
	if not _worm_cells.has(cell):
		return false
	return int(_worm_cells[cell]) != ignore_worm_id


func get_worm_id_on_cell(cell: Vector2i, ignore_worm_id: int = -1) -> int:
	if not _worm_cells.has(cell):
		return -1
	var worm_id := int(_worm_cells[cell])
	return -1 if worm_id == ignore_worm_id else worm_id
