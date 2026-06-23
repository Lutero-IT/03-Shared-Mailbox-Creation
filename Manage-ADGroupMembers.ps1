function Manage-ADGroupMembers {
    param(
        [string]$OUPath = "",
        [string]$Group = ""
    )

    # IMPORTED FUNCTIONS #
    . ".\Show-ArrowMenu.ps1"

    # GLOBAL VARIABLES #
    $Indent = "`t"
    $groupName = $Group
    $membersList = Get-ADGroupMember -Identity $groupName | Select-Object Name -ExpandProperty Name

    # WRAPPER FUNCTIONS #
    $Indent = "`t"
    function Write-IndentHost ([string]$Message) {
        Write-Host "${Indent}$Message" @Args
        Write-Host ""
    }

    function Read-IndentHost ([string]$Message) {
        Read-Host -Prompt "${Indent}$Message"
        Write-IndentHost ""
    }

    # GLOBAL PREDIFINIED WHITELISTS #
    $yesList = "yes y"-split" "
    $noList = "no n"-split" "

    # STARTING MENU #
    $WelcomeMessage = {
        Write-Host ""
        Write-IndentHost "Welcome in the Access Group menu for '$fullName - $titleName'!"
        Write-IndentHost "Here you can add or remove members or entire groups to the '$SMGroupName' group"
        Write-IndentHost "or you can change the currently managed group to the other access group"
        Write-Host ""
        Write-IndentHost "Choose one of the available options below"
    }


        # Here make the logic for add and remove members from the access group
        # how to change to other access group?


    while ($true) {
        # add -group parameter back to the show-arrowmenu or create another function
        
        $title = "Access Group Manager"
        $menu = @(
            "Add Members",
            "Remove Members",
            "Add Group",
            "Remove Group"
            "Change Access Group"
            "Exit"
        )

        Start-Sleep -Seconds 3
        $optionIndex = Show-ArrowMenu -Menu $menu -Title $title -Group $groupName -Message $WelcomeMessage

        switch ($optionIndex) {
            # OPTION 1 - ADD MEMBER #
            0 {
                Write-Host ""
                Write-IndentHost "Chose Option 1 - Add Members" -BackgroundColor Yellow -ForegroundColor Black
                Write-Host ""

                # USER VALIDATION LOOP #
                $addMember = $true
                while ($addMember) {

                    Write-IndentHost "Provide a member or members you wish to add to the '$groupName' group"
                    Write-IndentHost "(if you want to add multiple members, separate them with a comma)"
                    Write-IndentHost "or type [Cancel/C] if you want to cancel operation (case insensitive)"
                    $username = Read-IndentHost "Type username "

                    $usersList = $username.Split(",").Trim()

                    if ($usersList.Length -eq 0) {
                        Write-IndentHost "No input passed" -BackgroundColor Red -ForegroundColor White
                    }  elseif ( ($username -eq "cancel") -or ($username -eq "c") ) {
                        Write-IndentHost "Removing user canceled" -BackgroundColor Yellow -ForegroundColor Black
                        $addMember = $false # finishes user validation loop after the loop reaches end #
                    } else {
                        foreach ($user in $usersList) {
                            if ($user -in $membersList) {                                
                                $Indent
                                Write-IndentHost "'$user' is already a member of '$groupName' group!"  -BackgroundColor Yellow -ForegroundColor Black
                                Write-IndentHost "Processing to the next user on the list..."
                                $Indent
                            } else {
                                try {
                                    Get-ADUser -Identity $user -ErrorAction Stop | Out-Null
                                    Write-IndentHost "'$user' found in Active Directory database!"  -BackgroundColor Green -ForegroundColor White
                                    Write-IndentHost "Are you sure you want to add '$user' to the '$groupName' group?"
                                    $decision = Read-IndentHost "Type [Yes/y] or [No/n]"

                                    if ($decision -in $yesList) {
                                        Write-IndentHost "Adding '$user' to the '$groupName' group..."  -BackgroundColor Yellow -ForegroundColor Black
                                        try {
                                            Add-ADGroupMember -Identity $groupName -Members $user -ErrorAction Stop
                                            
                                            $Indent
                                            Write-IndentHost "Adding member completed sucessfully!" -BackgroundColor Green -ForegroundColor White
                                        } catch {
                                            Write-IndentHost "CRITICAL: Failed to add '$user'. Verify your AD permissions." -BackgroundColor Red -ForegroundColor White
                                        }
                                        $Indent
                                    } elseif ($decision -in $noList) {
                                        Write-IndentHost "Adding user canceled" -BackgroundColor Yellow -ForegroundColor Black
                                    } else {
                                        Write-IndentHost "Passed Invalid value!" -BackgroundColor Red -ForegroundColor White
                                        Write-IndentHost "User joining aborted"
                                    }
                                } catch {
                                    $Indent
                                    Write-IndentHost "'$user' not found in Active Directory database!"  -BackgroundColor Red -ForegroundColor White
                                    Write-IndentHost "Processing to the next user on the list..."
                                    $Indent
                                }
                            }  
                        }
                        Write-IndentHost "No more users left to add"
                        $addMember = $false

                    } # closes the 'else' statement if input is provided for add member option
                } # closes the add member validation 'while' loop
            } # closes the 'switch' (0) option - Add Member
        } # closes the main menu 'switch' statement
    } # closes the main 'while' loop
} # closes the function 'Manage-ADGroupMembers'