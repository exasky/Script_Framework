#!/bin/sh
################################################################################
# LOG FUNCTIONS
################################################################################
Red='\e[0;31m';
BRed='\e[1;31m';

Green='\e[0;32m'; 

Yellow='\e[0;33m';

Blue='\e[0;34m'; 
BBlue='\e[1;34m'; 

NC='\033[0m';

logF() {
    printf $1"*******************************************************\n"; shift;
    for string in "$@" ; do
        printf "**\t$string\n"
    done
    printf "*******************************************************\n"${NC}
}

logSimple()     { printf "$@\n"; }

logSInfo()	    { printf ${Blue}"$@\n"${NC}; }
logInfo()       { logF ${Blue} "$@"; }

logSStatus()    { printf ${BBlue}"$@\n"${NC}; }
logStatus()     { logF ${BBlue} "STATUS: $@"; }

logSSuccess()   { printf ${Green}"$@\n"${NC}; }
logSuccess()    { logF ${Green} "SUCCES: $@"; echo ""; }

logSWarn()      { printf ${Yellow}"$@\n"${NC}; }
logWarn()       { logF ${Yellow} "WARN: $@"; }

logSError()     { printf ${Red}"$@\n"${NC}; }
logError()      { logF ${Red} "ERROR: $@"; }

logFatal()      { logF ${BRed} "FATAL: $@"; exit 1; }
