# HELPER FUNCTIONS #

function Approve-Name {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $regex = '^[a-zA-Z-0-9_\-\.]{5,20}$'
    return ($Name -match $regex)
}

<#
    For Approve-Name
    Write mechanism that will manage empty input for parameter $Name
    I can use if/else before function to check if $name is null
    or can I do it inside function?
    I could bind CommonParameters and use -ErrorAction and try/catch
    on the Approve-Name function but is it the best way?
    Or simply check the input before calling a function?
#>

Write-Host "Provide name for a Shared Mailbox account"
$name = Read-Host -Prompt "Type name"

try {
    $isMatch = Approve-Name -Name $name
    # I need to get the value from Approve-Name
    # If it is true I pass the name to the Check User
    # If not I ask again for correct input
    if ($isMatch) {
        Write-Host "Name meet requirements"
    } else {
        Write-Host "Name doesn't meet requirements"
        # loop back to the prompt
    }
}
catch {
    Write-Host "No input passed"
}

# Check if user exist in database
try {
    Get-ADUser -Identity $name -ErrorAction Stop | Out-Null
    Write-Host "User exists in database"
    $userExist = $true
}
catch {
    Write-Host "User doesn't exist in database"
    $userExist = $false
}

# Check if operater has permissions to create users
if (-not $userExist) {
    try {
        # New-ADUser -Identity $name -ErrorAction Stop --- COMMENTED TO NOT CREATE USERS RIGHT NOW! UNCOMMENT LATER!
        
        # Create user if have admin permissions
        Write-Host "$name user account created"
    }
    catch {
        Write-Host "You don't have rights to create accounts in this Active Directory"
        Write-Host "Contact your administrator"
        }
}