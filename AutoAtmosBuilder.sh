#!/bin/bash

set -e

### Create directory structure
DIRS=(
  "./SwitchSD/atmosphere/config"
  "./SwitchSD/atmosphere/hosts"
  "./SwitchSD/switch/DBI"
  "./SwitchSD/switch/Goldleaf"
  "./SwitchSD/switch/Checkpoint"
  "./SwitchSD/switch/.packages"
  "./SwitchSD/warmboot_mariko"
  "./SwitchSD/themes"
  "./SwitchSD/bootloader/ini"
  "./SwitchSD/bootloader/res"
  "./SwitchSD/bootloader/payloads"
  "./SwitchSD/config/tesla"
  "./SwitchSD/config/Tesla-Menu/"
  "./SwitchSD/switch/.overlays"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

if [ -e description.txt ]; then
  rm -rf description.txt
fi

cd SwitchSD
###
### Function to download and handle zip files
download_and_unzip() {
  url=$1
  output_zip=$2
  dest_dir=$3

  curl -sL "$url" -o "$output_zip"
  if [ $? -ne 0 ]; then
    echo "$output_zip download\033[31m failed\033[0m."
  else
    echo "$output_zip download\033[32m success\033[0m."
    unzip -oq "$output_zip" -d "$dest_dir"
    rm "$output_zip"
  fi
}

echo "Fetching resources and storing information in description.txt..."

### Download Atmosphere
is_prerelease=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq '.[0].prerelease')
atmosphere_url=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].assets[0].browser_download_url')
fusee_url=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].assets[] | select(.name == "fusee.bin") | .browser_download_url')

download_and_unzip "$atmosphere_url" "atmosphere.zip" "."
curl -sL "$fusee_url" -o fusee.bin

### Download Hekate
hekate_url=$(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest | jq -r '.assets[0].browser_download_url')
download_and_unzip "$hekate_url" "hekate.zip" "."

if [ "$is_prerelease" != "true" ]; then
  echo "Stable release detected. Downloading additional tools."
  ### Download MissionControl
  missioncontrol_url=$(curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest | jq -r '.assets[0].browser_download_url')
  download_and_unzip "$missioncontrol_url" "MissionControl.zip" "."

  ### Download ldn_mitm
  ldn_mitm_url=$(curl -sL https://api.github.com/repos/spacemeowx2/ldn_mitm/releases/latest | jq -r '.assets[0].browser_download_url')
  download_and_unzip "$ldn_mitm_url" "ldn_mitm.zip" "."
fi

### Additional resources
resources=(
  "https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/Tesla.zip"
  "https://api.github.com/repos/masagrator/SaltyNX/releases/latest"
  "https://api.github.com/repos/exelix11/SysDVR/releases/latest"
  "https://api.github.com/repos/retronx-team/sys-clk/releases/latest"
)

for url in "${resources[@]}"; do
  resource_zip=$(basename "$url" | cut -d '?' -f 1)
  download_and_unzip "$url" "$resource_zip" "."
done

# Additional specific files
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/DBI.nro -o ./switch/DBI/DBI.nro

### Write configuration files
cat > ./bootloader/hekate_ipl.ini << ENDOFFILE
[config]
autoboot=0
autoboot_list=0
bootwait=3
verification=1
backlight=100
autohosoff=0
autonogc=1
updater2p=1
[大气层虚拟系统]
emummcforce=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_emunand.bmp
id=Atm-Emu
{烤鸭包的自动构建}
[大气层真实系统]
emummc_force_disable=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_sysnand.bmp
id=Atm-Sys
{烤鸭包的自动构建}
[安全模式]
fss0=atmosphere/package3
emummc_force_disable=1
cal0blank=0
{烤鸭包的自动构建}
ENDOFFILE

cat > ./bootloader/nyx.ini << ENDOFFILE
[config]
themebg=2d2d2d
themecolor=320
entries5col=0
timeoff=edbe80
homescreen=0
verification=1
umsemmcrw=0
jcdisable=0
jcforceright=0
bpmpclock=1
ENDOFFILE

cat > ./exosphere.ini << ENDOFFILE
[exosphere]
debugmode=1
log_port=0
log_baud_rate=115200
log_inverted=0
ENDOFFILE

cat > ./atmosphere/config/system_settings.ini << ENDOFFILE
[eupld]
upload_enabled = u8!0x0
[ro]
ease_nro_restriction = u8!0x1
[atmosphere]
dmnt_cheats_enabled_by_default = u8!0x0
fatal_auto_reboot_interval = u64!0x2710
enable_dns_mitm = u8!0x1
add_defaults_to_dns_hosts = u8!0x1
enable_external_bluetooth_db = u8!0x1
[usb]
usb30_force_enabled = u8!0x1
[tc]
sleep_enabled = u8!0x0
holdable_tskin = u32!0xEA60
tskin_rate_table_console = str!”[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]”
tskin_rate_table_handheld = str!”[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]”
ENDOFFILE

### Additional resources 等待补充

echo "\033[32mYour Switch SD card is prepared! 烤鸭包的自动构建已经完成\033[0m"
