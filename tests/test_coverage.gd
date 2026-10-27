extends "res://addons/gut/test.gd"

# Instrumented code performance should be within this margin of uninstrumented performance
const PERFORMANCE_MARGIN := 2.1

const SPATIAL_SCENE = preload("res://spatial.tscn")
const Coverage = preload("res://addons/coverage/coverage.gd")
const Other = preload("res://other.gd")
const ELSE_WHITESPACE_FIXTURE = "res://tests/fixtures/else_whitespace.gd"
const MULTILINE_STRING_FIXTURE = "res://tests/fixtures/multiline_string.gd"


func test_instrument_else_with_whitespace_before_colon():
	var fixture: GDScript = load(ELSE_WHITESPACE_FIXTURE)
	var original_source: String = fixture.source_code
	fixture.source_code = original_source.replace("else:", "else :")
	assert_eq(fixture.reload(), OK)
	var collector := Coverage.ScriptCoverageCollector.new(
		"res://addons/coverage/coverage.gd", ELSE_WHITESPACE_FIXTURE
	)
	collector.set_instrumented()
	var instance = fixture.new()
	assert_eq(instance.choose(true), "if")
	assert_eq(instance.choose(false), "else")
	collector.set_instrumented(false)
	fixture.source_code = original_source
	assert_eq(fixture.reload(), OK)


func test_instrument_multiline_string_without_inserting_counters():
	var collector := Coverage.ScriptCoverageCollector.new(
		"res://addons/coverage/coverage.gd", MULTILINE_STRING_FIXTURE
	)
	collector.set_instrumented()
	var fixture: GDScript = load(MULTILINE_STRING_FIXTURE)
	var source: String = fixture.new().get_source()
	assert_true(source.contains("if true:"))
	assert_true(source.contains("else :"))
	assert_true(source.contains('print("literal")'))
	assert_false(source.contains("__cl__"))
	collector.set_instrumented(false)


func test_autoload_coverage():
	assert_true(Autoload1._initted)
	assert_true(Autoload1.is_node_ready())
	assert_eq(Autoload2._counter, "2")
	var node = add_child_autoqfree(SPATIAL_SCENE.instantiate())
	node.auto_quit = false
	await wait_for_signal(node.done, 5000)
	assert_signal_emitted(node, "done")
	assert_true(Autoload1._initted)
	assert_true(Autoload1.is_node_ready())
	assert_eq(Autoload2._counter, "3")

	assert_eq(Autoload1.other._initted, 1)


func test_performance():
	var coverage: Coverage = Coverage.instance
	var collector: Coverage.ScriptCoverageCollector = coverage.get_coverage_collector(
		"res://other.gd"
	)
	var logger = get_logger()
	var other := Other.new()
	var other_script := other.get_script() as GDScript
	assert_true(
		other_script.source_code.match("*coverage.gd*"), "Other script should be instrumented"
	)
	var instrumented_source = other_script.source_code
	var instrumented_time = other.performance_test()
	collector.set_instrumented(false)
	assert_false(
		other.get_script().source_code.match("*coverage.gd*"),
		"Other script should no longer be instrumented"
	)
	var uninstrumented_time = other.performance_test()
	collector.set_instrumented(true)
	assert_true(
		other_script.source_code.match("*coverage.gd*"), "Other script should be instrumented"
	)
	var performance_loss := float(instrumented_time) / float(uninstrumented_time)
	var performance_passing := performance_loss < PERFORMANCE_MARGIN
	assert_gt(performance_loss, 1.2, "Performance loss should be measureable")
	assert_lt(
		performance_loss,
		PERFORMANCE_MARGIN,
		(
			"Performance loss for instrumentation: %.2fx < %.2f"
			% [performance_loss, PERFORMANCE_MARGIN]
		)
	)
	if !performance_passing:
		(
			logger
			. failed(
				(
					"%s\nInstrumented performance was not good enough.\n  Instrumented: %sus\nUninstrumented: %sus\n%sx > %sx"
					% [
						instrumented_source.get_slice("performance_test", 1),
						instrumented_time,
						uninstrumented_time,
						performance_loss,
						PERFORMANCE_MARGIN
					]
				)
			)
		)
