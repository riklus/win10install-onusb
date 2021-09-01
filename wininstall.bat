@echo off
:: Partition sizes
set win_re_tools_size=500
set EFI_size=260
set msr_size=128
set win_partition_size=692000
set re_image_size=5000



::
:: Prologue
::
title "Windows Installation Script"
echo,
echo - Windows Installation Script -
echo      Made w/ l0v3 by riklus
echo,
echo This script enables you to install Windows 10 onto a usb drive/hardisk.
echo Execute this script AFTER accepting the Windows license conditions.
echo Remember to pay close attention to the disk selection dialog.
echo Look me up on Github :)



::
:: Input size section
::
echo,
echo - Disk size -
echo,
echo You will be installing Windows onto a usb drive/hardisk.
echo In order to calculate the Windows partiton size you must first enter your disk size, on which you will be installing Windows.
set /p d_size=Enter the size of the target disk (MB): 
set /a win_partition_size=d_size-win_re_tools_size-EFI_size-msr_size-re_image_size > nul
echo The Windows partiton size will be %win_partition_size% MB.



::
:: Selection section
::
title "Disk selection"

:: writing diskpart script
echo list disk > X:\diskpart_list

:Disk_selection
echo,
echo - Disk selection -
echo,

diskpart /s X:\diskpart_list
set /p x= Select disk number to ERASE: 
set /p c= Are you sure to ERASE ALL DATA ON DISK n. %x%? [y,n]: 
if "%c%" neq "y" goto Disk_selection
:Disk_selection_END

:: deleting diskpart script
del X:\diskpart_list

:: really really sure?
echo,
echo The disk will be erased, partitioned and Windows will be installed on it.
echo,
echo [!] This will delete EVERYTHING on disk n. %x%.
set /p c= Are you really really sure to continue? [c,n]: 
if "%c%" neq "c" (
    exit
    exit
    exit
)



::
:: Partitioning section
::
:: this will delete everything
title "Creating partitions"
echo,
echo [i] Partitioning...
echo,
echo - These steps will be performed -
echo 1. ERASE OF DISK N. %x%.
echo 2. Creation of Windows RE Tools partition.
echo 3. Creation of EFI partition.
echo 4. Creation of MSR partition.
echo 5. Creation of Windows partition.
echo 6. Creation of Recovery Image partition.

:: writing diskpart script
echo select disk %x% > X:\diskpart_create
echo clean >> X:\diskpart_create

echo convert gpt >> X:\diskpart_create
echo create partition primary size=%win_re_tools_size% >> X:\diskpart_create
echo format quick fs=ntfs label="Windows RE Tools" >> X:\diskpart_create
echo assign letter="T" >> X:\diskpart_create
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >> X:\diskpart_create
echo gpt attributes=0x8000000000000001 >> X:\diskpart_create

echo create partition efi size=%EFI_size% >> X:\diskpart_create
echo format quick fs=fat32 label="System" >> X:\diskpart_create
echo assign letter="S" >> X:\diskpart_create

echo create partition msr size=%msr_size% >> X:\diskpart_create

echo create partition primary size=%win_partition_size% >> X:\diskpart_create
echo format quick fs=ntfs label="Windows" >> X:\diskpart_create
echo assign letter="W" >> X:\diskpart_create

echo create partition primary size=%re_image_size% >> X:\diskpart_create
echo format quick fs=ntfs label="Recovery Image" >> X:\diskpart_create
echo assign letter="R" >> X:\diskpart_create
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >> X:\diskpart_create
echo gpt attributes=0x8000000000000001 >> X:\diskpart_create

echo list volume >> X:\diskpart_create

:: executing diskpart script
diskpart /s X:\diskpart_create
if %ERRORLEVEL% neq 0 (
    del X:\diskpart_create
    echo [!] Error partitioning disk.
    exit
)

:: deleting diskpart script
del X:\diskpart_create



::
:: Installation Section
::
title "Installing Windows"
echo,
echo - Installing Windows -
echo,

echo [i] Copying Recovery Image...
md R:\RecoveryImage
copy C:\sources\install.wim R:\RecoveryImage\install.wim

echo [i] Deploying Windows Image...
cd X:\Windows\System32
dism /Apply-Image /ImageFile:R:\RecoveryImage\install.wim /Index:1 /ApplyDir:W:\

echo [i] Copying Recovery Tools...
md T:\Recovery\WindowsRE
copy W:\Windows\System32\Recovery\winre.wim T:\Recovery\WindowsRE\winre.wim

echo [i] Writing Boot Configuration Data...
bcdboot W:\Windows /s S: /f UEFI

echo [i] Setting up Recovery Environment...
W:\Windows\System32\reagentc /setosimage /path R:\RecoverImage /target W:\Windows /index 1
W:\Windows\System32\reagentc /setreimage /path T:\Recovery\WindowsRE /target W:\Windows

echo Installation done.



::
:: Epilogue
::
title "Everything done!"
echo,
echo All done!
echo You can now unplug the installation medium and reboot.
echo,
echo Shutting down in 20 seconds...

"W:\Windows\System32\shutdown.exe" /s /t 20
pause > nul