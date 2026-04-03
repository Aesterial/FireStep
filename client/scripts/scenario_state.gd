extends Node
class_name ScenarioState

signal objective_changed(text: String)
signal hint_changed(text: String)
signal banner_changed(text: String, tone: String)
signal feedback_requested(text: String, tone: String)
signal decision_requested(visible: bool, title: String, body: String)
signal result_requested(success: bool, title: String, body: String)
signal visuals_changed(state: String)

const IDLE_FAIL_SECONDS: float = 24.0

enum Phase {
	WAIT_STOP,
	MOVE_TO_SAFE_ZONE,
	DECISION,
	MOVE_TO_EXIT,
	SUCCESS,
	FAILURE,
}

var phase: int = Phase.WAIT_STOP
var idle_time: float = 0.0


func begin() -> void:
	phase = Phase.WAIT_STOP
	idle_time = 0.0
	objective_changed.emit("1. Обнаружьте дым и нажмите аварийную остановку.")
	hint_changed.emit("Посмотрите на красную кнопку аварийной остановки у компрессора и нажмите E.")
	banner_changed.emit("[ТРЕВОГА] У компрессора обнаружены дым и тревожная индикация.", "danger")
	feedback_requested.emit(
		"Режим обучения включён: остановите оборудование, отойдите на безопасную дистанцию, вызовите помощь и эвакуируйтесь.",
		"info"
	)
	decision_requested.emit(false, "", "")
	visuals_changed.emit("warning")
	set_process(true)


func _process(delta: float) -> void:
	if phase != Phase.WAIT_STOP:
		return

	idle_time += delta
	if idle_time >= IDLE_FAIL_SECONDS:
		_fail(
			"Тренировка не пройдена",
			"Сигнал опасности был проигнорирован слишком долго. Дым усилился, а зона у оборудования стала опаснее."
		)


func handle_action(action_id: String) -> void:
	if is_finished():
		return

	match action_id:
		"emergency_stop":
			_handle_emergency_stop()
		"machine_panel":
			_fail(
				"Тренировка не пройдена",
				"Оператор попытался спасать оборудование вместо того, чтобы сначала защитить людей и начать эвакуацию."
			)
		"exit":
			_handle_exit()


func on_safe_zone_entered() -> void:
	if phase != Phase.MOVE_TO_SAFE_ZONE:
		return

	phase = Phase.DECISION
	objective_changed.emit("3. На безопасной дистанции выберите следующее действие.")
	hint_changed.emit("Откроется панель решения. Сначала обеспечьте вызов помощи.")
	feedback_requested.emit("Верно. Сначала нужно выйти из опасной близости к оборудованию.", "success")
	decision_requested.emit(
		true,
		"Что делать дальше?",
		"Вы отошли на безопасную дистанцию. Выберите действие, которое соответствует учебному сценарию."
	)


func submit_decision(choice: String) -> void:
	if phase != Phase.DECISION:
		return

	match choice:
		"alarm":
			phase = Phase.MOVE_TO_EXIT
			objective_changed.emit("4. Покиньте помещение через отмеченный выход.")
			hint_changed.emit("Идите к двери выхода и нажмите E, чтобы перейти к этапу эвакуации.")
			banner_changed.emit("[ТРЕВОГА] Помощь вызвана. Продолжайте эвакуацию.", "warning")
			feedback_requested.emit("Помощь вызвана. Теперь немедленно покиньте помещение.", "success")
			decision_requested.emit(false, "", "")
			visuals_changed.emit("alarm_raised")
		"evacuate":
			feedback_requested.emit(
				"Эвакуация важна, но в рамках этого тренажёра нужно сначала зафиксировать вызов помощи из безопасной точки.",
				"warning"
			)
		"save":
			_fail(
				"Тренировка не пройдена",
				"Попытка спасать оборудование привела к потере времени. Дым усилился, а риск для человека вырос."
			)


func is_finished() -> bool:
	return phase == Phase.SUCCESS or phase == Phase.FAILURE


func _handle_emergency_stop() -> void:
	if phase == Phase.WAIT_STOP:
		phase = Phase.MOVE_TO_SAFE_ZONE
		objective_changed.emit("2. Перейдите в отмеченную безопасную зону.")
		hint_changed.emit("Отойдите к зелёной зоне, прежде чем принимать следующее решение.")
		banner_changed.emit("[ТРЕВОГА] Аварийная остановка активирована. Отойдите от оборудования.", "danger")
		feedback_requested.emit("Аварийная остановка нажата. Теперь создайте безопасную дистанцию.", "success")
		visuals_changed.emit("stopped")
		return

	feedback_requested.emit("Аварийная остановка уже активирована.", "info")


func _handle_exit() -> void:
	match phase:
		Phase.WAIT_STOP:
			feedback_requested.emit("Слишком рано. Сначала выполните аварийную остановку.", "warning")
		Phase.MOVE_TO_SAFE_ZONE:
			feedback_requested.emit("Сначала нужно отойти в безопасную зону.", "warning")
		Phase.DECISION:
			feedback_requested.emit("Перед выходом сначала зафиксируйте вызов помощи.", "warning")
		Phase.MOVE_TO_EXIT:
			_succeed()


func _succeed() -> void:
	phase = Phase.SUCCESS
	set_process(false)
	banner_changed.emit("Этап в цехе завершён. Проверьте резервный генератор в соседнем модуле.", "safe")
	feedback_requested.emit("Последовательность действий в цехе выполнена верно.", "success")
	decision_requested.emit(false, "", "")
	visuals_changed.emit("success")
	result_requested.emit(
		true,
		"Этап в цехе завершён",
		"Оборудование остановлено, безопасная дистанция создана, помощь вызвана. Теперь нужно отключить резервный генератор и только после этого завершить эвакуацию."
	)


func _fail(title: String, body: String) -> void:
	phase = Phase.FAILURE
	set_process(false)
	banner_changed.emit("[ОПАСНОСТЬ] Риск пожара возрастает.", "critical")
	decision_requested.emit(false, "", "")
	visuals_changed.emit("failure")
	result_requested.emit(false, title, body)
