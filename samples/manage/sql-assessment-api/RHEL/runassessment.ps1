$Error.Clear()

# Create output directory if not exists

$outDir = '/var/opt/mssql/log/assessments'
if (-not ( Test-Path $outDir )) { mkdir $outDir }
$outPath = Join-Path $outDir 'assessment-latest'

$errorPath = Join-Path $outDir 'assessment-latest-errors'
if( Test-Path $errorPath ) { remove-item $errorPath }

function ConvertTo-LogOutput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $input
    ) 
    process {
        switch($input){
            { $_ -is [System.Management.Automation.WarningRecord] }{
                $result = @{
                    'TimeStamp' = $(Get-Date).ToString("O");
                    'Warning'   = $_.Message
                }
            }
            default {
                $result = @{
                    'TimeStamp'      = $input.TimeStamp;
                    'Severity'       = $input.Severity;
                    'TargetType'     = $input.TargetType;
                    'ServerName'     = $serverName;
                    'HostName'       = $hostName;
                    'TargetName'     = $input.TargetObject.Name;
                    'TargetPath'     = $input.TargetPath;
                    'CheckId'        = $input.Check.Id;
                    'CheckName'      = $input.Check.DisplayName;
                    'Message'        = $input.Message;
                    'RulesetName'    = $input.Check.OriginName;
                    'RulesetVersion' = $input.Check.OriginVersion.ToString();
                    'HelpLink'       = $input.HelpLink
                }

                if ( $input.TargetType -eq 'Database') {
                    $result['AvailabilityGroup'] = $input.TargetObject.AvailabilityGroupName
                }
            }
        }

        $result
    }
}

function Get-TargetsRecursive {

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [Microsoft.SqlServer.Management.Smo.Server] $server
    )

    $server
    $server.Databases 
}

try {
    $login, $pwd    = Get-Content '/var/opt/mssql/secrets/assessment' -Encoding UTF8NoBOM -TotalCount 2
    $securePassword = ConvertTo-SecureString $pwd -AsPlainText -Force
    $credential     = New-Object System.Management.Automation.PSCredential ($login, $securePassword)

    $serverName = (Invoke-SqlCmd -ServerInstance . -Credential $credential -Query "SELECT @@SERVERNAME")[0]
    $hostName   = (Invoke-SqlCmd -ServerInstance . -Credential $credential -Query "SELECT HOST_NAME()")[0]

    # Invoke assessment and store results.
    # Replace 'ConvertTo-Json' with 'ConvertTo-Csv' to change output format.
    # Available output formats: JSON, CSV, XML.
    # Encoding parameter is optional.

    Get-SqlInstance -ServerInstance . -Credential $credential -ErrorAction Stop
    | Get-TargetsRecursive
    | Invoke-SqlAssessment 3>&1
    | ConvertTo-LogOutput
    | ConvertTo-Json -AsArray
    | Set-Content $outPath -Encoding UTF8NoBOM
}
finally {
    if ($Error) {
        $Error 
        | ForEach-Object { @{ 'TimeStamp' = $(Get-Date).ToString("O"); 'Message' = $_.ToString() } } 
        | ConvertTo-Json -AsArray 
        | Set-Content $errorPath -Encoding UTF8NoBOM
    }
}