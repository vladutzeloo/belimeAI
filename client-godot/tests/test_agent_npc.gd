extends GdUnitTestSuite

const NPC_SCENE = preload("res://scenes/AgentNPC.tscn")


func test_agent_npc_instantiates() -> void:
	var npc = NPC_SCENE.instantiate()
	assert_that(npc).is_not_null()
	npc.queue_free()


func test_setup_sets_agent_id() -> void:
	var npc: AgentNPC = NPC_SCENE.instantiate()
	add_child(npc)
	npc.setup("agent_planner", {"sprite_frames": "", "station": "Stations/PlanningConsole"})
	assert_that(npc.agent_id).is_equal("agent_planner")
	npc.queue_free()


func test_apply_state_does_not_crash_without_frames() -> void:
	var npc: AgentNPC = NPC_SCENE.instantiate()
	add_child(npc)
	npc.setup("agent_coder", {})
	# No SpriteFrames loaded – apply_state must handle this gracefully
	npc.apply_state("working")
	npc.queue_free()
