extends StreamPeerBuffer
class_name ByteBuffer


const U8_MAX_SIZE: int = 255;
const U16_MAX_SIZE: int = 65535;
const U32_MAX_SIZE: int = 4294967295;


static func new_little_endian() -> ByteBuffer:
	var buffer = ByteBuffer.new()
	buffer.big_endian = false
	return buffer


func put_vec2(vec: Vector2):
	self.put_float(vec.x)
	self.put_float(vec.y)


func put_ivec2(vec: Vector2i):
	self.put_32(vec.x)
	self.put_32(vec.y)


func put_uvec2(vec: Vector2i):
	assert(vec.x >= 0 && vec.x <= U32_MAX_SIZE)
	assert(vec.y >= 0 && vec.y <= U32_MAX_SIZE)
	self.put_u32(vec.x)
	self.put_u32(vec.y)


func put_vec3(vec: Vector3):
	self.put_float(vec.x)
	self.put_float(vec.y)
	self.put_float(vec.z)


func put_ivec3(vec: Vector3i):
	self.put_32(vec.x)
	self.put_32(vec.y)
	self.put_32(vec.z)


func put_uvec3(vec: Vector3i):
	assert(vec.x >= 0 && vec.x <= U32_MAX_SIZE)
	assert(vec.y >= 0 && vec.y <= U32_MAX_SIZE)
	assert(vec.z >= 0 && vec.z <= U32_MAX_SIZE)
	self.put_u32(vec.x)
	self.put_u32(vec.y)
	self.put_u32(vec.z)


# Puts an array of T[] with u8 size
# write: Fn(ByteBuffer, T)
func put_array_u8_len(array: Array, write: Callable):
	if array.size() > U8_MAX_SIZE:
		printerr("ByteBuffer: put_array_u8_len but len > U8_MAX_SIZE")
		return
	self.put_u8(array.size())
	for elem in array:
		write.call(self, elem)


# Puts an array of T[] with u16 size
# write: Fn(ByteBuffer, T)
func put_array_u16_len(array: Array, write: Callable):
	if array.size() > U16_MAX_SIZE:
		printerr("ByteBuffer: put_array_u16_len but len > U16_MAX_SIZE")
		return
	self.put_u16(array.size())
	for elem in array:
		write.call(self, elem)


# Puts an array of T[] with u32 size
# write: Fn(ByteBuffer, T)
func put_array_u32_len(array: Array, write: Callable):
	if array.size() > U32_MAX_SIZE:
		printerr("ByteBuffer: put_array_u32_len but len > U32_MAX_SIZE")
		return
	self.put_u32(array.size())
	for elem in array:
		write.call(self, elem)


func put_uuid(uuid: String):
	assert(uuid.length() == 36)
	var raw_uuid_hex: String = uuid.replace("-", "")
	assert(raw_uuid_hex.length() == 32)
	self.put_data(raw_uuid_hex.hex_decode())


# write: Fn(ByteBuffer, T)
func put_option(object, write: Callable):
	if object == null:
		self.put_u8(0)
	else:
		self.put_u8(1)
		write.call(self, object)


func put_bool(value: bool):
	self.put_u8(1 if value else 0)


func get_vec2() -> Vector2:
	return Vector2(self.get_float(), self.get_float())


func get_ivec2() -> Vector2i:
	return Vector2i(self.get_32(), self.get_32())


func get_uvec2() -> Vector2i:
	return Vector2i(self.get_u32(), self.get_u32())


func get_vec3() -> Vector3:
	return Vector3(self.get_float(), self.get_float(), self.get_float())


func get_ivec3() -> Vector3i:
	return Vector3i(self.get_32(), self.get_32(), self.get_32())


func get_uvec3() -> Vector3i:
	return Vector3i(self.get_u32(), self.get_u32(), self.get_u32())


# Gets array of T[] with a u8 size
# read: Fn(ByteBuffer) -> T
func get_array_u8_len(read: Callable) -> Array:
	var array = []
	var length = self.get_u8()
	for elem in length:
		array.append(read.call(self))
	return array


# Gets array of T[] with a u16 size
# read: Fn(ByteBuffer) -> T
func get_array_u16_len(read: Callable) -> Array:
	var array = []
	var length = self.get_u16()
	for elem in length:
		var item = read.call(self)
		array.append(item)
	return array


# Gets array of T[] with a u32 size
# read: Fn(ByteBuffer) -> T
func get_array_u32_len(read: Callable) -> Array:
	var array = []
	var length = self.get_u32()
	for elem in length:
		array.append(read.call(self))
	return array


func get_uuid() -> String:
	var result = self.get_data(16)
	assert(result[0] == OK)
	var bytes = result[1] 
	var uuid_str: String = ""
	for i in range(16):
		if i == 4 || i == 6 || i == 8 || i == 10:
			uuid_str += "-"
		uuid_str += "%x" % bytes[i]
	return uuid_str


# read: Fn(ByteBuffer) -> T
func get_option(read: Callable):
	var exists = self.get_u8()
	if exists == 1:
		return read.call(self)
	else:
		return null


func get_bool() -> bool:
	return self.get_u8() == 1
