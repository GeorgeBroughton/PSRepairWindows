# PSRepairWindows
Is windows messed up? Need to reinstall? Try this first.


It's just a script designed to be run from the PowerShell command line.  Not a full CMDlet, as i have my doubts it'll be used frequently enough for it to be one.

## Usage

```
& "C:\Temp\Repair-Windows.ps1" [-SkipSystemScans] [-SkipUWP] [-SkipBadDisks] [-CDriveOnly] [-NoRestart]
```

## Switches
### -SkipSystemScans
Skips the SFC scan, and also the DISM scans


### -SkipUWP
Skips Windows Store app resets & store reset.


### -SkipBadDisks
Skips disk checking. CHKDSK isn't run on next restart.

### -CDriveOnly
Checks only the C:\ drive. Useful if you know the problem isn't related to other disks in your system.

### -NoRestart
This one's self explanatory but basically the script by default restarts your computer so it can do an offline scan of the disks. Select this option if you don't want to restart at the end.

# To do
- [ ] Convert to a complete powershell module
  - [ ] Make every fix done in this a separate command, which can be invoked separately, or in one function that runs them consecutively
- [ ] Polish the dll registration code as it is kinda messy and spams the users screen with error messages unnecessarily
  - [ ] Add a spot for optional places for DLL registraction. i.e. appdata, program files, program data etc
- [ ] Release on PSGallery
- [ ] Registry cleaning & backup
- [ ] System restore points
- [ ] Offline virus scanning
- [ ] Aggressive driver removal
- [ ] Scheduling memory diagnostics using bcd
- [ ] Backup features
- [ ] GUI
- [ ] Debloat
- [ ] Telemetry blocking
- [ ] Hardening
- [ ] Full Windows 11 support (will need help with this as none of my computers support win11)
