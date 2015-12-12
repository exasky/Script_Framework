#!/bin/sh
################################################################################
#   Welcome in the main part of this framework
#       See README for more informations
#
#   Author:     SIMAR Jeremy
#   Version:    1.1
#
#   Change log:
#       V0.1 : Initial
#       V0.2 : Add recursive sourcing
#       V0.3 : Better/Faster env checks
#       V0.4 : Add "ignore treatment" in declare_source
#       V0.5 : Add "error treatment" mechanism when calling logError function
#       V0.6 : Add "breakpoint" function which allow to stop script execution and call functions 
#              (as echo $my_var, inner_function, etc..)
#       V0.7 : Modularize framework
#       V1.0 : First release
#       V1.1 : Add array functions
#
################################################################################

################# __ifndef__ #################
MAIN_SCRIPT=$(cd "$(dirname "$0")" && pwd -P)"/$(basename $0)"
script_path=$(echo $MAIN_SCRIPT | sed -e "s@/@_@g" -e "s@\.@_@g" -e "s@-@_@")
define_var="ALREADY_SOURCED_$script_path"
[[ ! -z ${!define_var} ]] && return
export ALREADY_SOURCED_$script_path="defined"
################# __ifndef__ #################

################################################################################
#
#   USABLE FRAMEWORK FUNCTIONS
#
################################################################################

##
# Function that check if an element belongs to a list
# $1 : The list
# $2 : The element
##
list_contains() {
    for element in $1; do
        [[ $element == $2 ]] && return 0
    done
    return 1
}

array_contains(){
    local array="$1[@]"
    for element in "${!array}"; do
        [[ $element == $2 ]] && return 0
    done
    return 1
}

##
# Function that add an element at the position N of an array
# $1 : The array
# $2 : The element
# $3 : The position
##
insert_into_array() {       
    local arrayname=${1:?Arrayname required} val=$2 num=${3:-1}
    local array
    eval "array=( \"\${$arrayname[@]}\" )"
    [ $num -lt 0 ] && num=0 #? Should this be an error instead?
    array=( "${array[@]:0:num}" "$val" "${array[@]:num}" )
    eval "$arrayname=( \"\${array[@]}\" )"
}

##
# Function that add element(s) at the beginning of an array
# $1 : The array
# $2 : The element(s)
##
push_into_array() {
    local arrayname=${1:?Array name required} #val=$2
    shift
    eval "$arrayname=( \"\$@\" \"\${$arrayname[@]}\" )"
}

##
# Function that add element(s) at the end of an array
# $1 : The array
# $2 : The element(s)
##
add_end_array() {        
  local arrayname=${1:?Array name required} val=$2
  eval "$arrayname+=( \"\$val\" )"
}

##
# Function that pop the first element of an array
# $1 : The array
##
pop_array() {
    local arrayname=${1:?Array name required}
    eval "$arrayname=( \"\${$arrayname[@]:1}\" )"
}

################################################################################
#
#   INTERNAL FRAMEWORK FUNCTIONS
#
################################################################################
SF_declare_env() {
    local PATH_TO_FW="${BASH_SOURCE[0]%/*}"

    source "$PATH_TO_FW/logFunctions.sh"
    source "$PATH_TO_FW/debugger.sh" "$@"
    source "$PATH_TO_FW/error.sh"

    FILES_TO_BE_SOURCED=""
    declare_env_flag=0
    check_env_flag=0
    
    usage_function="usage"
    declare_env_function="declare_env"
    declare_source_function="declare_source"
    check_env_function="check_env"
    main_function="main"
}

##
# Function that check if a function exists
# $1 : The function to be checked
##
SF_if_function_declared() { type $1 &> /dev/null; }

##
# Function that check if a function exists in a file
#   The function must be in this format: [function ]function_name[ ]*()
# $1 : The function to be checked
# $2 : The file
##
SF_if_function_exists_in_file() { [[ ! -z "$(egrep "$1 *\(\)" $2)" ]]; }

##
# Function that unset framework function
##
SF_unset_functions() {
    unset -f $declare_env_function
    unset -f $check_env_function
}

##
# Function that return all files declared in 'declare_source' function in a file
# $1 : The file
##
SF_get_declared_sources_in_file() {
    local declare_source_first_line_number=$(egrep "declare_source *\(\)" $1 -n | cut -d":" -f1)
    [[ ! -z $(echo $declare_source_first_line_number | grep " ") ]] && echo "failed" && return
    local sources=""
    local current_line_number=$((declare_source_first_line_number + 1))
    local current_line=$(sed "$current_line_number"'q;d' $1)
    
    while [ "${current_line//[[:blank:]]/}" != "}" ] ; do
        # Take only lines that start with double quote (")
        if [[ $(echo -e "${current_line}" | sed -e 's/^[[:space:]]*//') == \"* ]] ; then
            sources="$sources "$(echo -e "${current_line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\"//g')
        fi
        current_line_number=$((current_line_number + 1))
        current_line=$(sed "$current_line_number"'q;d' $1)
    done
    
    echo "$sources"
}

##
# Function that call declare_env function from the current sourced file
##
SF_internal_declare_env() { declare_env_flag=1 && $declare_env_function; }

##
# Function that call check_env function from the current sourced file
##
SF_internal_check_env() { check_env_flag=1 && $check_env_function; }

##
# Function that set FILES_TO_BE_SOURCED var with all the files which have to be sourced
##
SF_set_files_to_be_sourced_by_depth() {
    local files_to_source=$(SF_get_declared_sources_in_file $1)
    [[ "$files_to_source" == "failed" ]] && logFatal "Too many declare_source in " "$1"

    for file in $files_to_source ; do
        local currentFile=$file
        SF_if_function_exists_in_file $declare_source_function $currentFile && SF_set_files_to_be_sourced_by_depth $currentFile
        ! list_contains "$FILES_TO_BE_SOURCED" "$currentFile" && FILES_TO_BE_SOURCED="$FILES_TO_BE_SOURCED "$currentFile
    done
}

##
# Function that source and call declare_env and check_env from all the files 
# which have to be sourced
##
SF_internal_declare_sources() {
    SF_set_files_to_be_sourced_by_depth $MAIN_SCRIPT

    for file in $FILES_TO_BE_SOURCED ; do
        SF_unset_functions
        source $file
        SF_if_function_declared $declare_env_function && SF_internal_declare_env
        SF_if_function_declared $check_env_function   && SF_internal_check_env
    done
    SF_unset_functions
}

##
# Function that check the environment before launching the main function
##
SF_internal_check_functions() {
    ! SF_if_function_exists_in_file $usage_function $MAIN_SCRIPT && logError "Function $usage_function not implemented"
    ! SF_if_function_exists_in_file $main_function  $MAIN_SCRIPT && logError "Function $main_function not implemented"
    
    SF_if_function_exists_in_file $declare_source_function $MAIN_SCRIPT && SF_internal_declare_sources
    
    [[ $declare_env_flag != 1 ]] && ! SF_if_function_exists_in_file $declare_env_function $MAIN_SCRIPT  && logError "Function $declare_env_function not implemented"
    [[ $check_env_flag != 1 ]]   && ! SF_if_function_exists_in_file $check_env_function $MAIN_SCRIPT    && logError "Function $check_env_function not implemented"
    
    error_happened? exit 1
}

##
# Main function
##
SF_internal_main() {
    SF_declare_env "$@"
    SF_internal_check_functions

    source $MAIN_SCRIPT

    # These functions aren't mandatory if the main script sources files that contains them
    SF_if_function_declared $declare_env_function && $declare_env_function
    SF_if_function_declared $check_env_function   && $check_env_function $*

    main "$@"
}

SF_internal_main "$@"
