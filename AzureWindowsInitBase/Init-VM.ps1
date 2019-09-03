& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"en-gb.xml`""
Set-WinSystemLocale -SystemLocale en-GB
Set-WinHomeLocation -GeoId 242
Set-WinUserLanguageList -LanguageList (New-WinUserLanguageList -Language en-GB) -Force
Set-Culture en-GB
Start-Sleep -Seconds 40
$currentDriveLetters=Get-Volume | Where-Object{$_.DriveLetter} | Select -ExpandProperty DriveLetter
$lastDriveLetterChar=([int[]][char[]]$nextdisk | Measure -Maximum | select -ExpandProperty Maximum)
Get-Disk | Where-Object{$_.IsOffline -eq $true} | Set-Disk -IsOffline $false
$disks=Get-Disk | Where-Object{$_.PartitionStyle -eq "RAW"}
$disks | Initialize-Disk -PartitionStyle GPT
foreach($disk in $disks)
{
    $lastDriveLetterChar = $lastDriveLetterChar + 1
    $disk | New-Partition -UseMaximumSize -DriveLetter "$([char][int]$lastDriveLetterChar)"
    Format-Volume -DriveLetter "$([char][int]$lastDriveLetterChar)" -FileSystem "NTFS" -Full
}


Restart-Computer
exit 0