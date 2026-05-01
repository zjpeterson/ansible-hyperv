
$vhdPath = "D:\OEMDRV.vhdx"
$ksSource = "D:\ks.cfg"

# 1. Clean up existing VHD to ensure a fresh kickstart injection
if (Test-Path $vhdPath) {
    # Ensure it's not mounted from a previous failed run
    Get-VHD -Path $vhdPath -ErrorAction SilentlyContinue | Dismount-VHD -ErrorAction SilentlyContinue
    Remove-Item -Path $vhdPath -Force
}

# 2. Create and mount the new VHD
New-VHD -Path $vhdPath -Dynamic -SizeBytes 50MB | Out-Null
Mount-VHD -Path $vhdPath

# 3. Fetch the disk we just mounted using its Path to be safe
$diskNum = (Get-VHD -Path $vhdPath).DiskNumber

# 4. Initialize and create the partition
Initialize-Disk -Number $diskNum -PartitionStyle MBR
$partition = New-Partition -DiskNumber $diskNum -AssignDriveLetter -UseMaximumSize

# 5. Format as FAT32 with the required OEMDRV label
Format-Volume -Partition $partition -FileSystem FAT32 -NewFileSystemLabel "OEMDRV" -Confirm:$false | Out-Null

# 6. Copy the Kickstart file into the new volume
$driveLetter = $partition.DriveLetter
Copy-Item -Path $ksSource -Destination "$($driveLetter):\ks.cfg"

# 7. Safely dismount the VHD so Hyper-V can attach it to the VM
Dismount-VHD -Path $vhdPath

$acl = Get-Acl $vhdPath
# Grant "NT VIRTUAL MACHINE\Virtual Machines" access
$permission = "NT VIRTUAL MACHINE\Virtual Machines","FullControl","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $vhdPath $acl
