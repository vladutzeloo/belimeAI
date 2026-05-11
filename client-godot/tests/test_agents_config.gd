extends GdUnitTestSuite

const CONFIG_PATH = "res://config/agents_config.json"
const REQUIRED_AGENTS = ["agent_planner", "agent_researcher", "agent_coder", "agent_executor"]
const REQUIRED_FIELDS = ["sprite_frames", "station"]


func test_config_loads_as_dictionary() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	assert_that(file).is_not_null()
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	assert_that(parsed).is_instanceof(Dictionary)


func test_all_required_agents_present() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var cfg: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	for agent_id in REQUIRED_AGENTS:
		assert_that(cfg.has(agent_id)).is_true()


func test_all_entries_have_required_fields() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var cfg: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	for agent_id in cfg.keys():
		var entry: Dictionary = cfg[agent_id]
		for field in REQUIRED_FIELDS:
			assert_that(entry.has(field)).is_true()
