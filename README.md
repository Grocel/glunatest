# GLunaTest
GLunaTest is tool for running automatic tests for [Garry's Mod][] Lua. It is based on [Lunatest][]. Not to be confused with [CFC GLuaTest][]!

I developed this project in 2019, but never released it, because I do not have the time to long term maintain and document this project.

It is quite far developed with the basics basically set.

> [!WARNING]
> I do not recommend using this in production environments.
> The code is quite hacky at places and might not be suitable for every user environment.


## Discontinued Development
> [!IMPORTANT]
> This project has been discontinued in favour to [CFC GLuaTest][].

This project is unlikly to get any updates or further development.
As an effect of this discontinuation I will not add more documentation.

It is meant to be an inspiration for other developers.


## Key features
- xUnit-Style testing environment with basic sandboxing.
- Support for client and server testing. Including networking.
  - Clientside tests are downloaded from the server on every test run. Test files are stored on the server. (No `AddCSLuaFile()`)
- Colorful and detailed result output for Windows, Linux and in-game console.
  - Formated multi line diff output.
  - Formated binary data diff output.
  - Formated table diff output.
  - Nested formating for outputs and errors.
  - Color coded output.
- Modular config support with config networking.
- Modular code architecture.
- Support for extensions, called emulator helpers.
- Support for testing tests. Nested testing.
- Support for networking, timers and callbacks during tests. Asynchronous testing with timeouts.
- Fully self-tested.


## Weaknesses
- Stubs/Mocks are not fully implemented and only support global functions.
- Hacky code to emulate an vanilla Lua environment for Lunatest.
- Performance and memory footprint might not be optimal.
- No continuous integration/deployment.

## Install
Install this as a Garry's Mod addon.


## Usage
This addon is an developer tool, thus it requites advanced Lua developer skills. It is not made for end users.

It works out of the box.

### Getting started
Enter `cl_glunatest_help` or `sv_glunatest_help` into the console ingame.

Enter `cl_glunatest` or `sv_glunatest` to run all tests. This addon ships with some tests as an example.


## Details

### ConCommands
```
sv_glunatest:
  Run configured GLunaTest testing suites.
  Usage:
    sv_glunatest [<Project name>]
    sv_glunatest {all|<Project name>} [-v]
    sv_glunatest {all|<Project name>} [-v] [-s <Suite name pattern>] [-t <Test name pattern>]
  
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

sv_glunatest_help:
  Shows the concommands list of GLunaTest.

sv_glunatest_print_colortest:
  Prints a GLunaTest color test table.

sv_glunatest_print_emulatorhelpers:
  Prints a list of configured emulator helpers that extends GLunaTest's testing environment.

sv_glunatest_print_projectsuites:
  Prints a list of configured project testing suites that GLunaTest can run.

sv_glunatest_reload:
  Reloads the lua code of GLunaTest.
```
> [!NOTE]
> Each of them have a `cl_*` counter part for the clientside.

### Config
This addon comes with a default config at: `data_static/glunatest/config`
If you want to override or change config parameters, you can copy the files to your data folder. The system will also load it from there.
These default configs are an example of how you could setup your testing. They run out of the box.

The files `config/config.txt`, `config/client/config.txt`, `config/server/config.txt` are loaded on start up or on `cl/sv_glunatest_reload`.
The files `config/setup.txt`, `config/client/setup.txt`, `config/server/setup.txt` are loaded on every test run (`cl/sv_glunatest`).

#### Filepaths
You may see paths such as `SELFLUA:tests/client/test-glunatest-client.lua`.
The `SELFLUA` is the base bath. The path after the `:` is relative to that. 

These base paths are supported:

| Base path | Description |
| --------- | ----------- |
| DATA | Default, same as vanilla. |
| LUA | Same as vanilla. |
| MOD | Same as vanilla. |
| ... | Most vanilla paths work. |
| SELF | Path of this addon. |
| SELFLUA | Lua path of this addon. `lua/glunatest` |
| SELFDATA | Data path of this addon. `data/glunatest` |
| CONFIG | Main config path. `data/glunatest/config` |
| CONFIG_STATIC | Main config static path. `data_static/glunatest/config` |
| CONFIG_SERVER | Serverside config path. `data/glunatest/config/server` |
| CONFIG_SERVER_STATIC | Serverside config static path. `data_static/glunatest/config/server` |
| CONFIG_CLIENT | Clientside config path. `data/glunatest/config/server` |
| CONFIG_CLIENT_STATIC | Clientside config static path. `data_static/glunatest/config/server` |
| CACHE | Path for cache data. `data/glunatest/Cache` |
| LOG | Path for logging. `data/glunatest/log` |
| ADDON[ "myaddon" ] | Path of addon `myaddon` |


### Test scripts
The location of test scripts can be configured in `setup.txt`.

In this addon they are located at `lua\glunatest\tests`.
If needed you can add addional files to run in `setup.txt`.


### Emulator Helper
Emulator helpers are plugins that are run on every test run. They custom add functions to the testing environment.


[Garry's Mod]: <http://garrysmod.com/>
[Lunatest]: <https://github.com/silentbicycle/lunatest>
[CFC GLuaTest]: <https://github.com/CFC-Servers/GLuaTest>
