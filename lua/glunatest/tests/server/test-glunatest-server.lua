local lunatest = require "lunatest"

function test_server()
	lunatest.assert_true(SERVER)
	lunatest.assert_false(CLIENT)
end

lunatest.run()
