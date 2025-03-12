extends Object

class Base extends Object:
	func print_nodepaths(node_paths: Array[NodePath]) -> Base:
		print("Base's : {0}".format({0: node_paths}))
		return self
		
		
class Child extends Base:
	func print_nodepaths(node_paths: Array[NodePath]) -> Base:
		print("Child's : {0}".format({0: node_paths}))
		return self
	
	func print_xs() -> Base:
		print("xxxxxxxx")
		return self
		
		
class BaseProcessor:
	func x(base_obj: Base) -> Base:
		base_obj.print_nodepaths([^"aaaaaa"])
		return base_obj
	
class ChildProcessor extends BaseProcessor:
	func y(base_obj: Base) -> Base:
		base_obj.print_xs()
		return base_obj
		
func _ready() -> void:
	var base: Base = Base.new()
	base.print_nodepaths([^"a/b/c"]).print_xs()
	
	var child: Child = Child.new()
	child.print_nodepaths([^"1/2/3"]).print_xs()
	
	var child_proc: ChildProcessor = ChildProcessor.new()
	child_proc.y(child).print_xs()
