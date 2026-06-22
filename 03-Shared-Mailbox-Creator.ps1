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

$Indent = "`t"
function Write-IndentHost ([string]$Message) {
    Write-Host "${Indent}$Message" @Args
    Write-Host ""
}

function Read-IndentHost ([string]$Message) {
    Read-Host -Prompt "${Indent}$Message"
    Write-IndentHost ""
}

function Read-Password ([string]$Message) {
    Read-Host -Prompt "${Indent}$Message" -AsSecureString
    Write-IndentHost ""
}

# Variables

# Pre-flight check for account permissions
$myIdentity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myPrincipal = [System.Security.Principal.WindowsPrincipal]::new($myIdentity)
$isAdmin     = $myPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $condition = $true
} else {
    Write-IndentHost "You don't have rights to create accounts in this Active Directory"
    Write-IndentHost "Contact your administrator"
    $condition = $false
}

while ($condition) {
    Write-IndentHost "For what department do you want to create a shared mailbox?"
    do {
        $name = (Read-IndentHost "Type name").ToLower()

        try {
            $isMatch = Approve-Name -Name $name

            if ($isMatch) {
                Write-IndentHost "Name meet requirements"

                try {
                    Get-ADUser -Identity "sm_$name" -ErrorAction Stop | Out-Null
                    Write-IndentHost "Shared Mailbox account with this name already exists in the database!"
                    Write-IndentHost "Choose other name for a new Shared Mailbox Account"
                    $userExist = $true
                }
                catch {
                    Write-IndentHost "Shared Mailbox Account with this name doesn't exist in the database"
                    $userExist = $false
                    $condition = $false
                }

            } else {
                Write-IndentHost "Name doesn't meet requirements"
                Write-IndentHost "Name has to be at least 5 or at most 20 characters long"
                Write-IndentHost "and can contain only letters (upper or lowercase) or numbers"
                Write-IndentHost "and a three special signs: underscore (_), dash (-) and dot (.)"
            }
        }
        catch {
            Write-IndentHost "No input passed"
        }

    } until (-not $userExist)

    Write-IndentHost "To create Shared Mailbox Account, provide password"
    # use regex to verify it! what are the standards for a password?

    $password = Read-Password "Type password"

    # Variables for Account and Group Parameters
    $titleName = (Get-Culture).TextInfo.ToTitleCase($name)
    $domainRoot = (Get-ADDomain -Current LoggedOnUser).DNSRoot
    $samName = "sm_$name"
    $fullName = "Shared Mailbox"
    $GroupName = "sg_sm_${name}_access"

    $AccoutParams = @{
        Name = "$titleName $fullName"
        SamAccountName = $samName
        UserPrincipalName = "$samName@$domainRoot"
        DisplayName = "$fullName - $titleName"
        AccountPassword = $password
        Enabled = $false
        ChangePasswordAtLogon = $false
        Path = "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
        Description = "Shared Mailbox for '$titleName' department, created by Shared Mailbox Creator."

    }

    $GroupParams = @{
        Name = $GroupName
        DisplayName = "Security Group - SM - $titleName - Access"
        GroupScope = "Global"
        GroupCategory = "Security"
        Path = "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
        Description = "Access group for the $titleName Shared Mailbox. Created via automation script."
    }

    # try/catch to catch and display errors from New-ADUser or New-ADGroup
    try {
        New-ADUser @AccoutParams -ErrorAction Stop
        $newAccount = Get-ADUser -Identity "sm_$name"
        Write-IndentHost "$fullName for '$titleName' department created successfully!"

        New-ADGroup @GroupParams
        Write-IndentHost "Access group for '$fullName - $titleName' created successfully!"
    }
    catch {
        Write-IndentHost "ERROR: Failed to provision Shared Mailbox infrastructure" -BackgroundColor Red -ForegroundColor White
        Write-IndentHost "Reason: $($_.Exception.Message)"
        Remove-ADUser -Identity $samName -Confirm:$false -ErrorAction SilentlyContinue
    }

    # Add-ADGroupMember -Identity $GroupName -Members
    # napisać pętle która dodaje członkó danej grupy. np 'Shadows'
    # PO COMMICIE New-ADGroup !!!

}
