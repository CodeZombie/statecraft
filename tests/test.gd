extends Node2D


class BasicStateUnitTestSuite extends UnitTestSuite:
	var enter_calls: int = 0
	var update_calls: int = 0
	var exit_calls: int = 0
	var message_calls: int = 0
	
	func preflight():
		self.enter_calls = 0
		self.update_calls = 0
		self.exit_calls = 0
		self.message_calls = 0
		
	func fixture_empty_state():
		return State.new("emtpy_state")
		
	func fixture_enter_event_state():
		var state: State = State.new("test_state")
		state.add_enter_event(func(): self.enter_calls += 1)
		return state
		
	func fixture_update_event_state():
		var state: State = State.new("test_state")
		state.add_update_event(func(): self.update_calls += 1)
		return state
	
	func fixture_exit_event_state():
		var state: State = State.new("test_state")
		state.add_exit_event(func(): self.exit_calls += 1)
		return state
		
	func fixture_full_state():
		var state: State = State.new("full_state")
		state.add_enter_event(func(): self.enter_calls += 1)
		state.add_update_event(func(): 
			self.update_calls += 1
			return true)
		state.add_exit_event(func(): self.exit_calls += 1)
		return state

class BasicSuite extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0
	
	func fixture_simple_state() -> State:
		var state: State = State.new("test_state")
		state.add_enter_event(
			func():
				self.value_a += 1
		)
		return state
	
	
	
	func test_run_once(state=self.fixture_simple_state()):
		while true:
			if state.run():
				break
		assert(self.value_a == 1)

	func test_run_ten_times(state=self.fixture_simple_state()):
		self.value_a = 0
		
		for i in range(10):
			state.reset()
			while true:
				if state.run():
					break
		assert(self.value_a == 10)
		
	func test_run_instantly_once(state=self.fixture_simple_state()):
		state.run_instantly()
		assert(self.value_a == 1)
	
	func test_run_instantly_ten_times(state=self.fixture_simple_state()):
		for i in range(10):
			state.reset()
			state.run_instantly()
		assert(self.value_a == 10)

class BasicEnterAndUpdateSuite extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0

	func fixture_basic_state() -> State:
		var state: State = State.new("state")
		state.add_enter_event(
			func():
				self.value_a += 1
		)
		state.add_update_event(
			func():
				self.value_a += 1
				return true
		)
		return state
		
		
		
	func test_run_once(state=self.fixture_basic_state()):
		while true:
			if state.run():
				break
		assert(self.value_a == 2)
	
	func test_run_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			while true:
				if state.run():
					break
		assert(self.value_a == 20)
		
	func test_run_instantly_once(state=self.fixture_basic_state()):
		state.run_instantly()
		assert(self.value_a == 2)
	
	func test_run_instantly_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			state.run_instantly()
		assert(self.value_a == 20)

class BasicEnterAndUpdateAndExitSuite extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0
	
	func fixture_basic_state() -> State:
		var state: State = State.new("state")
		state.add_enter_event(
			func():
				self.value_a += 1
		)
		state.add_update_event(
			func():
				self.value_a += 1
				return true
		)
		state.add_exit_event(
			func():
				self.value_a += 1
		)
		return state

	func test_run_once(state=self.fixture_basic_state()):
		while true:
			if state.run():
				break
		assert(self.value_a == 3)
		
	func test_run_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			while true:
				if state.run():
					break
		assert(self.value_a == 30)
		
	func test_run_instantly_once(state=self.fixture_basic_state()):
		state.run_instantly()
		assert(self.value_a == 3)
	
	func test_run_instantly_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			state.run_instantly()
		assert(self.value_a == 30)

class BasicExitSuite extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0
	
	func fixture_basic_state() -> State:
		var state: State = State.new("state")

		state.add_exit_event(
			func():
				self.value_a += 1
		)
		return state
		
		
	func test_run_once(state=self.fixture_basic_state()):
		while true:
			if state.run():
				break
		assert(self.value_a == 1)
	
	func test_run_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			while true:
				if state.run():
					break
		assert(self.value_a == 10)
		
	func test_run_instantly_once(state=self.fixture_basic_state()):
		state.run_instantly()
		assert(self.value_a == 1)
	
	func test_run_instantly_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			state.run_instantly()
		assert(self.value_a == 10)

class BasicPropTestSuite extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0
	
	func fixture_basic_state() -> State:
		var state: State = State.new("state")
		state.add_enter_event(
			func(state: State):
				state.props["value"] = 0
		)
		state.add_update_event(
			func(delta: float, state: State):
				state.props["value"] += 1
				return true
		)
		state.add_exit_event(
			func(state: State):
				self.value_a += state.props["value"]
		)
		return state
	
	func test_basic_prop_run_once(state=self.fixture_basic_state()):
		while true:
			if state.run():
				break
		assert(self.value_a == 1)
		
	func test_basic_prop_run_ten_times(state=self.fixture_basic_state()):
		for i in range(10):
			state.reset()
			while true:
				if state.run():
					break
		assert(self.value_a == 10)

class AbstractStatusTest extends UnitTestSuite:
	func fixture_state() -> State:
		return null
	
	func test_not_started(state=self.fixture_state()):
		assert(state.status == State.StateStatus.READY)
		
	func test_run_one_tick(state=self.fixture_state()):
		state.run()
		assert(state.status == State.StateStatus.EXITED)
		
	func test_run_two_ticks(state=self.fixture_state()):
		state.run()
		state.run()
		assert(state.status == State.StateStatus.EXITED)
		
	func test_one_tick_and_exit(state=self.fixture_state()):
		state.run()
		state.exit()
		assert(state.status == State.StateStatus.EXITED)
	
	func test_one_tick_exit_and_restart(state=self.fixture_state()):
		state.run()
		state.exit()
		state.reset()
		assert(state.status == State.StateStatus.READY)
		
class EmptyStateStatusTest extends AbstractStatusTest:
	func fixture_state() -> State:
		return State.new("state")
		
class EnterEventStatusTest extends AbstractStatusTest:
	func fixture_state() -> State:
		return State.new("state").add_enter_event(
			func():
				return true
		)
		
class EnterAndUpdateEventStatusTest extends AbstractStatusTest:
	func fixture_state() -> State:
		return State.new("state")\
		.add_enter_event(
			func():
				pass
		)\
		.add_update_event(
			func():
				return true
		)
		
class EnterAndUpdateAndExitEventStatusTest extends AbstractStatusTest:
	func fixture_state() -> State:
		return State.new("state")\
		.add_enter_event(
			func():
				pass
		)\
		.add_update_event(
			func():
				return true
		)\
		.add_exit_event(
			func():
				pass
		)
		
class BasicSignalTest extends UnitTestSuite:
	var value_a: int = 0
	
	func preflight():
		self.value_a = 0
	
	func fixture_simple_signal_state() -> State:
		return State.new("state")\
		.add_enter_event(
			func(state: State): 
				state.emit_signal("signal_one")
		)\
		.add_signal("signal_one")\
		.on("signal_one", func():
			self.value_a += 1
		)
	
	func test_simple_signal_call(state=self.fixture_simple_signal_state()):
		state.run()
		assert(self.value_a == 1)
	
	func test_simple_signal_call_ten_times(state=self.fixture_simple_signal_state()):
		for i in range(10):
			state.reset()
			state.run()
		assert(self.value_a == 10)
		
	func test_multiple_signal_handlers(state=self.fixture_simple_signal_state()):
		state.on("signal_one", 
			func():
				self.value_a += 1
		)
		state.run()
		assert(self.value_a == 2)
		
	func test_running_all_signal_handlers_before_exiting(state=self.fixture_simple_signal_state()):
		state.on("signal_one", func():
			state.exit()
		)
		state.on("signal_one", func():
			self.value_a += 1
		)
		
		state.run()
		assert(self.value_a == 2)
		assert(state.status == State.StateStatus.EXITED)


class BasicStateTestSuite extends BasicStateUnitTestSuite:

	func test_state_initialization(state=self.fixture_empty_state()):
		assert(state.id == "emtpy_state", "State ID should be correctly assigned.")
		assert(state.status == State.StateStatus.READY, "State should initialize with READY status.")
		assert(state.enter_events.is_empty(), "Enter events should be empty on initialization.")
		assert(state.update_events.is_empty(), "Update events should be empty on initialization.")
		assert(state.exit_events.is_empty(), "Exit events should be empty on initialization.")
		
	func test_enter_event_execution(state=self.fixture_enter_event_state()):
		state.enter()
		assert(self.enter_calls == 1, "Enter event should be called.")
		assert(state.status == State.StateStatus.RUNNING, "State status should be RUNNING after calling enter().")

	func test_run_execution(state=self.fixture_update_event_state()):
		state.run(0.016)
		assert(self.update_calls == 1, "Update event should be called.")
		assert(state.status == State.StateStatus.RUNNING)

	func test_exit_event_execution(state=self.fixture_exit_event_state()):
		state.enter()
		state.exit()
		assert(self.exit_calls == 1, "Exit event should be called.")
		assert(state.status == State.StateStatus.EXITED, "State status should be EXITED after calling exit().")
		self.preflight()
		state.reset()
		state.run()
		assert(self.exit_calls == 1)
		assert(state.status == State.StateStatus.EXITED)

	func test_copy_empty_state(state=self.fixture_empty_state()):
		var copied_state = state.copy("copied_state")
		assert(copied_state.id == "copied_state", "Copied state should have the new ID.")
		assert(copied_state.enter_events.size() == state.enter_events.size(), "Enter events should be copied.")
		assert(copied_state.update_events.size() == state.update_events.size(), "Update events should be copied.")
		assert(copied_state.exit_events.size() == state.exit_events.size(), "Exit events should be copied.")
		
	func test_copy_full_state(state=self.fixture_full_state()):
		var copied_state = state.copy("copied_state")
		assert(copied_state.id == "copied_state", "Copied state should have the new ID.")
		assert(copied_state.enter_events.size() == state.enter_events.size(), "Enter events should be copied.")
		assert(copied_state.update_events.size() == state.update_events.size(), "Update events should be copied.")
		assert(copied_state.exit_events.size() == state.exit_events.size(), "Exit events should be copied.")

	func test_message_emission(state=self.fixture_empty_state()):
		state.add_signal("test_message")
		state.on("test_message", func(): self.message_calls += 1)
		state.emit_signal("test_message")
		assert(self.message_calls == 1, "Message handler should be called when message is emitted.")

	func test_run_instantly(state=self.fixture_full_state()):
		state.run_instantly()

		assert(self.enter_calls == 1, "Enter event should be called during run_instantly.")
		assert(self.update_calls == 1, "Update event should be called during run_instantly.")
		assert(self.exit_calls == 1, "Exit event should be called during run_instantly.")


class StateQueueBasicTestSuite extends BasicStateUnitTestSuite:
	
	func fixture_empty_state_queue():
		return StateQueue.new("state_queue")
		
	func fixture_signal_state():
		return State.new("signal_state")\
		.add_signal("signal")\
		.add_enter_event(func(state: State): state.emit_signal("signal"))
	
	func test_signal_bubble(queue=self.fixture_empty_state_queue(), sig_state=self.fixture_signal_state()):
		queue.on("signal_state.signal", func(): self.message_calls += 1)
		queue.add_state(sig_state)
		queue.run()
		assert(self.message_calls == 1)
		
	func test_signal_bubble_wildcard(queue=self.fixture_empty_state_queue(), sig_state=self.fixture_signal_state()):
		queue.on("*.signal", func(): self.message_calls += 1)
		queue.add_state(sig_state)
		queue.run()
		assert(self.message_calls == 1)
		
	func test_signal_bubble_wrong_state_name(queue=self.fixture_empty_state_queue(), sig_state=self.fixture_signal_state()):
		queue.on("fake_state.signal", func(): self.message_calls += 1)
		queue.add_state(sig_state)
		queue.run()
		assert(self.message_calls == 0)
		
	func test_double_wildcard(queue=self.fixture_empty_state_queue(), sig_state=self.fixture_signal_state()):
		queue.on("state_queue2.state_queue3.signal_state.signal", func(): self.message_calls += 1)
		var queue2 = StateQueue.new("state_queue2")
		var queue3 = StateQueue.new("state_queue3")
		queue3.add_state(sig_state)
		
		queue2.add_state(queue3)
		
		queue.add_state(queue2)
		
		queue.run()
		assert(self.message_calls == 1)
		
	func test_double_wildcard_out_of_order(queue=self.fixture_empty_state_queue(), sig_state=self.fixture_signal_state()):
		queue.on("state_queue2.state_queue3.signal_state.signal", func(): self.message_calls += 1)
		var queue2 = StateQueue.new("state_queue2")
		var queue3 = StateQueue.new("state_queue3")
		
		queue2.add_state(queue3)
		
		queue.add_state(queue2)
		
		queue3.add_state(sig_state)
		
		queue.run()
		assert(self.message_calls == 1)
	
	func test_state_queue_initialization(queue=self.fixture_empty_state_queue()):
		assert(queue.get_all_states().size() == 0)
		assert(queue.get_running_states().size() == 0)
		assert(queue.have_all_states_exited() == true)

	func test_adding_states(queue=self.fixture_empty_state_queue()):
		var state1 = State.new("State1")
		var state2 = State.new("State2")

		queue.add_state_back(state1)
		queue.add_state_front(state2)

		assert(queue.get_all_states().size() == 2)
		assert(queue.get_current_state() == state2)

	func test_serial_execution():
		var queue = StateQueue.new("SerialQueue")
		queue.set_execution_mode(StateQueue.ExecutionMode.SERIAL)

		var state1 = State.new("State1").add_enter_event(func(): self.enter_calls += 1)
		var state2 = State.new("State2").add_enter_event(func(): self.enter_calls += 1)

		queue.add_state(state1).add_state(state2)
		queue.run()
		assert(self.enter_calls == 1)
		
		queue.run()
		assert(self.enter_calls == 2)

	func test_parallel_execution(state1=self.fixture_full_state(), state2=self.fixture_full_state(), state3=self.fixture_full_state()):
		var queue = StateQueue.new("ParallelQueue")
		queue.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)

		var states = [state1, state2, state3]
		for state in states:
			queue.add_state(state)
			assert(state.status == State.StateStatus.READY)
			
		queue.run()
		
		for state in states:
			assert(state.status == State.StateStatus.EXITED)
		return true

	func test_exit_policy_keep():
		var queue = StateQueue.new("KeepQueue")
		queue.set_exit_policy(StateQueue.ExitPolicy.KEEP)
		var state = State.new("State1").add_enter_event(func(): pass)
		queue.add_state(state)

		queue.update(0.1)
		state.exit()
		queue.update(0.1)
		assert(queue.get_all_states().has(state))  # State remains
		return true

	func test_exit_policy_remove():
		var queue = StateQueue.new("RemoveQueue")
		queue.set_exit_policy(StateQueue.ExitPolicy.REMOVE)
		var state = State.new("State1")
		queue.add_state(state)

		queue.update(0.1)
		state.exit()
		queue.update(0.1)
		return not queue.get_all_states().has(state)  # State is removed

	func test_clear_states():
		var queue = StateQueue.new("ClearQueue")
		queue.add_state(State.new("State1")).add_state(State.new("State2"))
		queue.clear()
		return queue.get_all_states().size() == 0 and\
			queue.get_running_states().size() == 0

	func test_update_with_no_states():
		var queue = StateQueue.new("EmptyQueue")
		return queue.update(0.1)  # No states means immediate exit

	func test_pre_exited_states():
		var queue = StateQueue.new("PreExitedQueue")
		var state = State.new("State1")
		state.run()
		queue.add_state(state)
		return queue.have_all_states_exited()
	
	func test_add_state_after_exit():
		var queue = StateQueue.new("PreExitedQueue")
		var state = State.new("State1")
		queue.run()
		queue.add_state(state)
		return not queue.have_all_states_exited()
	
	func test_multiple_states_with_events():
		var queue = StateQueue.new("MultiStateQueue")
		self.enter_calls = 0
		self.exit_calls = 0

		var state1 = State.new("State1").add_enter_event(func(): self.enter_calls += 1)
		var state2 = State.new("State2").add_exit_event(func(): self.exit_calls += 1)

		queue.add_state(state1).add_state(state2)
		queue.update(0.1)
		assert(self.enter_calls == 1)

		state1.exit()
		queue.update(0.1)
		state2.exit()
		queue.update(0.1)
		return self.exit_calls == 1


	
func _ready() -> void:
	BasicSuite.new("BasicSuite")
	BasicEnterAndUpdateSuite.new("BasicEnterAndUpdateSuite")
	BasicEnterAndUpdateAndExitSuite.new("BasicEnterAndUpdateAndExitSuite")
	BasicExitSuite.new("BasicExitSuite")
	BasicPropTestSuite.new("BasicPropTestSuite")
	EmptyStateStatusTest.new("EmptyStateStatusTest")
	EnterEventStatusTest.new("EnterEventStatusTest")
	EnterAndUpdateEventStatusTest.new("EnterAndUpdateEventStatusTest")
	EnterAndUpdateAndExitEventStatusTest.new("EnterAndUpdateAndExitEventStatusTest")
	BasicSignalTest.new("BasicSignalTest")
	BasicStateTestSuite.new("BasicStateTestSuite")
	StateQueueBasicTestSuite.new("StateQueueBasicTestSuite")
