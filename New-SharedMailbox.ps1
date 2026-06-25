# HELPER FUNCTIONS #
# separate those helper functions tha are not using AD cmdlets to distinct files
# to keep main script maximum clear and simple

# Script parameter for a path to the OU where created Shared Mailboxes and Access Groups will be located
param(
    [string]$OUPath = "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
)

# IMPORTED FUNCTIONS #
. ".\Show-ArrowMenu.ps1"
. ".\Manage-ADGroupMembers.ps1"

# Helper functions
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
$domainRoot = (Get-ADDomain -Current LoggedOnUser).DNSRoot
$YesNo = @(
    "YES",
    "NO"
)

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

    Write-IndentHost ""
    Write-IndentHost "Welcome in the Shared Mailbox Creator!"
    Write-IndentHost ""
    Write-IndentHost "To create a Shared Mailbox, you need to provide a name for an AD account"
    Write-IndentHost "that will get the role of the Shared Mailbox."
    Write-IndentHost ""
    Write-IndentHost "Name has to be at least 5 or at most 20 characters long"
    Write-IndentHost "and can contain only letters (upper or lowercase) or numbers"
    Write-IndentHost "and a three special signs: underscore (_), dash (-) and dot (.)"

    $userExist = $true
    do {
        Write-IndentHost ""
        Write-IndentHost "For what department do you want to create a shared mailbox?"
        $name = (Read-IndentHost "Type name").ToLower()

        try {
            $isMatch = Approve-Name -Name $name

            if ($isMatch) {
                Write-IndentHost "Name meet requirements" -BackgroundColor Green -ForegroundColor White

                $upnToCheck = "sm_$name@$domainRoot"
                $samToCheck = "sm_$name"
                $existingUser = Get-ADUser -Filter "sAMAccountName -eq '$samToCheck' -or UserPrincipalName -eq '$upnToCheck'"

                if ($existingUser -ne $null) {
                    Write-IndentHost "Shared Mailbox account with this name already exists in the database!"  -BackgroundColor Yellow -ForegroundColor Black
                    Write-IndentHost "Choose other name for a new Shared Mailbox Account"
                } else {
                    Write-IndentHost "Shared Mailbox Account with this name doesn't exist in the database" -BackgroundColor Yellow -ForegroundColor Black
                    $userExist = $false
                }

            } else {
                Write-IndentHost "Name doesn't meet requirements" -BackgroundColor Red -ForegroundColor White
                Write-IndentHost "Name has to be at least 5 or at most 20 characters long"
                Write-IndentHost "and can contain only letters (upper or lowercase) or numbers"
                Write-IndentHost "and a three special signs: underscore (_), dash (-) and dot (.)"
            }
        }
        catch {
            Write-IndentHost "No input passed" -BackgroundColor Red -ForegroundColor White

        }

    } until (-not $userExist)

    
    while ($true) {
        Write-IndentHost "To create Shared Mailbox Account, provide password"
        Write-IndentHost ""
        Write-IndentHost "======================================================================"
        Write-IndentHost "                  PASSWORD COMPLEXITY REQUIREMENTS                    "
        Write-IndentHost "======================================================================"
        Write-IndentHost "To provision the account, the password MUST meet the following rules:`n"
        Write-IndentHost " 1. Minimum length: 7 characters (14 recommended for production)"
        Write-IndentHost " 2. Must contain characters from at least 3 of these groups:"
        Write-IndentHost "- Uppercase letters (A-Z)"
        Write-IndentHost "- Lowercase letters (a-z)"
        Write-IndentHost "- Base 10 digits (0-9)"
        Write-IndentHost "- Non-alphanumeric characters (e.g. !, @, #, $, %)"
        Write-IndentHost " 3. Cannot contain the account name (sm_$name) or department name."
        Write-IndentHost "======================================================================"

        $password = Read-Password "Type password"

            # Variables for Account and Group Parameters
            $titleName = (Get-Culture).TextInfo.ToTitleCase($name)
            $samName = "sm_$name"
            $fullName = "Shared Mailbox"
            $SMGroupName = "sg_sm_${name}_access"

            $AccoutParams = @{
                Name = "$titleName $fullName"
                SamAccountName = $samName
                UserPrincipalName = "$samName@$domainRoot"
                DisplayName = "$fullName - $titleName"
                AccountPassword = $password
                Enabled = $false
                ChangePasswordAtLogon = $false
                Path = $OUPath
                Description = "Shared Mailbox for '$titleName' department, created by Shared Mailbox Creator."

            }

            $GroupParams = @{
                Name = $SMGroupName
                DisplayName = "Security Group - SM - $titleName - Access"
                GroupScope = "Global"
                GroupCategory = "Security"
                Path = $OUPath
                Description = "Access group for the $titleName Shared Mailbox. Created via automation script."
            }

            # try/catch to catch and display errors from New-ADUser or New-ADGroup
            try {
                Write-IndentHost "Creating $fullName account for '$titleName' department..."
                New-ADUser @AccoutParams -ErrorAction Stop
                $newAccount = Get-ADUser -Identity "sm_$name"
                Write-IndentHost "$fullName account for '$titleName' department created successfully!" -BackgroundColor Green -ForegroundColor White

                Write-IndentHost "Creating access group for '$fullName - $titleName'..."
                New-ADGroup @GroupParams
                Write-IndentHost "Access group for '$fullName - $titleName' account created successfully!" -BackgroundColor Green -ForegroundColor White
                break
            }
            catch {
                $ExceptionType = $_.Exception.GetType().FullName
                $ExceptionMessage = $_.Exception.Message
                Write-IndentHost "ERROR: Failed to provision Shared Mailbox infrastructure" -BackgroundColor Red -ForegroundColor White
                Write-IndentHost "Reason: $ExceptionMessage" -BackgroundColor Red -ForegroundColor White
                Write-IndentHost "Type: $ExceptionType"  -BackgroundColor Red -ForegroundColor White
                Remove-ADUser -Identity $samName -Confirm:$false -ErrorAction SilentlyContinue

                if ($ExceptionType -eq "Microsoft.ActiveDirectory.Management.ADPasswordComplexityException") {
                    continue
                } else {
                    Write-IndentHost "Please contact your Enterprise Administrator to resolve this issue." -BackgroundColor Yellow -ForegroundColor Black
                }
            
            exit
            }
        }

    try {
        $ADGroupObject = Get-ADGroup -Identity $titleName -ErrorAction Stop
        $ADGroupName = (Get-ADGroup -Identity $titleName).Name
        $groupExists = $true
    }
    catch {
        $groupExists = $false
    }
    
    if ($groupExists) {
        $FoundMessage = {
        Write-IndentHost "Found a group in Active Directory that has the name`n`tof the deparment you wish to create Shared Mailbox for."
        Write-IndentHost "Do you wish to add the users of the group '$ADGroupName' to the`n`taccess group '$SMGroupName' for '$titleName $fullName' account?"
        }
        
        Start-Sleep -Seconds 3
        $OptionIndex = Show-ArrowMenu -Menu $YesNo -Title "Notice" -Message $FoundMessage
        Write-IndentHost ""

        switch ($OptionIndex) {
            0 {
                # YES OPTION
                Add-ADGroupMember -Identity $SMGroupName -Members $ADGroupObject
                Write-IndentHost "Group '$ADGroupName' add to the '$SMGroupName'!" -BackgroundColor Green -ForegroundColor White
            }
            1 {
                # NO OPTION
                Write-IndentHost "Moving to the main menu"
            }
        }
    }
    
    Manage-ADGroupMembers -OUPath $OUPath -Group $SMGroupName

$condition = $false
}

Write-IndentHost "Program executed!" -BackgroundColor Blue -ForegroundColor White