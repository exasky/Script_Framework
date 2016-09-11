declare_source(){
    "./include2.sh"
}

declare_env(){
    YOLO="varYOLO1"
}

check_env() {
    [[ $YOLO != "varYOLO1" ]] && logFatal "GLRLGRLGLRG"
}
