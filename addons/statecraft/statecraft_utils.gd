class_name SCUtils extends RefCounted


###
### Static Methods
### 

static func weakbind_state_to_callable(state: State, callable: Callable, invert: bool = false) -> Variant:
	var callable_args: int = callable.get_argument_count()
	if callable_args == 0:
		if invert:
			return func(): return not callable.call()
		else:
			return callable

	elif callable_args == 1:
		var weakref: WeakRef = weakref(state)
		
		if invert:
			return func(): 
				var ref: Object = weakref.get_ref()
				if ref:
					return not callable.call(ref)
				else:
					assert(false, "WeakRef to state was null.")
		else:
			return func(): 
				var ref: Object = weakref.get_ref()
				if ref:
					return callable.call(ref)
				else:
					assert(false, "WeakRef to state was null.")
	else:
		assert(false, "Trying to weakbind a method that takes more than one argument.")
		return null

static func call_with_possible_args(callable: Callable, optional_args: Array = []) -> Variant:
	var arg_count: int = callable.get_argument_count()
	return callable.callv(optional_args.slice(0, arg_count))


class CallbackTimer:
	var elapsed_time: float = 0.0
	var callbacks: Array[Callable] = []
	
	func add_callback(callback: Callable):
		self.callbacks.append(callback)

	func reset() -> void:
		self.elapsed_time = 0.0

	func process(target_time: float, delta: float) -> void:
		if self.elapsed_time >= target_time:
			return
			
		self.elapsed_time += delta
		if elapsed_time >= target_time:
			for callback in self.callbacks:
				callback.call()

class DynamicCallbackTimer:
	var duration_callable: Callable
	var _duration: float
	var elapsed_time: float = 0.0
	var callbacks: Array[Callable] = []
	
	func _init(duration_callable_: Callable):
		self.duration_callable = duration_callable_

	func add_callback(callback: Callable):
		self.callbacks.append(callback)

	func reset() -> void:
		self._duration = self.duration_callable.call()
		self.elapsed_time = 0.0

	func process(delta: float) -> void:
		if self.elapsed_time >= self._duration:
			return
			
		self.elapsed_time += delta
		if elapsed_time >= self._duration:
			for callback in self.callbacks:
				callback.call()
