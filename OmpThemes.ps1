# Oh-My-Posh theme switcher. Dot-source from $PROFILE:  . <path>\OmpThemes.ps1
# Themes folder: $env:OMP_THEMES_DIR (fallback: ~\.config\ohmyposh), plus .\themes\** and $env:POSH_THEMES_PATH
# Requires the standalone oh-my-posh binary; the deprecated PowerShell module (v3) is detected and an upgrade offered.

function Get-OmpThemesDir {
    $dir = if ($env:OMP_THEMES_DIR) { $env:OMP_THEMES_DIR } else { Join-Path $HOME '.config\ohmyposh' }
    $dir = [Environment]::ExpandEnvironmentVariables($dir)
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $dir
}

function Get-OmpExe {
    # Resolve the oh-my-posh executable once. Besides PATH, look in the folders the usual installers use;
    # if found there, prepend that folder to PATH so the profile's `oh-my-posh init pwsh` line works too.
    if ($script:OmpExe -and (Test-Path -LiteralPath $script:OmpExe)) { return $script:OmpExe }
    $cmd = Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $script:OmpExe = $cmd.Source; return $script:OmpExe }
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"   # installer (user scope)
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\oh-my-posh.exe"    # winget portable package
        "$env:ProgramFiles\oh-my-posh\bin\oh-my-posh.exe"            # installer (machine scope)
        "$HOME\scoop\apps\oh-my-posh\current\oh-my-posh.exe"         # scoop
        "$env:ChocolateyInstall\bin\oh-my-posh.exe"                  # chocolatey
        '/usr/local/bin/oh-my-posh', '/opt/homebrew/bin/oh-my-posh', "$HOME/.local/bin/oh-my-posh"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    if ($candidates) {
        $script:OmpExe = $candidates[0]
        $env:Path = (Split-Path $script:OmpExe) + [IO.Path]::PathSeparator + $env:Path
        return $script:OmpExe
    }
    $legacy = Get-Module -ListAvailable oh-my-posh -ErrorAction SilentlyContinue | Select-Object -First 1
    $hint = if ($legacy) {
        "Only the deprecated oh-my-posh PowerShell module v$($legacy.Version) was found ($($legacy.ModuleBase)). " +
        "Its bundled v3 binary cannot render current themes."
    } else { 'oh-my-posh is not installed.' }
    throw "$hint Run Install-OhMyPosh (or: winget install JanDeDobbeleer.OhMyPosh -s winget) and open a new shell."
}

function Get-OmpVersion {
    try { (& (Get-OmpExe) version 2>$null | Select-Object -First 1) } catch { $null }
}

function Install-OhMyPosh {
    # Install or upgrade the standalone oh-my-posh binary (the supported distribution) via winget,
    # then make it usable in this session. Replaces the deprecated `Import-Module oh-my-posh` setup.
    [CmdletBinding()]
    param([switch]$RemoveLegacyModule)
    if (-not $IsWindows) { Write-Error 'Install-OhMyPosh only automates Windows (winget); see https://ohmyposh.dev/docs/installation'; return }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Error 'winget not found; install oh-my-posh manually: https://ohmyposh.dev/docs/installation/windows'; return }
    $before = Get-OmpVersion
    $verb = if ($before) { 'upgrade' } else { 'install' }
    Write-Host "winget $verb JanDeDobbeleer.OhMyPosh ..." -ForegroundColor Cyan
    winget $verb JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements | Out-Host
    # Pick up the PATH change the installer made without opening a new shell
    $env:Path = @([Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join [IO.Path]::PathSeparator
    if (-not $env:POSH_THEMES_PATH) { $env:POSH_THEMES_PATH = [Environment]::GetEnvironmentVariable('POSH_THEMES_PATH', 'User') }
    $script:OmpExe = $null
    $after = Get-OmpVersion
    if (-not $after) { Write-Error 'oh-my-posh still not found after install; open a new shell and retry.'; return }
    Write-Host "oh-my-posh $after at $(Get-OmpExe)" -ForegroundColor Green
    $legacy = Get-Module -ListAvailable oh-my-posh -ErrorAction SilentlyContinue
    if ($legacy) {
        if ($RemoveLegacyModule) {
            Get-Module oh-my-posh | Remove-Module -Force -ErrorAction SilentlyContinue
            Uninstall-Module oh-my-posh -AllVersions -Force -ErrorAction Continue
        } else {
            Write-Host "Deprecated PowerShell module oh-my-posh v$($legacy.Version) is still installed; remove it with:  Uninstall-Module oh-my-posh -AllVersions" -ForegroundColor Yellow
        }
    }
}

function Get-OmpNerdFont {
    # Installed Nerd Font files from the font registry (user + machine). v3 families are "<Name> Nerd Font [Mono|Propo]"
    # or the short "<Name> NF/NFM/NFP"; v2 files ("... Nerd Font Complete [Mono] [Windows Compatible]") lack the
    # newer glyphs and, since they register under the same family name, must go when a v3 version is installed.
    foreach ($hive in 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts') {
        $key = Get-Item -LiteralPath $hive -ErrorAction SilentlyContinue
        if (-not $key) { continue }
        foreach ($n in $key.GetValueNames()) {
            if ($n -notmatch 'Nerd Font|\bNF[MP]?\b') { continue }
            $file = $key.GetValue($n)
            if ($file -and -not [IO.Path]::IsPathRooted($file)) { $file = Join-Path $env:windir 'Fonts' $file }
            $family = $n -replace '\s*\((TrueType|OpenType)\)\s*$', ''
            while ($family -match '\s(Regular|Bold|Italic|Light|ExtraLight|SemiLight|SemiBold|Medium|Thin|Black|Heavy|Retina|Oblique|Book)$') { $family = $family -replace '\s\w+$', '' }
            $legacy = $n -match 'Nerd Font Complete'
            if ($legacy -and $file -and (Test-Path -LiteralPath $file)) {
                # v2 registry names differ from the family inside the file (which is what terminals match), so read it
                try { Add-Type -AssemblyName System.Drawing; $pfc = [System.Drawing.Text.PrivateFontCollection]::new(); $pfc.AddFontFile($file); if ($pfc.Families) { $family = $pfc.Families[0].Name }; $pfc.Dispose() } catch {}
            }
            [pscustomobject]@{ Family = $family; Name = $n; File = $file; Hive = $hive; Legacy = $legacy }
        }
    }
}

function Remove-OmpLegacyFont {
    # Unregister v2 Nerd Font files and move them to a backup folder (kept next to the themes dir)
    param([Parameter(Mandatory)][object[]]$Entry)
    $backup = Join-Path (Get-OmpThemesDir) 'font-backup'
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    if (-not ('OmpFontApi' -as [type])) {
        Add-Type -Namespace OmpFontApi -Name Gdi -MemberDefinition @'
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)] public static extern bool RemoveFontResourceW(string file);
[DllImport("user32.dll")] public static extern int SendMessageTimeout(IntPtr h, uint msg, IntPtr w, IntPtr l, uint flags, uint t, out IntPtr r);
'@ -ErrorAction SilentlyContinue
    }
    foreach ($e in $Entry) {
        try {
            if ($e.Hive -like 'HKLM*') { Write-Warning "Skipping machine-wide font '$($e.Name)' (needs admin): $($e.File)"; continue }
            if ($e.File -and (Test-Path -LiteralPath $e.File)) {
                try { [OmpFontApi.Gdi]::RemoveFontResourceW($e.File) | Out-Null } catch {}
                Move-Item -LiteralPath $e.File -Destination (Join-Path $backup (Split-Path $e.File -Leaf)) -Force
            }
            Remove-ItemProperty -LiteralPath $e.Hive -Name $e.Name -ErrorAction Stop
            Write-Host "Removed old font '$($e.Name)' (backup in $backup)" -ForegroundColor Green
        } catch { Write-Warning "Could not remove '$($e.Name)': $_ (a file in use is freed after sign-out; remove it via Settings > Fonts)" }
    }
    try { $r = [IntPtr]::Zero; [OmpFontApi.Gdi]::SendMessageTimeout([IntPtr]0xFFFF, 0x1D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$r) | Out-Null } catch {}   # WM_FONTCHANGE
}

function Set-OmpTerminalFont {
    # Point Windows Terminal at a font family: profiles.defaults, plus every profile that already overrides
    # its font with a Nerd Font (an old "NF" variant, typically). Other explicit fonts are left alone.
    param([Parameter(Mandatory)][string]$Family)
    $settings = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    ) | Where-Object { Test-Path -LiteralPath $_ }
    if (-not $settings) { Write-Host "Windows Terminal settings not found; set your terminal font to '$Family' by hand." -ForegroundColor Yellow; return }
    foreach ($file in $settings) {
        try {
            $json = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
            if (-not $json.profiles.defaults) { $json.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force }
            $touched = @()
            $targets = @($json.profiles.defaults) + @($json.profiles.list | Where-Object { "$($_.font.face)$($_.fontFace)" -match 'Nerd Font|\bNF[MP]?\b' })
            foreach ($t in $targets) {
                if ($t.PSObject.Properties['fontFace']) { $t.PSObject.Properties.Remove('fontFace') }   # pre-1.10 key
                if (-not $t.font) { $t | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) -Force }
                if ($t.font.PSObject.Properties['face']) { $t.font.face = $Family } else { $t.font | Add-Member -NotePropertyName face -NotePropertyValue $Family }
                $touched += $(if ($t.name) { $t.name } else { 'defaults' })
            }
            Copy-Item -LiteralPath $file "$file.bak" -Force
            $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $file -Encoding UTF8
            Write-Host "Windows Terminal font set to '$Family' ($($touched -join ', ')) in $file" -ForegroundColor Green
        } catch { Write-Warning "Could not update $file ($_); set the font to '$Family' in Windows Terminal > Settings > Defaults > Appearance." }
    }
    Write-Host "Other terminals: VS Code -> `"terminal.integrated.fontFamily`": `"$Family`"" -ForegroundColor DarkGray
}

function Install-OmpFont {
    # Install a Nerd Font with oh-my-posh's built-in installer and make Windows Terminal use it.
    # Themes need Nerd Fonts v3 glyphs; the old v2 "... NF" fonts show boxes for the newer icons.
    # No -Name opens oh-my-posh's interactive font picker. Names: oh-my-posh font list
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Name, [switch]$NoTerminalConfig, [switch]$RemoveOldVersions)
    try { $omp = Get-OmpExe } catch { Write-Error $_; return }
    $before = @(Get-OmpNerdFont)
    $reported = @()
    if ($Name) {
        # oh-my-posh lists the installed families ("  • CaskaydiaCove NF"); the download name often differs from
        # the family name (CascadiaCode -> CaskaydiaCove, Meslo -> MesloLGM), so capture that list
        & $omp font install $Name 2>&1 | ForEach-Object { Write-Host $_; if (($_ -replace '\x1b\[[0-9;]*[A-Za-z]|\x1b\][^\x1b\x07]*(\x1b\\|\x07)', '') -match '\u2022\s*([^\x1b]+?)\s*$') { $reported += $Matches[1] } }
    } else { & $omp font install }   # interactive picker needs the console
    if ($LASTEXITCODE -ne 0) { Write-Error "Font install failed (exit $LASTEXITCODE). Names: oh-my-posh font list"; return }
    $all = @(Get-OmpNerdFont)
    $families = @($all | Where-Object { -not $_.Legacy -and ($_.Name -notin $before.Name -or $_.Family -in $reported) } | ForEach-Object Family | Sort-Object -Unique)
    if (-not $families) { Write-Host 'No Nerd Font files registered; check the output above.' -ForegroundColor Yellow; return }
    # Prefer the regular variant (wide glyphs); Mono (NFM) squeezes icons into one cell, Propo (NFP) is for editors
    $family = ($families | Where-Object { $_ -match '(Nerd Font|\bNF)$' } | Select-Object -First 1)
    if (-not $family) { $family = $families[0] }
    Write-Host "Installed: $($families -join ', ')" -ForegroundColor Green
    # v2 files of the same family would shadow the new ones
    $old = @($all | Where-Object { $_.Legacy -and $_.Family -in $families })
    if ($old) {
        if ($RemoveOldVersions) { Remove-OmpLegacyFont $old }
        else { Write-Host "Old Nerd Font v2 files share the family name and may shadow the new glyphs:`n  $($old.File -join "`n  ")`nRemove them with:  omp-font $Name -RemoveOldVersions" -ForegroundColor Yellow }
    }
    if (-not $NoTerminalConfig -and $IsWindows) { Set-OmpTerminalFont $family }
    Write-Host 'Open a new terminal tab to see the glyphs.' -ForegroundColor DarkGray
}

function Get-OmpThemeFile {
    param([string]$Name)
    # Custom themes shipped with this repo (.\themes\**) take precedence over same-named downloaded ones
    $custom = Join-Path $PSScriptRoot 'themes'
    $files = @()
    if (Test-Path -LiteralPath $custom) { $files += Get-ChildItem -LiteralPath $custom -File -Recurse }
    $files += Get-ChildItem -LiteralPath (Get-OmpThemesDir) -File
    # Stock themes shipped with the standalone install (POSH_THEMES_PATH is set by the installer)
    if ($env:POSH_THEMES_PATH -and (Test-Path -LiteralPath $env:POSH_THEMES_PATH)) { $files += Get-ChildItem -LiteralPath $env:POSH_THEMES_PATH -File }
    $files = $files | Where-Object { $_.Name -match '\.omp\.(json|ya?ml|toml)$' } |
        Group-Object Name | ForEach-Object { $_.Group[0] }
    if ($Name) {
        $n = $Name -replace '\.omp\.(json|ya?ml|toml)$', ''
        $files = $files | Where-Object { ($_.Name -replace '\.omp\.(json|ya?ml|toml)$', '') -like $n }
    }
    $files | Sort-Object Name
}

function Get-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Name, [switch]$Preview)
    $current = $env:POSH_CONFIG
    $files = @(Get-OmpThemeFile -Name $Name)
    if (-not $files) { Write-Warning "No themes found in $(Get-OmpThemesDir)"; return }
    foreach ($f in $files) {
        $short = $f.Name -replace '\.omp\.(json|ya?ml|toml)$', ''
        $isCur = $current -and ($f.FullName -ieq $current)
        if ($Preview) {
            Write-Host ("`n== {0}{1}" -f $short, $(if ($isCur) { '  (current)' } else { '' })) -ForegroundColor Cyan
            Show-OmpPreview $f.FullName
        } else {
            [pscustomobject]@{ Current = $(if ($isCur) { '*' } else { '' }); Name = $short; Path = $f.FullName }
        }
    }
}

function Show-OmpPreview {
    param([string]$Path)
    # The session id makes oh-my-posh reuse the cached active config, so clear it; decode output as UTF-8
    $oldSession = $env:POSH_SESSION_ID
    $oldEnc = [Console]::OutputEncoding
    try {
        $env:POSH_SESSION_ID = [guid]::NewGuid().ToString()
        [Console]::OutputEncoding = [Text.Encoding]::UTF8
        & (Get-OmpExe) print primary --config $Path --shell pwsh --escape=false 2>&1 | Write-Host
        # The transient prompt reads values from the previous prompt, which a preview doesn't have, so use fake ones
        $fake = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'omp-preview-' + [guid]::NewGuid().ToString('N') + '.omp.json')
        $text = [IO.File]::ReadAllText($Path)
        $text = $text.Replace('.Segments.Executiontime.FormattedMs', '\"1.2s\"').
            Replace('.Segments.Git.HEAD', '\"main\"').
            Replace('.Segments.Sysinfo.PhysicalTotalMemory', '34359738368.0').
            Replace('.Segments.Sysinfo.PhysicalAvailableMemory', '17179869184.0').
            Replace('.Segments.Sysinfo.PhysicalPercentUsed', '50.0')
        [IO.File]::WriteAllText($fake, $text)
        $transient = & (Get-OmpExe) print transient --config $fake --shell pwsh --escape=false --terminal-width ([Math]::Max(40, $Host.UI.RawUI.WindowSize.Width)) --status 0 2>&1
        Remove-Item $fake -ErrorAction SilentlyContinue
        # Drop the cursor and line-clear codes the shell integration uses
        $transient = ($transient -join '') -replace "`e7|`e8|`e\[K|`e\[0J|`e\]7777;\d+", ''
        if ($transient.Trim()) {
            Write-Host '  after command:' -ForegroundColor DarkGray
            Write-Host $transient
        }
        Write-Host ''
    }
    catch { Write-Warning "Preview failed: $_" }
    finally {
        [Console]::OutputEncoding = $oldEnc
        $env:POSH_SESSION_ID = $oldSession
    }
}

function Set-OmpProfileTheme {
    param([string]$Path)
    $line = "oh-my-posh init pwsh --config `"$Path`" | Invoke-Expression"
    $prof = $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $prof)) { New-Item -ItemType File -Path $prof -Force | Out-Null }
    Copy-Item $prof "$prof.bak" -Force
    $lines = @(Get-Content $prof)
    # Lines from the deprecated PowerShell module (Import-Module oh-my-posh / Set-PoshPrompt) would set a v3 prompt
    # first, or fail once that module is removed, so comment them out
    $legacy = '^\s*(Import-Module\s+(-Name\s+)?[''"]?oh-my-posh[''"]?\s*$|Set-PoshPrompt\b)'
    $lines = @(foreach ($l in $lines) { if ($l -match $legacy) { "# $l  # legacy oh-my-posh module, disabled by OmpThemes.ps1" } else { $l } })
    $idx = for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*oh-my-posh\s+init\s+pwsh') { $i } }
    if ($idx) {
        $lines[$idx[0]] = $line
        $lines = for ($i = 0; $i -lt $lines.Count; $i++) { if ($idx.Count -gt 1 -and $idx[1..($idx.Count - 1)] -contains $i) { "# $($lines[$i])" } else { $lines[$i] } }
    } else { $lines += $line }
    Set-Content $prof $lines
}

function Set-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name, [switch]$NoPersist)
    $f = @(Get-OmpThemeFile -Name $Name)
    if ($f.Count -ne 1) {
        Write-Error $(if ($f.Count) { "Ambiguous name '$Name': $($f.Name -join ', ')" } else { "Theme '$Name' not found in $(Get-OmpThemesDir)" })
        return
    }
    try { $omp = Get-OmpExe } catch { Write-Error $_; return }
    & $omp init pwsh --config $f[0].FullName | Invoke-Expression
    $env:POSH_CONFIG = $f[0].FullName
    if (-not $NoPersist) { Set-OmpProfileTheme $f[0].FullName; Write-Host "Theme '$Name' applied and saved to profile." -ForegroundColor Green }
}

Register-ArgumentCompleter -CommandName Set-OmpTheme, Get-OmpTheme -ParameterName Name -ScriptBlock {
    param($cmd, $param, $word)
    Get-OmpThemeFile | ForEach-Object { $_.Name -replace '\.omp\.(json|ya?ml|toml)$', '' } |
        Where-Object { $_ -like "$word*" } | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

function Select-OmpTheme {
    [CmdletBinding()]
    param()
    $files = @(Get-OmpThemeFile)
    if (-not $files) { Write-Warning 'No themes found.'; return }
    $i = [Math]::Max(0, [array]::IndexOf(@($files.FullName), $env:POSH_CONFIG))
    $top = [Console]::CursorTop
    while ($true) {
        Clear-Host
        Write-Host 'Up/Down: browse   Enter: apply   Esc/Q: cancel' -ForegroundColor Yellow
        $win = 10; $start = [Math]::Max(0, [Math]::Min($i - 5, $files.Count - $win))
        for ($k = $start; $k -lt [Math]::Min($files.Count, $start + $win); $k++) {
            $n = $files[$k].Name -replace '\.omp\.(json|ya?ml|toml)$', ''
            if ($k -eq $i) { Write-Host "> $n" -ForegroundColor Cyan } else { Write-Host "  $n" }
        }
        Write-Host ''
        Show-OmpPreview $files[$i].FullName
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { $i = ($i - 1 + $files.Count) % $files.Count }
            'DownArrow' { $i = ($i + 1) % $files.Count }
            'PageUp' { $i = [Math]::Max(0, $i - 10) }
            'PageDown' { $i = [Math]::Min($files.Count - 1, $i + 10) }
            'Enter' { Clear-Host; Set-OmpTheme ($files[$i].Name -replace '\.omp\.(json|ya?ml|toml)$', ''); return }
            { $_ -in 'Escape', 'Q' } { Clear-Host; return }
        }
    }
}

function Install-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string[]]$Name, [switch]$All, [switch]$List, [switch]$Force, [switch]$Apply)
    $headers = @{ 'User-Agent' = 'OmpThemes-ps1' }
    if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
    try {
        $items = Invoke-RestMethod -Headers $headers 'https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes'
    } catch { Write-Error "Could not list GitHub themes: $_"; return }
    $remote = $items | Where-Object { $_.name -match '\.omp\.(json|ya?ml|toml)$' }
    if ($List -or (-not $Name -and -not $All)) {
        $local = Get-OmpThemeFile | ForEach-Object Name
        $remote | ForEach-Object { [pscustomobject]@{ Installed = $(if ($local -contains $_.name) { '*' } else { '' }); Name = $_.name -replace '\.omp\.(json|ya?ml|toml)$', '' } }
        return
    }
    $dir = Get-OmpThemesDir
    $sel = if ($All) { $remote } else {
        foreach ($n in $Name) {
            $m = @($remote | Where-Object { ($_.name -replace '\.omp\.(json|ya?ml|toml)$', '') -like $n })
            if (-not $m) { Write-Warning "No GitHub theme matches '$n'" }
            $m
        }
    }
    foreach ($t in $sel) {
        $dest = Join-Path $dir $t.name
        if ((Test-Path $dest) -and -not $Force) { Write-Host "Skip (exists): $($t.name)"; continue }
        try { Invoke-WebRequest -Headers $headers $t.download_url -OutFile $dest; Write-Host "Installed: $($t.name)" -ForegroundColor Green }
        catch { Write-Warning "Failed $($t.name): $_" }
    }
    if ($Apply -and $sel.Count -eq 1) { Set-OmpTheme ($sel[0].name -replace '\.omp\.(json|ya?ml|toml)$', '') }
}

Set-Alias omp-theme Select-OmpTheme
Set-Alias omp-list Get-OmpTheme
Set-Alias omp-set Set-OmpTheme
Set-Alias omp-install Install-OmpTheme
Set-Alias omp-upgrade Install-OhMyPosh
Set-Alias omp-font Install-OmpFont

function Show-OmpHelp {
    Write-Host @"

  OH-MY-POSH THEME SWITCHER - HOW IT WORKS
  ----------------------------------------
  Themes folder : $(Get-OmpThemesDir)
                  (change with `$env:OMP_THEMES_DIR; default ~\.config\ohmyposh)
  Current theme : $(if ($env:POSH_CONFIG) { Split-Path $env:POSH_CONFIG -Leaf } else { '(unknown)' })
  oh-my-posh    : $(try { "v$(Get-OmpVersion)  ($(Get-OmpExe))" } catch { 'NOT FOUND - run omp-upgrade' })

  Menu:   run  .\OmpThemes.ps1   (or  omp-menu  once loaded from your profile)
  Direct commands (after dot-sourcing in `$PROFILE):
    omp-theme             interactive picker with live preview
    omp-list [-Preview]   list themes (with rendered previews)
    omp-set <name>        switch theme (Tab completes); saved to profile
    omp-install [names]   list/download themes from GitHub
                          (-All, -Force, -Apply)
    omp-upgrade           install/upgrade the oh-my-posh binary via winget
                          (-RemoveLegacyModule also drops the old PS module)
    omp-font [name]       install a Nerd Font (default: picker; e.g. CascadiaCode,
                          Meslo) and set it in Windows Terminal (-NoTerminalConfig,
                          -RemoveOldVersions drops v2 files of the same family)

  Notes: glyphs need a Nerd Font v3 (omp-font); boxes/garbage mean an old or
  missing font. Switching in the menu only affects the
  profile for new shells; use  omp-set  / dot-source to change the live shell.

"@ -ForegroundColor Gray
}

function Show-OmpMenu {
    [CmdletBinding()] param()
    while ($true) {
        Clear-Host
        $cur = if ($env:POSH_CONFIG) { (Split-Path $env:POSH_CONFIG -Leaf) -replace '\.omp\.(json|ya?ml|toml)$', '' } else { '-' }
        $count = @(Get-OmpThemeFile).Count
        Write-Host ''
        Write-Host '  +----------------------------------------+' -ForegroundColor Cyan
        Write-Host '  |      OH-MY-POSH  THEME  SWITCHER       |' -ForegroundColor Cyan
        Write-Host '  +----------------------------------------+' -ForegroundColor Cyan
        Write-Host "  Folder  : $(Get-OmpThemesDir)"
        $ver = try { "v$(Get-OmpVersion)" } catch { 'NOT FOUND (use option 6)' }
        Write-Host "  Current : $cur     Installed: $count themes     oh-my-posh: $ver`n"
        Write-Host '  [1] Browse & switch theme (live preview)'
        Write-Host '  [2] List installed themes'
        Write-Host '  [3] Preview all installed themes'
        Write-Host '  [4] Download themes from GitHub'
        Write-Host '  [5] Help / how it works'
        Write-Host '  [6] Install / upgrade oh-my-posh (winget)'
        Write-Host '  [7] Install a Nerd Font (fixes boxes in the prompt)'
        Write-Host '  [Q] Quit' -ForegroundColor DarkGray
        $c = (Read-Host "`n  Choose").Trim().ToUpper()
        switch ($c) {
            '1' { Select-OmpTheme }
            '2' { Get-OmpTheme | Format-Table -AutoSize | Out-Host; Read-Host '  Enter to continue' | Out-Null }
            '3' { Get-OmpTheme -Preview; Read-Host '  Enter to continue' | Out-Null }
            '4' {
                $list = @(Install-OmpTheme -List)
                if (-not $list) { Read-Host '  Enter to continue' | Out-Null; continue }
                $filter = Read-Host "  Filter (blank = all $($list.Count) themes)"
                $shown = @($list | Where-Object { $_.Name -like "*$filter*" })
                for ($k = 0; $k -lt $shown.Count; $k++) {
                    Write-Host ("  {0,3}) {1}{2}" -f ($k + 1), $shown[$k].Name, $(if ($shown[$k].Installed) { '  [installed]' } else { '' }))
                }
                $pick = Read-Host '  Numbers to download (e.g. 1,4,7 or "all"; blank = cancel)'
                if ($pick) {
                    $names = if ($pick -eq 'all') { $shown.Name } else { $pick -split '[,\s]+' | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $shown.Count } | ForEach-Object { $shown[[int]$_ - 1].Name } }
                    if ($names) { Install-OmpTheme $names }
                }
                Read-Host '  Enter to continue' | Out-Null
            }
            '5' { Show-OmpHelp; Read-Host '  Enter to continue' | Out-Null }
            '6' { Install-OhMyPosh; Read-Host '  Enter to continue' | Out-Null }
            '7' {
                $cur = @(Get-OmpNerdFont | ForEach-Object { if ($_.Legacy) { "$($_.Family) (v2)" } else { $_.Family } } | Sort-Object -Unique)
                if ($cur) { Write-Host "  Nerd Fonts installed: $($cur -join ', ')" -ForegroundColor DarkGray }
                $n = Read-Host '  Font name (blank = interactive picker; e.g. CascadiaCode, Meslo, JetBrainsMono)'
                $old = (Read-Host '  Also remove old Nerd Font v2 files of the same family? (y/N)').Trim() -match '^y'
                Install-OmpFont $n -RemoveOldVersions:$old
                Read-Host '  Enter to continue' | Out-Null
            }
            { $_ -in 'Q', '' } { return }
        }
    }
}

Set-Alias omp-menu Show-OmpMenu
Set-Alias omp-help Show-OmpHelp

try { Get-OmpExe | Out-Null } catch { Write-Warning $_ }

# Run the menu when executed directly (.\OmpThemes.ps1) but not when dot-sourced
if ($MyInvocation.InvocationName -ne '.') { Show-OmpMenu }
