$ErrorActionPreference = "Stop"

$srcDir = "C:\Users\enman\Desktop\Juego-de-godot\src"
$menuDir = "$srcDir\menu"

# Create directories
New-Item -ItemType Directory -Force -Path "$menuDir\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\components" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\features\phone" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\features\dialog" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\features\journal" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\features\auth" | Out-Null
New-Item -ItemType Directory -Force -Path "$menuDir\assets" | Out-Null

$map = @{
    "end_screen" = "screens"
    "intro_cinematic" = "screens"
    "intro_video" = "screens"
    "main_menu" = "screens"
    "pause_menu" = "screens"
    "splash_screen" = "screens"

    "custom_button" = "components"
    "mute_button" = "components"
    "slot_selector" = "components"
    "controles_panel" = "components"
    "creditos_panel" = "components"
    "opciones_panel" = "components"
    "stats_panel" = "components"
    "pixel" = "components"
    "ThemeMapa" = "components"

    "phone_hud" = "features/phone"
    "phone_panel" = "features/phone"
    "WhatsApp_Audio" = "features/phone"

    "dialog_box" = "features/dialog"
    "ai_dialog_box" = "features/dialog"
    "interact_prompt" = "features/dialog"
    "objeto_interactivo" = "features/dialog"
    "professor_replay_choice" = "features/dialog"

    "journal_panel" = "features/journal"
    "quest_log_panel" = "features/journal"
    "quest_notification" = "features/journal"

    "login_panel" = "features/auth"

    "Click" = "assets"
    "OnHover" = "assets"
}

$replacements = @()
foreach ($key in $map.Keys) {
    $dest = $map[$key]
    
    $files = Get-ChildItem -Path $menuDir -Filter "$key.*" -File
    
    foreach ($file in $files) {
        $fileName = $file.Name
        $oldPathStr = "res://src/menu/$fileName"
        $newPathStr = "res://src/menu/$dest/$fileName"
        
        $replacements += [PSCustomObject]@{
            Old = $oldPathStr
            New = $newPathStr
        }
        
        Move-Item -Path $file.FullName -Destination "$menuDir\$dest\" -Force
        Write-Host "Moved $fileName to $dest"
    }
}

Write-Host "Starting string replacement..."
$allFiles = Get-ChildItem -Path $srcDir -Include *.gd, *.tscn, *.tres, *.import, *.cfg -Recurse -File

foreach ($file in $allFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $modified = $false
        
        foreach ($rep in $replacements) {
            if ($content.Contains($rep.Old)) {
                $content = $content.Replace($rep.Old, $rep.New)
                $modified = $true
            }
        }
        
        if ($modified) {
            # Use ASCII encoding or UTF8 without BOM depending on original file. Godot prefers UTF8 without BOM.
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            Write-Host "Updated references in $($file.FullName)"
        }
    } catch {
        Write-Host "Error processing file: $($file.FullName) - $($_.Exception.Message)"
    }
}

Write-Host "Done!"
