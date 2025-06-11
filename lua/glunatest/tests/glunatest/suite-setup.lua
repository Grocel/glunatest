local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_instance()
	lunatest.assert_table(GLunaTestLib)
	lunatest.assert_function(GLunaTestLib.CreateGLunaTestSetupInstance)

	local glunatestsetup = GLunaTestLib:CreateGLunaTestSetupInstance()
	lunatest.assert_table(glunatestsetup)
end

function suite.test_add_project()
	local glunatestsetup = GLunaTestLib:CreateGLunaTestSetupInstance()
	local testProject1 = glunatestsetup:AddProject("testproject1")
	local testProject2 = glunatestsetup:AddProject("testproject2")

	local testProjectReturned1 = glunatestsetup:GetProjectByName("testproject1")
	local testProjectReturned2 = glunatestsetup:GetProjectByName("testproject2")

	local doesNotExistProject = glunatestsetup:GetProjectByName("does-not-exist")

	lunatest.assert_true(testProjectReturned1:isa("glunatest/project"))
	lunatest.assert_true(testProjectReturned2:isa("glunatest/project"))
	lunatest.assert_nil(doesNotExistProject)

	lunatest.assert_equal(testProject1, testProjectReturned1)
	lunatest.assert_equal(testProject2, testProjectReturned2)

	lunatest.assert_not_equal(testProject1, testProject2)
	lunatest.assert_not_equal(testProjectReturned1, testProjectReturned2)

	lunatest.assert_not_equal(testProject1, testProjectReturned2)
	lunatest.assert_not_equal(testProject2, testProjectReturned1)
end

function suite.test_add_emulator()
	local glunatestsetup = GLunaTestLib:CreateGLunaTestSetupInstance()
	local testProject = glunatestsetup:AddProject("testproject")

	testProject:AddEmulatorHelper("glunatest/emulatorhelper/gmod.lua")

	local testProjectReturned = glunatestsetup:GetProjectByName("testproject")
	local emulatorHelpers = testProjectReturned:GetEmulatorHelpers()

	lunatest.assert_table(emulatorHelpers)
	lunatest.assert_path_equal("LUA:glunatest/emulatorhelper/gmod.lua", emulatorHelpers[1])
	lunatest.assert_path_equal("SELFLUA:emulatorhelper/gmod.lua", emulatorHelpers[1])
end

function suite.test_add_testsuite()
	local glunatestsetup = GLunaTestLib:CreateGLunaTestSetupInstance()
	local testProject = glunatestsetup:AddProject("testproject")

	testProject:AddTestSuite("glunatest/tests/test-gmod.lua")

	local testProjectReturned = glunatestsetup:GetProjectByName("testproject")
	local testSuites = testProjectReturned:GetTestSuites()

	lunatest.assert_table(testSuites)
	lunatest.assert_path_equal("LUA:glunatest/tests/test-gmod.lua", testSuites[1])
	lunatest.assert_path_equal("SELFLUA:tests/test-gmod.lua", testSuites[1])
end

function suite.test_load_config()
	local glunatestsetup = GLunaTestLib:CreateGLunaTestSetupInstance()

	local loadConfigCallback = lunatest.async(function(loaded, err)
		lunatest.assert_true(loaded, err)

		local project = glunatestsetup:GetProjectByName("glunatest")
		lunatest.assert_true(project:isa("glunatest/project"))

		local testSuites = project:GetTestSuites("glunatest")
		local emulatorHelpers = project:GetEmulatorHelpers()

		lunatest.assert_table(emulatorHelpers)
		lunatest.assert_gte(1, #emulatorHelpers)

		lunatest.assert_table(testSuites)
		lunatest.assert_gte(1, #testSuites)
	end)

	glunatestsetup:LoadConfig(loadConfigCallback)

	loadConfigCallback:SyncOptional(20)
end

return suite
