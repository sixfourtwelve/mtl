cmake_minimum_required(VERSION 4.0)

project(mtl VERSION 1.0 LANGUAGES OBJC C OBJCXX CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(glm CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(Stb REQUIRED)
find_package(ObjFW 1.5 REQUIRED)
find_package(SDL3 REQUIRED)
find_path(MINIAUDIO_INCLUDE_DIRS "miniaudio.h")
find_program(SHADERCROSS_EXECUTABLE NAMES shadercross REQUIRED)

file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.mm")

set(SHADER_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/assets/shaders")
set(SHADER_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/assets/shaders")

file(GLOB_RECURSE SHADER_SOURCES
  CONFIGURE_DEPENDS
  "${SHADER_SOURCE_DIR}/*.hlsl"
)
file(GLOB_RECURSE SHADER_INCLUDES
  CONFIGURE_DEPENDS
  "${SHADER_SOURCE_DIR}/*.hlsli"
)

set(SHADER_OUTPUTS)
foreach(SHADER_SOURCE IN LISTS SHADER_SOURCES)
  file(RELATIVE_PATH SHADER_RELATIVE_PATH "${SHADER_SOURCE_DIR}" "${SHADER_SOURCE}")

  if(SHADER_RELATIVE_PATH MATCHES "\\.vert\\.hlsl$")
    set(SHADER_STAGE vertex)
  elseif(SHADER_RELATIVE_PATH MATCHES "\\.frag\\.hlsl$")
    set(SHADER_STAGE fragment)
  elseif(SHADER_RELATIVE_PATH MATCHES "\\.comp\\.hlsl$")
    set(SHADER_STAGE compute)
  else()
    message(FATAL_ERROR
      "Shader '${SHADER_RELATIVE_PATH}' must end in .vert.hlsl, .frag.hlsl, or .comp.hlsl"
    )
  endif()

  string(REGEX REPLACE "\\.hlsl$" "" SHADER_RELATIVE_STEM "${SHADER_RELATIVE_PATH}")
  set(SHADER_OUTPUT_BASE "${SHADER_OUTPUT_DIR}/${SHADER_RELATIVE_STEM}")
  get_filename_component(SHADER_OUTPUT_SUBDIR "${SHADER_OUTPUT_BASE}" DIRECTORY)

  set(SHADER_SPIRV "${SHADER_OUTPUT_BASE}.spv")
  set(SHADER_MSL "${SHADER_OUTPUT_BASE}.msl")
  set(SHADER_DXIL "${SHADER_OUTPUT_BASE}.dxil")

  add_custom_command(
    OUTPUT
      "${SHADER_SPIRV}"
      "${SHADER_MSL}"
      "${SHADER_DXIL}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${SHADER_OUTPUT_SUBDIR}"
    COMMAND "${SHADERCROSS_EXECUTABLE}" "${SHADER_SOURCE}"
      --source HLSL --dest SPIRV --stage "${SHADER_STAGE}"
      --include "${SHADER_SOURCE_DIR}" --output "${SHADER_SPIRV}"
    COMMAND "${SHADERCROSS_EXECUTABLE}" "${SHADER_SOURCE}"
      --source HLSL --dest MSL --stage "${SHADER_STAGE}"
      --include "${SHADER_SOURCE_DIR}" --output "${SHADER_MSL}"
    COMMAND "${SHADERCROSS_EXECUTABLE}" "${SHADER_SOURCE}"
      --source HLSL --dest DXIL --stage "${SHADER_STAGE}"
      --include "${SHADER_SOURCE_DIR}" --output "${SHADER_DXIL}"
    DEPENDS "${SHADER_SOURCE}" ${SHADER_INCLUDES}
    COMMENT "Compiling shader ${SHADER_RELATIVE_PATH}"
    VERBATIM
  )

  list(APPEND SHADER_OUTPUTS
    "${SHADER_SPIRV}"
    "${SHADER_MSL}"
    "${SHADER_DXIL}"
  )
endforeach()

add_custom_target(shaders ALL DEPENDS ${SHADER_OUTPUTS})

add_executable(${PROJECT_NAME} ${SOURCES})
add_dependencies(${PROJECT_NAME} shaders)

target_link_libraries(${PROJECT_NAME} ObjFW::ObjFW ObjFW::ARC SDL3::SDL3 glm::glm imgui::imgui)
target_include_directories(${PROJECT_NAME} PRIVATE 
  "${Stb_INCLUDE_DIR}"
  ${MINIAUDIO_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)

execute_process(
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/assets
    ${CMAKE_CURRENT_BINARY_DIR}/assets
)

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
