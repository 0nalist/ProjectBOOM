extends Node


signal collect_entity(collectable_entity_resource: BaseCollectableResource)



func emit_collect_entity(collectable_entity_resource: BaseCollectableResource) -> void:
	collect_entity.emit(collectable_entity_resource)

