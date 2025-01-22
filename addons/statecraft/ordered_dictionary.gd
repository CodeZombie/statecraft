class_name OrderedDictionary

var _iter_current: int = 0
var _dict: Dictionary = {}
var _keys_in_order: Array[String] = []

func keys() -> Array[String]:
	return self._keys_in_order
	
func length() -> int:
	return len(self._dict.values())

func has_key(key: String) -> bool:
	return key in self.keys()

func has_value(value: Variant) -> bool:
	return value in self._dict.values()

func index_of(key: String):
	for i in range(len(self._keys_in_order)):
		if self._keys_in_order[i] == key:
			return i
			
func get_value(key: String):
	return self._dict[key]

func get_at_index(index: int):
	return self._dict[self._keys_in_order[index]]

#func insert(key: String, value: Variant):
	#self._dict[key] = value
	#if key not in self._dict.keys():
		#self._keys_in_order.append(key)
		#
func push_back(key: String, value: Variant):
	if key not in self._dict.keys():
		self._keys_in_order.push_back(key)
	self._dict[key] = value

func push_front(key: String, value: Variant):
	if key not in self._dict.keys():
		self._keys_in_order.push_front(key)
	self._dict[key] = value


func _iter_init(arg):
	self._iter_current = 0
	return self._iter_current < len(self._keys_in_order)
	
func _iter_next(arg):
	self._iter_current += 1
	return self._iter_current < len(self._keys_in_order)
	
func _iter_get(arg):
	return self._dict[self._keys_in_order[self._iter_current]]
