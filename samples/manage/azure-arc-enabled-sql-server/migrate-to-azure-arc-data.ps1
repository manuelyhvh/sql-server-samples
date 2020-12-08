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
#  Sample script for migrating the existing SQL Server - Azure Arc resources from Microsoft.AzureData namespace to Microsoft.AzureArcData namespace 
#  within a single Resource Group
#

$ResourceGroup=read-host -Prompt "Enter Resource Group Name"

$SqlArcResources = Get-AzResource -ExpandProperties -ResourceType Microsoft.AzureData/sqlServerInstances -ResourceGroupName $ResourceGroup
foreach ($r in $SqlArcResources) {
    if( $null -ne $r.Properties.tcpPorts ){
        Write-Warning "The property `"tcpPorts`" has been renamed to `"tcpStaticPorts`". The property name will be updated during resource migration."
        $r.Properties | Add-Member -MemberType NoteProperty -Name "tcpStaticPorts" -Value $r.Properties.tcpPorts
        $r.Properties.psobject.properties.remove("tcpPorts")
    }

    if( $null -ne $r.Properties.createTime ){
        Write-Warning "There is a known bug in the createTime property. This property will be removed during resource migration."
        $r.Properties.psobject.properties.remove("createTime")
    }

    New-AzResource -ResourceName $r.Name -Location $r.Location -Properties $r.Properties -ResourceGroupName $r.ResourceGroupName `
        -ResourceType Microsoft.AzureArcData/sqlServerInstances -Force
}

Write-Host "Namespace migration completed for SQL Server - Azure Arc resources."

