#Requires -Module AzureADPreview
<#
.SYNOPSIS
    Create a batch of dynamic groups with queries under the character maximums.
.DESCRIPTION
    AzureAD Dynamic group membership rules have an arbitrary limit of 3072 characters as determined in trial and error 
    testing. This script will take a larget list of identifiers, a rule, a group name prefix, and optionally an 
    assigned group name to nest into, then batch the identifiers and create individual dynamic groups.
.EXAMPLE
    PS C:\> New-BatchDynamicGroup.ps1 -QuerryArray $devices 
        -QueryTemplate "(deviceName -in {QuerryArray})"
        -DynamicGroupNameTemplate "Intune_Devices_DynamicGroup_Batch-Name-{Number}"
        -ParentGroupObjectID 00000000-0000-0000-0000-000000000000
    The above command takes an array of objects to put into the dynamic querry, then creates the nesscesary number of 
    dynamic groups to fit the entire batch. Each of these are then nested into the given parent group.
    For example, given inputs
        QueryTemplate = "(deviceName -in {QuerryArray})"
        QuerryArray = @("iPhone-123", "iPhone-456", "iPad-AAA")
        DynamicGroupNameTemplate = "Intune_Device_DynamicGroup_Test-Batch{Number}"
    The script will create a dynamic group named Intune_Device_DynamicGroup_Test-Batch1 with a dynamic querry of
        "(deviceName -in ["iPhone-123","iPhone-456","iPad-AAA"])"
.INPUTS
    QuerryArray = string array of querry items
    QueryTemplate = the query format, must have {QuerryArray} where the array of items is placed, non-negotiable.
    DynamicGroupNameTemplate = Name template for the new dynamic groups. Must have {Number} for the batch ID, otherwise 
        it will be appended to the end of the name.
    ParentGroupObjectID = If chosen, the dynamic groups can be nested into a parent group. Not mandatory.
.OUTPUTS
    None
.NOTES
    This script assumes you have already signed into Azure AD.
    This script is better used when you are managing large numbers of items in the array. Depending on the length of 
        each item in the array, this number could be small or large. For the example above where all items in the array 
        are of the form {{DeviceType}}-{{SerialNumber}} I can typically fit about 137 items.
#>

[CmdletBinding()]
param (
    # List of items which will be in the array of the dynamic rule
    [Parameter(Mandatory=$true)]
    [string[]]
    $QuerryArray,
    # Dynamic query template
    [Parameter(Mandatory=$true)]
    [string]
    $QueryTemplate,
    # Group Name Prefix template
    [Parameter(Mandatory=$true)]
    [string]
    $DynamicGroupNameTemplate,
    # Parent Group ObjectID
    [string]
    $ParentGroupObjectID
)

$MaximumRuleLength = 3072

# Validate templates have the appropriate variables
if(-not $QueryTemplate.Contains("{QuerryArray}")){
    Write-Error -Exception "The querry template must include the string {QuerryArray}." -ErrorAction Stop
}

if(-not $DynamicGroupNameTemplate.Contains("{Number}")){
    Write-Warning -Message "{Number} has been appended to DynamicGroupNameTemplate"
    $DynamicGroupNameTemplate = $DynamicGroupNameTemplate + "-{Number}"
}

# Process
$currentBatchNumber = 0
$itemsPerBatch = 1
$lastBatch = $false
$querryTemplateLength = $QueryTemplate.Replace("{QuerryArray}", "").Length
for($i = 0; $i -lt $QuerryArray.Length;){
    # Check if there are less than itemsPerBatch items remaining
    if($i + $itemsPerBatch -gt $QuerryArray.Length){
        # This is the last batch, just grab all remaining items
        $itemsPerBatch = $QuerryArray.Length - $i
        $lastBatch = $true
    }
    # Create the array based on what was previously found
    $batchArray = $QuerryArray[$i..($i + $itemsPerBatch)] | ConvertTo-Json -Compress
    while((-not $lastBatch) -and ($batchArray.Length + $querryTemplateLength -lt $MaximumRuleLength)){
        # Assume we're under the character limit, recreate the array with one more item
        $itemsPerBatch++
        $batchArray = $QuerryArray[$i..($i + $itemsPerBatch)] | ConvertTo-Json -Compress
    }
    while(($batchArray.Length + $querryTemplateLength -gt $MaximumRuleLength)){
        # Now go the opposite way in case we over-shot until the array is below the character count
        $itemsPerBatch--
        $batchArray = $QuerryArray[$i..($i + $itemsPerBatch)] | ConvertTo-Json -Compress
    }
    # We found the appropriate number of items for the array, re-index $i for the next run
    $i = $i + $itemsPerBatch

    # Form the Dynamic Query
    $batchQuerry = $QueryTemplate.Replace("{QuerryArray}", $batchArray)
    Write-Output $("Batch ID: " + $currentBatchNumber)
    Write-Output $("`tQuery Length  : " + $batchQuerry.Length)
    Write-Output $("`tItems in array: " + $itemsPerBatch)
    Write-Output $("`tCurrent Index : " + $i)

    # Create the new group
    $groupName = $DynamicGroupNameTemplate.Replace("{Number}", $currentBatchNumber+1)
    Write-Output $("`tGroup Name: " + $groupName)
    $newGroup = New-AzureADMSGroup -DisplayName $groupName `
        -MailEnabled $false `
        -MailNickname $groupName `
        -SecurityEnabled $true `
        -GroupTypes "DynamicMembership" `
        -MembershipRule $batchQuerry `
        -MembershipRuleProcessingState "On"
    Write-Output $("`tGroup ID: " + $newGroup.ID)

    # Add to Parent Group if needed
    if($ParentGroupObjectID){
        Add-AzureADGroupMember -ObjectId $ParentGroupObjectID -RefObjectId $newGroup.ID
    }

    $currentBatchNumber++
}