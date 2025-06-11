local glclass = GLunaTestLib.class
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_isa_manager()
	local manager = glclass:CreateObj("object_manager/manager")

	lunatest.assert_true(manager:isa("object_manager/manager"))
	lunatest.assert_true(manager:isa("object_manager/managed_base"))
	lunatest.assert_true(manager:isa("base"))
end


function suite.test_manager()
	local manager = glclass:CreateObj("object_manager/manager")

	local obj1_test1 = manager:CreateManagedObj("test1", "object_manager/managed_base")
	local obj2_test1 = manager:CreateManagedObj("test1", "object_manager/managed_base")
	local obj3_test1 = manager:Get("test1")

	local obj1_test2 = manager:CreateManagedObj("test2", "object_manager/managed_base")
	local obj2_test2 = manager:CreateManagedObj("test2", "object_manager/managed_base")
	local obj3_test2 = manager:Get("test2")

	local obj1_test3 = manager:CreateManagedObj("test3", "object_manager/manager")
	local obj2_test3 = manager:CreateManagedObj("test3", "object_manager/manager")
	local obj3_test3 = manager:Get("test3")

	lunatest.assert_not_nil(obj1_test1)
	lunatest.assert_not_nil(obj2_test1)
	lunatest.assert_not_nil(obj3_test1)

	lunatest.assert_not_nil(obj1_test2)
	lunatest.assert_not_nil(obj2_test2)
	lunatest.assert_not_nil(obj3_test2)

	lunatest.assert_not_nil(obj1_test3)
	lunatest.assert_not_nil(obj2_test3)
	lunatest.assert_not_nil(obj3_test3)

	lunatest.assert_equal(obj1_test1, obj2_test1)
	lunatest.assert_equal(obj1_test1, obj3_test1)
	lunatest.assert_equal(obj2_test1, obj3_test1)

	lunatest.assert_equal(obj1_test1:GetID(), obj2_test1:GetID())
	lunatest.assert_equal(obj1_test1:GetID(), obj3_test1:GetID())

	lunatest.assert_equal(obj1_test2, obj2_test2)
	lunatest.assert_equal(obj1_test2, obj3_test2)
	lunatest.assert_equal(obj2_test2, obj3_test2)

	lunatest.assert_equal(obj1_test2:GetID(), obj2_test2:GetID())
	lunatest.assert_equal(obj1_test2:GetID(), obj3_test2:GetID())

	lunatest.assert_equal(obj1_test3, obj2_test3)
	lunatest.assert_equal(obj1_test3, obj3_test3)
	lunatest.assert_equal(obj2_test3, obj3_test3)

	lunatest.assert_equal(obj1_test3:GetID(), obj2_test3:GetID())
	lunatest.assert_equal(obj1_test3:GetID(), obj3_test3:GetID())

	lunatest.assert_not_equal(obj1_test1, obj1_test2)
	lunatest.assert_not_equal(obj1_test1, obj1_test3)
	lunatest.assert_not_equal(obj1_test2, obj1_test3)

	lunatest.assert_not_equal(obj1_test1:GetID(), obj1_test2:GetID())
	lunatest.assert_not_equal(obj1_test1:GetID(), obj1_test3:GetID())
	lunatest.assert_not_equal(obj1_test2:GetID(), obj1_test3:GetID())

	lunatest.assert_true(obj1_test1:isa("object_manager/managed_base"))
	lunatest.assert_true(obj1_test1:isa("base"))

	lunatest.assert_true(obj1_test2:isa("object_manager/managed_base"))
	lunatest.assert_true(obj1_test2:isa("base"))

	lunatest.assert_true(obj1_test3:isa("object_manager/manager"))
	lunatest.assert_true(obj1_test3:isa("object_manager/managed_base"))
	lunatest.assert_true(obj1_test3:isa("base"))

	lunatest.assert_equal("test1", obj1_test1:GetName())
	lunatest.assert_equal("test2", obj1_test2:GetName())
	lunatest.assert_equal("test3", obj1_test3:GetName())
end

return suite
