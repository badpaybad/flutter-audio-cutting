# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.24

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /home/dunp/.local/lib/python3.8/site-packages/cmake/data/bin/cmake

# The command to remove a file.
RM = /home/dunp/.local/lib/python3.8/site-packages/cmake/data/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /work/flutter-audio-cutting/lib/interop/simpleclang

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /work/flutter-audio-cutting/lib/interop/simpleclang

# Include any dependencies generated for this target.
include CMakeFiles/simpleso_library.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/simpleso_library.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/simpleso_library.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/simpleso_library.dir/flags.make

CMakeFiles/simpleso_library.dir/simpleso.c.o: CMakeFiles/simpleso_library.dir/flags.make
CMakeFiles/simpleso_library.dir/simpleso.c.o: simpleso.c
CMakeFiles/simpleso_library.dir/simpleso.c.o: CMakeFiles/simpleso_library.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/work/flutter-audio-cutting/lib/interop/simpleclang/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/simpleso_library.dir/simpleso.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/simpleso_library.dir/simpleso.c.o -MF CMakeFiles/simpleso_library.dir/simpleso.c.o.d -o CMakeFiles/simpleso_library.dir/simpleso.c.o -c /work/flutter-audio-cutting/lib/interop/simpleclang/simpleso.c

CMakeFiles/simpleso_library.dir/simpleso.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/simpleso_library.dir/simpleso.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /work/flutter-audio-cutting/lib/interop/simpleclang/simpleso.c > CMakeFiles/simpleso_library.dir/simpleso.c.i

CMakeFiles/simpleso_library.dir/simpleso.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/simpleso_library.dir/simpleso.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /work/flutter-audio-cutting/lib/interop/simpleclang/simpleso.c -o CMakeFiles/simpleso_library.dir/simpleso.c.s

# Object files for target simpleso_library
simpleso_library_OBJECTS = \
"CMakeFiles/simpleso_library.dir/simpleso.c.o"

# External object files for target simpleso_library
simpleso_library_EXTERNAL_OBJECTS =

libsimpleso.so.1.0.0: CMakeFiles/simpleso_library.dir/simpleso.c.o
libsimpleso.so.1.0.0: CMakeFiles/simpleso_library.dir/build.make
libsimpleso.so.1.0.0: simpleso.def
libsimpleso.so.1.0.0: CMakeFiles/simpleso_library.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/work/flutter-audio-cutting/lib/interop/simpleclang/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C shared library libsimpleso.so"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/simpleso_library.dir/link.txt --verbose=$(VERBOSE)
	$(CMAKE_COMMAND) -E cmake_symlink_library libsimpleso.so.1.0.0 libsimpleso.so.1 libsimpleso.so

libsimpleso.so.1: libsimpleso.so.1.0.0
	@$(CMAKE_COMMAND) -E touch_nocreate libsimpleso.so.1

libsimpleso.so: libsimpleso.so.1.0.0
	@$(CMAKE_COMMAND) -E touch_nocreate libsimpleso.so

# Rule to build all files generated by this target.
CMakeFiles/simpleso_library.dir/build: libsimpleso.so
.PHONY : CMakeFiles/simpleso_library.dir/build

CMakeFiles/simpleso_library.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/simpleso_library.dir/cmake_clean.cmake
.PHONY : CMakeFiles/simpleso_library.dir/clean

CMakeFiles/simpleso_library.dir/depend:
	cd /work/flutter-audio-cutting/lib/interop/simpleclang && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /work/flutter-audio-cutting/lib/interop/simpleclang /work/flutter-audio-cutting/lib/interop/simpleclang /work/flutter-audio-cutting/lib/interop/simpleclang /work/flutter-audio-cutting/lib/interop/simpleclang /work/flutter-audio-cutting/lib/interop/simpleclang/CMakeFiles/simpleso_library.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/simpleso_library.dir/depend

