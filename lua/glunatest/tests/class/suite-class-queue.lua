local glclass = GLunaTestLib.class
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_pushleft()
	local queue = glclass:CreateObj("queue")

	queue:PushLeft("test1")
	queue:PushLeft("test2")
	queue:PushLeft("test3")

	local expected = {
		"test3",
		"test2",
		"test1",
	}

	lunatest.assert_equal(3, queue:GetSize())
	lunatest.assert_equal_ex(expected, queue:ToTable())
end

function suite.test_pushright()
	local queue = glclass:CreateObj("queue")

	queue:PushRight("test1")
	queue:PushRight("test2")
	queue:PushRight("test3")

	local expected = {
		"test1",
		"test2",
		"test3",
	}

	lunatest.assert_equal(3, queue:GetSize())
	lunatest.assert_equal_ex(expected, queue:ToTable())
end

function suite.test_preloaded()
	local queue = glclass:CreateObj("queue", {
		"ptest1",
		"ptest2",
		"ptest3",
		362,
	})

	queue:PushRight("r")
	queue:PushLeft("l")

	local expected = {
		"l",
		"ptest1",
		"ptest2",
		"ptest3",
		362,
		"r",
	}

	lunatest.assert_equal(6, queue:GetSize())
	lunatest.assert_equal_ex(expected, queue:ToTable())
end

function suite.test_preloaded_reversed()
	local queue = glclass:CreateObj("queue", {
		"rtest1",
		"rtest2",
		"rtest3",
		412,
	})

	queue:PushRight("r")
	queue:PushLeft("l")

	queue:Reverse()

	local expected = {
		"r",
		412,
		"rtest3",
		"rtest2",
		"rtest1",
		"l",
	}

	lunatest.assert_equal(6, queue:GetSize())
	lunatest.assert_equal_ex(expected, queue:ToTable())
end

function suite.test_popleft()
	local queue = glclass:CreateObj("queue")

	queue:PushRight("test1")
	queue:PushRight("test2")
	queue:PushRight("test3")
	queue:PushLeft("first2")
	queue:PushLeft("first")

	lunatest.assert_equal(5, queue:GetSize())

	lunatest.assert_equal("first", queue:PopLeft())
	lunatest.assert_equal(4, queue:GetSize())

	lunatest.assert_equal("first2", queue:PopLeft())
	lunatest.assert_equal(3, queue:GetSize())

	lunatest.assert_equal("test1", queue:PopLeft())
	lunatest.assert_equal("test2", queue:PopLeft())
	lunatest.assert_equal("test3", queue:PopLeft())

	lunatest.assert_equal(0, queue:GetSize())
	lunatest.assert_nil(queue:PopLeft())
end

function suite.test_popright()
	local queue = glclass:CreateObj("queue")

	queue:PushRight("test1")
	queue:PushRight("test2")
	queue:PushRight("test3")
	queue:PushLeft("first2")
	queue:PushLeft("first")

	lunatest.assert_equal(5, queue:GetSize())

	lunatest.assert_equal("test3", queue:PopRight())
	lunatest.assert_equal(4, queue:GetSize())

	lunatest.assert_equal("test2", queue:PopRight())
	lunatest.assert_equal(3, queue:GetSize())

	lunatest.assert_equal("test1", queue:PopRight())
	lunatest.assert_equal("first2", queue:PopRight())
	lunatest.assert_equal("first", queue:PopRight())

	lunatest.assert_equal(0, queue:GetSize())
	lunatest.assert_nil(queue:PopRight())

end

function suite.test_copy()
	local queue = glclass:CreateObj("queue")

	queue:PushRight("test1")
	queue:PushRight("test2")
	queue:PushRight("test3")
	queue:PushLeft("first2")
	queue:PushLeft("first")

	local queueCopy = queue:Copy()

	lunatest.assert_not_equal(queue, queueCopy, "The queue objects must be not the same instance.")
	lunatest.assert_equal_ex(queue:ToTable(), queueCopy:ToTable())

	queueCopy:PushRight("test4")
	lunatest.assert_not_equal_ex(queue:ToTable(), queueCopy:ToTable())

	queue:PushRight("test4")
	lunatest.assert_equal_ex(queue:ToTable(), queueCopy:ToTable())
end

return suite
