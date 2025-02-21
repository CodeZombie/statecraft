class_name UnitTestSuite

class TestReport:
	enum Status {PASSED, FAILED}
	var status: Status
	var test_name: String
	
	func _init(test_name: String, status: Status) -> void:
		self.test_name = test_name
		self.status = status

var suite_name: String = ""
var test_reports: Array[TestReport] = []

func _init(suite_name: String) -> void:
	self.suite_name = suite_name
	for method in self.get_method_list():
		if method['name'].begins_with("test_"):
			self.preflight()
			self.call(method['name'])
			print("[PASSED] : {class_name}.{test_name}".format({
				'class_name': self.suite_name,
				'test_name': method['name']
			}))
			#if self.call(method['name']):
			#	self.test_reports.append(TestReport.new(method['name'], TestReport.Status.PASSED))
			#else:
			#	self.test_reports.append(TestReport.new(method['name'], TestReport.Status.FAILED))
	
	#self.print_report()

func preflight():
	pass

#func print_report():
	#for test_report in self.test_reports:
		#print("{status}: {name}".format({
			#'status': "PASSED" if test_report.status == TestReport.Status.PASSED else "[ FAILED ]",
			#'name': "{class_name}.{test_name}".format({
				#'class_name': self.suite_name,
				#'test_name': test_report.test_name
				#})
		#}))
