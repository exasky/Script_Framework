source "../../scriptFramework.sh"

function declare_source  () 
 {
    "./include.sh"
    #".e/include2.sh"
}

check_env(){
    :
}

usage(){
    echo "TEST_ERROR With multi declare_source functions"
}

main(){
    echo "mwahaha"
    echo $YOLO
    echo $YOLA
    
    logError "wolo"
    error_happened? && exit 1
    echo "This line wont be printed"
}

function declare_source  () 
 {
    #"./include.sh"
    "./include2.sh"
}
