if(NOT PYTHON_DEFAULT_EXECUTABLE)
   message(WARNING "Python required for Julia bindings...disabling")
   ocv_module_disable(julia)
endif()

find_package(JlCxx QUIET)

if(NOT JlCxx_FOUND)
    message(STATUS "JlCxx not found")
    ocv_module_disable(julia)
    return()
else()
    message(STATUS "JlCxx_DIR: ${JlCxx_DIR}")
endif()

set(JlCxx_DIR "${JlCxx_DIR}" CACHE STRING ADVANCED)
set(HAVE_JULIA "YES" CACHE STRING ADVANCED)


set(the_description "The Julia bindings")
ocv_add_module(
    julia
    BINDINGS
    OPTIONAL
    opencv_core
    opencv_imgproc
    opencv_imgcodecs
    opencv_highgui
    opencv_videoio
    opencv_dnn
    opencv_features2d
    opencv_objdetect
    opencv_calib3d
)

set(HDR_PARSER_PATH ${CMAKE_SOURCE_DIR}/modules/python/src2/hdr_parser.py)

set(opencv_hdrs "")
foreach(m ${OPENCV_MODULES_BUILD})
  list(APPEND opencv_hdrs ${OPENCV_MODULE_${m}_HEADERS})
endforeach(m)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/gen/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/gen)
file(COPY ${HDR_PARSER_PATH} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/gen)

message(STATUS "Generating Julia Binding Files")

execute_process(
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/gen"
                COMMAND ${PYTHON_DEFAULT_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/gen/gen_all.py" ${CMAKE_SOURCE_DIR}/modules ${OPENCV_MODULES_BUILD}
                )

file(COPY ${CMAKE_CURRENT_BINARY_DIR}/gen/cpp_files/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/gen/autogen_cpp)
file(COPY ${CMAKE_CURRENT_BINARY_DIR}/gen/jl_cxx_files/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/gen/autogen_jl)

ocv_glob_module_sources()
ocv_module_include_directories()
ocv_warnings_disable(CMAKE_CXX_FLAGS -Wmissing-prototypes -Wmissing-declarations)

ocv_add_library(${the_module} SHARED ${OPENCV_MODULE_${the_module}_HEADERS}
                                     ${OPENCV_MODULE_${the_module}_SOURCES}
                                     "${CMAKE_CURRENT_BINARY_DIR}/gen/autogen_cpp/cv_core.cpp")

if(NOT JULIA_PKG_INSTALL_PATH)
    set(JULIA_PKG_INSTALL_PATH ${CMAKE_BINARY_DIR})
endif()
set(JULIA_PKG_INSTALL_PATH_HOOK ${JULIA_PKG_INSTALL_PATH} CACHE STRING "" FORCE)
mark_as_advanced(JULIA_PKG_INSTALL_PATH_HOOK)


message(STATUS "Installing ${the_module} bindings at ${JULIA_PKG_INSTALL_PATH}")


install(DIRECTORY package/ DESTINATION ${JULIA_PKG_INSTALL_PATH})
install(TARGETS ${the_module} LIBRARY DESTINATION ${JULIA_PKG_INSTALL_PATH}/OpenCV/src/lib)


# message(STATUS "Installing Julia bindings using ${JULIA_COMMAND}")



# ocv_create_module()

# ocv_add_accuracy_tests()
# ocv_add_perf_tests()
ocv_add_samples()

message(STATUS     ${OPENCV_MODULE_${the_module}_DEPS_TO_LINK})

ocv_target_link_libraries(${the_module} PUBLIC    ${OPENCV_MODULE_${the_module}_DEPS_TO_LINK}
                                        INTERFACE ${OPENCV_MODULE_${the_module}_DEPS_TO_LINK}
)
ocv_target_link_libraries(${the_module} PUBLIC    ${OPENCV_MODULE_${the_module}_DEPS_EXT}
                                        INTERFACE ${OPENCV_MODULE_${the_module}_DEPS_EXT}
)
ocv_target_link_libraries(${the_module} PRIVATE ${OPENCV_LINKER_LIBS} ${OPENCV_HAL_LINKER_LIBS} ${IPP_LIBS} ${ARGN})

ocv_target_link_libraries(${the_module} JlCxx::cxxwrap_julia)
ocv_target_link_libraries(${the_module} JlCxx::cxxwrap_julia_stl)

# targets# opencv_julia_sources --> opencv_julia


add_custom_command(TARGET ${the_module}
                   POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/package/OpenCV ${CMAKE_BINARY_DIR}/OpenCV
                   COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_BINARY_DIR}/gen/autogen_jl/ ${CMAKE_BINARY_DIR}/OpenCV/src
                   COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${the_module}> ${CMAKE_BINARY_DIR}/OpenCV/src/lib/libopencv_julia
                   COMMENT "Copying over julia package"
                   )



if (BUILD_TESTS)
    add_subdirectory(test)
endif()
