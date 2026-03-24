## Version information for the game
## Referenced by menus and build pipeline

extends Node

const VERSION: String = "0.1.0"
const BUILD_DATE: String = "2026-02-08"
const BUILD_COMMIT: String = ""


## Returns formatted version string for display
static func get_version_string() -> String:
	if BUILD_COMMIT != "":
		return "v%s (%s)" % [VERSION, BUILD_COMMIT.left(7)]
	return "v%s" % VERSION


## Returns full version info for bug reports
static func get_full_version_info() -> String:
	var info := "Version: %s\n" % VERSION
	info += "Build Date: %s\n" % BUILD_DATE
	if BUILD_COMMIT != "":
		info += "Commit: %s\n" % BUILD_COMMIT
	info += "Engine: Godot %s\n" % Engine.get_version_info().string
	info += "OS: %s\n" % OS.get_name()
	return info
