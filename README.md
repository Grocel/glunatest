# GLunaTest

GLunaTest is tool for running automatic tests for [Garry's Mod][] Lua. It is based on [Lunatest][]. Not to be confused with [CFC GLuaTest][]!

I developed this project in 2019, but never released it, because I do not have the time to long term maintain and document this project.

It is quite far developed with the basics basically set.

I do not recommend using this in production environments.
The code is quite hacky at places and might not be suitable for every user environment.


## Discontinued Development

This project has been discontinued in favour to [CFC GLuaTest][].

This project is unlikly to get any updates or further development.
As an effect of this discontinuation I will not add more documentation.

It is meant to be an inspiration for other developers.


## Key features

- xUnit-Style testing environment with basic sandboxing.
- Support for client and server testing. Including networking.
- Client side testing will be freshly download test files on every test run. Test files are stored on the server.
- Colorful result output for Windows, Linux and in-game console.
- Modular config support.
- Support for extensions, called emulator helpers.
- Support for testing tests (nested testing).
- Support for Networking, timers and callbacks during tests. (Asynchronous testing)


## Install

Install this as a Garry's Mod addon.


## Usage

This addon is an developer tool, thus it requites advanced Lua developer skills. It is not made for end users.

It works out of the box.


### Getting started

To get started enter `cl_glunatest_help` or `sv_glunatest_help` into the console ingame.

Enter `cl_glunatest` or `sv_glunatest` to run all tests. This addon ships with some tests as an example.


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
NOTE: Each of them have `cl_*` counter parts.


### Config

This addon comes with a default config at: `data_static/glunatest/config`
If you want to override or change config parameters please copy the files to your data folder. The systems will also load it from there.
These default configs are an example of how you could setup your testing. They run out of the box.

The files `config/config.txt`, `config/client/config.txt`, `config/server/config.txt` are loaded on start up or on `cl/sv_glunatest_reload`.
The files `config/setup.txt`, `config/client/setup.txt`, `config/server/setup.txt` are loaded on every test run (`cl/sv_glunatest`).


### Test scripts

The location of test scripts can be configured in `setup.txt`.

In this addon they are located at `lua\glunatest\tests`.
If needed you can add addional files to run in `setup.txt`.


### Emulator Helper

Emulator helpers are plugins that are run on every test run. They custom add functions to the testing environment.


[Garry's Mod]: <http://garrysmod.com/>
[Lunatest]: <https://github.com/silentbicycle/lunatest>
[CFC GLuaTest]: <https://github.com/CFC-Servers/GLuaTest>
