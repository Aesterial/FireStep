extends Node

const SERVICE_ENDPOINT_SETTING := "firestep/network/api_endpoint"
const AUTH_ENDPOINT_SETTING := "firestep/network/auth_endpoint"
const SERVICE_ENDPOINT_ENV := "FIRESTEP_API_ENDPOINT"
const AUTH_ENDPOINT_ENV := "FIRESTEP_AUTH_ENDPOINT"
const DEFAULT_SERVICE_ENDPOINT := "http://127.0.0.1:8080"
const DEFAULT_AUTH_ENDPOINT := "http://127.0.0.1:3000"
const TOOL_PROJECT_PATH := "res://csharp-tool/Aesterial.FireStep.Client.Grpc.Tool.csproj"
const TOOL_BINARY_PATH := "res://csharp-tool/bin/Debug/net8.0/Aesterial.FireStep.Client.Grpc.Tool.dll"

var last_error: String = ""


func login(username: String, password: String) -> Dictionary:
	var service_endpoint := get_service_endpoint()
	if service_endpoint.is_empty():
		return _config_error("Адрес API не настроен.")

	return _wrap_data(_run_tool([
		"login",
		"--server", service_endpoint,
		"--username", username,
		"--password", password,
	]))


func register_user(username: String, email: String, password: String, initials: String, org: String) -> Dictionary:
	var service_endpoint := get_service_endpoint()
	if service_endpoint.is_empty():
		return _config_error("Адрес API не настроен.")

	return _wrap_data(_run_tool([
		"register",
		"--server", service_endpoint,
		"--username", username,
		"--email", email,
		"--password", password,
		"--initials", initials,
		"--org", org,
	]))


func validate_session(session_token: String) -> Dictionary:
	var service_endpoint := get_service_endpoint()
	if service_endpoint.is_empty():
		return _config_error("Адрес API не настроен.")

	return _wrap_data(_run_tool([
		"validate",
		"--server", service_endpoint,
		"--session-token", session_token,
	]))


func save_seance(payload_path: String) -> Dictionary:
	var service_endpoint := get_service_endpoint()
	if service_endpoint.is_empty():
		return _config_error("Адрес API не настроен.")

	return _wrap_data(_run_tool([
		"save-seance",
		"--server", service_endpoint,
		"--payload-file", ProjectSettings.globalize_path(payload_path),
	]))


func open_auth_redirect() -> Dictionary:
	var auth_redirect_url := get_auth_redirect_url()
	if auth_redirect_url.is_empty():
		return _config_error("Адрес авторизации не настроен.")

	OS.shell_open(auth_redirect_url)
	return {"success": true}


func get_service_endpoint() -> String:
	return _read_endpoint(SERVICE_ENDPOINT_SETTING, SERVICE_ENDPOINT_ENV, DEFAULT_SERVICE_ENDPOINT)


func get_auth_redirect_url() -> String:
	var auth_endpoint := _read_endpoint(AUTH_ENDPOINT_SETTING, AUTH_ENDPOINT_ENV, DEFAULT_AUTH_ENDPOINT)
	if auth_endpoint.is_empty():
		return ""

	if not auth_endpoint.ends_with("/"):
		auth_endpoint += "/"
	return auth_endpoint + "client-auth"


func _run_tool(arguments: Array[String]) -> Dictionary:
	if not _ensure_tool_built():
		return {
			"success": false,
			"error": last_error,
		}

	var output: Array = []
	var exit_code := OS.execute(
		"dotnet",
		[ProjectSettings.globalize_path(TOOL_BINARY_PATH)] + arguments,
		output,
		true,
		false
	)

	var text := ""
	for line in output:
		text += str(line)

	var parsed = JSON.parse_string(text.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Helper returned invalid JSON: %s" % text.strip_edges()
		return {
			"success": false,
			"error": last_error,
		}

	var success := bool(parsed.get("success", false)) and exit_code == 0
	if not success:
		last_error = str(parsed.get("error", "Unknown helper error"))
		return {
			"success": false,
			"error": last_error,
		}

	return {
		"success": true,
		"data": parsed.get("data", {}),
	}


func _wrap_data(response: Dictionary) -> Dictionary:
	if not response.get("success", false):
		return response

	var data = response.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return {"success": true}

	var result = data.duplicate(true)
	result["success"] = true
	return result


func _config_error(message: String) -> Dictionary:
	last_error = message
	return {
		"success": false,
		"error": message,
	}


func _read_endpoint(setting_path: String, env_name: String, default_value: String) -> String:
	var value := OS.get_environment(env_name)
	if value.is_empty():
		value = str(ProjectSettings.get_setting(setting_path, default_value))
	return value.strip_edges()


func _ensure_tool_built() -> bool:
	var binary_path := ProjectSettings.globalize_path(TOOL_BINARY_PATH)
	if FileAccess.file_exists(binary_path):
		return true

	var output: Array = []
	var exit_code := OS.execute(
		"dotnet",
		["build", ProjectSettings.globalize_path(TOOL_PROJECT_PATH)],
		output,
		true,
		false
	)
	if exit_code != 0:
		last_error = ""
		for line in output:
			last_error += str(line)
		return false

	return FileAccess.file_exists(binary_path)
