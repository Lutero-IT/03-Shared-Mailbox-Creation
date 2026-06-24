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

    $mainLoop = $true
    while ($mainLoop) {
        # add -group parameter back to the show-arrowmenu or create another function
        
        $title = "Access Group Manager"
        $menu = @(
            "Add Members",
            "Remove Members",
            "Show Group Members",
            "Add Group",
            "Remove Group",
            "Exit"
        )

        Start-Sleep -Seconds 3
        $optionIndex = Show-ArrowMenu -Menu $menu -Title $title -Group $groupName -Message $WelcomeMessage

        switch ($optionIndex) {
            0 { # OPTION 1 - ADD MEMBERS #
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

                        $membersList = Get-ADGroupMember -Identity $groupName | Select-Object Name -ExpandProperty Name
                        $addMember = $false

                    } # closes the 'else' statement if input is provided for add member option
                } # closes the add member validation 'while' loop
            } # closes the 'switch' (0) option - Add Member


            1 { # OPTION 2 - REMOVE MEMBERS #
                Write-Host ""
                Write-IndentHost "Chose Option 2 - Remove Members" -BackgroundColor Yellow -ForegroundColor Black
                Write-Host ""

                $removeLoop  = $true
                while ($removeLoop) {
                        
                    # REMOVE MENU #
                    $optionsList = @(
                        "1. List Group Members ",
                        "2. Type Username ",
                        "3. Back to Main Menu "
                    )

                    $optionIndex = Show-ArrowMenu -Title "Remove Menu" -Group $groupName -Menu $optionsList

                    switch ($optionIndex) {
                        0 {
                            
                            Write-IndentHost "| '$groupName' group Members: |"
                            Write-Host ""
                            if ($membersList -eq $null) {
                                Write-IndentHost "This group has no members!" -BackgroundColor Yellow -ForegroundColor Black
                            } else {
                                $membersList | ForEach-Object -Process {
                                        Write-IndentHost "* $_"
                                    }
                            }
                            Write-IndentHost ""
                            Read-IndentHost "Press 'Enter' to go back to the Remove Menu"
                        }
                        
                        1 {
                            # USER VALIDATION LOOP #
                            $removeLoop2 = $true
                            while ($removeLoop2) {

                                Write-IndentHost "Provide a member or members of the '$groupName' group you wish to remove"
                                Write-IndentHost "(if you want to remove multiple members, separate them with a comma)"
                                Write-IndentHost "or type [Cancel/C] if you want to cancel operation (case insensitive)"
                                $username = Read-IndentHost "Type username "

                                $usersList = $username.Split(",").Trim()

                                if ($usersList.Length -eq 0) {
                                    Write-IndentHost "No input passed" -BackgroundColor Red -ForegroundColor White
                                } elseif ( ($username -eq "cancel") -or ($username -eq "c") ) {
                                    Write-IndentHost "Removing user canceled" -BackgroundColor Yellow -ForegroundColor Black
                                    $removeLoop2 = $false
                                } else {
                                    foreach ($user in $usersList) {
                                        if ($user -in $membersList) {                                
                                            $Indent
                                            Write-IndentHost "'$user' is a member of '$groupName' group!"  -BackgroundColor Green -ForegroundColor White
                                            $Indent
                                            Write-IndentHost "Are you sure you want to remove '$user' from the '$groupName' group?"
                                            $decision = Read-IndentHost "Type [Yes/y] or [No/n]"

                                            if ($decision -in $yesList) {
                                                Write-IndentHost "Removing '$user' from the '$groupName' group..."  -BackgroundColor Yellow -ForegroundColor Black
                                                try {
                                                Remove-ADGroupMember -Identity $groupName -Members $user -Confirm:$false -ErrorAction Stop
                                                $Indent
                                                Write-IndentHost "Removing member completed sucessfully!" -BackgroundColor Green -ForegroundColor White
                                                } catch {
                                                Write-IndentHost "CRITICAL: Failed to remove '$user'. Verify your AD permissions." -BackgroundColor Red -ForegroundColor White
                                                }
                                            } elseif ($decision -in $noList) {
                                                Write-IndentHost "Removing user canceled" -BackgroundColor Yellow -ForegroundColor Black
                                            } else {
                                                Write-IndentHost "Passed Invalid value!" -BackgroundColor Red -ForegroundColor White
                                                Write-IndentHost "User removal aborted"
                                            }
                                        } else {
                                            $Indent
                                            Write-IndentHost "'$user' is not a member of '$groupName' group!" -BackgroundColor Red -ForegroundColor White
                                            Write-IndentHost "Processing to the next user on the list..."
                                            $Indent
                                        }

                                    $Indent
                                    Write-IndentHost "No more users left to remove"

                                    $membersList = Get-ADGroupMember -Identity $groupName | Select-Object Name -ExpandProperty Name
                                    $removeLoop2 = $false # breaks user validation loop

                                    } # closes the 'foreach' loop
                                } # closes the 'else' statement
                            } # closes the remove member validation 'while' loop

                        } # closes the (1) option of Remove Member option - Type username

                        2 {
                            Write-IndentHost "Getting back to Main Menu" -BackgroundColor Yellow -ForegroundColor Black
                            $removeLoop2 = $false
                            $removeLoop = $false
                        } # closes the 'switch' (2) option - Back to Main Menu
                    } # closes the remove menu 'switch' statement
                } # closes the 'removeLoop' while loop
            } # closes the 'switch' (1) option - Remove Member

            2 { # OPTION 3 - SHOW GROUP MEMBERS #           
                Write-IndentHost "| '$groupName' group Members: |"
                Write-Host ""
                if ($membersList -eq $null) {
                    Write-IndentHost "This group has no members!" -BackgroundColor Yellow -ForegroundColor Black
                } else {
                    $membersList | ForEach-Object -Process {
                            Write-IndentHost "* $_"
                        }
                }
                Write-IndentHost ""
                Read-IndentHost "Press 'Enter' to go back to the Remove Menu"
                
            } # closes the 'switch' (2) option - Show Group Members

            3 { # OPTION 4 - ADD GROUP #

            } # closes the 'switch' (3) option - Add Group

            4 { # OPTION 5 - REMOVE GROUP #

            } # closes the 'switch' (4) option - Remove Group

            5 { # OPTION 6 - EXIT #
                Write-IndentHost "Chose to exit the program" -BackgroundColor Yellow -ForegroundColor Black
                $mainLoop = $false
                $condition = $false
            } # closes the 'switch' (6) option - Exit

        } # closes the main menu 'switch' statement
    } # closes the main 'while' loop
} # closes the function 'Manage-ADGroupMembers'