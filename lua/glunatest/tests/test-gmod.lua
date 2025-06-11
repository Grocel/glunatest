local lunatest = require "lunatest"
local testEnt = nil

function setup()
	local foundents = ents.GetAll()

	for i, ent in ipairs(foundents) do
		if not IsValid(ent) then
			continue
		end

		testEnt = ent
		break
	end
end

function test_gamelib()
	lunatest.assert_table(game)
end

function test_version()
	lunatest.assert_number(VERSION)
	lunatest.assert_gte(250509, VERSION, "Your game is outdated!")
end

function test_assert_vector()
	lunatest.assert_vector(Vector())
	lunatest.assert_vector(Vector(1, 2, 3))
end

function test_assert_not_vector()
	lunatest.assert_not_vector(nil)
	lunatest.assert_not_vector(23)
	lunatest.assert_not_vector("lapdesk")
	lunatest.assert_not_vector(false)
	lunatest.assert_not_vector(function () return 3 end)
	lunatest.assert_not_vector({"1", "2", "3"})
	lunatest.assert_not_vector({ foo=true, bar=true, baz=true })
	lunatest.assert_not_vector(Angle())
	lunatest.assert_not_vector(Matrix())
	lunatest.assert_not_vector(testEnt)
	lunatest.assert_not_vector(NULL)
end

function test_assert_angle()
	lunatest.assert_angle(Angle())
	lunatest.assert_angle(Angle(1, 2, 3))
end

function test_assert_not_angle()
	lunatest.assert_not_angle(nil)
	lunatest.assert_not_angle(23)
	lunatest.assert_not_angle("lapdesk")
	lunatest.assert_not_angle(false)
	lunatest.assert_not_angle(function () return 3 end)
	lunatest.assert_not_angle({"1", "2", "3"})
	lunatest.assert_not_angle({ foo=true, bar=true, baz=true })
	lunatest.assert_not_angle(Vector())
	lunatest.assert_not_angle(Matrix())
	lunatest.assert_not_angle(testEnt)
	lunatest.assert_not_angle(NULL)
end

function test_assert_matrix()
	lunatest.assert_matrix(Matrix())
end

function test_assert_not_matrix()
	lunatest.assert_not_matrix(nil)
	lunatest.assert_not_matrix(23)
	lunatest.assert_not_matrix("lapdesk")
	lunatest.assert_not_matrix(false)
	lunatest.assert_not_matrix(function () return 3 end)
	lunatest.assert_not_matrix({"1", "2", "3"})
	lunatest.assert_not_matrix({ foo=true, bar=true, baz=true })
	lunatest.assert_not_matrix(Vector())
	lunatest.assert_not_matrix(Angle())
	lunatest.assert_not_matrix(testEnt)
	lunatest.assert_not_matrix(NULL)
end

function test_assert_entity()
	lunatest.assert_entity(testEnt)
	lunatest.assert_entity(NULL)
end

function test_assert_not_entity()
	lunatest.assert_not_entity(nil)
	lunatest.assert_not_entity(23)
	lunatest.assert_not_entity("lapdesk")
	lunatest.assert_not_entity(false)
	lunatest.assert_not_entity(function () return 3 end)
	lunatest.assert_not_entity({"1", "2", "3"})
	lunatest.assert_not_entity({ foo=true, bar=true, baz=true })
	lunatest.assert_not_entity(Vector())
	lunatest.assert_not_entity(Angle())
	lunatest.assert_not_entity(Matrix())
end

function test_assert_valid()
	lunatest.assert_valid(testEnt)
end

function test_assert_not_valid()
	lunatest.assert_not_valid(nil)
	lunatest.assert_not_valid(23)
	lunatest.assert_not_valid("lapdesk")
	lunatest.assert_not_valid(false)
	lunatest.assert_not_valid(true)
	lunatest.assert_not_valid(function () return 3 end)
	lunatest.assert_not_valid({"1", "2", "3"})
	lunatest.assert_not_valid({ foo=true, bar=true, baz=true })
	lunatest.assert_not_valid(Vector())
	lunatest.assert_not_valid(Angle())
	lunatest.assert_not_valid(Matrix())
	lunatest.assert_not_valid(NULL)
end

if CLIENT then
	function test_realm_client()
		lunatest.assert_true(CLIENT)
		lunatest.assert_false(SERVER)

		lunatest.assert_table(surface)
		lunatest.assert_nil(constraint.Weld)
	end
else
	function test_realm_server()
		lunatest.assert_true(SERVER)
		lunatest.assert_false(CLIENT)

		lunatest.assert_function(constraint.Weld)
		lunatest.assert_nil(surface)
	end
end

lunatest.run()
