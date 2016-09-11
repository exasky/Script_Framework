included_function()
{
    echo -e "\t\t\tDANS INCLUDED"
    echo -e "\t\t\tFIN FUNCTION"
}

func_with_parameters() {
    
    echo $1

    inner_func_with_params "my" "params"
    breakpoint
    echo $2
    
    echo "INNER"
}

inner_func() {
    
    echo "plop"
}

inner_func_with_params() {
    echo $1
    echo $2

    echo "fin params2"
}
