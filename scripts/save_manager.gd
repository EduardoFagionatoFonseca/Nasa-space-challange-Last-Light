class_name MissionSave
extends RefCounted

const PATH := "user://last_light_save.json"

static func exists() -> bool:
	return FileAccess.file_exists(PATH)

static func save(model: MissionModel) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(model.to_data()))
	file.close()
	return true

static func load_game() -> MissionModel:
	if not exists():
		return null
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	return MissionModel.from_data(parsed)

static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

