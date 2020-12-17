# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ---------------------------------------------------------------------------------
#
# Sample script to calculate the consolidated SQL Server license usage by all of the SQL resources in a specific subscription or the entire the account.
#
# This script accepts a .csv file as a parameter, which provides a list of subscriptions to be scanned for the license usage. You can create   
# such a file by the following command and then edit to remove the subscriptions you don't  want to scan:
# > Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation
#
# If no file is provided, the script will prompt for a subscriptiobn ID or `*`. The latter will automatically scan all the subscriptions you account 
# has access to.
#
#
# NOTE: The script does not calculate usage for Azure SQL resources that use the DTU-based purchasing model
#

# Import the subscription info

if ($args[0] -ne $null) {
    # Read subscription list from the .csv file
    $subscriptions = Import-Csv $args[0]
} else {
    # Promt for the subscription 
    $Id = read-host -Prompt "Enter Subscription ID"
    if ($Id -eq "*") {
        $subscriptions = Get-AzSubscription     
    } else {
        $subscriptions = [PSCustomObject]@{SubscriptionId = $Id} | Get-AzSubscription 
    }
}

#Initialize arrays
[System.Collections.ArrayList]$usage = @()
if ($ec -eq $null){
    $usage += ,(@("Subscription Name", "Subscription ID", "AHB Std vCores", "AHB Ent vCores", "PAYG Std vCores", "PAYG Ent vCores", "HADR Std vCores", "HADR Ent vCores", "Developer vCores", "Express vCores"))
}else{
    $usage += ,(@("Subscription Name", "Subscription ID", "AHB ECs", "PAYG ECs", "AHB Std vCores", "AHB Ent vCores", "PAYG Std vCores", "PAYG Ent vCores", "HADR Std vCores", "HADR Ent vCores", "Developer vCores", "Express vCores"))
}

$subtotal = [pscustomobject]@{ahb_std=0; ahb_ent=0; payg_std=0; payg_ent=0; hadr_std=0; hadr_ent=0; developer=0; express=0}
$total = [pscustomobject]@{}
foreach( $property in $subtotal.psobject.properties.name ){
    $total | Add-Member -MemberType NoteProperty -Name $property -Value 6
}

#Save the VM SKU table
$VM_SKUs = Get-AzComputeResourceSku

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions...")

# Calculate usage for each subscription 
foreach ($sub in $subscriptions){

    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id
    }catch {
        write-host "Invalid subscription: " $sub.Id
        {continue}
    }

    # Reset the subtotals     
    foreach( $property in $subtotal.psobject.properties.name ){
        $subtotal.$property = 0
    }
    
    #Get all logical servers
    $servers = Get-AzSqlServer 

    #Get all SQL database resources in the subscription
    $databases = $servers | Get-AzSqlDatabase

    # Process the vCore-based databases 
    foreach ($db in $databases ){
        if ($db.SkuName -eq "ElasticPool") {continue}

        if ($db.LicenseType -eq "LicenseIncluded") {
            if ($db.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $db.Capacity
            } elseif ($db.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $db.Capacity
            }
        }else{
            if ($db.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $db.Capacity
            } elseif ($db.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $db.Capacity
            }
        } 
    }

    #Get all SQL elastic pool resources in the subscription
    $pools = $servers | Get-AzSqlElasticPool

    # Process the vCore-based elastic pools 
    foreach ($pool in $pools){
        if ($pool.LicenseType -eq "LicenseIncluded") {
            if ($pool.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $pool.Capacity
            } elseif ($pool.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $pool.Capacity
            }
        }else{
            if ($pool.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $pool.Capacity
            } elseif ($pool.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $pool.Capacity
            }
        }
    }

    #Get all SQL managed instance resources in the subscription
    $instances = Get-AzSqlInstance

    # Process the SQL managed instances with License Included and add to VCore count
    foreach ($ins in $instances){
        if ($ins.InstancePoolName -eq $null){
            if ($ins.LicenseType -eq "LicenseIncluded") {
                if ($ins.Sku.Tier -eq "BusinessCritical") {
                    $subtotal.ahb_ent += $ins.VCores
                } elseif ($ins.Sku.Tier -eq "GeneralPurpose") {
                    $subtotal.ahb_std += $ins.VCores
                }
            }else{
                if ($ins.Edition -eq "BusinessCritical") {
                    $subtotal.payg_ent += $pool.Capacity
                } elseif ($ins.Edition -eq "GeneralPurpose") {
                    $subtotal.payg_std += $ins.Capacity
                }        
            }
        }
    }

    #Get all instance pool resources in the subscription
    $ipools = Get-AzSqlInstancePool

    # Process the instance pools 
    foreach ($ip in $ipools){
        if ($ip.LicenseType -eq "LicenseIncluded") {
            if ($ip.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $ip.VCores
            } elseif ($ip.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $ip.VCores
            }
        }else{
            if ($ip.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $ip.Capacity
            } elseif ($ip.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $ip.Capacity
            }        
        }
    }

     
    #Get all SSIS imtegration runtime resources in the subscription
    $ssis_irs = Get-AzResourceGroup | Get-AzDataFactoryV2 | Get-AzDataFactoryV2IntegrationRuntime

    # Get the VM size, match it with the corresponding VCPU count and add to VCore count
    foreach ($ssis_ir in $ssis_irs){
        # Select first size and get the VCPus available
        $size_info = $VM_SKUs | where { $_.Name -like $ssis_ir.NodeSize} | Select-Object -First 1
        
        # Save the VCPU count
        $vcpu= $size_info.Capabilities | Where-Object {$_.name -eq "vCPUsAvailable"}

        if ($ssis_ir.State -eq "Started"){      
            if ($ssis_ir.LicenseType -like "LicenseIncluded"){
                if ($ssis_ir.Edition -like "Enterprise"){
                    $subtotal.ahb_ent += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Standard"){
                    $subtotal.ahb_std += $vcpu.value
                }
            }elseif ($data.license -like "BasePrice"){ 
                if ($ssis_ir.Edition -like "Enterprise"){
                    $subtotal.payg_ent += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Standard"){
                    $subtotal.payg_std += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Developer"){
                    $subtotal.developer += $vcpu.value             
                }elseif ($ssis_ir.Edition -like "Express"){
                    $subtotal.express += $vcpu.value
                }
            }
        }
    }
    
    
    #Get All SQL VMs resources in the subscription
    $sql_vms = Get-AzSqlVM 

    # Get the VM size, match it with the corresponding VCPU count and add to VCore count
    foreach ($sql_vm in $sql_vms){
        $vm = Get-AzVm -Name $sql_vm.Name -ResourceGroupName $sql_vm.ResourceGroupName
        $vm_size = $vm.HardwareProfile.VmSize
        # Select first size and get the VCPus available
        $size_info = $VM_SKUs | where {$_.ResourceType.Contains('virtualMachines') -and $_.Name -like $vm_size} | Select-Object -First 1
        # Save the VCPU count
        $vcpu= $size_info.Capabilities | Where-Object {$_.name -eq "vCPUsAvailable"}

        if ($vcpu){
            $data = [pscustomobject]@{vm_resource_uri=$vm.Id;sku=$sql_vm.Sku;license=$sql_vm.LicenseType;size=$vm_size;vcpus=$vcpu.value}
        
            if ($data.license -like "DR"){          
                if ($data.sku -like "Enterprise"){
                    $subtotal.hadr_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.hadr_std += $data.vcpus
                }
            }elseif ($data.license -like "AHUB"){
                if ($data.sku -like "Enterprise"){
                    $subtotal.ahb_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.ahb_std += $data.vcpus
                }
            }elseif ($data.license -like "PAYG"){ 
                if ($data.sku -like "Enterprise"){
                    $subtotal.payg_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.payg_std += $data.vcpus
                }elseif ($data.sku -like "Developer"){
                    $subtotal.developer += $data.vcpus             
                }elseif ($data.sku -like "Express"){
                    $subtotal.express += $data.vcpus
                }
            }
        }
    }
    
    # Increment the totals and add subtotals to the usage array
    foreach( $property in $subtotal.psobject.properties.name ){
        $total.$property += $subtotal.$property
    }
    if ($ec -eq $null){
        $usage += ,(@($sub.Name, $sub.Id, $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express))
    }else{
        $usage += ,(@($sub.Name, $sub.Id, ($subtotal.ahb_std + $subtotal.ahb_ent*4), ($subtotal.payg_std + $subtotal.payg_ent*4), $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express))
    }
}

if ($ec -eq $null){
        $usage += ,(@("Total", $null, $total.ahb_std, $total.ahb_ent, $total.payg_std, $total.payg_ent, $total.hadr_std, $total.hadr_ent, $total.developer, $total.express))
}else{
        $usage += ,(@("Total", $null, ($total.ahb_std + $total.ahb_ent*4), ($total.payg_std + $total.payg_ent*4), $total.ahb_std, $total.ahb_ent, $total.payg_std, $total.payg_ent, $total.hadr_std, $total.hadr_ent, $total.developer, $total.express))
}

$table = ConvertFrom-Csv ($usage | %{ $_ -join ','} ) 
$table | Format-table
$fileName = '.\sql-license-usage_' + (Get-Date -f yyyy-MM-dd_HH-mm-ss) + '.csv'
$table | Export-Csv .\sql-license-usage.csv -NoTypeInformation

Write-Host ([Environment]::NewLine + "-- The usage data is saved to .\sql-license-usage.csv")
