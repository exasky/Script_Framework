declare_env() {
    YOLA="varYALA2"
}

check_env() {
    [[ $YOLA != "varYALA2" ]] && logFatal "GLRLGRLGLRG"
}
