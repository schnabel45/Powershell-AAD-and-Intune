<#
.SYNOPSIS
    Get a list of package Skus from Azure AD along with consumed and total license counts.
.NOTES
    Must be connected to Azure AD already.
    Returns a CSV.
#>

$skus = Get-AzureADSubscribedSku | `
    Select-Object ObjectId, SkuPartNumber, SkuId, ConsumedUnits, `
        @{N="PurchasedUnits";E={$_.PrepaidUnits.Enabled}} | `
    ConvertTo-Csv -NoTypeInformation

return $skus