@tool
extends Node3D

const DEFAULT_SPLAT_PLY_FILE := 'res://resources/demo.ply'

@export var vr_camera : XRCamera3D
@export var stereo_screen : MeshInstance3D 
@export var splat_container : Node3D

@onready var viewport : Variant = Engine.get_singleton('EditorInterface').get_editor_viewport_3d(0) if Engine.is_editor_hint() else get_viewport()
@onready var camera : Variant = vr_camera if vr_camera != null else viewport.get_camera_3d()

var rasterizer_left : Array[GaussianSplattingRasterizer] = []
var rasterizer_right : Array[GaussianSplattingRasterizer] = []
var loaded_file : String

func _ready() -> void:
	if stereo_screen:
		var material = ShaderMaterial.new()
		material.shader = load("res://util/stereo_mix.gdshader") 
		stereo_screen.material_override = material
	
	reload_all_splats()
	
func reload_all_splats() -> void:
	cleanup_all()
	
	if not splat_container:
		return
	
	var render_size = viewport.size
	if XRServer.primary_interface:
		render_size = XRServer.primary_interface.get_render_target_size() #returns resolution that should render
	
	for splat_child in splat_container.get_children():
		if splat_child is SplatObject and splat_child.ply_file_path != "":
			var ply_file = PlyFile.new(splat_child.ply_file_path)
			
			var texture_left = Texture2DRD.new()
			var gaussian_rasterizer_left = GaussianSplattingRasterizer.new(ply_file,render_size,texture_left,camera,splat_child,0)
			rasterizer_left.append(gaussian_rasterizer_left)
			
			var texture_right = Texture2DRD.new()
			var gaussian_rasterizer_right = GaussianSplattingRasterizer.new(ply_file,render_size,texture_right,camera,splat_child,1)
			rasterizer_right.append(gaussian_rasterizer_right)
		
	# TEMPORARY SHADER CONNECTION 
	if rasterizer_left.size() > 0:
		stereo_screen.material_override.set_shader_parameter("texture_left",rasterizer_left[0].render_texture)
		stereo_screen.material_override.set_shader_parameter("texture_right",rasterizer_right[0].render_texture) # temporary fix. only render one ply.
		
		
func _process(_delta : float) -> void:
	for rast in rasterizer_left:
		rast.update_camera_matrices()
		RenderingServer.call_on_render_thread(rast.rasterize)
		
	for rast in rasterizer_right:
		rast.update_camera_matrices()
		RenderingServer.call_on_render_thread(rast.rasterize)


func cleanup_all():
	for r in rasterizer_left: r.cleanup_gpu()
	for r in rasterizer_right: r.cleanup_gpu()
	rasterizer_left.clear()
	rasterizer_right.clear()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		cleanup_all()
