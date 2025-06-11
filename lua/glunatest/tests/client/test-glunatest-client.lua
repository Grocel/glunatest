local lunatest = require "lunatest"

function test_client()
	lunatest.assert_true(CLIENT)
	lunatest.assert_false(SERVER)
end

lunatest.run()
