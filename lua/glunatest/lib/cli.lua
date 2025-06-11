local libPrint = nil
local libColor = nil
local libConcommand = nil

local LIB = {}

function LIB:GetSetup()
	if not self.setup then
		self.setup = self.LIB:CreateGLunaTestSetupInstance()
	end

	return self.setup
end

function LIB:Load(lib)
	libPrint = lib.print
	libColor = lib.color
	libConcommand = lib.Concommand
end

function LIB:Ready(lib)
	local glunatest = self:GetSetup()
	local glunatestHelpText = [[
Run configured ##PROJECTNAME## testing suites.
Usage:
	##CMD## [<Project name>]
	##CMD## {all|<Project name>} [-v]
	##CMD## {all|<Project name>} [-v] [-s <Suite name pattern>] [-t <Test name pattern>]

Arguments:
	<Project name>:
		Only test the given project.
		If not set or set to "all", it will test all configured projects.
		It must be set as the first parameter.

	-v:
		Enables verbose output

	-t <Test name pattern>:
		Only run test suites whose names match the given pattern.

	-t <Test name pattern>:
		Only run test functions whose names match the given pattern.
]]

	libConcommand:Add("", function(ply, args, cmd, cmdlong)
		local colError = libColor:GetColor("error")

		libPrint:print("")
		libPrint:print("Loading config...")

		glunatest:LoadConfig(function(loaded, err)
			if not loaded then
				libPrint:printcf(colError, "Error loading config: %s", err)
				return
			end

			libPrint:print("Config loaded.")
			libPrint:print("Preparing download...")

			glunatest:PrepareDownload(function(loaded, err)
				if not loaded then
					libPrint:printcf(colError, "Error Preparing download: %s", err)
					return
				end

				libPrint:print("Download prepared.")
				libPrint:print("")

				local err = nil
				local status = xpcall(function()
					local projectName = tostring(args[1] or "")
					args[1] = nil

					if projectName == "" or projectName == "all" then
						local projects = glunatest:GetProjects()
						local tmp = {}

						for k, project in SortedPairs(projects) do
							glunatest:RunProjectTestSuites(project, args, nil, ply)
						end

						return
					end

					glunatest:RunProjectTestSuites(projectName, args, nil, ply)
				end, function(thiserr)
					err = tostring(thiserr or "")
					if err == "" then
						err = "Unknown error!"
					end
				end)

				if not status then
					libPrint:printcf(colError, "Error running test suites: %s", err)
					return
				end
			end)
		end)
	end, libConcommand.SHARED, glunatestHelpText)

	libConcommand:Add("print_projectsuites", function(ply, args, cmd, cmdlong)
		local colDefault = libColor:GetColor("default")
		local colInfo = libColor:GetColor("info")
		local colError = libColor:GetColor("error")

		libPrint:print("")
		libPrint:print("Loading config...")

		glunatest:LoadConfig(function(loaded, err)
			if not loaded then
				libPrint:printcf(colError, "Error loading config: %s", err)
				return
			end

			libPrint:print("Config loaded.")

			local projects = glunatest:GetProjects()

			libPrint:print("")
			libPrint:print("List of project test suites:")
			libPrint:print("")

			local empty = true

			for name, project in SortedPairs(projects) do
				libPrint:printcc(colDefault, "Project:\t", colInfo, name)

				libPrint:print("")
				libPrint:print("")

				empty = false

				local projectempty = true
				local testSuites = project:GetTestSuites()

				for i, testSuite in ipairs(testSuites) do
					libPrint:printf("\t%s", testSuite:GetRealString())
					projectempty = false
				end

				if projectempty then
					libPrint:print("\tNo test suites found for this project")
				end

				libPrint:print("")
				libPrint:print("")
			end

			if empty then
				libPrint:print("No test suites found")
				libPrint:print("")
				libPrint:print("")
			end
		end)
	end, libConcommand.SHARED, "Prints a list of configured project testing suites that ##PROJECTNAME## can run.")

	libConcommand:Add("print_emulatorhelpers", function(ply, args, cmd, cmdlong)
		local colDefault = libColor:GetColor("default")
		local colInfo = libColor:GetColor("info")
		local colError = libColor:GetColor("error")

		libPrint:print("")
		libPrint:print("Loading config...")

		glunatest:LoadConfig(function(loaded, err)
			if not loaded then
				libPrint:printcf(colError, "Error loading config: %s", err)
				return
			end

			libPrint:print("Config loaded.")

			local projects = glunatest:GetProjects()

			libPrint:print("")
			libPrint:print("List of emulator helpers:")
			libPrint:print("")

			empty = true

			for name, project in SortedPairs(projects) do
				libPrint:printcc(colDefault, "Project:\t", colInfo, name)

				libPrint:print("")
				libPrint:print("")

				empty = false

				local projectempty = true
				local emulatorHelpers = project:GetEmulatorHelpers()

				for i, emulatorHelper in ipairs(emulatorHelpers) do
					libPrint:printf("\t%s", emulatorHelper:GetRealString())
					projectempty = false
				end

				if projectempty then
					libPrint:print("\tNo emulator helpers found for this project")
				end

				libPrint:print("")
				libPrint:print("")
			end

			if empty then
				libPrint:print("No emulator helpers found")
				libPrint:print("")
				libPrint:print("")
			end
		end)
	end, libConcommand.SHARED, "Prints a list of configured emulator helpers that extends ##PROJECTNAME##'s testing environment.")

	libConcommand:Add("print_colortest", function(ply, args, cmd, cmdlong)
		libColor:PrintTest(args[1])
	end, libConcommand.SHARED, "Prints a ##PROJECTNAME## color test table.")

	libConcommand:Add("help", function(ply, args, cmd, cmdlong)
		libConcommand:PrintList()
	end, libConcommand.SHARED, "Shows the concommands list of ##PROJECTNAME##.")
end

return LIB
