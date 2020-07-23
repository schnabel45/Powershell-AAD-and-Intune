# Powershell for Automating Azure Active Directory and Intune Management
Collection of PowerShell scripts I've written to make managing Intune more bearable.

## New-BatchedAzureADMSGroup.ps1
### Summary
This script is used to create batches of Dynamic groups in Azure AD. 

Dynamic groups are restricted to query length, so when wanting to create a 
large querry this script will break it up into multiple groups.

### Use Case Example
I have devices in Apple School Manager (similar to Apple Business Manager) which will be enrolled with non-user 
affinity in a supervised mannor. When these devices are enrolled, I apply a naming template 
```{{DEVICETYPE}}-{{SERIAL}}```. I would like to have these devices automatically pull configuration and compliance 
profiles as soon as they are past the iOS setup screen.

Rather than relying on device categories, I rely on nested Azure AD Groups. With this script I can create dynamic 
querry groups which are based on the device Display Name. For example, my querry in this case would be

```(device.DispalyName -in ["iPhone-123", "iPhone-456"])```

With this script I can automatically optomize the number of Dynamic groups required to capture all devices I'm looking 
to enroll. For a batch of approximately 700 iphones, my script created 6 dynamic groups with up to 137 devices in each.

As an added bonus, the script will automatically nest the newly created groups in a parent group I specify. This 
enables me to have a single group containing all of the devices dynamically.

### Notes
The Query Template must include ```{QuerryArray}``` in the string. This is replaced with the dynamic json-ified array 
of objects for the group.
The group name prefix should include ```{Number}``` in the string. If this is not included, it will be automatically 
appended to the end of the string.

### Example
```powershell
$deviceNames = @("iPhone-123", "iPhone-456") #obviously this is just a test list
$queryTemplate = "(device.DisplayName -in {QuerryArray})"
$groupNamePrefix = "Intune_Device_DynamicGroup_Test-Batch{Number}"
$parentGroupObjectID = "00000000-0000-0000-0000-000000000000"

New-BatchedAzureADMSGroup.ps1 -QuerryArray $deviceNames `
    -QueryTemplate $queryTemplate`
    -DynamicGroupNameTemplate $groupNamePrefix`
    -ParentGroupObjectID $parentGroupObjectID
```