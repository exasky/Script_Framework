################################################################################
#   Welcome in the debugger part of this framework
#
#   Author:     SIMAR Jeremy
#   Version:    1.6
#
#   Change log:
#       V0.1 : Initial
#       V0.2 : Add options to breakpoint function
#       V0.3 : Add stacktrace
#       V0.4 : Add around line display
#       V0.5 : Add next_instruction & continue
#       V1.0 : First release - Light debugger, only for simple
#       V1.1 : Add step out
#       V1.2 : Refactor variables (DEBUG_CURRENT_ SOURCE/FUNCTION/LINENO)
#       V1.3 : Add step in
#           V1.3.1 : Correct bug when using "continue" after a "step in"
#           V1.3.2 : Correct bug if using "next" when a breakpoint is set in
#                    an inner-function
#       V1.4 : Add "argument processing" when stepping in
#       V1.5 : IF processing
#       V1.6 : WHILE processing
#
#
#   WARNING: The debugger does not work with keywords: for, switch, until
#            To use only on simple/medium complexity parts
#
################################################################################

# Global variable that has to be to be initialized only one time
DEBUG_BREAKPOINT_ACTIVATED=true
# Used for getting argument params (in case of a breakpoint in the main)
local programm_arguments_formatted=""
for arg in "$@"; do
    programm_arguments_formatted=$programm_arguments_formatted" \"$arg\""
done
add_end_array DEBUG_CURRENT_ARGS "$programm_arguments_formatted"
################################################################################
#
#   USABLE DEBUG FUNCTIONS
#
################################################################################

##
# Function that pause the script execution
##
breakpoint() {
    DEBUG_init_internal_variables
    DEBUG_goto_next_valid_instruction
    
    while $DEBUG_BREAKPOINT_ACTIVATED && $DEBUG_CONTINUE; do
        read -p "(DEBUG - h for help) $(basename ${DEBUG_CURRENT_SOURCE[0]}):$DEBUG_CURRENT_LINE_NUMBER > " user_command
        echo ""
        [[ $user_command = "" ]] && user_command=$SF_PREVIOUS_USER_COMMAND
        SF_PREVIOUS_USER_COMMAND=$user_command

        case $user_command in
            c )        DEBUG_continue;;
            cls )      clear;;
            h | help)  DEBUG_display_breakpoint_help;;
            l | list)  DEBUG_display_around_lines;;
            n | next)  DEBUG_next_instruction;;
            q | quit)  DEBUG_BREAKPOINT_ACTIVATED=false; break;;
            s | step)  DEBUG_step_in;;
            t | stack) DEBUG_display_stacktrace;;
            \$* )      eval "echo $user_command";;
            * )        eval $user_command;;
        esac
    done
}

################################################################################
#
#   INTERNAL DEBUG FUNCTIONS
#
################################################################################
DEBUG_display_breakpoint_help() {
    echo
    echo "Short help description (under construct)"
    echo -e "h:\t To display this help"
    echo -e "c:\t To run to the next breakpoint"
    echo -e "l:\t To display current location"
    echo -e "n:\t To execute the current one and go to the next instruction"
    echo -e "q:\t To dismiss all next breakpoints"
    echo -e "s:\t To go into the current instruction"
    echo -e "t:\t To display stacktrace"
    echo -e "\"\$foo\":\t To display the foo variable"
    echo -e "cls:\t To clear the screen"
    echo -e "Enter:\t Re-execute the last command"
    echo
    logSWarn "WARNING: The debugger does not work with keywords: while, for, etc.."
    logSWarn "\t To use only for print/modify variables or for simple parts"
}

DEBUG_init_internal_variables() {
    # If DEBUG_CURRENT_SOURCE isn't empty, it means that the user did a "next"
    # and the debugger stops in an inner function which contains a "breapoint"
    if [ ! -z "$DEBUG_CURRENT_SOURCE" ] ; then
        # Get number of missing stack to be added to the current one
        local i=0
        for element in "${FUNCNAME[@]:2}"; do
            [[ $element == DEBUG_* ]] && break
            i=$((i+1))
        done
        
        local temp_source=${BASH_SOURCE[@]:2:$i}
        local temp_lineno=${BASH_LINENO[@]:2:$i}
        local temp_func=${FUNCNAME[@]:2:$i}
        
        push_into_array DEBUG_CURRENT_SOURCE $temp_source
        push_into_array DEBUG_CURRENT_FUNCTION $temp_func
        push_into_array DEBUG_CURRENT_LINENO $temp_lineno
        
        #Re-align DEBUG_CURRENT_LINENO
        DEBUG_CURRENT_LINENO[$((i-1))]=$DEBUG_CURRENT_LINE_NUMBER
    else 
        DEBUG_CURRENT_SOURCE=("${BASH_SOURCE[@]:2}")
        DEBUG_CURRENT_FUNCTION=("${FUNCNAME[@]:2}")
        DEBUG_CURRENT_LINENO=("${BASH_LINENO[@]:2}")
    fi

    DEBUG_PREVIOUS_USER_COMMAND=""
    DEBUG_CURRENT_LINE_NUMBER=${BASH_LINENO[1]}
    DEBUG_CURRENT_INSTRUCTION=""
    DEBUG_CONTINUE=true
    DEBUG_CURRENT_IF_PASSED=()
}
##
# Function that displays lines around the current line
##
DEBUG_display_around_lines() {
    local current_file="${DEBUG_CURRENT_SOURCE[0]}"
    local current_line_number="$DEBUG_CURRENT_LINE_NUMBER"
    
    # This is used to avoid errors when the first line is < 3
    local first_line=$((current_line_number-3))
    local middle=$((first_line + 3))
    [ $first_line -lt 1 ] && first_line=1 && middle=$DEBUG_CURRENT_LINE_NUMBER
    
    for (( i=${first_line}; i <= $((current_line_number + 5)); i++)); do
        printf "$i."
        [[ "$i" == "$middle" ]] && printf " >"
        printf "\t"
        echo "$(sed "$i"'!d' $current_file)"
    done
}

##
# Function that displays the stacktrace
##
DEBUG_display_stacktrace() {
    local -i start=1
    local -i end=$((${#DEBUG_CURRENT_SOURCE[@]}-3))

    echo -e "\tStacktrace (last called is first):" 1>&2

    echo -e "\t\t${DEBUG_CURRENT_FUNCTION[0]}() in ${DEBUG_CURRENT_SOURCE[0]}:${DEBUG_CURRENT_LINE_NUMBER}" 1>&2
    for ((i=${start}; i < ${end}; i++)); do
        j=$(( $i - 1 ))
        local function="${DEBUG_CURRENT_FUNCTION[$i]}"
        local file="${DEBUG_CURRENT_SOURCE[$i]}"
        local line="${DEBUG_CURRENT_LINENO[$j]}"
        echo -e "\t\t${function}() in ${file}:${line}" 1>&2
    done
    echo ""
}

##
# Function that try to go into the current instruction if it is a function
#   Execute DEBUG_next_instruction otherwise
##
DEBUG_step_in() {
    if [[ $(type -t $DEBUG_CURRENT_INSTRUCTION) == "function" ]] ; then
        # Get informations of the function
        shopt -s extdebug
        local description=$(declare -F $DEBUG_CURRENT_INSTRUCTION)
        shopt -u extdebug
        
        local function_name=$(echo $description | cut -d' ' -f1)
        local function_line=$(echo $description | cut -d' ' -f2)
        local function_file=$(echo $description | cut -d' ' -f3)

        push_into_array DEBUG_CURRENT_SOURCE $function_file
        push_into_array DEBUG_CURRENT_FUNCTION $function_name
        push_into_array DEBUG_CURRENT_LINENO $DEBUG_CURRENT_LINE_NUMBER
        push_into_array DEBUG_CURRENT_ARGS "$(echo $DEBUG_CURRENT_INSTRUCTION | sed "s/$function_name //")"
         
        DEBUG_CURRENT_LINE_NUMBER=$function_line
        DEBUG_goto_next_valid_instruction
        
    else
        DEBUG_next_instruction
    fi
}

##
# Function that execute the current instruction and go to the next one
##
DEBUG_next_instruction() {
    # At the first call, DEBUG_CURRENT_INSTRUCTION has already been 
    DEBUG_execute_current_instruction

    if [[ $? != 0 ]] ; then
        logSWarn "Instruction  \"$DEBUG_CURRENT_INSTRUCTION\"  not supported. Continue.."
        DEBUG_continue
        return
    fi
    DEBUG_goto_next_valid_instruction
}

##
# Function that execute the current instruction
# Here are defined keywords where the user can be stop on
##
DEBUG_execute_current_instruction() {
    # Set args in DEBUG_CURRENT_INSTRUCTION
    eval DEBUG_set_args_in_current_instruction "${DEBUG_CURRENT_ARGS[0]}"
    
    if [[ "$DEBUG_CURRENT_INSTRUCTION" == "if "* ]] || [[ "$DEBUG_CURRENT_INSTRUCTION" == "elif "* ]]; then
        [[ "$DEBUG_CURRENT_INSTRUCTION" == "if "* ]] && push_into_array DEBUG_CURRENT_IF_PASSED false
        if ! eval $(echo $DEBUG_CURRENT_INSTRUCTION | sed -e "s/^if//" -e "s/^elif//" -e "s/then$//") ; then
            DEBUG_goto_next_else_elif
        else 
            #Case when go into the current if/elif
            DEBUG_CURRENT_IF_PASSED[0]=true
        fi
    elif [[ "$DEBUG_CURRENT_INSTRUCTION" == "while "* ]] ; then
        if ! eval $(echo $DEBUG_CURRENT_INSTRUCTION | sed -e "s/^while //" -e "s/do$//") ; then
            DEBUG_goto_done
        fi
    elif [[ "$DEBUG_CURRENT_INSTRUCTION" == "break" ]] ; then
        DEBUG_goto_done
    elif [[ "$DEBUG_CURRENT_INSTRUCTION" == "continue" ]] ; then
        DEBUG_goto_previous_loop_statement
        # GOTO previous line because when stepping out of this function -> goto next line
        DEBUG_goto_previous_line
    else
        eval "$DEBUG_CURRENT_INSTRUCTION"
    fi
}

##
# Function that set the correct parameters in the DEBUG_CURRENT_INSTRUCTION 
##
DEBUG_set_args_in_current_instruction() {
    local i=0
    for arg in "$@"; do
        i=$((i+1))
        DEBUG_CURRENT_INSTRUCTION=$(echo $DEBUG_CURRENT_INSTRUCTION | sed "s/\$$i/$arg/")
    done
}

##
# Function that go to the next else of elif statement  
##
DEBUG_goto_next_else_elif() {
    local if_depth=1

    while [ $if_depth != 0 ]; do
        DEBUG_goto_next_line

        [[ $DEBUG_CURRENT_INSTRUCTION == "if "* ]] && if_depth=$((if_depth+1))
        [[ $DEBUG_CURRENT_INSTRUCTION == fi ]] && if_depth=$((if_depth-1))
        [[ $DEBUG_CURRENT_INSTRUCTION == "elif "* ]] && if_depth=$((if_depth-1))
        [[ $DEBUG_CURRENT_INSTRUCTION == else ]] && if_depth=$((if_depth-1))
    done
    
    [[ $DEBUG_CURRENT_INSTRUCTION == "elif "* ]] && DEBUG_goto_previous_line
    [[ $DEBUG_CURRENT_INSTRUCTION == else ]] && DEBUG_CURRENT_IF_PASSED[0]=true
    [[ $DEBUG_CURRENT_INSTRUCTION == fi ]] && pop_array DEBUG_CURRENT_IF_PASSED
    return 0
}

##
# Function that go to the next fi statement  
##
DEBUG_goto_fi_statement() {
    local if_depth=1

    while [ $if_depth != 0 ]; do
        DEBUG_goto_next_line

        [[ $DEBUG_CURRENT_INSTRUCTION == "if "* ]] && if_depth=$((if_depth+1))
        [[ $DEBUG_CURRENT_INSTRUCTION == fi ]] && if_depth=$((if_depth-1))
    done
    
    pop_array DEBUG_CURRENT_IF_PASSED
    return 0
}

DEBUG_goto_previous_loop_statement() {
    local done_depth=1

    while [ $done_depth != 0 ]; do
        DEBUG_goto_previous_line

        [[ $DEBUG_CURRENT_INSTRUCTION == "while "* ]] && done_depth=$((done_depth-1))
        #[[ $DEBUG_CURRENT_INSTRUCTION == "for "* ]] && done_depth=$((done_depth+1))
        [[ $DEBUG_CURRENT_INSTRUCTION == done ]] && done_depth=$((done_depth+1))
    done

    return 0
}

DEBUG_goto_done() {
    local done_depth=1

    while [ $done_depth != 0 ]; do
        DEBUG_goto_next_line

        [[ $DEBUG_CURRENT_INSTRUCTION == "while "* ]] && done_depth=$((done_depth+1))
        #[[ $DEBUG_CURRENT_INSTRUCTION == "for "* ]] && done_depth=$((done_depth+1))
        [[ $DEBUG_CURRENT_INSTRUCTION == done ]] && done_depth=$((done_depth-1))
    done
    
    return 0
}

##
# Function that set the DEBUG_CURRENT_INSTRUCTION variable by retrieving
#   the next valid instruction
##
DEBUG_goto_next_valid_instruction() {
    DEBUG_goto_next_line

    while ! DEBUG_current_instruction_is_valid; do
        DEBUG_process_control_statements
        DEBUG_goto_next_line
    done

    DEBUG_process_control_statements
}

##
# Function that process end of statements
#   For example: fi, done
##
DEBUG_process_control_statements() {
    [[ "$DEBUG_CURRENT_INSTRUCTION" == "fi" ]] && pop_array DEBUG_CURRENT_IF_PASSED
    # We cannot stop on a else statement, if so then go to fi
    [[ "$DEBUG_CURRENT_INSTRUCTION" == "else" ]] && DEBUG_goto_fi_statement && DEBUG_goto_next_valid_instruction
    # If we've already gone into an elif statement, then the ${DEBUG_CURRENT_IF_PASSED[0]} var is to true. We don't want to go into another one so goto_fi
    [[ "$DEBUG_CURRENT_INSTRUCTION" == "elif "* ]] && ${DEBUG_CURRENT_IF_PASSED[0]} && DEBUG_goto_fi_statement && DEBUG_goto_next_valid_instruction
    
    # We cannot stop on a done statement, if so then go corresponding for or while
    [[ "$DEBUG_CURRENT_INSTRUCTION" == "done" ]] && DEBUG_goto_previous_loop_statement    
    
    [[ "${DEBUG_CURRENT_INSTRUCTION//[[:blank:]]/}" == "}" ]] && DEBUG_step_out_function
}

##
# Function that check if the current instruction is a valid one
#   Commented lines, empty lines, ... Are incorrect
##
DEBUG_current_instruction_is_valid() {
    #               SKIP BREAKPOINT                                    SKIP EMPTY LINES               
    [[ "$DEBUG_CURRENT_INSTRUCTION" != "breakpoint" ]] && [[ "$DEBUG_CURRENT_INSTRUCTION" != "" ]] && \
    #             SKIP COMMENTED LINES                            SKIP LINES STARTING WITH '{'
    [[ "$DEBUG_CURRENT_INSTRUCTION" != \#* ]] && [[ "${DEBUG_CURRENT_INSTRUCTION//[[:blank:]]/}" != "{" ]] && \
    #              SKIP then                                        SKIP fi
    [[ "$DEBUG_CURRENT_INSTRUCTION" != "then" ]] && [[ "$DEBUG_CURRENT_INSTRUCTION" != "fi" ]] && \
    #              SKIP do
    [[ "$DEBUG_CURRENT_INSTRUCTION" != "do" ]]
}

##
# Function that resume the execution of the script
##
DEBUG_continue() {
    DEBUG_ON
    DEBUG_CONTINUE=false
}

##
# Function that set the current line number to the previous one
##
DEBUG_goto_previous_line() {
    DEBUG_CURRENT_LINE_NUMBER=$((DEBUG_CURRENT_LINE_NUMBER-1))
    DEBUG_set_surrent_instruction
}

##
# Function that set the current line number to the next one
##
DEBUG_goto_next_line() {
    DEBUG_CURRENT_LINE_NUMBER=$((DEBUG_CURRENT_LINE_NUMBER+1))
    DEBUG_set_surrent_instruction
}

##
# Function that set the current instruction according to the current file and line number
##
DEBUG_set_surrent_instruction() {
    DEBUG_CURRENT_INSTRUCTION=$(sed -e "$DEBUG_CURRENT_LINE_NUMBER"'!d' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' ${DEBUG_CURRENT_SOURCE[0]})
}

DEBUG_step_out_function() {
    # DEBUG_CURRENT_LINENO[0] correspond to the current line of the upper function
    DEBUG_CURRENT_LINE_NUMBER=${DEBUG_CURRENT_LINENO[0]}
    
    # Re-align the current stack by removing the current element
    pop_array DEBUG_CURRENT_ARGS
    pop_array DEBUG_CURRENT_SOURCE
    pop_array DEBUG_CURRENT_LINENO
    pop_array DEBUG_CURRENT_FUNCTION

    # If True then we are at the end of the main
    if [[ ${DEBUG_CURRENT_SOURCE[0]} == *scriptFramework.sh ]]; then
        #Activate the degug in order to not re-execute lines
        DEBUG_ON
        DEBUG_CONTINUE=false;
    else
        DEBUG_goto_next_valid_instruction
    fi
}

DEBUG_ON() {
    # This option allows the bash to switch to a debug environment
    shopt -s extdebug
    # This option allows the bash to go into functions (use with step_in)
    set -o functrace
    # This option allows the bash to give each command to the DEBUG function
    trap 'DEBUG_extdebug_trap $BASH_COMMAND' DEBUG
}

DEBUG_OFF() {
    trap - DEBUG
    set +o functrace
    shopt -u extdebug
}

# return 0 => execute instruction
# return 1 => don't execute instruction
DEBUG_extdebug_trap() {
    # This test allows the execution of debugger.sh instructions
    [[ ${BASH_SOURCE[1]} == *debugger.sh ]] && return 0;
    
    # This test allow bash to executes functions that are in the stack
    array_contains DEBUG_CURRENT_FUNCTION "$@" && return 0;

    #This test prevent re-execution of code:
    #   For example, if the DEBUG_LINE is > to the current file line (BASH_LINENO[0])
    #                then the current_line won't be executed because the 
    #                debugger has already executed this line
    [[ $DEBUG_CURRENT_LINE_NUMBER != ${BASH_LINENO[0]} ]] && return 1
    
    # When calling continue, this test afford to stop debugging when the current_debug_line
    # is equal to current_script_line 
    [[ $DEBUG_CURRENT_LINE_NUMBER == ${BASH_LINENO[0]} ]] && DEBUG_OFF && return 0
}
