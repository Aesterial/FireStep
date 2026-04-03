extends Node

var workshop_summary: String = ""
var final_success: bool = false
var final_title: String = ""
var final_body: String = ""
var final_highlights: Array[String] = []


func reset_session() -> void:
	workshop_summary = ""
	final_success = false
	final_title = ""
	final_body = ""
	final_highlights = []


func set_workshop_summary(summary: String) -> void:
	workshop_summary = summary


func set_final_result(success: bool, title: String, body: String, highlights: Array[String]) -> void:
	final_success = success
	final_title = title
	final_body = body
	final_highlights = highlights.duplicate()
