class_name TestRunner
extends RefCounted

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func run_suite(suite_name: String, tests: Callable) -> void:
	print("\n[%s]" % suite_name)
	tests.call()


func assert_true(condition: bool, message: String = "Expected true") -> void:
	if condition:
		passed += 1
		return
	_record_failure(message)


func assert_false(condition: bool, message: String = "Expected false") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		passed += 1
		return
	var detail := message if message != "" else "Values are not equal"
	_record_failure("%s (expected=%s actual=%s)" % [detail, str(expected), str(actual)])


func assert_array_eq(actual: Array, expected: Array, message: String = "") -> void:
	if actual == expected:
		passed += 1
		return
	var detail := message if message != "" else "Arrays are not equal"
	_record_failure("%s (expected=%s actual=%s)" % [detail, str(expected), str(actual)])


func summary() -> int:
	print("\n=== Test summary ===")
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)
	for failure in failures:
		print("  - %s" % failure)
	return 0 if failed == 0 else 1


func _record_failure(message: String) -> void:
	failed += 1
	failures.append(message)
	push_error(message)
