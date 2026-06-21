# HELPER FUNCTIONS #
# separate those helper functions tha are not using AD cmdlets to distinct files
# to keep main script maximum clear and simple

function Approve-Name {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $regex = '^[a-zA-Z0-9_\-\.]{5,20}$'
    return ($Name -match $regex)
}

# Pre-flight check for account permissions
$myIdentity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myPrincipal = [System.Security.Principal.WindowsPrincipal]::new($myIdentity)
$isAdmin     = $myPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $condition = $true
} else {
    Write-Host "You don't have rights to create accounts in this Active Directory"
    Write-Host "Contact your administrator"
    $condition = $false
}

while ($condition) {
    Write-Host "Provide name for a Shared Mailbox account"
    do {
        $name = Read-Host -Prompt "Type name"

        try {
            $isMatch = Approve-Name -Name $name

            if ($isMatch) {
                Write-Host "Name meet requirements"

                try {
                    Get-ADUser -Identity $name -ErrorAction Stop | Out-Null
                    Write-Host "User exists in database"
                    Write-Host "Choose other name for a new Shared Mailbox Account"
                    $userExist = $true
                }
                catch {
                    Write-Host "User doesn't exist in database"
                    $userExist = $false
                    $condition = $false
                }

            } else {
                Write-Host "Name doesn't meet requirements"
                Write-Host "Name has to be at least 5 or at most 20 characters long"
                Write-Host "and can contain only letters (upper or lowercase) or numbers"
                Write-Host "and a three special signs: underscore (_), dash (-) and dot (.)"
            }
        }
        catch {
            Write-Host "No input passed"
        }

    } until (-not $userExist)
}


# New-ADUser -Identity $name -ErrorAction Stop --- COMMENTED TO NOT CREATE USERS RIGHT NOW! UNCOMMENT LATER!
# czy moga byc inne błedy niż te wynikająca z tego, że skrypt nie uruchomił administrator?
