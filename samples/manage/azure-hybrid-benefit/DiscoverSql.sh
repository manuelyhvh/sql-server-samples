if ! systemctl is-active --quiet mssql-server.service; then 
    echo "False" 
    exit 
    else 
        echo "True" 
    fi