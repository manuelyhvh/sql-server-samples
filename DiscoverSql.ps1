
    
    # This function is to run on each VM to detect if SQL server is installed
    
    [bool] $SqlInstalled = $false 
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
    if (Test-Path $regPath) {
        $inst = (get-itemproperty $regPath).InstalledInstances
        $SqlInstalled = ($inst.Count -gt 0)
    }
    Write-Output $SqlInstalled
