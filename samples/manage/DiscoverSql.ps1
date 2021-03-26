
    
# This script checks if SQL Server is installed on Windows
    
    [bool] $SqlInstalled = $false 
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
    if (Test-Path $regPath) {
        $inst = (get-itemproperty $regPath).InstalledInstances
        $SqlInstalled = ($inst.Count -gt 0)
    }
    Write-Output $SqlInstalled
