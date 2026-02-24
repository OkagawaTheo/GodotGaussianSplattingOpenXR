@tool
extends Node3D

const DEFAULT_SPLAT_PLY_FILE := 'res://resources/demo.ply'

@export var vr_camera : XRCamera3D
@export var stereo_screen : MeshInstance3D 

@onready var viewport : Variant = Engine.get_singleton('EditorInterface').get_editor_viewport_3d(0) if Engine.is_editor_hint() else get_viewport()
@onready var camera : Variant = vr_camera if vr_camera != null else viewport.get_camera_3d()

var rasterizer_left : GaussianSplattingRasterizer
var rasterizer_right : GaussianSplattingRasterizer
var loaded_file : String

func _ready() -> void:
	if stereo_screen:
		var material = ShaderMaterial.new()
		material.shader = load("res://util/stereo_mix.gdshader") 
		stereo_screen.material_override = material
	
	init_rasterizers(DEFAULT_SPLAT_PLY_FILE)

func init_rasterizers(ply_path : String) -> void:
	if rasterizer_left: rasterizer_left.cleanup_gpu()
	if rasterizer_right: rasterizer_right.cleanup_gpu()
	
	var ply_file = PlyFile.new(ply_path)
	var render_size = viewport.size
	
	if XRServer.primary_interface:
		render_size = XRServer.primary_interface.get_render_target_size()
	
	var tex_left = Texture2DRD.new()
	rasterizer_left = GaussianSplattingRasterizer.new(ply_file, render_size, tex_left, camera, self, 0)
	stereo_screen.material_override.set_shader_parameter("texture_left", tex_left)
	
	var tex_right = Texture2DRD.new()
	rasterizer_right = GaussianSplattingRasterizer.new(ply_file, render_size, tex_right, camera, self, 1)
	stereo_screen.material_override.set_shader_parameter("texture_right", tex_right)
	
	loaded_file = ply_path.get_file()

func _process(delta: float) -> void:
	if rasterizer_left: 
		rasterizer_left.update_camera_matrices()
		RenderingServer.call_on_render_thread(rasterizer_left.rasterize)
		
	if rasterizer_right:
		rasterizer_right.update_camera_matrices()
		RenderingServer.call_on_render_thread(rasterizer_right.rasterize)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if rasterizer_left: RenderingServer.call_on_render_thread(rasterizer_left.cleanup_gpu)
		if rasterizer_right: RenderingServer.call_on_render_thread(rasterizer_right.cleanup_gpu)
