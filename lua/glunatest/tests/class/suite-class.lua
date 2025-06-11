local glclass = GLunaTestLib.class
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_isa_class_string()
	local obj1 = glclass:CreateObj("queue")
	local obj2 = glclass:CreateObj("result/sync_result")


	lunatest.assert_true(obj1:isa("queue"))
	lunatest.assert_true(obj1:isa("base"))

	lunatest.assert_false(obj1:isa("sync"))
	lunatest.assert_false(obj1:isa("result/sync_result"))
	lunatest.assert_false(obj1:isa("result/base"))
	lunatest.assert_false(obj1:isa("non-existing_class"))


	lunatest.assert_true(obj2:isa("result/sync_result"))
	lunatest.assert_true(obj2:isa("result/base"))
	lunatest.assert_true(obj2:isa("base"))

	lunatest.assert_false(obj2:isa("sync"))
	lunatest.assert_false(obj2:isa("queue"))
	lunatest.assert_false(obj2:isa("non-existing_class"))
end

function suite.test_isa_class_obj_from_obj()
	local obj1 = glclass:CreateObj("queue")
	local obj2 = glclass:CreateObj("result/sync_result")

	local class_queue = obj1:GetClass()
	local class_base1 = obj1:GetBaseClass()

	local class_sync_result = obj2:GetClass()
	local class_base_result = obj2:GetBaseClass()
	local class_base2 = obj2:GetBaseClass():GetBaseClass()

	lunatest.assert_true(obj1:isa(class_queue))
	lunatest.assert_true(obj1:isa(class_base1))
	lunatest.assert_true(obj1:isa(class_base2))

	lunatest.assert_false(obj1:isa(class_sync_result))
	lunatest.assert_false(obj1:isa(class_base_result))


	lunatest.assert_true(obj2:isa(class_sync_result))
	lunatest.assert_true(obj2:isa(class_base_result))
	lunatest.assert_true(obj2:isa(class_base1))
	lunatest.assert_true(obj2:isa(class_base2))

	lunatest.assert_false(obj2:isa(class_queue))
end

function suite.test_isa_class_obj_from_system()
	local obj1 = glclass:CreateObj("queue")
	local obj2 = glclass:CreateObj("result/sync_result")

	local class_queue = glclass:GetClass("queue")
	local class_base = glclass:GetClass("base")

	local class_sync_result = glclass:GetClass("result/sync_result")
	local class_base_result = glclass:GetClass("result/base")


	lunatest.assert_true(obj1:isa(class_queue))
	lunatest.assert_true(obj1:isa(class_base))

	lunatest.assert_false(obj1:isa(class_sync_result))
	lunatest.assert_false(obj1:isa(class_base_result))


	lunatest.assert_true(obj2:isa(class_sync_result))
	lunatest.assert_true(obj2:isa(class_base_result))
	lunatest.assert_true(obj2:isa(class_base))

	lunatest.assert_false(obj2:isa(class_queue))
end

function suite.test_class_equal()
	local base = glclass:CreateObj("base")
	local queue = glclass:CreateObj("queue")

	local class_base1 = glclass:GetClass("base")
	local class_base2 = glclass:GetClass("base")
	local class_base3 = base:GetClass()
	local class_base4 = queue:GetClass():GetBaseClass()
	local class_base5 = queue:GetBaseClass()

	lunatest.assert_equal(class_base1, class_base1)
	lunatest.assert_equal(class_base1, class_base2)
	lunatest.assert_equal(class_base1, class_base3)
	lunatest.assert_equal(class_base1, class_base4)
	lunatest.assert_equal(class_base1, class_base5)

	lunatest.assert_equal(class_base2, class_base2)
	lunatest.assert_equal(class_base2, class_base3)
	lunatest.assert_equal(class_base2, class_base4)
	lunatest.assert_equal(class_base2, class_base5)

	lunatest.assert_equal(class_base3, class_base3)
	lunatest.assert_equal(class_base3, class_base4)
	lunatest.assert_equal(class_base3, class_base5)

	lunatest.assert_equal(class_base4, class_base4)
	lunatest.assert_equal(class_base4, class_base5)

	lunatest.assert_equal(class_base5, class_base5)
end

function suite.test_globalvars()
	local base = glclass:CreateObj("base")
	local queue = glclass:CreateObj("queue")

	local class_base = glclass:GetClass("base")
	local class_queue = glclass:GetClass("queue")
	local class_sync = glclass:GetClass("sync")

	base:SetGlobalVar("test_base", 1)
	class_base:SetGlobalVar("test_class_base", 2)

	queue:SetGlobalVar("test_queue", "10")
	class_queue:SetGlobalVar("test_class_queue", "20")


	lunatest.assert_equal(1, base:GetGlobalVar("test_base"))
	lunatest.assert_equal(2, base:GetGlobalVar("test_class_base"))
	lunatest.assert_equal("10", base:GetGlobalVar("test_queue"))
	lunatest.assert_equal("20", base:GetGlobalVar("test_class_queue"))
	lunatest.assert_equal("test", base:GetGlobalVar("test_non_existing_var", "test"))
	lunatest.assert_equal("test1", base:GetGlobalVar("test_non_existing_var", "test1"))
	lunatest.assert_equal(nil, base:GetGlobalVar("test_non_existing_var"))

	lunatest.assert_equal(1, class_base:GetGlobalVar("test_base"))
	lunatest.assert_equal(2, class_base:GetGlobalVar("test_class_base"))
	lunatest.assert_equal("10", class_base:GetGlobalVar("test_queue"))
	lunatest.assert_equal("20", class_base:GetGlobalVar("test_class_queue"))
	lunatest.assert_equal("test", class_base:GetGlobalVar("test_non_existing_var", "test"))
	lunatest.assert_equal("test2", class_base:GetGlobalVar("test_non_existing_var", "test2"))
	lunatest.assert_equal(nil, class_base:GetGlobalVar("test_non_existing_var"))

	lunatest.assert_equal(1, queue:GetGlobalVar("test_base"))
	lunatest.assert_equal(2, queue:GetGlobalVar("test_class_base"))
	lunatest.assert_equal("10", queue:GetGlobalVar("test_queue"))
	lunatest.assert_equal("20", queue:GetGlobalVar("test_class_queue"))
	lunatest.assert_equal("test", queue:GetGlobalVar("test_non_existing_var", "test"))
	lunatest.assert_equal("test3", queue:GetGlobalVar("test_non_existing_var", "test3"))
	lunatest.assert_equal(nil, queue:GetGlobalVar("test_non_existing_var"))

	lunatest.assert_equal(1, class_queue:GetGlobalVar("test_base"))
	lunatest.assert_equal(2, class_queue:GetGlobalVar("test_class_base"))
	lunatest.assert_equal("10", class_queue:GetGlobalVar("test_queue"))
	lunatest.assert_equal("20", class_queue:GetGlobalVar("test_class_queue"))
	lunatest.assert_equal("test", class_queue:GetGlobalVar("test_non_existing_var", "test"))
	lunatest.assert_equal("test4", class_queue:GetGlobalVar("test_non_existing_var", "test4"))
	lunatest.assert_equal(nil, class_queue:GetGlobalVar("test_non_existing_var"))
end

function suite.test_localvars()
	local base1 = glclass:CreateObj("base")
	local base2 = glclass:CreateObj("base")
	local queue = glclass:CreateObj("queue")
	local sync = glclass:CreateObj("sync", function() end)

	base1.test_var1 = "test_base1"
	base2.test_var2 = "test_base2"
	queue.test_var3 = "test_queue"
	sync.test_var4 = "test_sync"

	base1.test_varx = "x1"
	base2.test_varx = "x2"
	queue.test_varx = "x3"
	sync.test_varx = "x4"

	lunatest.assert_nil(base2.test_var1)
	lunatest.assert_nil(queue.test_var1)
	lunatest.assert_nil(sync.test_var1)

	lunatest.assert_nil(base1.test_var2)
	lunatest.assert_nil(queue.test_var2)
	lunatest.assert_nil(sync.test_var2)

	lunatest.assert_nil(base2.test_var3)
	lunatest.assert_nil(base1.test_var3)
	lunatest.assert_nil(sync.test_var3)

	lunatest.assert_nil(base2.test_var4)
	lunatest.assert_nil(base1.test_var4)
	lunatest.assert_nil(queue.test_var4)

	lunatest.assert_equal("test_base1", base1.test_var1)
	lunatest.assert_equal("test_base2", base2.test_var2)
	lunatest.assert_equal("test_queue", queue.test_var3)
	lunatest.assert_equal("test_sync", sync.test_var4)

	lunatest.assert_equal("x1", base1.test_varx)
	lunatest.assert_equal("x2", base2.test_varx)
	lunatest.assert_equal("x3", queue.test_varx)
	lunatest.assert_equal("x4", sync.test_varx)
end

function suite.test_inheritance()
	local base1 = glclass:CreateObj("base")
	local base2 = glclass:CreateObj("base")
	local queue = glclass:CreateObj("queue")
	local sync = glclass:CreateObj("sync", function() end)
	local stream = glclass:CreateObj("stream")
	local sync_result = glclass:CreateObj("result/sync_result")

	lunatest.assert_equal(base1.GetFunction, base1.GetFunction)
	lunatest.assert_equal(base1.GetFunction, base2.GetFunction)
	lunatest.assert_equal(base1.GetFunction, queue.GetFunction)
	lunatest.assert_equal(base1.GetFunction, sync.GetFunction)
	lunatest.assert_equal(base1.GetFunction, stream.GetFunction)
	lunatest.assert_equal(base1.GetFunction, sync_result.GetFunction)

	lunatest.assert_equal(base2.GetFunction, base2.GetFunction)
	lunatest.assert_equal(base2.GetFunction, queue.GetFunction)
	lunatest.assert_equal(base2.GetFunction, sync.GetFunction)
	lunatest.assert_equal(base2.GetFunction, stream.GetFunction)
	lunatest.assert_equal(base2.GetFunction, sync_result.GetFunction)

	lunatest.assert_equal(queue.GetFunction, queue.GetFunction)
	lunatest.assert_equal(queue.GetFunction, sync.GetFunction)
	lunatest.assert_equal(queue.GetFunction, stream.GetFunction)
	lunatest.assert_equal(queue.GetFunction, sync_result.GetFunction)

	lunatest.assert_equal(sync.GetFunction, sync.GetFunction)
	lunatest.assert_equal(sync.GetFunction, stream.GetFunction)
	lunatest.assert_equal(sync.GetFunction, sync_result.GetFunction)

	lunatest.assert_equal(stream.GetFunction, stream.GetFunction)
	lunatest.assert_equal(stream.GetFunction, sync_result.GetFunction)

	lunatest.assert_equal(sync_result.GetFunction, sync_result.GetFunction)

	lunatest.assert_nil(stream.Sync)
	lunatest.assert_nil(stream.GetSyncObject)
	lunatest.assert_nil(sync.AppendData)
	lunatest.assert_nil(sync.GetSyncObject)
	lunatest.assert_nil(sync_result.Sync)
	lunatest.assert_nil(sync_result.AppendData)

	lunatest.assert_function(stream.AppendData)
	lunatest.assert_function(sync.Sync)
	lunatest.assert_function(sync_result.GetSyncObject)
end

function suite.test_equal()
	local base1 = glclass:CreateObj("base")
	local base2 = glclass:CreateObj("base")
	local queue = glclass:CreateObj("queue")
	local sync = glclass:CreateObj("sync", function() end)
	local stream = glclass:CreateObj("stream")
	local sync_result = glclass:CreateObj("result/sync_result")

	lunatest.assert_not_equal(base1, base2)
	lunatest.assert_not_equal(base1, queue)
	lunatest.assert_not_equal(base1, sync)
	lunatest.assert_not_equal(base1, stream)
	lunatest.assert_not_equal(base1, sync_result)

	lunatest.assert_not_equal(base2, base1)
	lunatest.assert_not_equal(base2, queue)
	lunatest.assert_not_equal(base2, sync)
	lunatest.assert_not_equal(base2, stream)
	lunatest.assert_not_equal(base2, sync_result)

	lunatest.assert_not_equal(queue, base1)
	lunatest.assert_not_equal(queue, base2)
	lunatest.assert_not_equal(queue, sync)
	lunatest.assert_not_equal(queue, stream)
	lunatest.assert_not_equal(queue, sync_result)

	lunatest.assert_not_equal(sync, base1)
	lunatest.assert_not_equal(sync, base2)
	lunatest.assert_not_equal(sync, queue)
	lunatest.assert_not_equal(sync, stream)
	lunatest.assert_not_equal(sync, sync_result)

	lunatest.assert_not_equal(stream, base1)
	lunatest.assert_not_equal(stream, base2)
	lunatest.assert_not_equal(stream, queue)
	lunatest.assert_not_equal(stream, sync)
	lunatest.assert_not_equal(stream, sync_result)

	lunatest.assert_not_equal(sync_result, base1)
	lunatest.assert_not_equal(sync_result, base2)
	lunatest.assert_not_equal(sync_result, queue)
	lunatest.assert_not_equal(sync_result, sync)
	lunatest.assert_not_equal(sync_result, stream)

	lunatest.assert_equal(base1, base1)
	lunatest.assert_equal(base2, base2)
	lunatest.assert_equal(queue, queue)
	lunatest.assert_equal(sync, sync)
	lunatest.assert_equal(stream, stream)
	lunatest.assert_equal(sync_result, sync_result)
end

return suite
