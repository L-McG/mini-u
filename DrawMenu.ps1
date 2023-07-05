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
    
    while ($keycode -ne 13) {
        Draw-Menu $menuItems $pos $menuTitle $object
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $keycode = $press.virtualkeycode
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
    return $($menuItems[$pos])
}