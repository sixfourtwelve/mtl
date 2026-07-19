cmake_minimum_required(VERSION 4.0)

project(mtl VERSION 1.0 LANGUAGES OBJC C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(ObjFW 1.5 REQUIRED)
find_package(SDL3 REQUIRED)

file(GLOB_RECURSE SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.m")

add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(${PROJECT_NAME} ObjFW::ObjFW ObjFW::ARC SDL3::SDL3)

if(APPLE)
	execute_process(
		COMMAND sh ${ObjFW_CONFIG_EXECUTABLE} --framework-libs --ldflags
		OUTPUT_VARIABLE _objfw_framework_ldflags
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	string(REGEX MATCH "-F([^ ]+)" _ "${_objfw_framework_ldflags}")
	set(_objfw_framework_dir "${CMAKE_MATCH_1}")

	set_target_properties(${PROJECT_NAME} PROPERTIES
		BUILD_RPATH "${_objfw_framework_dir}")
	add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
		COMMAND install_name_tool -change
			"@executable_path/../Frameworks/ObjFW.framework/ObjFW"
			"@rpath/ObjFW.framework/ObjFW"
			$<TARGET_FILE:${PROJECT_NAME}>
		VERBATIM
	)
endif()
