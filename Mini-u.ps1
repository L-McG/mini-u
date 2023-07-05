function Draw-Menu {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $menuItems,
        [Parameter()]
        [int32]
        $menuPosition,
        [Parameter()]
        [String]
        $menuTitle,
        [Parameter()]
        [System.Object]
        $object,
        [Parameter()]
        [String]
        $navigation,
        [Parameter()]
        [String]
        $secondaryKey = 'Description',
        [Parameter()]
        [String]
        $tertiaryKey = 'Navigation'
    )

    $menuLength = $menuItems.length
    $consoleWidth = $host.ui.RawUI.WindowSize.Width
    $foregroundColor = $host.UI.RawUI.ForegroundColor
    $backgroundColor = $host.UI.RawUI.BackgroundColor
    $leftTitlePadding = ($consoleWidth - $menuTitle.Length) / 2
    $titlePaddingString = ' ' * ([Math]::Max(0, $leftTitlePadding))
    $leftDescriptionPadding = ($consoleWidth - $secondaryKey.Length) / 2
    $descriptionPaddingString = ' ' * ([Math]::Max(0, $leftDescriptionPadding))
    $leftTertiaryKeyPadding = ($consoleWidth - $tertiaryKey.Length) / 2
    $tertiaryKeyPaddingString = ' ' * ([Math]::Max(0, $leftTertiaryKeyPadding))
    $leftNavigationPadding = ($consoleWidth - $navigation.Length) / 2
    $navigationPaddingString = ' ' * ([Math]::Max(0, $leftNavigationPadding))

    Clear-Host
    Write-Host $('-' * $consoleWidth -join '')
    Write-Host ($titlePaddingString)($menuTitle)
    Write-Host $('-' * $consoleWidth -join '')

    $currentDescription = ""

    for ($i = 0; $i -lt $menuLength; $i++) {
        Write-Host "`t" -NoNewLine
        if ($i -eq $menuPosition) {
            Write-Host "$($menuItems[$i])" -ForegroundColor $backgroundColor -BackgroundColor $foregroundColor
            $currentItem = $menuItems[$i]
            $currentDescription = ($object | Where-Object { $_.Name -eq $currentItem }).Value.Description
        } else {
            Write-Host "$($menuItems[$i])" -ForegroundColor $foregroundColor -BackgroundColor $backgroundColor
        }
    }

    Write-Host $('-' * $consoleWidth -join '')
    Write-Host ($descriptionPaddingString)($secondaryKey)
    Write-Host $('-' * $consoleWidth -join '')
    # Display the description after the menu is rendered.
    Write-Host "`t$currentDescription"

    Write-Host `n
    Write-Host `n
    Write-Host $('-' * $consoleWidth -join '')
    Write-Host ($navigationPaddingString)($navigation)
}

function Navigate-Menu {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $menuItems,
        [Parameter()]
        [String]
        $menuTitle = "Menu",
        [Parameter()]
        [System.Object]
        $object,
        [Parameter()]
        [String]
        $navigation        
    )
    $keycode = 0
    $pos = 0
    
    while ($keycode -ne 13 -and $keycode -ne 81 -and $keycode -ne 8) {
        Draw-Menu $menuItems $pos $menuTitle $object $navigation
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $keycode = $press.virtualkeycode
        if ($keycode -eq 8) {
            $global:back = $true
            break
        }
        if ($keycode -eq 81) {
            $global:quit = $true
            break
        }
        if ($keycode -eq 38) {
            $pos--
        }
        if ($keycode -eq 40) {
            $pos++
        }
        if ($pos -lt 0) {
            $pos = ($menuItems.length - 1)
        }
        if ($pos -ge $menuItems.length) {
            $pos = 0
        }
    }

    if ($null -ne $($menuItems[$pos]) -and !$global:quit -and !$global:back) {
        return $($menuItems[$pos])
    }
}
function mini-u {
<#
.SYNOPSIS
	This function serves as an example of how I implement command line 
    interface menus in PowerShell. To use this, run 
    'Import-Module .\Mini-u.ps1' from within this project's directory.
.DESCRIPTION
    Using a JSON file, a main menu is generated which contain names to
    objects within the JSON file that serve as submenus. Each submenu 
    has addition objects that can be selected. Edit the JSON file to 
    create your desired menu layout, currently limited to a depth of
    2.

    DrawMenu.ps1 allows the user to select menu options with the 
    Up/Down arrow keys and make a selection with 'Enter'.
.NOTES
    Version:    v1.0 -- 07 Dec 2022
                v1.1 -- 23 Jun 2023
	Author:     Lucas McGlamery
.EXAMPLE
	PS> mini-u
#>
    [bool]$global:back = $false
    [bool]$global:quit = $false
    $MainMenu = (Get-Content .\menus\MainMenu.json | ConvertFrom-Json).PSObject.Properties
    $MenuStack = New-Object System.Collections.ArrayList
    # generate navigation help
    $Navigation = Get-Content .\menus\Navigation.json | ConvertFrom-Json
    $Navigation = $Navigation | ForEach-Object {
        "[$($_.Key)]-$($_.Function)"
    }
    $Navigation = $Navigation -join " "

    # begin main loop
    while(!$global:quit) {
        if ($global:back) {
            $MenuStack.Remove($MenuStack[-1])
            $global:back = $false
        }
        if ($null -eq $MenuStack[0]) {
            $MainMenuSelection = Navigate-Menu $MainMenu.Name "Main Menu" $MainMenu $Navigation
            if ($global:quit -or $global:back) {
                continue
            }
            $MenuStack.Add(($MainMenu[$MainMenuSelection]))
        } else {
            $SubMenu = ($MenuStack[-1].Value | %{$_.PSObject.Properties | ?{$_.Name -ne 'Description'}})
            $Selection = Navigate-Menu $SubMenu.Name "Select a submenu option" $SubMenu $Navigation
            if ($global:quit -or $global:back) {
                continue
            }
            if ($null -ne (($Submenu | ?{$_.name -eq $Selection}).value).ScriptText) {
                Invoke-Expression (($Submenu | ?{$_.name -eq $Selection}).value).ScriptText
            } else {
                $MenuStack.Add(($Submenu | ?{$_.name -eq $Selection}))
            }
        }
    }
    Clear-Host
}