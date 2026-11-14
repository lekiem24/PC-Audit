# PC Audit - read-only Windows hardware inventory
# Windows PowerShell 5.1 / PowerShell 7+. No admin rights normally required.
$ErrorActionPreference = "SilentlyContinue"
function Section($n) { Write-Host "`n========== $n ==========" -ForegroundColor Cyan }
function GB($b) { if (!$b -or $b -le 0) { "Unknown" } else { "{0:N2} GB" -f ($b / 1GB) } }

Write-Host "`nPC AUDIT - READ-ONLY HARDWARE REPORT" -ForegroundColor Green
Write-Host "Computer: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Section "OPERATING SYSTEM"
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
[pscustomobject]@{OS=$os.Caption; Version=$os.Version; Build=$os.BuildNumber; Architecture=$os.OSArchitecture; Manufacturer=$cs.Manufacturer; Model=$cs.Model} | Format-List

Section "MOTHERBOARD AND BIOS"
$b = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
[pscustomobject]@{MotherboardManufacturer=$b.Manufacturer; MotherboardModel=$b.Product; BoardVersion=$b.Version; BIOSVersion=($bios.SMBIOSBIOSVersion -join ", "); BIOSDate=$bios.ReleaseDate} | Format-List

Section "CPU"
Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed | Format-List

Section "MEMORY SUMMARY"
$ram = @(Get-CimInstance Win32_PhysicalMemory)
$installedModuleBytes = ($ram | Measure-Object -Property Capacity -Sum).Sum
$usable = [double]$os.TotalVisibleMemorySize * 1KB
[pscustomobject]@{
  InstalledPhysicalRAM=GB $installedModuleBytes
  FirmwareReportedPhysicalRAM=GB $cs.TotalPhysicalMemory
  WindowsUsableRAM=GB $usable
  MemorySlotsReported=(Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object MemoryDevices -Sum).Sum
} | Format-List

Section "RAM STICKS / MODULES"
if ($ram.Count) {
  $ram | ForEach-Object {
    [pscustomobject]@{
      Slot=$_.DeviceLocator; Bank=$_.BankLabel
      CapacityGB=[math]::Round(([double]$_.Capacity/1GB),2)
      Manufacturer=$_.Manufacturer; PartNumber=($_.PartNumber -replace '\s+$','')
      ConfiguredSpeedMHz=$(if ($_.ConfiguredClockSpeed) {$_.ConfiguredClockSpeed} else {"Unknown"})
      RatedSpeedMHz=$(if ($_.Speed) {$_.Speed} else {"Unknown"})
      MemoryTypeCode=$_.SMBIOSMemoryType; FormFactorCode=$_.FormFactor
    }
  } | Format-Table -AutoSize
  Write-Host "Configured speed = current firmware-reported speed; Rated speed = module-reported speed."
} else { Write-Host "RAM module details unavailable." }

Section "GRAPHICS / GPU"
$gpu = @(Get-CimInstance Win32_VideoController)
if ($gpu.Count) {
  $gpu | ForEach-Object {
    [pscustomobject]@{
      GPU=$_.Name
      WindowsReportedAdapterMemoryGB=$(if ($_.AdapterRAM -gt 0) {[math]::Round(([double]$_.AdapterRAM/1GB),2)} else {"Not reported"})
      DriverVersion=$_.DriverVersion; DriverDate=$_.DriverDate
      VideoProcessor=$_.VideoProcessor
      Resolution=$(if ($_.CurrentHorizontalResolution) {"$($_.CurrentHorizontalResolution) x $($_.CurrentVerticalResolution)"} else {"Unknown"})
    }
  } | Format-List
} else { Write-Host "GPU details unavailable." }
Write-Host "Note: Adapter memory is not guaranteed dedicated VRAM; integrated GPUs may use shared/reserved system RAM."

Section "PHYSICAL STORAGE DRIVES"
$pd = @(Get-PhysicalDisk)
if ($pd.Count) {
  $pd | ForEach-Object {
    [pscustomobject]@{
      Drive=$_.FriendlyName; Model=$_.Model; MediaType=$_.MediaType; BusType=$_.BusType
      CapacityGB=[math]::Round(([double]$_.Size/1GB),2)
      Health=$_.HealthStatus; Status=($_.OperationalStatus -join ", ")
    }
  } | Format-Table -AutoSize
} else {
  Get-CimInstance Win32_DiskDrive | Select-Object Model,InterfaceType,MediaType,@{N="CapacityGB";E={[math]::Round(([double]$_.Size/1GB),2)}},Status | Format-Table -AutoSize
}

Section "DISKS / PARTITIONS"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  [pscustomobject]@{
    Drive=$_.DeviceID; Volume=$_.VolumeName; FileSystem=$_.FileSystem
    CapacityGB=[math]::Round(([double]$_.Size/1GB),2)
    FreeGB=[math]::Round(([double]$_.FreeSpace/1GB),2)
  }
} | Format-Table -AutoSize

Section "NETWORK ADAPTERS"
Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = TRUE" | ForEach-Object {
  [pscustomobject]@{
    Adapter=$_.Description
    MACAddress=$_.MACAddress
    DHCPEnabled=$_.DHCPEnabled
    IPv4Address=(@($_.IPAddress | Where-Object {
      try { ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork }
      catch { $false }
    }) -join ", ")
    DefaultGateway=$_.DefaultIPGateway -join ", "
    DNServers=$_.DNSServerSearchOrder -join ", "
  }
} | Format-List

Write-Host "`nPC AUDIT COMPLETE" -ForegroundColor Green
