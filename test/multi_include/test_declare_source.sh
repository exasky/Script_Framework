#!/bin/bash
. "../../scriptFramework.sh"

function declare_source  () 
 {
    "./include.sh"
    #"./include10.sh"
}

check_env(){
    :
}

usage(){
    echo "USAGE is a lie"
}

main(){
    echo "include.sh : "$YOLO
    echo "include2.sh: "$YOLA
    logError "wolo"
    error_happened? && exit 1
    echo "This line wont be printed"
}


