class_name SpatialHash2D
extends RefCounted

var _bucket_size := 8
var _buckets: Dictionary = {}
var _cells: Dictionary = {}
var _query_cache: Dictionary = {}
var _query_cache_order: Array[String] = []


func _init(bucket_size: int = 8) -> void:
	_bucket_size = maxi(bucket_size, 1)


func clear() -> void:
	_buckets.clear()
	_cells.clear()
	_query_cache.clear()
	_query_cache_order.clear()


func insert(cell: Vector2i) -> void:
	if _cells.has(cell):
		return
	var bucket := _bucket_for(cell)
	var bucket_cells: Array = _buckets.get(bucket, [])
	bucket_cells.append(cell)
	_buckets[bucket] = bucket_cells
	_cells[cell] = bucket
	_invalidate_queries()


func remove(cell: Vector2i) -> void:
	if not _cells.has(cell):
		return
	var bucket: Vector2i = _cells[cell]
	var bucket_cells: Array = _buckets.get(bucket, [])
	var index := bucket_cells.find(cell)
	if index != -1:
		bucket_cells.remove_at(index)
	if bucket_cells.is_empty():
		_buckets.erase(bucket)
	else:
		_buckets[bucket] = bucket_cells
	_cells.erase(cell)
	_invalidate_queries()


func has_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


func count_in_radius(center_cell: Vector2i, radius: int) -> int:
	if radius <= 0:
		return 1 if _cells.has(center_cell) else 0
	var count := 0
	var max_distance_squared := radius * radius
	for cell in get_candidates(center_cell, radius, 1024):
		if center_cell.distance_squared_to(cell) <= max_distance_squared:
			count += 1
	return count


func get_candidates(origin_cell: Vector2i, max_distance: int, limit: int = 96) -> Array:
	var safe_limit := maxi(limit, 1)
	var cache_key := "%d|%d|%d|%d" % [origin_cell.x, origin_cell.y, max_distance, safe_limit]
	if _query_cache.has(cache_key):
		return (_query_cache[cache_key] as Array).duplicate()

	var bucket_radius := int(ceil(float(max_distance) / float(_bucket_size))) + 1
	var origin_bucket := _bucket_for(origin_cell)
	var candidates: Array = []
	var max_distance_squared := maxi(max_distance, 1) * maxi(max_distance, 1)

	for by in range(origin_bucket.y - bucket_radius, origin_bucket.y + bucket_radius + 1):
		for bx in range(origin_bucket.x - bucket_radius, origin_bucket.x + bucket_radius + 1):
			var bucket := Vector2i(bx, by)
			if not _buckets.has(bucket):
				continue
			for cell in _buckets[bucket]:
				if origin_cell.distance_squared_to(cell) > max_distance_squared:
					continue
				candidates.append(cell)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return origin_cell.distance_squared_to(a) < origin_cell.distance_squared_to(b)
	)

	if candidates.size() > safe_limit:
		candidates.resize(safe_limit)
	_store_query(cache_key, candidates)
	return candidates.duplicate()


func _bucket_for(cell: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(cell.x) / float(_bucket_size))),
		int(floor(float(cell.y) / float(_bucket_size)))
	)


func _invalidate_queries() -> void:
	_query_cache.clear()
	_query_cache_order.clear()


func _store_query(cache_key: String, candidates: Array) -> void:
	_query_cache[cache_key] = candidates.duplicate()
	_query_cache_order.append(cache_key)
	if _query_cache_order.size() <= 256:
		return
	var stale_key: String = _query_cache_order.pop_front()
	_query_cache.erase(stale_key)
