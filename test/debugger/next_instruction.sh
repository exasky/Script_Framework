#!/bin/bash
###############################################
#    GENERATED BY scriptFramework_tools.sh    #
###############################################

. "../../scriptFramework.sh"

usage() {
    :
}

declare_env() {
    :
}

check_env() {
    :
}

declare_source() {
    "./included_next_instruction.sh"
}

#####################################
#    DECLARE YOUR FUNCTIONS HERE    #
#####################################

infunction() {
    echo -e "\tIN1"
    ininfunction
    echo -e "\tIN2"
}

ininfunction() {
    echo -e "\t\tININ1"
    included_function
    #breakpoint
    echo -e "\t\tININ2"
}

#####################################

main() {
    a=2
    echo "FIRST"
    echo "SECOND"
    echo "BREAK"
    infunction
    a=3
    breakpoint
    
    echo "THIRD"
    echo "FOURTH"
    breakpoint
    echo "FIFTH"
    echo $a
}

