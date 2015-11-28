included_function()
{
    echo -e "\t\t\tDANS INCLUDED"
    echo -e "\t\t\tFIN FUNCTION"
}

func_with_parameters() {
    
    echo $1
    echo $2
    breakpoint
    echo "INNER"
    
    inner_func
    echo "INNER"
    echo "w"
}

inner_func() {
    
    echo "plop"
}
