################################################################################
#   Welcome in the error treatment part of this framework
#
#   Author:     SIMAR Jeremy
#   Version:    1.0
#
#   Change log:
#       V1.0 : First release
#
################################################################################

ERR_INTERNAL_ERROR=0

################################################################################
#
#   USABLE ERROR FUNCTIONS
#
################################################################################
##
# Function set the error flag to false
##
unerror() { ERR_INTERNAL_ERROR=0; }

##
# Function set the error flag to true
##
error() { ERR_INTERNAL_ERROR=1; }

logError() { 
    logF ${Red} "ERROR: $@"
    error
}

##
# Function that check if an error happened. If so, arguments are executed
#   Example: error_happened? exit_with_usage 1
#       will call "exit_with_usage" function with argument "1" if an error happened
##
error_happened?() { [[ $ERR_INTERNAL_ERROR == 1 ]] && "$@"; }

exit_with_error_message() { logFatal "$@"; }

exit_with_error_and_usage() {
    local error=$1
    shift
    logError "$@"
    usage
    exit $error
}

exit_with_usage() {
    usage
    exit $1
}
