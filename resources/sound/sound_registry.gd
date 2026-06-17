extends RegistryBase
class_name SoundRegistry

func _validate_entry(entry: Variant) -> bool:
    return entry is AudioStream
