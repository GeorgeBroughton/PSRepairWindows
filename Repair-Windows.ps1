Param (
  [parameter(Mandatory=$false)][Switch]$SkipSystemScans,
  [parameter(Mandatory=$false)][Switch]$SkipUWP,
  [parameter(Mandatory=$false)][Switch]$SkipBadDisks,
  [parameter(Mandatory=$false)][Switch]$CDriveOnly,
  [parameter(Mandatory=$false)][Switch]$NoRestart
)

$PowerShellVersion = (get-host | select-object version).Version.Major

Function Write-Header {
  Param (
    [string]$Message,
    [parameter(Mandatory=$false)][Switch]$EndLine,
    [parameter(Mandatory=$false)][Switch]$Skipped
  )

  Write-Host "================================================================================"
  if(!$EndLine) { Write-Host "  $Message"
    if(!$Skipped) { Write-Host "================================================================================" }
  }

}

switch ($PowerShellVersion) {
  7 {
    function PassFail {
      Param (
        [parameter(Mandatory=$true)][ScriptBlock]$ScriptBlock,
        [parameter(Mandatory=$true)][string]$Message
      )

      Write-Host -NoNewLine " [ ] - $Message"

      $ErrorActionPreference = "SilentlyContinue"
      $ScriptBlock.Invoke()

      if($?) {
        Write-Host "`r [`u{2713}] - $Message"
      } else {
        Write-Host "`r [`u{2613}] - $Message"
      }
    }
  }
  default {
    function PassFail {
      Param (
        [parameter(Mandatory=$true)][ScriptBlock]$ScriptBlock,
        [parameter(Mandatory=$true)][string]$Message
      )

      Write-Host -NoNewLine " [....] - $Message"

      $ErrorActionPreference = "SilentlyContinue"
      $ScriptBlock.Invoke()

      if($?) {
        Write-Host "`r [PASS] - $Message"
      } else {
        Write-Host "`r [FAIL] - $Message"
      }
    }
  }
}

Write-Header "Warnings"
if($SkipSystemScans) { Write-Host " [!] - [WARN] System Scans Will Be Skipped" }
if($SkipUWP)         { Write-Host " [!] - [WARN] Universal Windows Apps Will Be Skipped" }
if($SkipBadDisks)    { Write-Host " [!] - [WARN] Disk Check Will Be Skipped" }
if($CDriveOnly)      { Write-Host " [!] - [WARN] All Disks Except C:\ Will Be Skipped" }
if($NoRestart)       { Write-Host " [!] - [WARN] Restart Will Be Skipped" }

Write-Header "Clearing Windows Update Cache"
  PassFail -Message "Stopping Windows Update Service"                  -ScriptBlock { Stop-Service -Name "wuauserv"  -Force }
  PassFail -Message "Stopping Cryptographic Service"                   -ScriptBlock { Stop-Service -Name "CryptSvc"  -Force }
  PassFail -Message "Stopping Background Intelligent Transfer Service" -ScriptBlock { Stop-Service -Name "bits"      -Force }
  PassFail -Message "Stopping Microsoft Installer Service"             -ScriptBlock { Stop-Service -Name "msiserver" -Force }

  PassFail -Message "Deleting Contents of `"$env:windir\SoftwareDistribution\Download`""                                    -ScriptBlock { Remove-Item "$env:windir\SoftwareDistribution\Download"                                    -Recurse -Force }
  PassFail -Message "Deleting Contents of `"$env:windir\SoftwareDistribution\DataStore`""                                   -ScriptBlock { Remove-Item "$env:windir\SoftwareDistribution\DataStore"                                   -Recurse -Force }
  PassFail -Message "Deleting Contents of `"$env:windir\SoftwareDistribution\PostRebootEventCache.V2`""                     -ScriptBlock { Remove-Item "$env:windir\SoftwareDistribution\PostRebootEventCache.V2"                     -Recurse -Force }
  PassFail -Message "Deleting Contents of `"$env:windir\System32\catroot2`""                                                -ScriptBlock { Remove-Item "$env:windir\System32\catroot2"                                                -Recurse -Force }
  PassFail -Message "Deleting Contents of `"$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat`"" -ScriptBlock { Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Recurse -Force }

  cmd /c "sc.exe sdset bits D:(A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)"
  cmd /c "sc.exe sdset wuauserv D:(A;;CCLCSWRPLORC;;;AU)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)"
  
  Set-Location -Path "$env:windir\system32"

  "atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll","jscript.dll","vbscript.dll","scrrun.dll","msxml.dll","msxml3.dll","msxml6.dll","actxprxy.dll","softpub.dll","wintrust.dll","dssenh.dll","rsaenh.dll","gpkcsp.dll","sccbase.dll","slbcsp.dll","cryptdlg.dll","oleaut32.dll","ole32.dll","shell32.dll","initpki.dll","wuapi.dll","wuaueng.dll","wuaueng1.dll","wucltui.dll","wups.dll","wups2.dll","wuweb.dll","qmgr.dll","qmgrprxy.dll","wucltux.dll","muweb.dll","wuwebv.dll" | ForEach-Object {
    if (Test-Path -Path "C:\Windows\system32\$_") {
      regsvr32.exe "C:\Windows\System32\$_"
    } else {
      "Could not find $_"
    }
  }
  Start-Sleep -Secods 5
  Stop-Process -Name "regsvr32" -Force

  netsh winsock reset

  PassFail -Message "Starting Windows Update Service"                  -ScriptBlock { Start-Service -Name "wuauserv"  }
  PassFail -Message "Starting Cryptographic Service"                   -ScriptBlock { Start-Service -Name "CryptSvc"  }
  PassFail -Message "Starting Background Intelligent Transfer Service" -ScriptBlock { Start-Service -Name "bits"      }
  PassFail -Message "Starting Microsoft Installer Service"             -ScriptBlock { Start-Service -Name "msiserver" }

  bitsadmin.exe /reset /allusers

Write-Header "Clearing Windows Prefetch Cache"
  PassFail -Message "Deleting Contents of `"$env:windir\prefetch`"" -ScriptBlock { Remove-Item -Path "$env:windir\prefetch" -Recurse -Force }

Write-Header "Clearing Temp Directories"
  PassFail -Message "Deleting Contents of `"$env:localappdata\Temp\*`"" -ScriptBlock { Remove-Item -Path "$env:localappdata\Temp\*" -Recurse -Force }
  PassFail -Message "Deleting Contents of `"$env:windir\Temp\*`""       -ScriptBlock { Remove-Item -Path "$env:windir\Temp\*"       -Recurse -Force }

Write-Header "Clearing Icon Cache"
  PassFail -Message "Killing Explorer.exe temporarily while the cache is cleared"                     -ScriptBlock { Stop-Process -Name 'Explorer' -Force                                                                                                                 }
  PassFail -Message "Deleting icon cache files from `"$env:localappdata\Microsoft\Windows\Explorer`"" -ScriptBlock { Get-ChildItem -File -Recurse -Path "$env:localappdata\Microsoft\Windows\Explorer" | Where-Object Name -Match 'iconcache.*\.db' | Remove-item -Force  }
  PassFail -Message "Starting Explorer.exe now it is cleared"                                         -ScriptBlock { Start-Process -FilePath "$env:windir\Explorer.exe"                                                                                                   }
  
Write-Header "Clearing CCMCache"
  PassFail -Message "Deleting Contents of `"$env:windir\CCMCache\*`"" -ScriptBlock { Remove-Item -Path "$env:windir\CCMCache\*" -Recurse -Force -Verbose }

if($SkipSystemScans) {
  Write-Header "<< Skipping `"Running System Scans`" Stage Due To -SkipSystemScans >>" -Skipped
} else {
  Write-Header "Running System Scans"
    PassFail -Message "[SFC ] Scaning and Repairing Corrupt System Files" -ScriptBlock { [void](sfc /scannow) }
    PassFail -Message "[DISM] Checking health"                            -ScriptBlock { [void](DISM /Online /Cleanup-Image /CheckHealth) }
    PassFail -Message "[DISM] Restoring health"                           -ScriptBlock { [void](DISM /Online /Cleanup-Image /RestoreHealth) }
}

if($SkipUWP) {
  Write-Header "<< Skipping `"Resetting Microsoft Store & UWP Apps`" Stage Due To -SkipUWP >>" -Skipped
} else {
  Write-Header "Resetting Microsoft Store & UWP Apps"
    Get-AppXPackage | ForEach-Object { PassFail -Message "Resetting App `"$($_.Name)`"" -ScriptBlock { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" }}
    PassFail -Message "Resetting Microsoft Store" -ScriptBlock { wsreset }
}

if($SkipBadDisks) {
  Write-Header "<< Skipping `"Setting Disks as Dirty`" Stage Due to -SkipBadDisks >>" -Skipped
} else {
  Write-Header "Setting Disks as Dirty"
  if ($CDriveOnly) {
    PassFail -Message "Setting Drive `"C:\`" as Dirty. CHKDSK will be performed on reboot." -ScriptBlock {
        [void](fsutil dirty set "C:")
    }
  } else {
    foreach ( $i in (Get-Volume | Where-Object DriveLetter -ne $null).DriveLetter ) { PassFail -Message "Setting Drive `"${i}:\`" as Dirty. CHKDSK will be performed on reboot." -ScriptBlock {
        [void](fsutil dirty set "${i}:")
    }}
  }
}

if($NoRestart) {
  Write-Header "<< Skipping `"Finishing Up Stage`" Due to -NoRestart >>" -Skipped
} else {
  Write-Header "Finishing Up"
    PassFail -Message "Scheduling System Restart in 5 Minutes" -ScriptBlock { [void](shutdown -r -t 300) }
}
Write-Header -EndLine
