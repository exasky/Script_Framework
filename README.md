#	Script Framework

## Usage

Implements at least these functions:
- usage:          To explain how to use your script
- declare_env:    To declare all variables in your script
- check_env:      To check script's prerequisites to a good execution. All script's parameters are passed through
- main:           To launch the script execution. All script's parameters are passed through
    
## You have to follow some rules:

    Use "source 'path_to_script_framework'" at the beginning of yours
    Declare variables in declare_env function only
    Do not call declare_env and check_env
    Do not use any instruction out of a function
        @ Ignoring this may cause issues at the execution
        @ The main function is automatically called
    Assign your function arguments to variables with a meaningful name at the beginning of your functions
        @ e.g. my_var="$1", or my_var="$@", etc...
    If you want to use "recursive sourcing" (eg. Source a file that sources a file, etc..)
        @ Declare the declare_source function with lines like: "/path/to/your_script.sh"
        @ When "recursice sourcing" is used, you can declare 'declare & check _env' functions in your 
          sourced files. You don't have to declare them in your main script anymore
        @ Be careful when using 'multi sourcing': do not declare functions with the same name,
          variables with the same name, etc.. 
               It doesn't apply for declare_env, check_env & declare_source
    The function "logError" set an error flag that is used by "error_happened?" function
    To use the debugger part, you juste have to call "breakpoint" function at any line of your script
        @ Do not call 'breakpoint' before n for or until (NOT SUPPORTED YET)
    Make clean code
        @ Do not write a comment on the same line than another instruction
        @ Make line breaks

## Change log:
- V0.1 : Initial
- V0.2 : Add recursive sourcing
- V0.3 : Better/Faster env checks
- V0.4 : Add "ignore treatment" in declare_source
- V0.5 : Add "error treatment" mechanism when calling logError function
- V0.6 : Add "breakpoint" function which allow to stop script execution and call functions (as echo $my_var, inner_function, etc..)
- V0.7 : Modularize framework
- V1.0 : First release
- V1.1 : Add features to debugger

> Author:     SIMAR Jeremy<br/>
> Version:    1.1
