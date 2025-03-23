class_name SignalEvent extends StateEvent

var sig: Signal
var strip_args: bool
var arg_filter: Variant

func _init(sig: Signal, strip_args: bool = false, arg_filter: Variant = null):
	self.sig = sig
	self.strip_args = strip_args
	self.arg_filter = arg_filter

func attach_to_state(state: State, callable: Callable, target_state_paths: Array = [^""]) -> void:
	var signal_ = self.sig
	var strip_args_ = self.strip_args
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var arg_filter_ = self.arg_filter
	var filtered_bound_callable: Callable
	if arg_filter_:
		var arg_filter_arg_count: int = arg_filter_.get_argument_count()
		if arg_filter_arg_count == 0:
			filtered_bound_callable = func(): if arg_filter_.call(): bound_callable.call()
		if arg_filter_arg_count == 1:
			filtered_bound_callable = func(a): if arg_filter_.call(a): bound_callable.call()
		if arg_filter_arg_count == 2:
			filtered_bound_callable = func(a, b): if arg_filter_.call(a, b): bound_callable.call()
		if arg_filter_arg_count == 3:
			filtered_bound_callable = func(a, b, c): if arg_filter_.call(a, b, c): bound_callable.call()
		if arg_filter_arg_count == 4:
			filtered_bound_callable = func(a, b, c, d): if arg_filter_.call(a, b, c, d): bound_callable.call()
		if arg_filter_arg_count == 5:
			filtered_bound_callable = func(a, b, c, d, e): if arg_filter_.call(a, b, c, d, e): bound_callable.call()
	else:
		filtered_bound_callable = bound_callable
	
	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.connect_signal(signal_, filtered_bound_callable, strip_args_)
		else:
			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[signal_, filtered_bound_callable, strip_args_],
			))
