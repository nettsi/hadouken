#[=======================================================================[.rst:
    __hdk_make_target_name
    ------------------- 
    Visibility level: Private

    Create a name with respect to given arguments

    This function automatically deduces target name from current context 
    project's name. If user is explicitly specified a name, this function will
    use it instead. The function prepends the prefix and appends the suffix to 
    the name and sets `<output_variable_name>` as a result.

    .. code-block:: cmake
        hdk_make_target_name(<output_variable_name>
            NAME <name> `Explicitly specified name [optional]`
            PREFIX <prefix> `Prefix to prepend to the target name [optional]`
            SUFFIX <suffix> `Suffix to append to the target name [optional]`
        )

    Note: This function is private and intended to be used internally. Do not call this directly.
#]=======================================================================]
function(__hdk_make_target_name TARGET_NAME)
    hdk_log_set_context("hdk.mt")
    hdk_log_trace("hdk_make_target_name(): called with args : ${ARGV}")
    cmake_parse_arguments(ARGS "AUTO_SUFFIX" "" "PREFIX;NAME;SUFFIX;TYPE;" ${ARGN})
    # By default, use project's name as target name.
    set(PREFERRED_NAME ${PROJECT_NAME})
    # If user specified a name, use it.
    if(ARGS_NAME)
        hdk_log_trace("hdk_make_target_name(): function has NAME parameter")
        set(PREFERRED_NAME ${ARGS_NAME})
    endif()

    if(${ARGS_AUTO_SUFFIX})
        hdk_log_trace("hdk_make_target_name(): auto suffix for ${PREFERRED_NAME} ${ARGS_AUTO_SUFFIX}")
        if(NOT ARGS_TYPE)
            message(FATAL_ERROR "hdk_make_target_name(): AUTO_SUFFIX requries TYPE argument.")
        endif()
        string(TOLOWER "${ARGS_TYPE}" TYPE_TOLOWER)
        set(ARGS_SUFFIX ".${TYPE_TOLOWER}${ARGS_SUFFIX}")
    endif()
    # Create target name
    set(${TARGET_NAME} ${ARGS_PREFIX}${PREFERRED_NAME}${ARGS_SUFFIX} PARENT_SCOPE)
endfunction()


#[=======================================================================[.rst:
    __hdk_add_project_include_directory
    ------------------- 
    Visibility level: Private

    Add include directory to target's include directories.

    `include` directory is searched relative to current project's source directory. The directory
    will be added as PUBLIC unless target type is not INTERFACE type.

    .. code-block:: cmake
        hadouken_add_project_include_directory(
            TARGET_NAME <name> `Target's name to add current project's include directory`
            TYPE <prefix> `Type of the target`
        )

    Note: This function is private and intended to be used internally. Do not call this directly.
#]=======================================================================]
function(__hdk_add_project_include_directory)
    hdk_log_set_context("hdk.mt")
    hdk_log_trace("call hdk_add_project_include_directory() with args : ${ARGV}")
    cmake_parse_arguments(ARGS,  "" "TARGET_NAME;TYPE;" "" ${ARGN})

    if(NOT DEFINED TARGET_NAME)
        hdk_log_err("hdk_add_project_include_directory(): function requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        hdk_log_err("hdk_add_project_include_directory(): function requires TYPE parameter.")
    endif()

    if(${ARGS_TYPE} STREQUAL "INTERFACE")
        hdk_log_trace("hdk_add_project_include_directory(): type is INTERFACE")
        target_include_directories(${TARGET_NAME} INTERFACE ${PROJECT_SOURCE_DIR}/include/)
    else()
        hdk_log_trace("hdk_add_project_include_directory(): type is not INTERFACE")
        target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/include/)
    endif()
endfunction()


#[=======================================================================[.rst:
    __hdk_add_target_options
    -------------------
    Visibility level: Private

    Add user-specified options to designated target.

    .. code-block:: cmake
        hdk_add_target_options(
            TARGET_NAME <name> 
            TYPE <prefix> 
            PARTOF <target_name>
            DEPENDS <target_name,...> 
            LINK <target_name,...> 
            COMPILE_OPTIONS <compile_option,...> 
            COMPILE_DEFINITIONS <compile_definition,...> 
            INCLUDES <include_directory,...> 
            SOURCES <source_file_path,...> 
            HEADERS <header_file_path,...> 
            SYMBOL_VISIBILITY <default|hidden|protected>
        )

    Arguments:
        TARGET_NAME         <name>                  `Designated target to add options to`
        TYPE                <target_type>           `Type of the designated target`
        PARTOF              <target_name>           `Make specified target dependent to this target [optional]`
        DEPENDS             <target_name,...>       `Make this target dependent to specified target list [optional]`
        LINK                <target_name,...>       `Link to specified targets or libraries. Arguments can be either CMake targets or library names. 
                                                    This target will link against specified cmake target's non-private libraries and this target 
                                                    will be able to see all non-private headers of specified targets. [optional]`
        COMPILE_OPTIONS     <compile_option,...>   `Options and flags to pass compiler for this target [optional]`
        COMPILE_DEFINITIONS <compile_option,...>   `Macro definitions to pass compiler for this target [optional]`

    `target_type` can be: STATIC|SHARED|INTERFACE|EXECUTABLE|UNIT_TEST|BENCHMARK

    Note: This function is private and intended to be used internally. Do not call this directly.
#]=======================================================================]
function(__hdk_add_target_options)
    hdk_log_set_context("hdk.mt")
    cmake_parse_arguments(ARGS "" "TARGET_NAME;TYPE;PARTOF;OUTPUT_NAME;" "LINK;COMPILE_OPTIONS;COMPILE_DEFINITIONS;DEPENDS;INCLUDES;SOURCES;HEADERS;SYMBOL_VISIBILITY;" ${ARGN})

    if(NOT DEFINED ARGS_TARGET_NAME)
        message(FATAL_ERROR "add_target_options() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "add_target_options() requires TYPE parameter.")
    endif()

    if(${ARGS_TYPE} STREQUAL "INTERFACE")
        if(DEFINED ARGS_INCLUDES)
            target_include_directories(${TARGET_NAME} INTERFACE ${ARGS_INCLUDES})
        endif()
        if(DEFINED ARGS_LINK)
            target_link_libraries(${TARGET_NAME} INTERFACE ${ARGS_LINK})
        endif()

        if(DEFINED ARGS_COMPILE_OPTIONS)
            target_compile_options(${TARGET_NAME} INTERFACE ${ARGS_COMPILE_OPTIONS})
        endif()

        if(DEFINED ARGS_SYMBOL_VISIBILITY)
            target_compile_options(${TARGET_NAME} INTERFACE -fvisibility=${ARGS_SYMBOL_VISIBILITY})
        endif()
    else()

        if(ARGS_INCLUDES)
            target_include_directories(${TARGET_NAME} PUBLIC ${ARGS_INCLUDES})
        endif()

        if(ARGS_LINK)
            target_link_libraries(${TARGET_NAME} PRIVATE ${ARGS_LINK})
        endif()

        if(ARGS_COMPILE_OPTIONS)
            target_compile_options(${TARGET_NAME} PRIVATE ${ARGS_COMPILE_OPTIONS})
        endif()
        
        if(ARGS_SYMBOL_VISIBILITY)
            target_compile_options(${TARGET_NAME} PRIVATE -fvisibility=${ARGS_SYMBOL_VISIBILITY})
        endif()
    endif()

    # Set output name for the target
    if(ARGS_OUTPUT_NAME)
        set_target_properties(${TARGET_NAME} PROPERTIES OUTPUT_NAME ${ARGS_OUTPUT_NAME})
    endif()

    if(ARGS_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET_NAME} PRIVATE ${ARGS_COMPILE_DEFINITIONS})
    endif()

    if(ARGS_DEPENDS)
        add_dependencies(${TARGET_NAME} ${ARGS_DEPENDS})
    endif()

    # We allow created targets to be a part of a bigger meta-target.
    if(ARGS_PARTOF) 
        add_dependencies(${ARGS_PARTOF} ${TARGET_NAME})
    endif()

endfunction()

function(__hdk_setup_coverage_targets)
    hdk_log_set_context("hdk.mt")
    cmake_parse_arguments(ARGS "" "TARGET_NAME;TYPE;" "LINK;COVERAGE_TARGETS;COVERAGE_LCOV_FILTER_PATTERN;COVERAGE_GCOVR_FILTER_PATTERN;COVERAGE_REPORT_OUTPUT_DIRECTORY;WORKING_DIRECTORY;" ${ARGN})
    if(NOT DEFINED ARGS_TARGET_NAME)
        message(FATAL_ERROR "setup_coverage_targets() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "setup_coverage_targets() requires TYPE parameter.")
    endif()

    if(NOT DEFINED ARGS_COVERAGE_LCOV_FILTER_PATTERN)
        # Default filter pattern
        set(ARGS_COVERAGE_LCOV_FILTER_PATTERN "*")
    endif()

    if(NOT DEFINED ARGS_COVERAGE_GCOVR_FILTER_PATTERN)
        # Default filter pattern
        set(ARGS_COVERAGE_GCOVR_FILTER_PATTERN "${CMAKE_SOURCE_DIR}")
    endif()


    if(NOT ${ARGS_TYPE} STREQUAL "INTERFACE")
        if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV AND GCOV)
            target_compile_options(${TARGET_NAME} PRIVATE -fprofile-arcs -ftest-coverage)
            target_link_libraries(${TARGET_NAME} PRIVATE gcov)

            if(ARGS_COVERAGE_TARGETS)
                foreach(CT IN LISTS ARGS_COVERAGE_TARGETS)
                    if(TARGET ${CT})
                        target_compile_options(${CT} PRIVATE -fprofile-arcs -ftest-coverage)
                        target_link_libraries(${CT} PRIVATE gcov)
                    else()
                        message(WARNING "${CT} is not a valid CMake target, skipping.")
                    endif()
                endforeach()
            endif()
            
            if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOVR AND GCOVR)

                SETUP_TARGET_FOR_COVERAGE_GCOVR_XML(
                    NAME ${TARGET_NAME}.gcovr.xml 
                    EXECUTABLE ${TARGET_NAME} 
                    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../ 
                    FILTER_PATTERN ${ARGS_COVERAGE_GCOVR_FILTER_PATTERN}
                    OUTPUT_DIRECTORY ${ARGS_COVERAGE_REPORT_OUTPUT_DIRECTORY}
                    WORKING_DIRECTORY ${ARGS_WORKING_DIRECTORY}
                )

                SETUP_TARGET_FOR_COVERAGE_GCOVR_HTML(
                    NAME ${TARGET_NAME}.gcovr.html 
                    EXECUTABLE ${TARGET_NAME} 
                    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../ 
                    FILTER_PATTERN ${ARGS_COVERAGE_GCOVR_FILTER_PATTERN}
                    OUTPUT_DIRECTORY ${ARGS_COVERAGE_REPORT_OUTPUT_DIRECTORY}
                    WORKING_DIRECTORY ${ARGS_WORKING_DIRECTORY}
                )

                # Project-level meta gcovr.xml target
                if (TARGET ${HDK_ROOT_PROJECT_NAME}.gcovr.xml)
                    add_dependencies(${HDK_ROOT_PROJECT_NAME}.gcovr.xml ${TARGET_NAME}.gcovr.xml)
                else()
                    add_custom_target(${HDK_ROOT_PROJECT_NAME}.gcovr.xml DEPENDS ${TARGET_NAME}.gcovr.xml)
                endif()

                # Project-level meta gcovr.html target
                if (TARGET ${HDK_ROOT_PROJECT_NAME}.gcovr.html)
                    add_dependencies(${HDK_ROOT_PROJECT_NAME}.gcovr.html ${TARGET_NAME}.gcovr.html)
                else()
                    add_custom_target(${HDK_ROOT_PROJECT_NAME}.gcovr.html DEPENDS ${TARGET_NAME}.gcovr.html)
                endif()

            endif()

            if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LCOV AND LCOV)

                SETUP_TARGET_FOR_COVERAGE_LCOV(
                    NAME ${TARGET_NAME}.lcov 
                    EXECUTABLE ${TARGET_NAME} 
                    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../ 
                    FILTER_PATTERN ${ARGS_COVERAGE_LCOV_FILTER_PATTERN} 
                    LCOV_ARGS --directory ${CMAKE_SOURCE_DIR} --no-external
                    OUTPUT_DIRECTORY ${ARGS_COVERAGE_REPORT_OUTPUT_DIRECTORY}
                    WORKING_DIRECTORY ${ARGS_WORKING_DIRECTORY}
                )

                # Project-level meta lcov target
                if (TARGET ${HDK_ROOT_PROJECT_NAME}.lcov)
                    add_dependencies(${HDK_ROOT_PROJECT_NAME}.lcov ${TARGET_NAME}.lcov)
                else()
                    add_custom_target(${HDK_ROOT_PROJECT_NAME}.lcov DEPENDS ${TARGET_NAME}.lcov)
                endif()

            endif()

        endif() 
    else()
        target_compile_options(${TARGET_NAME} INTERFACE -fprofile-arcs -ftest-coverage)
    endif()
endfunction()


function(__hdk_make_install)
    hdk_log_set_context("hdk.mt")
    cmake_parse_arguments(ARGS "" "TARGET_NAME;TYPE;" "" ${ARGN})

    if(NOT DEFINED ARGS_TARGET_NAME)
        message(FATAL_ERROR "make_install() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "make_install() requires TYPE parameter.")
    endif()

    install (
        TARGETS ${ARGS_TARGET_NAME}
        ARCHIVE 
            DESTINATION lib
        LIBRARY 
            DESTINATION lib
        RUNTIME 
            DESTINATION bin
        PUBLIC_HEADER
            DESTINATION include
        PRIVATE_HEADER
            DESTINATION include
    )

    install (
        DIRECTORY ${PROJECT_SOURCE_DIR}/include/
        DESTINATION include
        FILES_MATCHING PATTERN "**/*"
    )

endfunction()