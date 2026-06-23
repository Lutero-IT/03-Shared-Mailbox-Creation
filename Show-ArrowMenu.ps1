
# ============= PROGRAM ================= #

function Write-Indent ([string]$Message) {
    Write-Host "${Indent}$Message" @Args
}

function Show-ArrowMenu {

    # PARAMETERS #
    param (
        [string[]]$Menu = "",
        [string]$Title = "",
        [string]$Group = $null,
        [scriptblock]$Message = {}
    )

    # VARIABLES #
    $pressedKey = ""
    $selectIndex = 0
    $maxIndex = ($Menu.Length - 1)

    # MAIN BODY #
    while ($pressedKey -ne "Enter") {

        Clear-Host

        Write-Host ""
        Write-Indent ("="*80)
        Write-Indent (" " * ((80 - [int]$Title.Length) / 2 ) ) $Title
        Write-Indent ("="*80)

        if ($Message -ne $null) {
            & $Message
        }
        
        if ( $selectIndex -gt $maxIndex ) {
            $selectIndex = 0    
        } elseif ( $selectIndex -lt 0 ) {
            $selectIndex = $maxIndex
        }

        if ( -not ([string]::IsNullOrEmpty($Group)) ) {
            Write-Host ""
            Write-Indent "You are currently editing " -NoNewLine
            Write-Host "'$Group'" -ForegroundColor Black -BackgroundColor Yellow  -NoNewline
            Write-Host " group"
            Write-Host ""
        } else {
            Write-Host ""
        }

        foreach ($option in $Menu) {
            if ($Menu.IndexOf($option) -eq $selectIndex) {
                Write-Indent $option -BackgroundColor Yellow -ForegroundColor Black
            } else {
                Write-Indent $option -ForegroundColor White
            }
        }
            
        $key = [Console]::ReadKey($true)
        $pressedKey = ($key.Key).ToString()

        switch ($pressedKey) {
            "UpArrow" {$selectIndex--}
            "DownArrow" {$selectIndex++}
            "Enter" { return $selectIndex }
        }
    
    }
}

<# TO LAUNCH:
    1. Change WinRM protocole (Enter PS-Session) to SSH protocole
    so the ReadKey method of [Console] class can work on a remote session.

#>