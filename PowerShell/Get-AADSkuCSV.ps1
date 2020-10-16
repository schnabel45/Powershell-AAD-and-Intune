<#
.SYNOPSIS
    Get a list of package Skus from Azure AD along with consumed and total license counts.
.NOTES
    Must be connected to Azure AD already.
    Returns a CSV.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $ExportAsCSV
)

$skus = Get-AzureADSubscribedSku | `
    Select-Object ObjectId, SkuPartNumber, SkuId, ConsumedUnits, `
        @{N="PurchasedUnits";E={$_.PrepaidUnits.Enabled}}
        
if($ExportAsCSV){ return $skus | ConvertTo-Csv -NoTypeInformation}
return $skus