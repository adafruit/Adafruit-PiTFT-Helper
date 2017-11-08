#!/bin/bash

if [ $(id -u) -ne 0 ]; then
	echo "Installer must be run as root."
	echo "Try 'sudo bash $0'"
	exit 1
fi


UPDATE_DB=false

############################ Script assisters ############################

# Given a list of strings representing options, display each option
# preceded by a number (1 to N), display a prompt, check input until
# a valid number within the selection range is entered.
selectN() {
	for ((i=1; i<=$#; i++)); do
		echo $i. ${!i}
	done
	echo
	REPLY=""
	while :
	do
		echo -n "SELECT 1-$#: "
		read
		if [[ $REPLY -ge 1 ]] && [[ $REPLY -le $# ]]; then
			return $REPLY
		fi
	done
}


function print_version() {
    echo "Adafruit PiTFT Helper v0.9.0"
    exit 1
}

function print_help() {
    echo "Usage: $0 -t [pitfttype]"
    echo "    -h            Print this help"
    echo "    -v            Print version information"
    echo "    -u [homedir]  Specify path of primary user's home directory (defaults to /home/pi)"
    echo "    -t [type]     Specify the type of PiTFT: '28r' (PID 1601) or '28c' (PID 1983) or '35r' or '22'"
    echo
    echo "You must specify a type of display."
    exit 1
}

group=ADAFRUIT
function info() {
    system="$1"
    group="${system}"
    shift
    FG="1;32m"
    BG="40m"
    echo -e "[\033[${FG}\033[${BG}${system}\033[0m] $*"
}

function bail() {
    FG="1;31m"
    BG="40m"
    echo -en "[\033[${FG}\033[${BG}${group}\033[0m] "
    if [ -z "$1" ]; then
        echo "Exiting due to error"
    else
        echo "Exiting due to error: $*"
    fi
    exit 1
}

function ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question
        read -p "$1 [$prompt] " REPLY

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}


progress() {
    count=0
    until [ $count -eq $1 ]; do
        echo -n "..." && sleep 1
        ((count++))
    done
    echo
}

sysupdate() {
    if ! $UPDATE_DB; then
        echo "Updating apt indexes..." && progress 3 &
        sudo apt-get update 1> /dev/null || { warning "Apt failed to update indexes!" && exit 1; }
        echo "Reading package lists..."
        progress 3 && UPDATE_DB=true
    fi
}


# Given a filename, a regex pattern to match and a replacement string,
# perform replacement if found, else append replacement to end of file.
# (# $1 = filename, $2 = pattern to match, $3 = replacement)
reconfig() {
	grep $2 $1 >/dev/null
	if [ $? -eq 0 ]; then
		# Pattern found; replace in file
		sed -i "s/$2/$3/g" $1 >/dev/null
	else
		# Not found; append (silently)
		echo $3 | sudo tee -a $1 >/dev/null
	fi
}


############################ Sub-Scripts ############################

function softwareinstall() {
    echo "Installing Pre-requisite Software...This may take a few minutes!" 
    apt-get install -y fbi git python-pip python-smbus python-spidev evtest tslib libts-bin 1> /dev/null  || { warning "Apt failed to install software!" && exit 1; }
    pip install evdev 1> /dev/null  || { warning "Pip failed to install software!" && exit 1; }
}

function overlayinstall() {
    if [ -e /boot/overlays/pitft2x-notouch-overlay.dtbo ]; then
		echo "pitft2x-notouch-overlay already exists. Skipping!"
    else
	cd ${target_homedir}
	curl -sLO https://github.com/adafruit/Adafruit_Userspace_PiTFT/raw/master/pitft2x-notouch-overlay.dtbo
	mv pitft2x-notouch-overlay.dtbo /boot/overlays/
    fi
}

# update /boot/config.txt with appropriate values
function update_configtxt() {
    if grep -q "adafruit-pitft-helper" "/boot/config.txt"; then
        echo "Already have an adafruit-pitft-helper section in /boot/config.txt."
	echo "Removing old section..."
        cp /boot/config.txt /boot/configtxt.bak
	sed -i -e "/^# --- added by adafruit-pitft-helper/,/^# --- end adafruit-pitft-helper/d" /boot/config.txt
    fi

    if [ "${pitfttype}" == "22" ]; then
        # formerly: options fbtft_device name=adafruit22a gpios=dc:25 rotate=270 frequency=32000000
        overlay="dtoverlay=pitft22,rotate=270,speed=32000000,fps=20"
    fi

    if [ "${pitfttype}" == "28r" ]; then
        overlay="dtoverlay=pitft2x-notouch-overlay,rotate=90,speed=64000000,fps=30"
    fi

    date=`date`

    cat >> /boot/config.txt <<EOF

# --- added by adafruit-pitft-helper $date ---
[pi0]
device_tree=bcm2708-rpi-0-w.dtb
[pi1]
device_tree=bcm2708-rpi-b-plus.dtb
[pi2]
device_tree=bcm2709-rpi-2-b.dtb
[pi2]
device_tree=bcm2710-rpi-3-b.dtb
[all]
dtparam=spi=on
dtparam=i2c1=on
dtparam=i2c_arm=on
$overlay
# --- end adafruit-pitft-helper $date ---
EOF
}

function touchmouseinstall() {
    cd ${target_homedir}
    echo "Downloading touchmouse.py"
    curl -sLO https://raw.githubusercontent.com/adafruit/Adafruit_Userspace_PiTFT/master/touchmouse.py
    echo "Adding touchmouse.py to /etc/rc.local"
    # removing any old version
    sed -i -e "/^sudo python.*touchmouse.py.*/d" /etc/rc.local
    sed -i -e "s|exit 0|sudo python $target_homedir/touchmouse.py \&\\nexit 0|" /etc/rc.local
}

function update_udev() {
    cat > /etc/udev/rules.d/95-touchmouse.rules <<EOF
    SUBSYSTEM=="input", ATTRS{name}=="touchmouse", ENV{DEVNAME}=="*event*", SYMLINK+="input/touchscreen"
EOF
}

# currently for '90' rotation only
function update_pointercal() {
    if [ "${pitfttype}" == "28r" ]; then
        cat > /etc/pointercal <<EOF
21766410 -6 -5873 -799880 4215 -11 65536
EOF
    fi

    if [ "${pitfttype}" == "35r" ]; then
        cat > /etc/pointercal <<EOF
8 -8432 32432138 5699 -112 -965922 65536
EOF
    fi

    if [ "${pitfttype}" == "28c" ]; then
        cat > /etc/pointercal <<EOF
320 65536 0 -65536 0 15728640 65536
EOF
    fi
}


function install_console() {
    if ! grep -q 'fbcon=map:10 fbcon=font:VGA8x8' /boot/cmdline.txt; then
        echo "Updating /boot/cmdline.txt"
        sed -i 's/rootwait/rootwait fbcon=map:10 fbcon=font:VGA8x8/g' "/boot/cmdline.txt"
    else
        echo "/boot/cmdline.txt already updated"
    fi

    echo "Turning off console blanking"
    # pre-stretch this is what you'd do:
    if [ -e /etc/kbd/config ]; then
      sed -i 's/BLANK_TIME=.*/BLANK_TIME=0/g' "/etc/kbd/config"
    fi
    # as of stretch....
    # removing any old version
    sed -i -e '/^# disable console blanking.*/d' /etc/rc.local
    sed -i -e '/^sudo sh -c "TERM=linux setterm -blank.*/d' /etc/rc.local
    sed -i -e "s|exit 0|# disable console blanking on PiTFT\\nsudo sh -c \"TERM=linux setterm -blank 0 >/dev/tty0\"\\nexit 0|" /etc/rc.local

    reconfig /etc/default/console-setup "^.*FONTFACE.*$" "FONTFACE=\"Terminus\""
    reconfig /etc/default/console-setup "^.*FONTSIZE.*$" "FONTSIZE=\"6x12\""

    echo "Setting raspi-config to boot to console w/o login..."
    raspi-config nonint do_boot_behaviour B2

    # remove fbcp
    sed -i -e "/^.*fbcp.*$/d" /etc/rc.local
}


function uninstall_console() {
    echo "Removing console fbcon map from /boot/cmdline.txt"
    sed -i 's/rootwait fbcon=map:10 fbcon=font:VGA8x8/rootwait/g' "/boot/cmdline.txt"
    echo "Screen blanking time reset to 10 minutes"
    if [ -e "/etc/kbd/config" ]; then
      sed -i 's/BLANK_TIME=0/BLANK_TIME=10/g' "/etc/kbd/config"
    fi
    sed -i -e '/^# disable console blanking.*/d' /etc/rc.local
    sed -i -e '/^sudo sh -c "TERM=linux.*/d' /etc/rc.local
}

function install_fbcp() {
    echo "Installing cmake..."
    apt-get --yes --force-yes install cmake 1> /dev/null  || { warning "Apt failed to install software!" && exit 1; }
    echo "Downloading rpi-fbcp..."
    cd /tmp
    curl -sLO https://github.com/tasanakorn/rpi-fbcp/archive/master.zip
    echo "Uncompressing rpi-fbcp..."
    rm -rf /tmp/rpi-fbcp-master
    unzip master.zip 1> /dev/null  || { warning "Failed to uncompress fbcp!" && exit 1; }
    cd rpi-fbcp-master
    mkdir build
    cd build
    echo "Building rpi-fbcp..."
    cmake ..  1> /dev/null  || { warning "Failed to cmake fbcp!" && exit 1; }
    make  1> /dev/null  || { warning "Failed to make fbcp!" && exit 1; }
    echo "Installing rpi-fbcp..."
    install fbcp /usr/local/bin/fbcp
    rm -rf /tmp/rpi-fbcp-master

    # Add fbcp to /rc.local:
    echo "Add fbcp to /etc/rc.local..."
    grep fbcp /etc/rc.local >/dev/null
    if [ $? -eq 0 ]; then
	# fbcp already in rc.local, but make sure correct:
	sed -i "s|^.*fbcp.*$|/usr/local/bin/fbcp \&|g" /etc/rc.local >/dev/null
    else
	#Insert fbcp into rc.local before final 'exit 0'
	sed -i "s|^exit 0|/usr/local/bin/fbcp \&\\nexit 0|g" /etc/rc.local >/dev/null
    fi
    echo "Setting raspi-config to boot to desktop w/o login..."
    raspi-config nonint do_boot_behaviour B4

    # Disable overscan compensation (use full screen):
    raspi-config nonint do_overscan 1
    # Set up HDMI parameters:
    echo "Configuring boot/config.txt for forced HDMI"
    reconfig /boot/config.txt "^.*hdmi_force_hotplug.*$" "hdmi_force_hotplug=1"
    reconfig /boot/config.txt "^.*hdmi_group.*$" "hdmi_group=2"
    reconfig /boot/config.txt "^.*hdmi_mode.*$" "hdmi_mode=87"
    reconfig /boot/config.txt "^.*hdmi_cvt.*$" "hdmi_cvt=${WIDTH_VALUES[PITFT_SELECT-1]} ${HEIGHT_VALUES[PITFT_SELECT-1]} 60 1 0 0 0"
}





# currently for '90' rotation only
function update_xorg() {
    if [ "${pitfttype}" == "28r" ]; then
        cat > /usr/share/X11/xorg.conf.d/20-calibration.conf <<EOF
Section "InputClass"
        Identifier "Touchscreen Calibration"
        MatchDevicePath "/dev/input/touchscreen"
        Driver "libinput"
        Option "TransformationMatrix" "0.024710 -1.098824 1.013750 1.113069 -0.008984 -0.069884 0 0 1"
EndSection
EOF
    fi

    if [ "${pitfttype}" == "35r" ]; then
        cat > /etc/X11/xorg.conf.d/99-calibration.conf <<EOF
Section "InputClass"
        Identifier      "calibration"
        MatchProduct    "stmpe-ts"
        Option  "Calibration"   "3800 120 200 3900"
        Option  "SwapAxes"      "1"
EndSection
EOF
    fi

    if [ "${pitfttype}" == "28c" ]; then
        cat > /etc/X11/xorg.conf.d/99-calibration.conf <<EOF
Section "InputClass"
         Identifier "captouch"
         MatchProduct "ft6x06_ts"
         Option "SwapAxes" "1"
         Option "InvertY" "1"
         Option "Calibration" "0 320 0 240"
EndSection
EOF
    fi
}

############### unused


function update_x11profile() {
    fbturbo_path="/usr/share/X11/xorg.conf.d/99-fbturbo.conf"
    if [ -e $fbturbo_path ]; then
        echo "Moving ${fbturbo_path} to ${target_homedir}"
        mv "$fbturbo_path" "$target_homedir"
    fi

    if grep -xq "export FRAMEBUFFER=/dev/fb1" "${target_homedir}/.profile"; then
        echo "Already had 'export FRAMEBUFFER=/dev/fb1'"
    else
        echo "Adding 'export FRAMEBUFFER=/dev/fb1'"
        cat >> "${target_homedir}/.profile" <<EOF
export FRAMEBUFFER=/dev/fb1
EOF
    fi
}

function update_etcmodules() {
    if [ "${pitfttype}" == "28c" ]; then
        ts_module="ft6x06_ts"
    elif [ "${pitfttype}" == "28r" ] || [ "${pitfttype}" == "35r" ]; then
        ts_module="stmpe_ts"
    else
        return 0
    fi

    if grep -xq "$ts_module" "/etc/modules"; then
        echo "Already had $ts_module"
    else
        echo "Adding $ts_module"
        echo "$ts_module" >> /etc/modules
    fi
}

function install_onoffbutton() {
    echo "Adding rpi_power_switch to /etc/modules"
    if grep -xq "rpi_power_switch" "${chr}/etc/modules"; then
        echo "Already had rpi_power_switch"
    else
        echo "Adding rpi_power_switch"
        cat >> /etc/modules <<EOF
rpi_power_switch
EOF
    fi

    echo "Adding rpi_power_switch config to /etc/modprobe.d/adafruit.conf"
    if grep -xq "options rpi_power_switch gpio_pin=23 mode=0" "${chr}/etc/modprobe.d/adafruit.conf"; then
        echo "Already had rpi_power_switch config"
    else
        echo "Adding rpi_power_switch"
        cat >> /etc/modprobe.d/adafruit.conf <<EOF
options rpi_power_switch gpio_pin=23 mode=0
EOF
    fi
}

####################################################### MAIN
target_homedir="/home/pi"


clear
echo "This script downloads and installs"
echo "PiTFT Support using userspace touch"
echo "controls and a DTO for display drawing."
echo "one of several configuration files."
echo "Run time of up to 5 minutes. Reboot required!"
echo

echo "Select configuration:"
selectN "PiTFT 2.8 inch resistive" \
        "PiTFT 2.2 inch no touch" \
        "Quit without installing"
PITFT_SELECT=$?
if [ $PITFT_SELECT -gt 2 ]; then
    exit 1
fi

PITFT_TYPES=("28r" "22")
WIDTH_VALUES=(640 640 320 480)
HEIGHT_VALUES=(480 480 240 320)
HZ_VALUES=(80000000 80000000 80000000 32000000)



args=$(getopt -uo 'hvri:o:b:u:' -- $*)
[ $? != 0 ] && print_help
set -- $args

for i
do
    case "$i"
    in
        -h)
            print_help
            ;;
        -v)
            print_version
            ;;
        -u)
            target_homedir="$2"
            echo "Homedir = ${2}"
            shift
            shift
            ;;
    esac
done

# check init system (technique borrowed from raspi-config):
info PITFT 'Checking init system...'
if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
  echo "Found systemd"
  SYSTEMD=1
elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
  echo "Found sysvinit"
  SYSTEMD=0
else
  bail "Unrecognised init system"
fi

if grep -q boot /proc/mounts; then
    echo "/boot is mounted"
else
    echo "/boot must be mounted. if you think it's not, quit here and try: sudo mount /dev/mmcblk0p1 /boot"
    if ask "Continue?"; then
        echo "Proceeding."
    else
        bail "Aborting."
    fi
fi

if [[ ! -e "$target_homedir" || ! -d "$target_homedir" ]]; then
    bail "$target_homedir must be an existing directory (use -u /home/foo to specify)"
fi

pitfttype=${PITFT_TYPES[$PITFT_SELECT-1]}


if [ "${pitfttype}" != "28r" ] && [ "${pitfttype}" != "28c" ] && [ "${pitfttype}" != "35r" ] && [ "${pitfttype}" != "22" ]; then
    echo "Type must be one of:"
    echo "  '28r' (2.8\" resistive, PID 1601)"
    echo "  '28c' (2.8\" capacitive, PID 1983)"
    echo "  '35r' (3.5\" Resistive)"
    echo "  '22'  (2.2\" no touch)"
    echo
    print_help
fi

info PITFT "System update"
sysupdate || bail "Unable to apt-get update"

info PITFT "Installing Python libraries & Software..."
softwareinstall || bail "Unable to install software"

info PITFT "Installing Device Tree Overlay..."
overlayinstall || bail "Unable to install overlay"

info PITFT "Updating /boot/config.txt..."
update_configtxt || bail "Unable to update /boot/config.txt"

if [ "${pitfttype}" == "28r" ] || [ "${pitfttype}" == "35r" ]; then
   info PITFT "Installing touchscreen..."
   touchmouseinstall || bail "Unable to install touch mouse script"

   info PITFT "Updating SysFS rules for Touchscreen..."
   update_udev || bail "Unable to update /etc/udev/rules.d"

   info PITFT "Updating TSLib default calibration..."
   update_pointercal || bail "Unable to update /etc/pointercal"
fi

# ask for console access
if ask "Would you like the console to appear on the PiTFT display?"; then
    info PITFT "Updating console to PiTFT..."
    install_console || bail "Unable to configure console"
else
    info PITFT "Making sure console doesn't use PiTFT"
    uninstall_console || bail "Unable to configure console"

    if ask "Would you like the PIXEL desktop to appear on the PiTFT display?"; then
	info PITFT "Adding FBCP support for PIXEL..."
	install_fbcp || bail "Unable to configure fbcp"

        info PITFT "Updating X11 default calibration..."
	update_xorg || bail "Unable to update calibration"
    fi
fi


#info PITFT "Updating X11 setup tweaks..."
#update_x11profile || bail "Unable to update X11 setup"

#if [ "${pitfttype}" != "35r" ]; then
#    # ask for 'on/off' button
#    if ask "Would you like GPIO #23 to act as a on/off button?"; then
#        info PITFT "Adding GPIO #23 on/off to PiTFT..."
#        install_onoffbutton || bail "Unable to add on/off button"
#    fi
#fi

# update_bootprefs || bail "Unable to set boot preferences"


info PITFT "Success!"
echo
echo "Settings take effect on next boot."
echo
echo -n "REBOOT NOW? [y/N] "
read
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then
	echo "Exiting without reboot."
	exit 0
fi
echo "Reboot started..."
reboot
exit 0