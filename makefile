###########################################################################
#
#   makefile
#
#   Core makefile for building MAME and derivatives
#
###########################################################################



###########################################################################
#################   BEGIN USER-CONFIGURABLE OPTIONS   #####################
###########################################################################

# REGENIE = 1
# VERBOSE = 1
# NOWERROR = 1

# TARGET = mame
# SUBTARGET = tiny
# TOOLS = 1
# TESTS = 1
# BENCHMARKS = 1
# OSD = sdl

# USE_DISPATCH_GL = 0
# MODERN_WIN_API = 0
# USE_XAUDIO2 = 0
# DIRECTINPUT = 7
# USE_SDL = 1
# SDL_INI_PATH = .;$HOME/.mame/;ini;
# SDL2_MULTIAPI = 1
# NO_USE_MIDI = 1
# DONT_USE_NETWORK = 1
# USE_QTDEBUG = 1
# NO_X11 = 1
# NO_USE_XINPUT = 0
# FORCE_DRC_C_BACKEND = 1

# DEBUG = 1
# PROFILER = 1
# SANITIZE = 1

# PTR64 = 1
# BIGENDIAN = 1
# NOASM = 1

# OPTIMIZE = 3
# SYMBOLS = 1
# SYMLEVEL = 2
# MAP = 1
# PROFILE = 1
# ARCHOPTS =
# OPT_FLAGS =
# LDOPTS =

# USE_SYSTEM_LIB_EXPAT = 1
# USE_SYSTEM_LIB_ZLIB = 1
# USE_SYSTEM_LIB_JPEG = 1
# USE_SYSTEM_LIB_FLAC = 1
# USE_SYSTEM_LIB_LUA = 1
# USE_SYSTEM_LIB_SQLITE3 = 1
# USE_SYSTEM_LIB_PORTMIDI = 1
# USE_SYSTEM_LIB_PORTAUDIO = 1

# MESA_INSTALL_ROOT = /opt/mesa
# SDL_INSTALL_ROOT = /opt/sdl2
# SDL_FRAMEWORK_PATH = $(HOME)/Library/Frameworks
# USE_LIBSDL = 1
# CYGWIN_BUILD = 1

# BUILDDIR = build
# TARGETOS = windows
# CROSS_BUILD = 1
# TOOLCHAIN =
# OVERRIDE_CC = cc
# OVERRIDE_CXX = c++
# OVERRIDE_LD = ld

# DEPRECATED = 1
# LTO = 1
# SSE2 = 1
# OPENMP = 1
# FASTDEBUG = 1

# SEPARATE_BIN = 1
# PYTHON_EXECUTABLE = python3
# SHADOW_CHECK = 1
# STRIP_SYMBOLS = 0

# QT_HOME = /usr/lib64/qt48/

# SOURCES = src/mame/drivers/asteroid.cpp,src/mame/audio/llander.cpp

# FORCE_VERSION_COMPILE = 1

# MS BUILD = 1

ifdef PREFIX_MAKEFILE
include $(PREFIX_MAKEFILE)
else
-include useroptions.mak
endif

###########################################################################
##################   END USER-CONFIGURABLE OPTIONS   ######################
###########################################################################

MAKEPARAMS := -R

#
# Determine running OS
#

ifeq ($(OS),Windows_NT)
OS := windows
GENIEOS := windows
PLATFORM := x86
else
UNAME := $(shell uname -mps)
UNAME_M := $(shell uname -m)
UNAME_P := $(shell uname -p)
GENIEOS := linux
PLATFORM := unknown
ifneq ($(filter x86_64,$(UNAME_P)),)
PLATFORM := x86
endif 
ifneq ($(filter %86,$(UNAME_P)),)
PLATFORM := x86
endif 
ifneq ($(filter arm%,$(UNAME_M)),)
PLATFORM := arm
endif 
ifneq ($(filter arm%,$(UNAME_P)),)
PLATFORM := arm
endif 
ifneq ($(filter powerpc,$(UNAME_P)),)
PLATFORM := powerpc
endif 
ifeq ($(firstword $(filter Linux,$(UNAME))),Linux)
OS := linux
endif
ifeq ($(firstword $(filter Solaris,$(UNAME))),Solaris)
OS := solaris
GENIEOS := solaris
endif
ifeq ($(firstword $(filter SunOS,$(UNAME))),SunOS)
OS := solaris
GENIEOS := solaris
endif
ifeq ($(firstword $(filter FreeBSD,$(UNAME))),FreeBSD)
OS := freebsd
GENIEOS := bsd
endif
ifeq ($(firstword $(filter GNU/kFreeBSD,$(UNAME))),GNU/kFreeBSD)
OS := freebsd
GENIEOS := bsd
endif
ifeq ($(firstword $(filter NetBSD,$(UNAME))),NetBSD)
OS := netbsd
GENIEOS := bsd
endif
ifeq ($(firstword $(filter OpenBSD,$(UNAME))),OpenBSD)
OS := openbsd
GENIEOS := bsd
endif
ifeq ($(firstword $(filter Darwin,$(UNAME))),Darwin)
OS := macosx
GENIEOS := darwin
endif
ifeq ($(firstword $(filter Haiku,$(UNAME))),Haiku)
OS := haiku
endif
ifeq ($(firstword $(filter OS/2,$(UNAME))),OS/2)
OS := os2
GENIEOS := os2
endif
ifndef OS
$(error Unable to detect OS from uname -a: $(UNAME))
endif
endif

#-------------------------------------------------
# specify core target: mame, ldplayer
# specify subtarget: mame, arcade, mess, tiny, etc.
# build scripts will be run from
# scripts/target/$(TARGET)/$(SUBTARGET).lua
#-------------------------------------------------

ifndef TARGET
TARGET := mame
endif

ifndef SUBTARGET
SUBTARGET := $(TARGET)
endif

CONFIG = release
ifdef DEBUG
CONFIG := debug
endif

ifdef VERBOSE
MAKEPARAMS += verbose=1
else
SILENT := @
MAKEPARAMS += --no-print-directory
endif

ifndef BUILDDIR
BUILDDIR := build
endif

#-------------------------------------------------
# specify OS target, which further differentiates
# the underlying OS; supported values are:
# win32, unix, macosx, os2
#-------------------------------------------------

ifndef TARGETOS

ifeq ($(OS),windows)
TARGETOS := windows
ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
ARCHITECTURE := _x64
endif
ifeq ($(PROCESSOR_ARCHITECTURE),x86)
ARCHITECTURE := _x64
ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
else
ARCHITECTURE := _x86
endif
endif
else
UNAME    := $(shell uname -mps)
TARGETOS := $(OS)

ARCHITECTURE := _x86

ifeq ($(firstword $(filter x86_64,$(UNAME))),x86_64)
ARCHITECTURE := _x64
endif
ifeq ($(firstword $(filter amd64,$(UNAME))),amd64)
ARCHITECTURE := _x64
endif
ifeq ($(firstword $(filter ppc64,$(UNAME))),ppc64)
ARCHITECTURE := _x64
endif
endif

else
CROSS_BUILD := 1
endif # TARGET_OS

ifdef PTR64
ifeq ($(PTR64),1)
ARCHITECTURE := _x64
else
ARCHITECTURE := _x86
endif
endif

ifeq ($(OS),windows)
ifeq ($(ARCHITECTURE),_x64)
WINDRES  := $(MINGW64)/bin/windres
else
WINDRES  := $(MINGW32)/bin/windres
endif
else
ifeq ($(ARCHITECTURE),_x64)
WINDRES  := $(word 1,$(TOOLCHAIN) x86_64-w64-mingw32-)windres
else
WINDRES  := $(word 1,$(TOOLCHAIN) i686-w64-mingw32-)windres
endif
endif

ifeq ($(findstring arm,$(UNAME)),arm)
ARCHITECTURE :=
ifndef NOASM
	NOASM := 1
endif
endif

# Emscripten
ifeq ($(findstring emcc,$(CC)),emcc)
TARGETOS := asmjs
ARCHITECTURE :=
ifndef NOASM
	NOASM := 1
endif
endif

# Autodetect BIGENDIAN
# MacOSX
ifndef BIGENDIAN
ifneq (,$(findstring Power,$(UNAME)))
BIGENDIAN := 1
endif
# Linux
ifneq (,$(findstring ppc,$(UNAME)))
BIGENDIAN := 1
endif
endif # BIGENDIAN

ifndef PYTHON_EXECUTABLE
PYTHON := python
else
PYTHON := $(PYTHON_EXECUTABLE)
endif
CC := $(SILENT)gcc
LD := $(SILENT)g++
CXX:= $(SILENT)g++

#-------------------------------------------------
# specify OSD layer: windows, sdl, etc.
# build scripts will be run from
# scripts/src/osd/$(OSD).lua
#-------------------------------------------------

ifndef OSD

OSD := osdmini

ifeq ($(TARGETOS),windows)
OSD := windows
endif

ifeq ($(TARGETOS),linux)
OSD := sdl
endif

ifeq ($(TARGETOS),freebsd)
OSD := sdl
endif

ifeq ($(TARGETOS),netbsd)
OSD := sdl
endif

ifeq ($(TARGETOS),solaris)
OSD := sdl
endif

ifeq ($(TARGETOS),macosx)
OSD := sdl
endif

ifeq ($(TARGETOS),os2)
OSD := sdl
endif

ifeq ($(TARGETOS),asmjs)
OSD := sdl
endif
endif

#-------------------------------------------------
# which 3rdparty library to build;
#  link against system (common) library otherwise
#-------------------------------------------------
ifndef USE_SYSTEM_LIB_EXPAT
PARAMS += --with-bundled-expat
endif

ifndef USE_SYSTEM_LIB_ZLIB
PARAMS += --with-bundled-zlib
endif

ifndef USE_SYSTEM_LIB_JPEG
PARAMS += --with-bundled-jpeg
endif

ifndef USE_SYSTEM_LIB_FLAC
PARAMS += --with-bundled-flac
endif

ifndef USE_SYSTEM_LIB_LUA
PARAMS += --with-bundled-lua
endif

ifndef USE_SYSTEM_LIB_SQLITE3
PARAMS += --with-bundled-sqlite3
endif

ifndef USE_SYSTEM_LIB_PORTMIDI
PARAMS += --with-bundled-portmidi
endif

ifndef USE_SYSTEM_LIB_PORTAUDIO
PARAMS += --with-bundled-portaudio
endif

#-------------------------------------------------
# distribution may change things
#-------------------------------------------------

ifeq ($(DISTRO),)
DISTRO := generic
else
ifeq ($(DISTRO),debian-stable)
else
$(error DISTRO $(DISTRO) unknown)
endif
endif

PARAMS+= --distro=$(DISTRO)

ifdef TOOLCHAIN
PARAMS += --TOOLCHAIN='$(TOOLCHAIN)'
endif
ifdef OVERRIDE_CC
PARAMS += --CC='$(OVERRIDE_CC)'
ifndef CROSS_BUILD
CC := $(OVERRIDE_CC)
endif
endif
ifdef OVERRIDE_CXX
PARAMS += --CXX='$(OVERRIDE_CXX)'
ifndef CROSS_BUILD
CXX := $(OVERRIDE_CXX)
endif
endif
ifdef OVERRIDE_LD
PARAMS += --LD='$(OVERRIDE_LD)'
ifndef CROSS_BUILD
LD := $(OVERRIDE_LD)
endif
endif

#-------------------------------------------------
# sanity check the configuration
#-------------------------------------------------

# enable symbols as it is useless without them
ifdef SANITIZE
SYMBOLS = 1
endif

# profiler defaults to on for DEBUG builds
ifdef DEBUG
ifndef PROFILER
PROFILER = 1
endif
endif

# allow gprof profiling as well, which overrides the internal PROFILER
# also enable symbols as it is useless without them
ifdef PROFILE
PROFILER =
SYMBOLS = 1
ifndef SYMLEVEL
SYMLEVEL = 1
endif
endif

# specify a default optimization level if none explicitly stated
ifndef OPTIMIZE
OPTIMIZE = 3
endif

# set the symbols level
ifdef SYMBOLS
ifndef SYMLEVEL
SYMLEVEL = 1
ifdef SOURCES
SYMLEVEL = 2
endif
endif
endif

ifdef TOOLS
PARAMS += --with-tools
endif

ifdef TESTS
PARAMS += --with-tests
endif

ifdef BENCHMARKS
PARAMS += --with-benchmarks
endif

ifdef SYMBOLS
PARAMS += --SYMBOLS='$(SYMBOLS)'
endif

ifdef SYMLEVEL
PARAMS += --SYMLEVEL='$(SYMLEVEL)'
endif

ifdef PROFILER
PARAMS += --PROFILER='$(PROFILER)'
endif

ifdef PROFILE
PARAMS += --PROFILE='$(PROFILE)'
endif

ifdef OPTIMIZE
PARAMS += --OPTIMIZE=$(OPTIMIZE)
endif

ifdef SHLIB
PARAMS += --SHLIB=$(SHLIB)
endif

ifdef ARCHOPTS
PARAMS += --ARCHOPTS='$(ARCHOPTS)'
endif

ifdef OPT_FLAGS
PARAMS += --OPT_FLAGS='$(OPT_FLAGS)'
endif

ifdef MAP
PARAMS += --MAP='$(MAP)'
endif

ifdef USE_BGFX
PARAMS += --USE_BGFX='$(USE_BGFX)'
endif

ifdef NOASM
PARAMS += --NOASM='$(NOASM)'
endif

ifdef BIGENDIAN
PARAMS += --BIGENDIAN='$(BIGENDIAN)'
endif

ifdef FORCE_DRC_C_BACKEND
PARAMS += --FORCE_DRC_C_BACKEND='$(FORCE_DRC_C_BACKEND)'
endif

ifdef NOWERROR
PARAMS += --NOWERROR='$(NOWERROR)'
endif

ifdef TARGET
PARAMS += --target='$(TARGET)'
endif

ifdef SUBTARGET
PARAMS += --subtarget='$(SUBTARGET)'
endif

ifdef OSD
PARAMS += --osd='$(OSD)'
endif

ifdef BUILDDIR
PARAMS += --build-dir='$(BUILDDIR)'
endif

ifdef TARGETOS
PARAMS += --targetos='$(TARGETOS)'
endif

ifdef DONT_USE_NETWORK
PARAMS += --DONT_USE_NETWORK='$(DONT_USE_NETWORK)'
endif

ifdef USE_DISPATCH_GL
PARAMS += --USE_DISPATCH_GL='$(USE_DISPATCH_GL)'
endif

ifdef NO_USE_MIDI
PARAMS += --NO_USE_MIDI='$(NO_USE_MIDI)'
endif

ifdef USE_QTDEBUG
PARAMS += --USE_QTDEBUG='$(USE_QTDEBUG)'
endif

ifdef MODERN_WIN_API
PARAMS += --MODERN_WIN_API='$(MODERN_WIN_API)'
endif

ifdef USE_XAUDIO2
PARAMS += --USE_XAUDIO2='$(USE_XAUDIO2)'
endif

ifdef DIRECTINPUT
PARAMS += --DIRECTINPUT='$(DIRECTINPUT)'
endif

ifdef USE_SDL
PARAMS += --USE_SDL='$(USE_SDL)'
endif

ifdef SDL_INI_PATH
PARAMS += --SDL_INI_PATH='$(SDL_INI_PATH)'
endif

ifdef CYGWIN_BUILD
PARAMS += --CYGWIN_BUILD='$(CYGWIN_BUILD)'
endif

ifdef MESA_INSTALL_ROOT
PARAMS += --MESA_INSTALL_ROOT='$(MESA_INSTALL_ROOT)'
endif

ifdef NO_X11
PARAMS += --NO_X11='$(NO_X11)'
endif

ifdef NO_USE_XINPUT
PARAMS += --NO_USE_XINPUT='$(NO_USE_XINPUT)'
endif

ifdef SDL_LIBVER
PARAMS += --SDL_LIBVER='$(SDL_LIBVER)'
endif

ifdef SDL2_MULTIAPI
PARAMS += --SDL2_MULTIAPI='$(SDL2_MULTIAPI)'
endif

ifdef SDL_INSTALL_ROOT
PARAMS += --SDL_INSTALL_ROOT='$(SDL_INSTALL_ROOT)'
endif

ifdef SDL_FRAMEWORK_PATH
PARAMS += --SDL_FRAMEWORK_PATH='$(SDL_FRAMEWORK_PATH)'
endif

ifdef USE_LIBSDL
PARAMS += --USE_LIBSDL='$(USE_LIBSDL)'
endif

ifdef LDOPTS
PARAMS += --LDOPTS='$(LDOPTS)'
endif

ifdef LTO
PARAMS += --LTO='$(LTO)'
endif

ifdef DEPRECATED
PARAMS += --DEPRECATED='$(DEPRECATED)'
endif

ifdef SSE2
PARAMS += --SSE2='$(SSE2)'
endif

ifdef OPENMP
PARAMS += --OPENMP='$(OPENMP)'
endif

ifdef FASTDEBUG
PARAMS += --FASTDEBUG='$(FASTDEBUG)'
endif

ifdef SEPARATE_BIN
PARAMS += --SEPARATE_BIN='$(SEPARATE_BIN)'
endif

ifdef PYTHON_EXECUTABLE
PARAMS += --PYTHON_EXECUTABLE='$(PYTHON_EXECUTABLE)'
endif

ifdef SHADOW_CHECK
PARAMS += --SHADOW_CHECK='$(SHADOW_CHECK)'
endif

ifdef STRIP_SYMBOLS
PARAMS += --STRIP_SYMBOLS='$(STRIP_SYMBOLS)'
endif

ifdef QT_HOME
PARAMS += --QT_HOME='$(QT_HOME)'
endif

ifdef SOURCES
PARAMS += --SOURCES='$(SOURCES)'
endif

ifdef FORCE_VERSION_COMPILE
PARAMS += --FORCE_VERSION_COMPILE='$(FORCE_VERSION_COMPILE)'
endif

ifdef PLATFORM
PARAMS += --PLATFORM='$(PLATFORM)'
endif

#-------------------------------------------------
# All scripts
#-------------------------------------------------


SCRIPTS = scripts/genie.lua \
	scripts/src/lib.lua \
	scripts/src/emu.lua \
	scripts/src/machine.lua \
	scripts/src/main.lua \
	scripts/src/3rdparty.lua \
	scripts/src/cpu.lua \
	scripts/src/osd/modules.lua \
	$(wildcard scripts/src/osd/$(OSD)*.lua) \
	scripts/src/sound.lua \
	scripts/src/tools.lua \
	scripts/src/tests.lua \
	scripts/src/benchmarks.lua \
	scripts/src/video.lua \
	scripts/src/bus.lua \
	scripts/src/netlist.lua \
	scripts/toolchain.lua \
	scripts/src/osd/modules.lua \
	$(wildcard src/osd/$(OSD)/$(OSD).mak) \
	$(wildcard src/$(TARGET)/$(SUBTARGET).mak)

ifeq ($(SUBTARGET),mame)
SCRIPTS += scripts/target/$(TARGET)/arcade.lua
SCRIPTS += scripts/target/$(TARGET)/mess.lua
endif

ifndef SOURCES
SCRIPTS += scripts/target/$(TARGET)/$(SUBTARGET).lua
endif

ifdef REGENIE
SCRIPTS+= regenie
endif

#-------------------------------------------------
# Dependent stuff
#-------------------------------------------------

# extension for executables
EXE :=

ifeq ($(OS),windows)
EXE := .exe
endif
ifeq ($(OS),os2)
EXE := .exe
endif

SHELLTYPE := msdos
ifeq (,$(ComSpec)$(COMSPEC))
  SHELLTYPE := posix
endif
ifeq (/bin,$(findstring /bin,$(SHELL)))
  SHELLTYPE := posix
endif
ifeq (/bin,$(findstring /bin,$(MAKESHELL)))
  SHELLTYPE := posix
endif

ifeq (posix,$(SHELLTYPE))
  MKDIR = $(SILENT) mkdir -p "$(1)"
  COPY  = $(SILENT) cp -fR "$(1)" "$(2)"
else
  MKDIR = $(SILENT) mkdir "$(subst /,\\,$(1))" 2> nul || exit 0
  COPY  = $(SILENT) copy /Y "$(subst /,\\,$(1))" "$(subst /,\\,$(2))"
endif

GENDIR = $(BUILDDIR)/generated

# all sources are under the src/ directory
SRC = src

# all 3rd party sources are under the 3rdparty/ directory
3RDPARTY = 3rdparty
ifeq ($(SUBTARGET),mame)
PROJECT_NAME := $(SUBTARGET)
else ifeq ($(SUBTARGET),mess)
PROJECT_NAME := $(SUBTARGET)
else
PROJECT_NAME := $(TARGET)$(SUBTARGET)
endif


ifeq ($(OS),windows)
ifeq (posix,$(SHELLTYPE))
GCC_VERSION      := $(shell $(TOOLCHAIN)$(subst @,,$(CC)) -dumpversion 2> /dev/null)
CLANG_VERSION    := $(shell $(TOOLCHAIN)$(subst @,,$(CC)) --version 2> /dev/null| head -n 1 | grep clang | sed "s/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$$/\1/" | head -n 1)
PYTHON_AVAILABLE := $(shell $(PYTHON) --version > /dev/null 2>&1 && echo python)
else
GCC_VERSION      := $(shell $(TOOLCHAIN)$(subst @,,$(CC)) -dumpversion 2> NUL)
CLANG_VERSION    := $(shell $(TOOLCHAIN)$(subst @,,$(CC)) --version 2> NUL| head -n 1 | grep clang | sed "s/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$$/\1/" | head -n 1)
PYTHON_AVAILABLE := $(shell $(PYTHON) --version > NUL 2>&1 && echo python)
endif
ifdef MSBUILD
MSBUILD_PARAMS   := /v:minimal /m:$(NUMBER_OF_PROCESSORS)
ifeq ($(CONFIG),debug)
MSBUILD_PARAMS += /p:Configuration=Debug
else
MSBUILD_PARAMS += /p:Configuration=Release
endif
ifeq ($(ARCHITECTURE),_x64)
MSBUILD_PARAMS += /p:Platform=x64
else
MSBUILD_PARAMS += /p:Platform=win32
endif
endif
else
GCC_VERSION      := $(shell $(TOOLCHAIN)$(subst @,,$(CC)) -dumpversion 2> /dev/null)
ifneq ($(OS),solaris)
CLANG_VERSION    := $(shell $(TOOLCHAIN)$(subst @,,$(CC))  --version  2> /dev/null | head -n 1 | grep -e 'version [0-9]\.[0-9]\(\.[0-9]\)\?' -o | grep -e '[0-9]\.[0-9]\(\.[0-9]\)\?' -o | tail -n 1)
endif
PYTHON_AVAILABLE := $(shell $(PYTHON) --version > /dev/null 2>&1 && echo python)
endif
ifeq ($(CLANG_VERSION),)
$(info GCC $(GCC_VERSION) detected)
else
$(info Clang $(CLANG_VERSION) detected)
ifeq ($(ARCHITECTURE),_x64)
ARCHITECTURE := _x64_clang
else
ARCHITECTURE := _x86_clang
endif
endif
ifneq ($(PYTHON_AVAILABLE),python)
$(error Python is not available in path)
endif

GENIE := 3rdparty/genie/bin/$(GENIEOS)/genie$(EXE)

ifeq ($(TARGET),$(SUBTARGET))
SUBDIR := $(OSD)/$(TARGET)
else
SUBDIR := $(OSD)/$(TARGET)$(SUBTARGET)
endif
PROJECTDIR := $(BUILDDIR)/projects/$(SUBDIR)

.PHONY: all clean regenie generate
all: $(GENIE) $(TARGETOS)$(ARCHITECTURE)
regenie:

#-------------------------------------------------
# gmake-mingw64-gcc
#-------------------------------------------------

$(PROJECTDIR)/gmake-mingw64-gcc/Makefile: makefile $(SCRIPTS) $(GENIE)
ifndef MINGW64
	$(error MINGW64 is not set)
endif
	$(SILENT) $(GENIE) $(PARAMS) --gcc=mingw64-gcc --gcc_version=$(GCC_VERSION) gmake

.PHONY: windows_x64
windows_x64: generate $(PROJECTDIR)/gmake-mingw64-gcc/Makefile
ifndef MINGW64
	$(error MINGW64 is not set)
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw64-gcc config=$(CONFIG)64 WINDRES=$(WINDRES) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw64-gcc config=$(CONFIG)64 WINDRES=$(WINDRES) 

#-------------------------------------------------
# gmake-mingw32-gcc
#-------------------------------------------------

.PHONY: windows
windows: windows_x86

$(PROJECTDIR)/gmake-mingw32-gcc/Makefile: makefile $(SCRIPTS) $(GENIE)
ifndef MINGW32
	$(error MINGW32 is not set)
endif
	$(SILENT) $(GENIE) $(PARAMS) --gcc=mingw32-gcc --gcc_version=$(GCC_VERSION) gmake

.PHONY: windows_x86
windows_x86: generate $(PROJECTDIR)/gmake-mingw32-gcc/Makefile
ifndef MINGW32
	$(error MINGW32 is not set)
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw32-gcc config=$(CONFIG)32 WINDRES=$(WINDRES) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw32-gcc config=$(CONFIG)32 WINDRES=$(WINDRES)

#-------------------------------------------------
# gmake-mingw-clang
#-------------------------------------------------

$(PROJECTDIR)/gmake-mingw-clang/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=mingw-clang --gcc_version=$(CLANG_VERSION) gmake

.PHONY: windows_x64_clang
windows_x64_clang: generate $(PROJECTDIR)/gmake-mingw-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw-clang config=$(CONFIG)64 WINDRES=$(WINDRES) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw-clang config=$(CONFIG)64 WINDRES=$(WINDRES)

.PHONY: windows_x86_clang
windows_x86_clang: generate $(PROJECTDIR)/gmake-mingw-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw-clang config=$(CONFIG)32 WINDRES=$(WINDRES) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-mingw-clang config=$(CONFIG)32 WINDRES=$(WINDRES)

vs2013: generate
	$(SILENT) $(GENIE) $(PARAMS) vs2013
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2013/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2013_intel: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=intel-15 vs2013
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2013-intel/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2013_xp: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=vs2013-xp vs2013
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2013-xp/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2013_clang: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=vs2013-clang vs2013

vs2013_winrt: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=winstore81 vs2013

vs2015: generate
	$(SILENT) $(GENIE) $(PARAMS) vs2015
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2015/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2015_intel: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=intel-15 vs2015
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2015-intel/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2015_xp: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=vs2015-xp vs2015
ifdef MSBUILD
	$(SILENT) msbuild $(PROJECTDIR)/vs2015-xp/$(PROJECT_NAME).sln $(MSBUILD_PARAMS)
endif

vs2015_clang: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=vs2015-clang vs2015

vs2015_winrt: generate
	$(SILENT) $(GENIE) $(PARAMS) --vs=winstore81 vs2015

android-arm: generate
ifndef ANDROID_NDK_ARM
	$(error ANDROID_NDK_ARM is not set)
endif
ifndef ANDROID_NDK_ROOT
	$(error ANDROID_NDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=android-arm --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-android-arm config=$(CONFIG)

android-mips: generate
ifndef ANDROID_NDK_MIPS
	$(error ANDROID_NDK_MIPS is not set)
endif
ifndef ANDROID_NDK_ROOT
	$(error ANDROID_NDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=android-mips --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-android-mips config=$(CONFIG)

android-x86: generate
ifndef ANDROID_NDK_X86
	$(error ANDROID_NDK_X86 is not set)
endif
ifndef ANDROID_NDK_ROOT
	$(error ANDROID_NDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=android-x86 --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-android-x86 config=$(CONFIG)

asmjs: generate
ifndef EMSCRIPTEN
	$(error EMSCRIPTEN is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=asmjs --gcc_version=4.9 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-asmjs config=$(CONFIG)


nacl: nacl_x86

nacl_x64: generate
ifndef NACL_SDK_ROOT
	$(error NACL_SDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=nacl --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-nacl config=$(CONFIG)64

nacl_x86: generate
ifndef NACL_SDK_ROOT
	$(error NACL_SDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=nacl --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-nacl config=$(CONFIG)32

nacl-arm: generate
ifndef NACL_SDK_ROOT
	$(error NACL_SDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=nacl-arm --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-nacl-arm config=$(CONFIG)

pnacl: generate
ifndef NACL_SDK_ROOT
	$(error NACL_SDK_ROOT is not set)
endif
ifndef COMPILE
	$(SILENT) $(GENIE) $(PARAMS) --gcc=pnacl --gcc_version=4.8 gmake
endif
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-pnacl config=$(CONFIG)

#-------------------------------------------------
# gmake-linux
#-------------------------------------------------

$(PROJECTDIR)/gmake-linux/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=linux-gcc --gcc_version=$(GCC_VERSION) gmake

.PHONY: linux_x64
linux_x64: generate $(PROJECTDIR)/gmake-linux/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG)64

.PHONY: linux_x86
linux_x86: generate $(PROJECTDIR)/gmake-linux/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG)32

.PHONY: linux
linux: generate $(PROJECTDIR)/gmake-linux/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux config=$(CONFIG)

#-------------------------------------------------
# gmake-linux-clang
#-------------------------------------------------

$(PROJECTDIR)/gmake-linux-clang/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=linux-clang --gcc_version=$(CLANG_VERSION) gmake

.PHONY: linux_x64_clang
linux_x64_clang: generate $(PROJECTDIR)/gmake-linux-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux-clang config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux-clang config=$(CONFIG)64

.PHONY: linux_x86_clang
linux_x86_clang: generate $(PROJECTDIR)/gmake-linux-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux-clang config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-linux-clang config=$(CONFIG)32

#-------------------------------------------------
# gmake-osx
#-------------------------------------------------

$(PROJECTDIR)/gmake-osx/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=osx --gcc_version=$(GCC_VERSION) gmake

.PHONY: macosx_x64
macosx_x64: generate $(PROJECTDIR)/gmake-osx/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx config=$(CONFIG)64

.PHONY: macosx
macosx: macosx_x86

.PHONY: macosx_x86
macosx_x86: generate $(PROJECTDIR)/gmake-osx/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx config=$(CONFIG)32

#-------------------------------------------------
# gmake-osx-clang
#-------------------------------------------------

$(PROJECTDIR)/gmake-osx-clang/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=osx-clang --gcc_version=$(CLANG_VERSION) gmake

.PHONY: macosx_x64_clang
macosx_x64_clang: generate $(PROJECTDIR)/gmake-osx-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx-clang config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx-clang config=$(CONFIG)64

.PHONY: macosx_x86_clang
macosx_x86_clang: generate $(PROJECTDIR)/gmake-osx-clang/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx-clang config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-osx-clang config=$(CONFIG)32

xcode4: generate
	$(SILENT) $(GENIE) $(PARAMS) --targetos=macosx --xcode=osx xcode4

xcode4-ios: generate
	$(SILENT) $(GENIE) $(PARAMS) --targetos=macosx --xcode=ios xcode4

#-------------------------------------------------
# gmake-solaris
#-------------------------------------------------


$(PROJECTDIR)/gmake-solaris/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=solaris --gcc_version=$(GCC_VERSION) gmake

.PHONY: solaris_x64
solaris_x64: generate $(PROJECTDIR)/gmake-solaris/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-solaris config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-solaris config=$(CONFIG)64

.PHONY: solaris
solaris: solaris_x86

.PHONY: solaris_x86
solaris_x86: generate $(PROJECTDIR)/gmake-solaris/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-solaris config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-solaris config=$(CONFIG)32


#-------------------------------------------------
# gmake-freebsd
#-------------------------------------------------


$(PROJECTDIR)/gmake-freebsd/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=freebsd --gcc_version=$(GCC_VERSION) gmake

.PHONY: freebsd_x64
freebsd_x64: generate $(PROJECTDIR)/gmake-freebsd/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-freebsd config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-freebsd config=$(CONFIG)64

.PHONY: freebsd
freebsd: freebsd_x86

.PHONY: freebsd_x86
freebsd_x86: generate $(PROJECTDIR)/gmake-freebsd/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-freebsd config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-freebsd config=$(CONFIG)32


#-------------------------------------------------
# gmake-netbsd
#-------------------------------------------------


$(PROJECTDIR)/gmake-netbsd/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=netbsd --gcc_version=$(GCC_VERSION) gmake

.PHONY: netbsd_x64
netbsd_x64: generate $(PROJECTDIR)/gmake-netbsd/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-netbsd config=$(CONFIG)64 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-netbsd config=$(CONFIG)64

.PHONY: netbsd
netbsd: netbsd_x86

.PHONY: netbsd_x86
netbsd_x86: generate $(PROJECTDIR)/gmake-netbsd/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-netbsd config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-netbsd config=$(CONFIG)32


#-------------------------------------------------
# gmake-os2
#-------------------------------------------------


$(PROJECTDIR)/gmake-os2/Makefile: makefile $(SCRIPTS) $(GENIE)
	$(SILENT) $(GENIE) $(PARAMS) --gcc=os2 --gcc_version=$(GCC_VERSION) gmake

.PHONY: os2
os2: os2_x86

.PHONY: os2_x86
os2_x86: generate $(PROJECTDIR)/gmake-os2/Makefile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-os2 config=$(CONFIG)32 precompile
	$(SILENT) $(MAKE) -C $(PROJECTDIR)/gmake-os2 config=$(CONFIG)32


#-------------------------------------------------
# gmake-steamlink
#-------------------------------------------------

$(PROJECTDIR)/gmake-steamlink/Makefile: makefile $(SCRIPTS) $(GENIE)
ifndef MARVELL_SDK_PATH
	$(error MARVELL_SDK_PATH is not set)
endif
ifndef MARVELL_ROOTFS
	$(error MARVELL_ROOTFS is not set)
endif
	$(SILENT) $(GENIE) $(PARAMS) --gcc=steamlink --gcc_version=$(GCC_VERSION) --NO_OPENGL=1 --NO_USE_MIDI=1 --NO_X11=1 --NOASM=1 --SDL_INSTALL_ROOT=$(MARVELL_ROOTFS)/usr  gmake  

.PHONY: steamlink
ifndef MARVELL_SDK_PATH
	$(error MARVELL_SDK_PATH is not set)
endif
ifndef MARVELL_ROOTFS
	$(error MARVELL_ROOTFS is not set)
endif
steamlink: generate $(PROJECTDIR)/gmake-steamlink/Makefile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-steamlink config=$(CONFIG) precompile
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C $(PROJECTDIR)/gmake-steamlink config=$(CONFIG)



#-------------------------------------------------
# cmake
#-------------------------------------------------
cmake: generate
	$(SILENT) $(GENIE) $(PARAMS) cmake
ifeq ($(OS),windows)
	$(SILENT)echo cmake_minimum_required(VERSION 2.8.4) > CMakeLists.txt
	$(SILENT)echo add_subdirectory($(PROJECTDIR)/cmake) >> CMakeLists.txt
else
	$(SILENT)echo "cmake_minimum_required(VERSION 2.8.4)" > CMakeLists.txt
	$(SILENT)echo "add_subdirectory($(PROJECTDIR)/cmake)" >> CMakeLists.txt
endif


#-------------------------------------------------
# Clean/bootstrap
#-------------------------------------------------

GENIE_SRC=$(wildcard 3rdparty/genie/src/host/*.c)

$(GENIE): $(GENIE_SRC)
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C 3rdparty/genie/build/gmake.$(GENIEOS) -f genie.make

3rdparty/genie/src/hosts/%.c:

.PHONY: genieclean
genieclean:
	$(SILENT) $(MAKE) $(MAKEPARAMS) -C 3rdparty/genie/build/gmake.$(GENIEOS) -f genie.make clean

clean: genieclean
	@echo Cleaning...
	-@rm -rf $(BUILDDIR)
	$(SILENT) $(MAKE) -C $(SRC)/devices/cpu/m68000 clean

GEN_FOLDERS := $(GENDIR)/$(TARGET)/layout/ $(GENDIR)/$(TARGET)/$(SUBTARGET)/

LAYOUTS=$(wildcard $(SRC)/$(TARGET)/layout/*.lay)

ifneq (,$(wildcard src/osd/$(OSD)/$(OSD).mak))
include src/osd/$(OSD)/$(OSD).mak
endif

ifneq (,$(wildcard src/$(TARGET)/$(TARGET).mak))
include src/$(TARGET)/$(TARGET).mak
endif

$(GEN_FOLDERS):
	-$(call MKDIR,$@)

genie: $(GENIE)

generate: \
		genie \
		$(GEN_FOLDERS) \
		$(patsubst $(SRC)/%.lay,$(GENDIR)/%.lh,$(LAYOUTS)) \
		$(SRC)/devices/cpu/m68000/m68kops.cpp

$(GENDIR)/%.lh: $(SRC)/%.lay scripts/build/file2str.py | $(GEN_FOLDERS)
	@echo Converting $<...
	$(SILENT)$(PYTHON) scripts/build/file2str.py $< $@ layout_$(basename $(notdir $<))

$(SRC)/devices/cpu/m68000/m68kops.cpp: $(SRC)/devices/cpu/m68000/m68k_in.cpp $(SRC)/devices/cpu/m68000/m68kmake.cpp
ifeq ($(TARGETOS),asmjs)
	$(SILENT) $(MAKE) -C $(SRC)/devices/cpu/m68000
else
	$(SILENT) $(MAKE) -C $(SRC)/devices/cpu/m68000 CC="$(CC)" CXX="$(CXX)"
endif

#-------------------------------------------------
# Regression tests
#-------------------------------------------------

include regtests/regtests.mak

.PHONY: tests

tests: $(REGTESTS)

#-------------------------------------------------
# Source cleanup
#-------------------------------------------------

.PHONY: cleansrc

cleansrc:
	@echo Cleaning up tabs/spaces/end of lines....
ifeq ($(OS),windows)
	$(shell for /r src %%i in (*.c) do srcclean %%i >&2 )
	$(shell for /r src %%i in (*.h) do srcclean %%i >&2 )
	$(shell for /r src %%i in (*.mak) do srcclean %%i >&2 )
	$(shell for /r src %%i in (*.lst) do srcclean %%i >&2 )
	$(shell for /r src %%i in (*.lay) do srcclean %%i >&2 )
	$(shell for /r src %%i in (*.inc) do srcclean %%i >&2 )
	$(shell for /r hash %%i in (*.xml) do srcclean %%i >&2 )
else
	$(shell find src/ -name *.c -exec ./srcclean {} >&2 ;)
	$(shell find src/ -name *.h -exec ./srcclean {}  >&2 ;)
	$(shell find src/ -name *.mak -exec ./srcclean {} >&2 ;)
	$(shell find src/ -name *.lst -exec ./srcclean {} >&2 ;)
	$(shell find src/ -name *.lay -exec ./srcclean {} >&2 ;)
	$(shell find src/ -name *.inc -exec ./srcclean {} >&2 ;)
	$(shell find hash/ -name *.xml -exec ./srcclean {} >&2 ;)
endif

#-------------------------------------------------
# Doxygen documentation
#-------------------------------------------------

.PHONY: doxygen

doxygen:
	@echo Generate Doxygen documentation
	doxygen doxygen/doxygen.config

#-------------------------------------------------
# CppCheck analysis
#-------------------------------------------------

.PHONY: cppcheck

CPPCHECK_PARAMS  = -Isrc/osd
CPPCHECK_PARAMS += -Isrc/emu
CPPCHECK_PARAMS += -Isrc/lib
CPPCHECK_PARAMS += -Isrc/lib/util
CPPCHECK_PARAMS += -Isrc/mame
CPPCHECK_PARAMS += -Isrc/osd/modules/render
CPPCHECK_PARAMS += -Isrc/osd/windows
CPPCHECK_PARAMS += -Isrc/emu/cpu/m68000
CPPCHECK_PARAMS += -I3rdparty
ifndef USE_SYSTEM_LIB_LUA
CPPCHECK_PARAMS += -I3rdparty/lua/src
endif
ifndef USE_SYSTEM_LIB_ZLIB
CPPCHECK_PARAMS += -I3rdparty/zlib
endif
CPPCHECK_PARAMS += -I3rdparty/bgfx/include
CPPCHECK_PARAMS += -I3rdparty/bx/include
CPPCHECK_PARAMS += -I$(BUILDDIR)/generated/emu
CPPCHECK_PARAMS += -I$(BUILDDIR)/generated/emu/layout
CPPCHECK_PARAMS += -I$(BUILDDIR)/generated/mame/layout
CPPCHECK_PARAMS += -DX64_WINDOWS_ABI
CPPCHECK_PARAMS += -DPTR64=1
CPPCHECK_PARAMS += -DMAME_DEBUG
CPPCHECK_PARAMS += -DMAME_PROFILER
CPPCHECK_PARAMS += -DCRLF=3
CPPCHECK_PARAMS += -DLSB_FIRST
ifndef USE_SYSTEM_LIB_FLAC
CPPCHECK_PARAMS += -DFLAC__NO_DLL
endif
CPPCHECK_PARAMS += -DNATIVE_DRC=drcbe_x64
CPPCHECK_PARAMS += -DLUA_COMPAT_APIINTCASTS
CPPCHECK_PARAMS += -DWIN32
CPPCHECK_PARAMS += -D__GNUC__
CPPCHECK_PARAMS += -D__x86_64__
ifndef VERBOSE
CPPCHECK_PARAMS += --quiet
endif

cppcheck:
	@echo Generate CppCheck analysis report
	cppcheck --enable=all src/ $(CPPCHECK_PARAMS) -j9

.PHONY: shaders

shaders:
	$(SILENT) $(MAKE) -C $(SRC)/osd/modules/render/bgfx rebuild
	
.PHONY: translation

translation:
	$(SILENT) echo Generating mame.pot
	$(SILENT) find src -iname "*.cpp" | xargs xgettext --from-code=UTF-8 -k_ -o mame.pot
	$(SILENT) msgmerge -U "language/Afrikaans/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Albanian/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/Arabic/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Basque/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Belarusian/strings.po"                    mame.pot
	$(SILENT) msgmerge -U "language/Bosnian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Bulgarian/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Burmese/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Catalan/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Chinese (Simple)/strings.po"              mame.pot
	$(SILENT) msgmerge -U "language/Chinese (Traditional)/strings.po"         mame.pot
	$(SILENT) msgmerge -U "language/Croatian/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/Czech/strings.po"                         mame.pot
	$(SILENT) msgmerge -U "language/Danish/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Dutch/strings.po"                         mame.pot
	$(SILENT) msgmerge -U "language/English/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Estonian/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/Finnish/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/French/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/French (Canada)/strings.po"               mame.pot
	$(SILENT) msgmerge -U "language/Georgian/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/German/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Greek/strings.po"                         mame.pot
	$(SILENT) msgmerge -U "language/Hebrew/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Hindi/strings.po"                         mame.pot
	$(SILENT) msgmerge -U "language/Hungarian/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Indonesian/strings.po"                    mame.pot
	$(SILENT) msgmerge -U "language/Italian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Japanese/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/Korean/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Latvian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Lithuanian/strings.po"                    mame.pot
	$(SILENT) msgmerge -U "language/Macedonian/strings.po"                    mame.pot
	$(SILENT) msgmerge -U "language/Norwegian/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Persian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Polish/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Portuguese/strings.po"                    mame.pot
	$(SILENT) msgmerge -U "language/Portuguese (Brazil)/strings.po"           mame.pot
	$(SILENT) msgmerge -U "language/Romanian/strings.po"                      mame.pot
	$(SILENT) msgmerge -U "language/Russian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Serbian/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Serbian (Cyrillic)/strings.po"            mame.pot
	$(SILENT) msgmerge -U "language/Slovak/strings.po"                        mame.pot
	$(SILENT) msgmerge -U "language/Slovenian/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Spanish/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Spanish (Mexico)/strings.po"              mame.pot
	$(SILENT) msgmerge -U "language/Swedish/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Thai/strings.po"                          mame.pot
	$(SILENT) msgmerge -U "language/Turkish/strings.po"                       mame.pot
	$(SILENT) msgmerge -U "language/Ukrainian/strings.po"                     mame.pot
	$(SILENT) msgmerge -U "language/Vietnamese/strings.po"                    mame.pot
	$(SILENT) msgfmt --check --output-file "language/Afrikaans/strings.mo"             "language/Afrikaans/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Albanian/strings.mo"              "language/Albanian/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/Arabic/strings.mo"                "language/Arabic/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Basque/strings.mo"                "language/Basque/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Belarusian/strings.mo"            "language/Belarusian/strings.po"            
	$(SILENT) msgfmt --check --output-file "language/Bosnian/strings.mo"               "language/Bosnian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Bulgarian/strings.mo"             "language/Bulgarian/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Burmese/strings.mo"               "language/Burmese/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Catalan/strings.mo"               "language/Catalan/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Chinese (Simple)/strings.mo"      "language/Chinese (Simple)/strings.po"      
	$(SILENT) msgfmt --check --output-file "language/Chinese (Traditional)/strings.mo" "language/Chinese (Traditional)/strings.po" 
	$(SILENT) msgfmt --check --output-file "language/Croatian/strings.mo"              "language/Croatian/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/Czech/strings.mo"                 "language/Czech/strings.po"                 
	$(SILENT) msgfmt --check --output-file "language/Danish/strings.mo"                "language/Danish/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Dutch/strings.mo"                 "language/Dutch/strings.po"                 
	$(SILENT) msgfmt --check --output-file "language/English/strings.mo"               "language/English/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Estonian/strings.mo"              "language/Estonian/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/Finnish/strings.mo"               "language/Finnish/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/French/strings.mo"                "language/French/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/French (Canada)/strings.mo"       "language/French (Canada)/strings.po"       
	$(SILENT) msgfmt --check --output-file "language/Georgian/strings.mo"              "language/Georgian/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/German/strings.mo"                "language/German/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Greek/strings.mo"                 "language/Greek/strings.po"                 
	$(SILENT) msgfmt --check --output-file "language/Hebrew/strings.mo"                "language/Hebrew/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Hindi/strings.mo"                 "language/Hindi/strings.po"                 
	$(SILENT) msgfmt --check --output-file "language/Hungarian/strings.mo"             "language/Hungarian/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Indonesian/strings.mo"            "language/Indonesian/strings.po"            
	$(SILENT) msgfmt --check --output-file "language/Italian/strings.mo"               "language/Italian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Japanese/strings.mo"              "language/Japanese/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/Korean/strings.mo"                "language/Korean/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Latvian/strings.mo"               "language/Latvian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Lithuanian/strings.mo"            "language/Lithuanian/strings.po"            
	$(SILENT) msgfmt --check --output-file "language/Macedonian/strings.mo"            "language/Macedonian/strings.po"            
	$(SILENT) msgfmt --check --output-file "language/Norwegian/strings.mo"             "language/Norwegian/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Persian/strings.mo"               "language/Persian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Polish/strings.mo"                "language/Polish/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Portuguese/strings.mo"            "language/Portuguese/strings.po"            
	$(SILENT) msgfmt --check --output-file "language/Portuguese (Brazil)/strings.mo"   "language/Portuguese (Brazil)/strings.po"   
	$(SILENT) msgfmt --check --output-file "language/Romanian/strings.mo"              "language/Romanian/strings.po"              
	$(SILENT) msgfmt --check --output-file "language/Russian/strings.mo"               "language/Russian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Serbian/strings.mo"               "language/Serbian/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Serbian (Cyrillic)/strings.mo"    "language/Serbian (Cyrillic)/strings.po"    
	$(SILENT) msgfmt --check --output-file "language/Slovak/strings.mo"                "language/Slovak/strings.po"                
	$(SILENT) msgfmt --check --output-file "language/Slovenian/strings.mo"             "language/Slovenian/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Spanish/strings.mo"               "language/Spanish/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Spanish (Mexico)/strings.mo"      "language/Spanish (Mexico)/strings.po"      
	$(SILENT) msgfmt --check --output-file "language/Swedish/strings.mo"               "language/Swedish/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Thai/strings.mo"                  "language/Thai/strings.po"                  
	$(SILENT) msgfmt --check --output-file "language/Turkish/strings.mo"               "language/Turkish/strings.po"               
	$(SILENT) msgfmt --check --output-file "language/Ukrainian/strings.mo"             "language/Ukrainian/strings.po"             
	$(SILENT) msgfmt --check --output-file "language/Vietnamese/strings.mo"            "language/Vietnamese/strings.po"            
	
