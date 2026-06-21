Write-Host "Provide name for a Shared Mailbox account"
$name = Read-Host -Prompt "Type name"

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