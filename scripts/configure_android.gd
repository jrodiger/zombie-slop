@tool
extends SceneTree
# Run with --editor against a small external setup project, never a game export.
func _initialize():call_deferred("configure")
func configure():
 var java=OS.get_environment("JAVA_HOME");var sdk=OS.get_environment("ANDROID_HOME")
 if java.is_empty() or sdk.is_empty():push_error("Set JAVA_HOME and ANDROID_HOME before Android setup.");quit(1);return
 var files=EditorInterface.get_resource_filesystem()
 while files.is_scanning():await create_timer(.1).timeout
 var settings=EditorInterface.get_editor_settings()
 settings.set_setting("export/android/java_sdk_path",java)
 settings.set_setting("export/android/android_sdk_path",sdk)
 var result=ResourceSaver.save(settings)
 if result!=OK:push_error("Could not save Android editor paths.")
 await process_frame
 quit(0 if result==OK else 1)
