################################################################################
#   To use this framework 
#           You have to implement some functions:
#
#   usage:          To explain how to use your script
#   declare_env:    To declare all variables in your script
#   check_env:      To check script's prerequisites to a good execution
#                           All script's parameters are passed through
#   main:           To launch the script execution
#                           All script's parameters are passed through
#
#
#           You have to follow some rules:
#
#   - Use "source 'path_to_script_framework'" at the beginning of yours
#   - Declare variables in declare_env function only
#   - Do not call declare_env and check_env
#   - Do not use any instruction out of a function
#       @ Ignoring this may cause issues at the execution
#       @ The main function is automatically called
#   - If you want to use "recursive sourcing" (eg. Source a file that sources a file, etc..)
#       @ Declare the declare_source function with lines like: "/path/to/your_script.sh"
#       @ When "recursice sourcing" is used, you can declare 'declare & check _env' functions in your 
#         sourced files. You don't have to declare them in your main script anymore
#       @ Be careful when using 'multi sourcing': do not declare functions with the same name,
#         variables with the same name, etc.. 
#               It doesn't apply for declare_env, check_env & declare_source
#   - The function "logError" set an error flag that is used by "error_happened?" function
#   - To use the debugger part, you juste have to call "breakpoint" function at any line of your script
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
#           V0.6.1 : Add options to breakpoint function
#           V0.6.2 : Add print_stacktrace
#       V0.7 : Modularize framework
#       V1.0 : First release
#       V1.1 : Add features to debugger
#
################################################################################
