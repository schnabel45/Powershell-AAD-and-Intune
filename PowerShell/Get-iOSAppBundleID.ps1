<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]
    $AppID
)

$reqURI = ""
if($AppID -match "^[0-9]{9,10}$"){
    $reqURI = "https://itunes.apple.com/lookup?id=$AppID"
} elseif ($AppID -match "^https:\/\/apps\.apple\.com\/us\/app\/(?'appName'[\S]+)\/id(?'id'[0-9]{9,10})$"){
    $linkAppID = $Matches['id']
    $reqURI = "https://itunes.apple.com/lookup?id=$linkAppID"
} else {
    $errorMessage = "$AppID is not a valid AppID. Must be the 9 digit ID or an iTunes Store Link."
    Write-Error -Message $errorMessage -ErrorAction Stop
}

Write-Output $reqURI

$req = Invoke-RestMethod -Method Post -Uri $reqURI
$bundleID = $req.results[0].bundleId

Write-Output $($req.results[0].trackName + " - " + $bundleID)
$bundleID | Set-Clipboard
Write-Output $("Bundle ID saved to clipboard")