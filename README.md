![image](statecraft_logo.png)
# State Management Engine for Godot 4.x
## V0.0.1 - PRE-ALPHA
### Features
- Infinitely nest Finite State Machines and State Queues.
- Easily create complex behaviour with simple chaining interface
- Automatic tween management, creates and re-creates tweens after their execution.
- Simple Scope Binding. All custom State logic is written as if you were writing the code directly in a Node's class definition.
- Code-only solution. No messy States-As-Nodes or States-As-.Gd-Files patterns.
- Duplicate States, override sections of their existing behaviour, and re-use them in different contexts for maximum code-reuse.
- Run States, or entire State Machines, including all attached tweens at any variable speed via `speed_scale`

## Interface Reference

### State
State objects are the basis of all behavioural units within Statecraft. You can provide them with custom behavioural code in three distinct places:
 - `on_enter` : Executed once when the state is entered.
 - `on_update` : Executed every frame after the state has been entered until it exits.
 - `on_exit` : Executed once when the State exits.

Each of these methods is passed a `state_stack` Array, which is an ordered array of State objects which are calling this state's method.

The `on_update` method will also be provided a `delta` float, passed in from the `_on_update` Node method running this state machine.

Consider the following example
```
var rotate_state = State.new("rotate")
.set_on_enter(func():
    self.rotation = 0
)
.set_on_update(func(delta, state_stack):
    self.rotation += PI/4 * delta
    if self.rotation >= PI:
        state_stack[0].exit()
)
.set_on_exit(func():
    self.rotation = 0
)
```
This state will start by setting the Node's rotation to zero, then rotate the object by PI/4 radians per second until at least one full rotation has been completed, at which point it will signal to itself that it wishes to exit. This `exit` will be understood by either the State holding this State, or the `run()` method, which will then execute it's `on_exit` method, which sets the rotation back to zero.

| Method    | Description |
| -------- | ------- |
|`_init(id: String, skippable: bool)`|Creates a new state. `id` is a unique string identifier. `skippable` indicates whether this state's internal logic and all sub-states can be skipped over if the state holding it attempts to `process_immediately` or `skip_skippable_states`|
|`set_on_enter(callable: Callable)`|Attach a method to a state that will be executed every time the state is entered.|
|`set_on_update(callable: Callable)`|Attach a method to a state that will be executed every time the state updates.|
|`set_on_exit(callable: Callable)`|Attach a method to a state that will be executed every time the state exits.|
|`set_timeout(duration: float)`|Starts a timer (in seconds) for this state. Upon completion of the timer, the state will exit.|
|`add_tween(terminal: bool, scene_node: Node, tween_definition_method: Callable)`| Attaches a tween to the state that will execute when the state is entered. This method can be called multiple times to attach multiple tweens. `terminal` indicates whether the state will exit upon completion of this tween. `scene_node` is the node within the game scene to attach the tween to. `tween_definition_method` is a callable that takes on argument, a `Tween` object for you to define the behaviour of said tween. |
|`process_immediately()`| Processes this State and all children as quickly as possible. Any skippable children will be skipped. *NOTE*: that this can potentially be dangerous, as it is very possible to write a State that only exit upon a certain condition being met. If this condition is never met, calling this method will result in an infinite loop, halting your game.|
|`run(speed_scale: float, loop: bool = false)`| The primary entrypoint for a State. Use this to execute a State/StateQueue/StateMachine from your game code. Only one `run()` call is needed for any tree of States, regardless of how many children it may have. `speed_scale` is a value used to speed up or slow down the execute of a tree of States. Under the hood, all time-based methods, both internal and custom, including tweens, are provided a `delta` value. `speed_scale` can be used to modify this `delta` time, effectively speeding up (with a `speed_scale` > 1) or slow down (with a `speed_scale` < 1) time. This is particularly useful if you want to fast-forward the execution of certain events in your game, or to create bullet-time effects. `loop` indicates whether the root state should restart after exiting.

### StateQueue/StateMachine
StateQueue and StateMachine are both themselves States, and thus also have all of the methods listed above.

| Method    | Description |
| -------- | ------- |
|`add_state(state: State)`| Attaches a State to this StateQueue/StateMachine.|
|`get_state(state_id: String) -> State` | Returns the state contained within this StateQueue/StateMachine that matches the provided `state_id`|
|`get_current_state_id() -> String`| Returns the id string of the currently executing State within this StateQueue/StateMachine |
|`transition_to(state_id: String)`| Notifies this StateQueue/StateMachine to exit the current state and transition into another, given by the State's ID string.
|`clear()`| Removes all child states from this StateMachine/StateQueue |

### Tweens
Tweens in Godot 4 are very temporal. The engine will destroy them after they have finished executing, which means they must be re-created before a State containing 