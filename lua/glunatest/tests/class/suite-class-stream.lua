local glclass = GLunaTestLib.class
local lunatest = package.loaded.lunatest

local suite = {}

local function getTestEnt()
	local foundents = player.GetAll()

	for i, ent in ipairs(foundents) do
		if not IsValid(ent) then
			continue
		end

		return ent
	end

	local foundents = ents.GetAll()

	for i, ent in ipairs(foundents) do
		if not IsValid(ent) then
			continue
		end

		return ent
	end

	return nil
end

local continuedData = 'x' .. string.char(13, 154, 0, 7, 2, 10, 55)

function suite.test_datatype_raw()
	local stream = glclass:CreateObj("stream")

	local testDataW = "test 1234"

	local streamReturned = stream:WriteRaw(testDataW, 1000)
	lunatest.assert_equal(stream, streamReturned)
	lunatest.assert_equal(9, stream:GetSize())

	local dataR = stream:ReadRaw(1000)
	lunatest.assert_nil(dataR)
	lunatest.assert_equal(9, stream:GetSize())

	local dataR2 = stream:ReadRaw(9)
	lunatest.assert_equal(testDataW, dataR2)
	lunatest.assert_equal(9, stream:GetSize())
	lunatest.assert_equal(9, stream:GetReadPointer())
end

function suite.test_datatype_raw_long()
	local stream = glclass:CreateObj("stream")

	local testDataW = "test 1234 loooooooooooog"
	local testDataR1 = "test 1234 looooo"
	local testDataR1X = "test 1234 looooox"
	local testDataR2 = "test 1234 looo"

	local size = 16 + #continuedData

	local streamReturned = stream:WriteRaw(testDataW, 16):WriteRaw(continuedData, #continuedData)
	lunatest.assert_equal(stream, streamReturned)
	lunatest.assert_equal(size, stream:GetSize())

	local dataR1 = stream:ReadRaw(16)
	lunatest.assert_equal(testDataR1, dataR1)
	lunatest.assert_equal(size, stream:GetSize())
	lunatest.assert_equal(16, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR1X = stream:ReadRaw(17)
	lunatest.assert_equal(testDataR1X, dataR1X)
	lunatest.assert_equal(size, stream:GetSize())
	lunatest.assert_equal(17, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR2 = stream:ReadRaw(14)
	lunatest.assert_equal(testDataR2, dataR2)
	lunatest.assert_equal(size, stream:GetSize())
	lunatest.assert_equal(14, stream:GetReadPointer())
end

local function runIntTest(key, data, index, typeName, size)
	local stream = glclass:CreateObj("stream")

	local read = stream["Read" .. typeName]
	local write = stream["Write" .. typeName]

	local testDataW = data[1]
	local testDataRaw = data[2]

	local streamReturned = write(stream, testDataW)
	lunatest.assert_equal(stream, streamReturned)

	stream:WriteRaw(continuedData, #continuedData)

	local dataRaw = stream:ReadRaw(size)

	local sizeWithContinuedData = size + #continuedData

	lunatest.assert_equal_bytes(testDataRaw, dataRaw)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR = read(stream)
	lunatest.assert_equal(testDataW, dataR)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR2 = read(stream)
	lunatest.assert_equal(testDataW, dataR2)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())
end

lunatest.add_tests_by_table(suite, "stream_datatype_int8", {
	{0x00, "\x00"},
	{0x01, "\x01"},
	{0x20, "\x20"},
	{0x7F, "\x7F"},
	{-0x01, "\xFF"},
	{-0x20, "\xE0"},
	{-0x80, "\x80"},
}, function(key, data, index)
	runIntTest(key, data, index, "Int8", 1)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_uint8", {
	{0x00, "\x00"},
	{0x01, "\x01"},
	{0x20, "\x20"},
	{0x80, "\x80"},
	{0x7F, "\x7F"},
	{0xFF, "\xFF"},
}, function(key, data, index)
	runIntTest(key, data, index, "UInt8", 1)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_int16", {
	{0x0000, "\x00\x00"},
	{0x0001, "\x00\x01"},
	{0x0020, "\x00\x20"},
	{0x0300, "\x03\x00"},
	{0x4000, "\x40\x00"},
	{0x7FFF, "\x7F\xFF"},
	{-0x0001, "\xFF\xFF"},
	{-0x0020, "\xFF\xE0"},
	{-0x0300, "\xFD\x00"},
	{-0x4000, "\xC0\x00"},
	{-0x8000, "\x80\x00"},
}, function(key, data, index)
	runIntTest(key, data, index, "Int16", 2)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_uint16", {
	{0x0000, "\x00\x00"},
	{0x0001, "\x00\x01"},
	{0x0020, "\x00\x20"},
	{0x0300, "\x03\x00"},
	{0x4000, "\x40\x00"},
	{0x8000, "\x80\x00"},
	{0x7FFF, "\x7F\xFF"},
	{0xFFFF, "\xFF\xFF"},
}, function(key, data, index)
	runIntTest(key, data, index, "UInt16", 2)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_int24", {
	{0x000000, "\x00\x00\x00"},
	{0x000001, "\x00\x00\x01"},
	{0x000020, "\x00\x00\x20"},
	{0x000300, "\x00\x03\x00"},
	{0x004000, "\x00\x40\x00"},
	{0x050000, "\x05\x00\x00"},
	{0x600000, "\x60\x00\x00"},
	{0x7FFFFF, "\x7F\xFF\xFF"},
	{-0x000001, "\xFF\xFF\xFF"},
	{-0x000020, "\xFF\xFF\xE0"},
	{-0x000300, "\xFF\xFD\x00"},
	{-0x004000, "\xFF\xC0\x00"},
	{-0x050000, "\xFB\x00\x00"},
	{-0x600000, "\xA0\x00\x00"},
	{-0x800000, "\x80\x00\x00"},
}, function(key, data, index)
	runIntTest(key, data, index, "Int24", 3)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_uint24", {
	{0x000000, "\x00\x00\x00"},
	{0x000001, "\x00\x00\x01"},
	{0x000020, "\x00\x00\x20"},
	{0x000300, "\x00\x03\x00"},
	{0x004000, "\x00\x40\x00"},
	{0x050000, "\x05\x00\x00"},
	{0x600000, "\x60\x00\x00"},
	{0x800000, "\x80\x00\x00"},
	{0x7FFFFF, "\x7F\xFF\xFF"},
	{0xFFFFFF, "\xFF\xFF\xFF"},
}, function(key, data, index)
	runIntTest(key, data, index, "UInt24", 3)
end)


lunatest.add_tests_by_table(suite, "stream_datatype_int32", {
	{0x00000000, "\x00\x00\x00\x00"},
	{0x00000001, "\x00\x00\x00\x01"},
	{0x00000020, "\x00\x00\x00\x20"},
	{0x00000300, "\x00\x00\x03\x00"},
	{0x00004000, "\x00\x00\x40\x00"},
	{0x00050000, "\x00\x05\x00\x00"},
	{0x00600000, "\x00\x60\x00\x00"},
	{0x07000000, "\x07\x00\x00\x00"},
	{0x7FFFFFFF, "\x7F\xFF\xFF\xFF"},
	{-0x00000001, "\xFF\xFF\xFF\xFF"},
	{-0x00000020, "\xFF\xFF\xFF\xE0"},
	{-0x00000300, "\xFF\xFF\xFD\x00"},
	{-0x00004000, "\xFF\xFF\xC0\x00"},
	{-0x00050000, "\xFF\xFB\x00\x00"},
	{-0x00600000, "\xFF\xA0\x00\x00"},
	{-0x07000000, "\xF9\x00\x00\x00"},
	{-0x80000000, "\x80\x00\x00\x00"},

}, function(key, data, index)
	runIntTest(key, data, index, "Int32", 4)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_uint32", {
	{0x00000000, "\x00\x00\x00\x00"},
	{0x00000001, "\x00\x00\x00\x01"},
	{0x00000020, "\x00\x00\x00\x20"},
	{0x00000300, "\x00\x00\x03\x00"},
	{0x00004000, "\x00\x00\x40\x00"},
	{0x00050000, "\x00\x05\x00\x00"},
	{0x00600000, "\x00\x60\x00\x00"},
	{0x07000000, "\x07\x00\x00\x00"},
	{0x80000000, "\x80\x00\x00\x00"},
	{0xFFFFFFFF, "\xFF\xFF\xFF\xFF"},
}, function(key, data, index)
	runIntTest(key, data, index, "UInt32", 4)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_int48", {
	{0x000000000000, "\x00\x00\x00\x00\x00\x00"},
	{0x000000000001, "\x00\x00\x00\x00\x00\x01"},
	{0x000000000020, "\x00\x00\x00\x00\x00\x20"},
	{0x000000000300, "\x00\x00\x00\x00\x03\x00"},
	{0x000000004000, "\x00\x00\x00\x00\x40\x00"},
	{0x000000050000, "\x00\x00\x00\x05\x00\x00"},
	{0x000000600000, "\x00\x00\x00\x60\x00\x00"},
	{0x000007000000, "\x00\x00\x07\x00\x00\x00"},
	{0x000080000000, "\x00\x00\x80\x00\x00\x00"},
	{0x000900000000, "\x00\x09\x00\x00\x00\x00"},
	{0x00A000000000, "\x00\xA0\x00\x00\x00\x00"},
	{0x0B0000000000, "\x0B\x00\x00\x00\x00\x00"},
	{0x100000000000, "\x10\x00\x00\x00\x00\x00"},
	{0x7FFFFFFFFFFF, "\x7F\xFF\xFF\xFF\xFF\xFF"},
	{-0x000000000001, "\xFF\xFF\xFF\xFF\xFF\xFF"},
	{-0x000000000020, "\xFF\xFF\xFF\xFF\xFF\xE0"},
	{-0x000000000300, "\xFF\xFF\xFF\xFF\xFD\x00"},
	{-0x000000004000, "\xFF\xFF\xFF\xFF\xC0\x00"},
	{-0x000000050000, "\xFF\xFF\xFF\xFB\x00\x00"},
	{-0x000000600000, "\xFF\xFF\xFF\xA0\x00\x00"},
	{-0x000007000000, "\xFF\xFF\xF9\x00\x00\x00"},
	{-0x000080000000, "\xFF\xFF\x80\x00\x00\x00"},
	{-0x000900000000, "\xFF\xF7\x00\x00\x00\x00"},
	{-0x00A000000000, "\xFF\x60\x00\x00\x00\x00"},
	{-0x0B0000000000, "\xF5\x00\x00\x00\x00\x00"},
	{-0x100000000000, "\xF0\x00\x00\x00\x00\x00"},

}, function(key, data, index)
	runIntTest(key, data, index, "Int48", 6)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_uint48", {
	{0x000000000000, "\x00\x00\x00\x00\x00\x00"},
	{0x000000000001, "\x00\x00\x00\x00\x00\x01"},
	{0x000000000020, "\x00\x00\x00\x00\x00\x20"},
	{0x000000000300, "\x00\x00\x00\x00\x03\x00"},
	{0x000000004000, "\x00\x00\x00\x00\x40\x00"},
	{0x000000050000, "\x00\x00\x00\x05\x00\x00"},
	{0x000000600000, "\x00\x00\x00\x60\x00\x00"},
	{0x000007000000, "\x00\x00\x07\x00\x00\x00"},
	{0x000080000000, "\x00\x00\x80\x00\x00\x00"},
	{0x000900000000, "\x00\x09\x00\x00\x00\x00"},
	{0x00A000000000, "\x00\xA0\x00\x00\x00\x00"},
	{0x0B0000000000, "\x0B\x00\x00\x00\x00\x00"},
	{0xC00000000000, "\xC0\x00\x00\x00\x00\x00"},
	{0x800000000000, "\x80\x00\x00\x00\x00\x00"},
	{0xFFFFFFFFFFFF, "\xFF\xFF\xFF\xFF\xFF\xFF"},
}, function(key, data, index)
	runIntTest(key, data, index, "UInt48", 6)
end)

lunatest.add_tests_by_table(suite, "stream_datatype_bool", {
	{false, "\x00"},
	{true, "\x01"},
}, function(key, data, index)
	runIntTest(key, data, index, "Bool", 1)
end)


local function runIntTest(key, data, index, typeName, size)
	local stream = glclass:CreateObj("stream")

	local read = stream["Read" .. typeName]
	local write = stream["Write" .. typeName]

	local testDataW = data[1]
	local testDataRaw = data[2]

	local streamReturned = write(stream, testDataW)
	lunatest.assert_equal(stream, streamReturned)

	stream:WriteRaw(continuedData, #continuedData)

	local dataRaw = stream:ReadRaw(size)

	local sizeWithContinuedData = size + #continuedData

	lunatest.assert_equal_bytes(testDataRaw, dataRaw)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR = read(stream)
	lunatest.assert_equal(testDataW, dataR)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())

	stream:ResetReadPointer()

	local dataR2 = read(stream)
	lunatest.assert_equal(testDataW, dataR2)
	lunatest.assert_equal(sizeWithContinuedData, stream:GetSize())
	lunatest.assert_equal(size, stream:GetReadPointer())
end

function suite.test_datatype_entity()
	local stream = glclass:CreateObj("stream")

	local ent = getTestEnt()
	lunatest.assert_valid(ent)

	local streamReturned, ls = stream:WriteEntity(ent)
	lunatest.assert_equal(stream, streamReturned)

	local dataR = stream:ReadEntity()
	lunatest.assert_valid(dataR)
	lunatest.assert_equal(ent, dataR)
	lunatest.assert_equal(2, stream:GetReadPointer())
	lunatest.assert_equal(2, stream:GetSize())
end

lunatest.add_tests_by_table(suite, "stream_datatype_string", {
	{"", "\x00\x00\x00", 3},
	{"some test \t string with newLines \nvv", "\x00\x00\x24some test \t string with newLines \nvv", 39},
}, function(key, data, index)
	local stream = glclass:CreateObj("stream")

	local testDataW = data[1]
	local testStreamData = data[2]
	local size = data[3]

	local streamReturned, ls = stream:WriteString(testDataW)
	lunatest.assert_equal(stream, streamReturned)

	local dataR = stream:ReadString()
	lunatest.assert_equal(testDataW, dataR)
	lunatest.assert_equal(size, stream:GetReadPointer())
	lunatest.assert_equal(size, stream:GetSize())

	lunatest.assert_equal_bytes(testStreamData, stream:ToString())
	lunatest.assert_equal_bytes(testStreamData, tostring(stream))
end)

function suite.test_datatype_string_big()
	local stream = glclass:CreateObj("stream")

	local bigstring = string.rep("Some big test data!", 12931, " /// ")

	local testDataW = bigstring
	local testStreamData = "\x04\xBC\x43" .. bigstring
	local size = 310342

	local streamReturned, ls = stream:WriteString(testDataW)
	lunatest.assert_equal(stream, streamReturned)

	local dataR = stream:ReadString()
	lunatest.assert_equal(testDataW, dataR)
	lunatest.assert_equal(size, stream:GetReadPointer())
	lunatest.assert_equal(size, stream:GetSize())

	lunatest.assert_equal_bytes(testStreamData, stream:ToString())
	lunatest.assert_equal_bytes(testStreamData, tostring(stream))
end

function suite.test_create()
	local stream = glclass:CreateObj("stream")
	local ent = getTestEnt()

	lunatest.assert_equal(0, stream:GetSize())

	stream:WriteBool(true)
	stream:WriteBool(false)

	stream:WriteUInt8(5)
	stream:WriteUInt8(167)
	stream:WriteUInt16(1001)
	stream:WriteUInt16(54871)
	stream:WriteUInt24(4878344)
	stream:WriteUInt32(1144871244)
	stream:WriteUInt48(464152131541)
	stream:WriteUInt48(0)

	stream:WriteString("Im a String")

	stream:WriteEntity(ent)

	for i = 1, 6 do
		stream:WriteInt16(-3000 + 1000 * i)
	end

	-- test reinterpretation behaviour
	stream:WriteUInt16(0x1234)
	stream:WriteInt16(0x4567)
	stream:WriteInt16(-0x4567)

	lunatest.assert_equal(61, stream:GetSize())
	lunatest.assert_equal(0, stream:GetReadPointer())

	lunatest.assert_equal(true, stream:ReadBool())
	lunatest.assert_equal(false, stream:ReadBool())

	lunatest.assert_equal(5, stream:ReadUInt8())
	lunatest.assert_equal(167, stream:ReadUInt8())
	lunatest.assert_equal(1001, stream:ReadUInt16())
	lunatest.assert_equal(54871, stream:ReadUInt16())
	lunatest.assert_equal(4878344, stream:ReadUInt24())
	lunatest.assert_equal(1144871244, stream:ReadUInt32())
	lunatest.assert_equal(464152131541, stream:ReadUInt48())
	lunatest.assert_equal(0, stream:ReadUInt48())

	lunatest.assert_equal("Im a String", stream:ReadString())

	lunatest.assert_equal(ent, stream:ReadEntity())

	for i = 1, 6 do
		lunatest.assert_equal(-3000 + 1000 * i, stream:ReadInt16())
	end

	-- test reinterpretation behaviour
	lunatest.assert_equal(0x12, stream:ReadUInt8())
	lunatest.assert_equal(0x34, stream:ReadUInt8())

	lunatest.assert_equal(0x4567, stream:ReadUInt16())
	lunatest.assert_equal(0xBA99, stream:ReadUInt16())

	lunatest.assert_equal(61, stream:GetSize())
	lunatest.assert_equal(61, stream:GetReadPointer())

end

function suite.test_create_preloaded()
	local stream = glclass:CreateObj("stream", "\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31", false)

	lunatest.assert_equal(35, stream:GetSize())
	lunatest.assert_equal(0, stream:GetReadPointer())

	stream:WriteUInt16(6871)

	lunatest.assert_equal("Im a String", stream:ReadString())
	lunatest.assert_equal("Im also a String", stream:ReadString())
	lunatest.assert_equal(54321, stream:ReadUInt16())
	lunatest.assert_equal(6871, stream:ReadUInt16())

	stream:SetReadPointer(35)
	lunatest.assert_equal(35, stream:GetReadPointer())

	lunatest.assert_equal(6871, stream:ReadUInt16())

	lunatest.assert_equal(37, stream:GetSize())
	lunatest.assert_equal(37, stream:GetReadPointer())

	lunatest.assert_equal_bytes("\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31\x1A\xD7", stream:ToString())
	lunatest.assert_equal("00000B496D206120537472696E67000010496D20616C736F206120537472696E67D4311AD7", stream:ToHex())
end

function suite.test_create_preloaded_hex()
	local stream = glclass:CreateObj("stream", "0x00000B 496D2061 20537472 696E6700 001049 6d20616c 736F2061 20537472 696E67D4 31", true)

	lunatest.assert_equal(35, stream:GetSize())
	lunatest.assert_equal(0, stream:GetReadPointer())

	stream:WriteUInt16(6871)

	lunatest.assert_equal("Im a String", stream:ReadString())
	lunatest.assert_equal("Im also a String", stream:ReadString())
	lunatest.assert_equal(54321, stream:ReadUInt16())
	lunatest.assert_equal(6871, stream:ReadUInt16())

	stream:SetReadPointer(35)
	lunatest.assert_equal(35, stream:GetReadPointer())

	lunatest.assert_equal(6871, stream:ReadUInt16())

	lunatest.assert_equal(37, stream:GetSize())
	lunatest.assert_equal(37, stream:GetReadPointer())

	lunatest.assert_equal_bytes("\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31\x1A\xD7", stream:ToString())
	lunatest.assert_equal("00000B496D206120537472696E67000010496D20616C736F206120537472696E67D4311AD7", stream:ToHex())
end

function suite.test_concat_add_append()
	local stream = ((glclass:CreateObj("stream") .. "\x00\x00\x0BIm a String\x00") + "\x00\x10Im also "):AppendData("a String\xD4\x31")

	lunatest.assert_equal(35, stream:GetSize())
	lunatest.assert_equal(0, stream:GetReadPointer())

	stream:WriteUInt16(6871)

	lunatest.assert_equal("Im a String", stream:ReadString())
	lunatest.assert_equal("Im also a String", stream:ReadString())
	lunatest.assert_equal(54321, stream:ReadUInt16())
	lunatest.assert_equal(6871, stream:ReadUInt16())

	stream:SetReadPointer(35)
	lunatest.assert_equal(35, stream:GetReadPointer())

	lunatest.assert_equal(6871, stream:ReadUInt16())

	lunatest.assert_equal(37, stream:GetSize())
	lunatest.assert_equal(37, stream:GetReadPointer())

	lunatest.assert_equal_bytes("\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31\x1A\xD7", stream:ToString())
	lunatest.assert_equal("00000B496D206120537472696E67000010496D20616C736F206120537472696E67D4311AD7", stream:ToHex())
end

function suite.test_equal()
	local stream1 = glclass:CreateObj("stream", "\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31", false)
	local stream2 = glclass:CreateObj("stream", "\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31", false)
	local stream3 = glclass:CreateObj("stream", "0x00000B 496D2061 20537472 696E6700 001049 6d20616c 736F2061 20537472 696E67D4 31", true)
	local string1 = "\x00\x00\x0BIm a String\x00\x00\x10Im also a String\xD4\x31"

	lunatest.assert_equal_bytes(stream1, stream1)
	lunatest.assert_equal_bytes(stream1, stream2)
	lunatest.assert_equal_bytes(stream1, stream3)
	lunatest.assert_true(stream1:IsEqual(string1))

	lunatest.assert_equal_bytes(stream2, stream2)
	lunatest.assert_equal_bytes(stream2, stream3)
	lunatest.assert_true(stream2:IsEqual(string1))

	lunatest.assert_equal_bytes(stream3, stream3)
	lunatest.assert_true(stream3:IsEqual(string1))
end

return suite
