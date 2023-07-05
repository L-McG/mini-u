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
        $secondaryKey = 'Description'
    )

    $menuLength = $menuItems.length
    $consoleWidth = $host.ui.RawUI.WindowSize.Width
    $foregroundColor = $host.UI.RawUI.ForegroundColor
    $backgroundColor = $host.UI.RawUI.BackgroundColor
    $leftTitlePadding = ($consoleWidth - $menuTitle.Length) / 2
    $titlePaddingString = ' ' * ([Math]::Max(0, $leftTitlePadding))
    $leftDescriptionPadding = ($consoleWidth - $secondaryKey.Length) / 2
    $descriptionPaddingString = ' ' * ([Math]::Max(0, $leftDescriptionPadding))

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
}

function Menu {
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
        $object
    )
    $keycode = 0
    $pos = 0
    
    while ($keycode -ne 13 -and $keycode -ne 81) {
        Draw-Menu $menuItems $pos $menuTitle $object
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $keycode = $press.virtualkeycode
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

    if ($null -ne $($menuItems[$pos]) -and !$global:quit) {
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

    $MainMenu = (Get-Content .\menus\MainMenu.json | ConvertFrom-Json).PSObject.Properties
    $MenuStack = [System.Collections.ArrayList]@()

    [bool]$global:quit = $false
    while(!$global:quit) {
        if ($null -eq $MenuStack[0]) {
            $MainMenuSelection = Menu $MainMenu.Name "Main Menu" $MainMenu ; Clear-Host
            $MenuStack.Add($MainMenu[$MainMenuSelection])
            continue
        } else {
            $SubMenu = ($MenuStack[-1].Value | %{$_.PSObject.Properties | ?{$_.Name -ne 'Description'}})
            $Selection = Menu $SubMenu.Name "Select a submenu option" $SubMenu
            if ($null -ne (($Submenu | ?{$_.name -eq $Selection}).value).ScriptText) {
                Invoke-Expression (($Submenu | ?{$_.name -eq $Selection}).value).ScriptText
                continue
            } else {
                $MenuStack.Add(($Submenu | ?{$_.name -eq $Selection}))
                continue
            }
        }
    }
    Clear-Host
    
<#     $MainMenuSelection = Menu $MainMenu.Name "Main Menu" $MainMenu ; Clear-Host
    $SubMenuOptions = $MainMenu | Where-Object{
        $_.Name -eq $MainMenuSelection
    }
    $SubMenu = ($SubMenuOptions.Value | %{$_.PSObject.Properties | ?{$_.Name -ne 'Description'}})
    $MenuOptionSelection = Menu $SubMenu.Name "Select a submenu option" $SubMenu
    Write-Host $MenuOptionSelection #>
}