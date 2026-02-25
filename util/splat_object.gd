@tool
class_name SplatObject extends Node3D

@export_file("*.ply") var ply_file_path : String

func _ready() -> void:
	if Engine.is_editor_hint():
		_create_editor_helper()

func _create_editor_helper():
	if has_node("EditorVisualizer"): return
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "EditorVisualizer"
	
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 0, 0.3)
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)

func _process(_delta):
	if not Engine.is_editor_hint():
		if has_node("EditorVisualizer"):
			get_node("EditorVisualizer").visible = false
