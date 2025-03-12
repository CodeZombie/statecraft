class_name SCUtils extends Object


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
			print("XXXXX")
			for callback in self.callbacks:
				callback.call()

# static func call_with_optional_state(state: State, callable: Callable) -> Variant:
# 	if callable.get_argument_count() == 1:
# 		return callable.call(state)
# 	else:
# 		return callable.call()


# static func bind_with_optional_state(state: State, callable: Callable) -> Callable:
# 	if callable.get_bound_arguments_count() == 1:
# 		return callable.bind(state)
# 	return callable


# static func invert_callable(callable: Callable) -> Callable:
# 	var arg_count: int = callable.get_argument_count()
# 	if arg_count == 0:
# 		return func(): return not callable.call()
# 	elif arg_count == 1:
# 		return func(arg_a: Variant): return not callable.call(arg_a) 
# 	elif arg_count == 2:
# 		return func(arg_a: Variant, arg_b: Variant): return not callable.call(arg_a, arg_b)
# 	elif arg_count == 3:
# 		return func(arg_a: Variant, arg_b: Variant, arg_c: Variant): return not callable.call(arg_a, arg_b, arg_c)
# 	assert(false, "Cannot invert callable with more than 3 arguments.")
# 	return Callable()


#
#static func test_weak_bind() -> bool:
	#var state: State = State.new(&"test")   
	#var test_callable: Callable = func(state: State): return state.id == "test"
	#var weakbound_callable: Callable = SCUtils.weakbind_state_to_callable(state, test_callable)
	#assert(state.get_reference_count() == 1, "State should have 1 reference.")
	#assert(weakbound_callable.call(), "Weakbound callable should return true.")
	#assert(state.dereference() == true, "State should have 0 references and therefore be scheduled for freeing.")
	#assert(weakbound_callable.call() == false, "Weakbound callable should return false.")
	#return true
#
#
#static func test():
	#print("Running SCUtils tests.")
	#assert(SCUtils.test_weak_bind(), "Weak bind test failed.")
	#print("SCUtils tests passed.")
