@tool

extends EditorScript

var meshlib_path = "res://resources/kaykit-dungeon/kaykit_dungeon.meshlib"

func _run():
	update_meshlib()

func update_item(meshlib: MeshLibrary, item_id: int):
	print(item_id)
	var mesh = meshlib.get_item_mesh(item_id)
	for surface_idx in range(mesh.get_surface_count()):
		var mat = mesh.surface_get_material(surface_idx) as BaseMaterial3D
		print(mat.vertex_color_use_as_albedo)
		mat.vertex_color_use_as_albedo = false

func update_meshlib():
	var meshlib = load(meshlib_path) as MeshLibrary
	var item_list = meshlib.get_item_list()
	for item_id in item_list:
		update_item(meshlib, item_id)

	ResourceSaver.save(meshlib, meshlib_path)
