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
            "Add Members or Groups",
            "Remove Members or Groups",
            "Show Group Members",
            "Exit"
        )

        Start-Sleep -Seconds 3
        $optionIndex = Show-ArrowMenu -Menu $menu -Title $title -Group $groupName -Message $WelcomeMessage

        switch ($optionIndex) {
            0 { # OPTION 1 - ADD MEMBERS #
                Write-Host ""
                Write-IndentHost "Chose Option 1 - Add Members" -BackgroundColor Yellow -ForegroundColor Black
                Write-Host ""

                # object VALIDATION LOOP #
                $addMember = $true
                while ($addMember) {

                    Write-IndentHost "Provide members or groups you wish to add to the '$groupName' group"
                    Write-IndentHost "(if you want to add multiple members/groups separate them with a comma)"
                    Write-IndentHost "or type [Cancel/C] if you want to cancel operation (case insensitive)"
                    $ObjectName = Read-IndentHost "Type object name "

                    $ObjectsList = $ObjectName.Split(",").Trim()

                    if ($ObjectsList.Length -eq 0) {
                        Write-IndentHost "No input passed" -BackgroundColor Red -ForegroundColor White
                    }  elseif ( ($ObjectName -eq "cancel") -or ($ObjectName -eq "c") ) {
                        Write-IndentHost "Adding object canceled" -BackgroundColor Yellow -ForegroundColor Black
                        $addMember = $false # finishes object validation loop after the loop reaches end #
                    } else {
                        :ObjectLoop foreach ($object in $ObjectsList) {

                            $ObjectType = (Get-ADObject -Filter "Name -eq '$object'").ObjectClass

                            if ($object -in $membersList) {                                
                                $Indent
                                Write-IndentHost "'$object' is already a member of '$groupName' group!"  -BackgroundColor Yellow -ForegroundColor Black
                                Write-IndentHost "Processing to the next object on the list..."
                                $Indent
                            } else {
                                # HERE THE PROBLEM WITH NON-EXISTEN OBJECTS !!!
                                # the problem is that -Filter parameter of the 'Get-ADObject' cmdlet doesnt return error

                                $SearchObject = Get-ADObject -Filter "Name -eq '$object'"
                                if ($SearchObject -eq $null) {
                                    $Indent
                                    Write-IndentHost "'$object' not found in Active Directory database!"  -BackgroundColor Red -ForegroundColor White
                                    Write-IndentHost "Processing to the next object on the list..."
                                    $Indent
                                    
                                    Start-Sleep -Seconds 1
                                } else {
                                    switch ($ObjectType) {
                                        "user" {
                                            $ObjectMessage = {
                                            Write-IndentHost "'$object' found in Active Directory database!"  -BackgroundColor Green -ForegroundColor White

                                            Write-Indent "The passed object type is of a '" -NoNewLine
                                            Write-Host "USER" -ForegroundColor Black -BackgroundColor Yellow  -NoNewline
                                            Write-Host "' type"

                                            Write-IndentHost "Are you sure you want to add '$object' to the '$groupName' group?"
                                            }
                                            $ObjectTitle = "Confirm"
                                        }
                                        "group" {
                                            $ObjectMessage = {
                                            Write-IndentHost "'$object' found in Active Directory database!"  -BackgroundColor Green -ForegroundColor White

                                            Write-Indent "The passed object type is of a '" -NoNewLine
                                            Write-Host "GROUP" -ForegroundColor Black -BackgroundColor Yellow  -NoNewline
                                            Write-Host "' type"
                                            
                                            Write-IndentHost "Are you sure you want to add the entire group to the '$SMGroupName' access group?"
                                            Write-IndentHost "This will result in adding ALL users inside that group, which may present"
                                            Write-IndentHost "a security risk if you are not certain who the members of the group are."
                                            }
                                            $ObjectTitle = "Warning"
                                        }
                                    }

                                    Start-Sleep -Seconds 3
                                    $OptionIndex = Show-ArrowMenu -Menu $YesNo -Title $ObjectTitle -Message $ObjectMessage
                                    Write-IndentHost ""

                                    switch ($OptionIndex) {
                                        0 {
                                            Write-IndentHost "Adding '$object' to the '$groupName' group..."  -BackgroundColor Yellow -ForegroundColor Black
                                            try {
                                                Add-ADGroupMember -Identity $groupName -Members $object -ErrorAction Stop
                                                
                                                $Indent
                                                Write-IndentHost "Adding member completed sucessfully!" -BackgroundColor Green -ForegroundColor White
                                            } catch {
                                                Write-IndentHost "CRITICAL: Failed to add '$object'. Verify your AD permissions." -BackgroundColor Red -ForegroundColor White
                                            }
                                            $Indent
                                        }
                                        1 {
                                            # NO OPTION
                                            Write-IndentHost "Adding object canceled" -BackgroundColor Yellow -ForegroundColor Black
                                            Write-IndentHost "Processing to the next object on the list..."
                                            continue :ObjectLoop # start loop from the beginning on the next AD object from the list
                                        }
                                    } # closes $OptionIndex 'switch'
                                } # closes 'if/else' statement for Get-ADObject cmdlet
                            } # closes 'if/else' statement for $object in $membersList
                        } # closes :ObjectLoop foreach

                        Write-IndentHost "No more objects left to add"
                        Read-IndentHost "Press 'Enter' to go back to the Remove Menu"

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
                        "2. Type ObjectName ",
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
                            # object VALIDATION LOOP #
                            $removeLoop2 = $true
                            while ($removeLoop2) {

                                Write-IndentHost "Provide a member or members of the '$groupName' group you wish to remove"
                                Write-IndentHost "(if you want to remove multiple members, separate them with a comma)"
                                Write-IndentHost "or type [Cancel/C] if you want to cancel operation (case insensitive)"
                                $ObjectName = Read-IndentHost "Type ObjectName "

                                $ObjectsList = $ObjectName.Split(",").Trim()

                                if ($ObjectsList.Length -eq 0) {
                                    Write-IndentHost "No input passed" -BackgroundColor Red -ForegroundColor White
                                } elseif ( ($ObjectName -eq "cancel") -or ($ObjectName -eq "c") ) {
                                    Write-IndentHost "Removing object canceled" -BackgroundColor Yellow -ForegroundColor Black
                                    $removeLoop2 = $false
                                } else {
                                    foreach ($object in $ObjectsList) {
                                        if ($object -in $membersList) {                                
                                            $Indent
                                            Write-IndentHost "'$object' is a member of '$groupName' group!"  -BackgroundColor Green -ForegroundColor White
                                            $Indent
                                            Write-IndentHost "Are you sure you want to remove '$object' from the '$groupName' group?"
                                            $decision = Read-IndentHost "Type [Yes/y] or [No/n]"

                                            if ($decision -in $yesList) {
                                                Write-IndentHost "Removing '$object' from the '$groupName' group..."  -BackgroundColor Yellow -ForegroundColor Black
                                                try {
                                                Remove-ADGroupMember -Identity $groupName -Members $object -Confirm:$false -ErrorAction Stop
                                                $Indent
                                                Write-IndentHost "Removing member completed sucessfully!" -BackgroundColor Green -ForegroundColor White
                                                } catch {
                                                Write-IndentHost "CRITICAL: Failed to remove '$object'. Verify your AD permissions." -BackgroundColor Red -ForegroundColor White
                                                }
                                            } elseif ($decision -in $noList) {
                                                Write-IndentHost "Removing object canceled" -BackgroundColor Yellow -ForegroundColor Black
                                            } else {
                                                Write-IndentHost "Passed Invalid value!" -BackgroundColor Red -ForegroundColor White
                                                Write-IndentHost "object removal aborted"
                                            }
                                        } else {
                                            $Indent
                                            Write-IndentHost "'$object' is not a member of '$groupName' group!" -BackgroundColor Red -ForegroundColor White
                                            Write-IndentHost "Processing to the next object on the list..."
                                            $Indent
                                        }

                                    $Indent
                                    Write-IndentHost "No more objects left to remove"

                                    $membersList = Get-ADGroupMember -Identity $groupName | Select-Object Name -ExpandProperty Name
                                    $removeLoop2 = $false # breaks object validation loop

                                    } # closes the 'foreach' loop
                                } # closes the 'else' statement
                            } # closes the remove member validation 'while' loop

                        } # closes the (1) option of Remove Member option - Type ObjectName

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

            3 { # OPTION 6 - EXIT #
                Write-IndentHost "Chose to exit the program" -BackgroundColor Yellow -ForegroundColor Black
                $mainLoop = $false
                $condition = $false
            } # closes the 'switch' (6) option - Exit

        } # closes the main menu 'switch' statement
    } # closes the main 'while' loop
} # closes the function 'Manage-ADGroupMembers'