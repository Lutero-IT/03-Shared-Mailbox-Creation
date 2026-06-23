
# ============= PROGRAM ================= #

function Show-ArrowMenu {

    # PARAMETER #
    param (
        [string[]]$Menu = "",
        [string]$Title = "",
        [string]$Group = "None"
    )

    # VARIABLES #
    $pressedKey = ""
    $selectIndex = 0
    $maxIndex = ($Menu.Length - 1)

    # MAIN BODY #
    while ($pressedKey -ne "Enter") {

        Write-Host ""
        Write-IndentHost ("="*80)
        Write-IndentHost (" " * ((80 - [int]$Title.Length) / 2 ) ) $Title
        Write-IndentHost ("="*80)


        Write-Host ""
        Write-IndentHost "You are currently editing '$Group' group" -BackgroundColor Yellow -ForegroundColor Black
        Write-Host ""
        
        if ( $selectIndex -gt $maxIndex ) {
            $selectIndex = 0    
        } elseif ( $selectIndex -lt 0 ) {
            $selectIndex = $maxIndex
        }

        foreach ($option in $Menu) {
            if ($Menu.IndexOf($option) -eq $selectIndex) {
                Write-IndentHost $option -BackgroundColor Yellow -ForegroundColor Black
            } else {
                Write-IndentHost $option -ForegroundColor White
            }
        }
            
        $key = [Console]::ReadKey($true)
        $pressedKey = ($key.Key).ToString()

        switch ($pressedKey) {
            "UpArrow" {$selectIndex--}
            "DownArrow" {$selectIndex++}
            "Enter" { return $selectIndex }
        }

        Clear-Host
    }
}

<# TO DO:
    1. Change WinRM protocole (Enter PS-Session) to SSH protocole
    so the ReadKey method of [Console] class can work on a remote session.
    2. 

    TO COMMIT:
        1. Turned script into a function with a parameter. Deleted hardcoded values like $oldCampList.
        2. Parameter takes menu list as an input and displays all the options
        with arrow navigation and option highlighting.

#>