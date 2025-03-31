class_name EventActionCreator extends Object

var from_state_node_paths: Array
var parent: State

func _init(parent: State, from_state_node_paths: Array = [^""]):
	self.from_state_node_paths = from_state_node_paths
	self.parent = parent
	
func if_true(condition: Callable) -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, ConditionEvent.new(condition))

func if_false(condition: Callable) -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, ConditionEvent.new(condition, true))

func on_enter() -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, SignalPathEvent.new(^":entered"))

# TODO: this is incredibly confusing.
# Does this trigger when `from_state` exits, or when `parent` exits?
# I believe it's when `parent` exits, but based on how you'd write this, that isn't obvious.
# It also might not even ever work, because when the parent exits, its not "in" any states, so this
# will perhaps never even execute? not sure.
func on_exit() -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, SignalPathEvent.new(^":exited"))

func on_broadcast(broadcast_name: StringName) -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, BroadcastEvent.new(broadcast_name))

func on_signal(sig: Variant, arg_filter: Variant = null) -> EventActionCreatorReaction:
	if sig is String or sig is StringName or sig is NodePath:
		return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, SignalPathEvent.new(sig))
	else:
		return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, SignalEvent.new(sig, false, arg_filter))

func on_timer(duration: float) -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, TimerEvent.new(duration))
	
func on_dynamic_timer(duration_callable: Callable) -> EventActionCreatorReaction:
	return EventActionCreatorReaction.new(self.parent, self.from_state_node_paths, DynamicTimerEvent.new(duration_callable))
