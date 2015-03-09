#!/usr/bin/python

# Script to automatically update Raspberry Pi PiTFT touchscreen calibration
# based on the current rotation of the screen.

# Copyright (c) 2014 Adafruit Industries
# Author: Tony DiCola

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import argparse
import os
import subprocess
import sys


# Calibration configuration default values.
CAL_CONFIG = {}

# 2.8" resisitive touch calibration values.
CAL_CONFIG['28r'] = {}
CAL_CONFIG['28r']['pointercal'] = {}
CAL_CONFIG['28r']['pointercal']['0']   = '4315 -49 -889068 18 5873 -1043172 6553636'
CAL_CONFIG['28r']['pointercal']['90']  = '-30 -5902 22077792 4360 -105 -1038814 65536'
CAL_CONFIG['28r']['pointercal']['180'] = '-4228 73 16353030 -60 -5888 22004262 65536'
CAL_CONFIG['28r']['pointercal']['270'] = '-69 5859 -829540 -4306 3 16564590 6553636'
CAL_CONFIG['28r']['xorg'] = {}
CAL_CONFIG['28r']['xorg']['0'] = """
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "stmpe-ts"
    Option  "Calibration"   "252 3861 180 3745"
    Option  "SwapAxes"      "0"
EndSection
"""
CAL_CONFIG['28r']['xorg']['90'] = """
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "stmpe-ts"
    Option  "Calibration"   "3807 174 244 3872"
    Option  "SwapAxes"      "1"
EndSection
"""
CAL_CONFIG['28r']['xorg']['180'] = """
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "stmpe-ts"
    Option  "Calibration"   "3868 264 3789 237"
    Option "SwapAxes"      "0"
EndSection
"""
CAL_CONFIG['28r']['xorg']['270'] = """
Section "InputClass"
    Identifier      "calibration"
    MatchProduct    "stmpe-ts"
    Option  "Calibration"   "287 3739 3817 207"
    Option  "SwapAxes"      "1"
EndSection
"""

# 2.8" capacitive touch calibration values.
CAL_CONFIG['28c'] = {}
CAL_CONFIG['28c']['pointercal'] = {}
CAL_CONFIG['28c']['pointercal']['0']   = '-65536 0 15728640 -320 -65536 20971520 65536'
CAL_CONFIG['28c']['pointercal']['90']  = '320 65536 0 -65536 0 15728640 65536'
CAL_CONFIG['28c']['pointercal']['180'] = '65536 0 -655360 0 65536 -655360 65536'
CAL_CONFIG['28c']['pointercal']['270'] = '0 -65536 20971520 65536 0 -65536 65536'
CAL_CONFIG['28c']['xorg'] = {}
CAL_CONFIG['28c']['xorg']['0'] = """
Section "InputClass"
    Identifier "captouch"
    MatchProduct "ft6x06_ts"
    Option "SwapAxes" "0"
    Option "InvertY" "1"
    Option "InvertX" "1"
    Option "Calibration" "0 240 0 320"
EndSection
"""
CAL_CONFIG['28c']['xorg']['90'] = """
Section "InputClass"
    Identifier "captouch"
    MatchProduct "ft6x06_ts"
    Option "SwapAxes" "1"
    Option "InvertY" "1"
    Option "Calibration" "0 320 0 240"
EndSection
"""
CAL_CONFIG['28c']['xorg']['180'] = """
Section "InputClass"
    Identifier "captouch"
    MatchProduct "ft6x06_ts"
    Option "SwapAxes" "0"
    Option "InvertY" "0"
    Option "Calibration" "0 240 0 320"
EndSection
"""
CAL_CONFIG['28c']['xorg']['270'] = """
Section "InputClass"
    Identifier "captouch"
    MatchProduct "ft6x06_ts"
    Option "SwapAxes" "1"
    Option "InvertY" "0"
    Option "InvertX" "1"
    Option "Calibration" "0 320 0 240"
EndSection
"""

# 3.5" resisitive touch calibration values.
CAL_CONFIG['35r'] = {}
CAL_CONFIG['35r']['pointercal'] = {}
CAL_CONFIG['35r']['pointercal']['0']   = '5835 56 -1810410 22 8426 -1062652 65536'
CAL_CONFIG['35r']['pointercal']['90']  = '-16 -8501 33169914 5735 45 -1425640 65536'
CAL_CONFIG['35r']['pointercal']['180'] = '-5853 8 22390770 -59 -8353 32810368 65536'
CAL_CONFIG['35r']['pointercal']['270'] = '-95 8395 -908648 -5849 164 22156762 65536'
CAL_CONFIG['35r']['xorg'] = {}
CAL_CONFIG['35r']['xorg']['0'] = """
Section "InputClass"
    Identifier "calibration"
    MatchProduct "stmpe-ts"
    Option "Calibration" "291 3847 141 3889"
    Option "SwapAxes" "0"
EndSection
"""
CAL_CONFIG['35r']['xorg']['90'] = """
Section "InputClass"
    Identifier "calibration"
    MatchProduct "stmpe-ts"
    Option "Calibration" "150 3912 3843 255"
    Option "SwapAxes" "1"
    Option "InvertX" "1"
    Option "InvertY" "1"  
EndSection
"""
CAL_CONFIG['35r']['xorg']['180'] = """
Section "InputClass"
    Identifier "calibration"
    MatchProduct "stmpe-ts"
    Option "Calibration" "291 3847 141 3889"
    Option "SwapAxes" "0"
    Option "InvertX" "1"
    Option "InvertY" "1"
EndSection
"""
CAL_CONFIG['35r']['xorg']['270'] = """
Section "InputClass"
    Identifier "calibration"
    MatchProduct "stmpe-ts"
    Option "Calibration" "150 3912 3843 255"
    Option "SwapAxes" "1"
    Option "InvertX" "0"
    Option "InvertY" "0"  
EndSection
"""

# Other configuration.
POINTERCAL_FILE = '/etc/pointercal'
XORGCAL_FILE = '/etc/X11/xorg.conf.d/99-calibration.conf'
ALLOWED_TYPES = CAL_CONFIG.keys()
ALLOWED_ROTATIONS = ['0', '90', '180', '270']


def read_file(filename):
    """Read specified file contents and return them, or None if file isn't
    readable.
    """
    try:
        with open(filename, 'r') as infile:
            return infile.read()
    except IOError:
        return None

def write_file(filename, data):
    """Write specified data to file.  Returns True if data was written."""
    try:
        # Check if path to file exists.  Create path if necessary.
        directory = os.path.dirname(filename)
        if not os.path.exists(directory):
            os.makedirs(directory)
        # Open file and write data.
        with open(filename, 'w') as outfile:
            outfile.write(data)
            return True
    except IOError, OSError:
        return False

def determine_rotation():
    """Determine the rotation of the PiTFT screen by examining 
    /sys/class/graphics/fb1/rotate config.
    """
    return read_file('/sys/class/graphics/fb1/rotate')

def determine_type():
    """Determine the type of display by examining loaded kernel modules.
    """
    # Call lsmod to list kernel modules.
    output = subprocess.check_output('lsmod')
    # Parse out module names from lsmod response (grab first word of each line
    # after the first line).
    modules = map(lambda x: x.split()[0], output.splitlines()[1:])
    # Check for display type based on loaded modules.
    if 'stmpe_ts' in modules and 'fb_ili9340' in modules:
        return '28r'
    elif 'ft6x06_ts' in modules and 'fb_ili9340' in modules:
        return '28c'
    elif 'stmpe_ts' in modules and 'fb_hx8357d' in modules:
        return '35r'
    else:
        return None


# Parse command line arguments.
parser = argparse.ArgumentParser(description='Automatically set the PiTFT touchscreen calibration for both /etc/pointercal and X.Org based on the current screen rotation.')
parser.add_argument('-t', '--type',
    choices=ALLOWED_TYPES, 
    required=False,
    dest='type',
    help='set display type')
parser.add_argument('-r', '--rotation', 
    choices=ALLOWED_ROTATIONS, 
    required=False,
    dest='rotation',
    help='set calibration for specified screen rotation')
parser.add_argument('-f', '--force',
    required=False,
    action='store_const',
    const=True,
    default=False,
    dest='force',
    help='update calibration without prompting for confirmation')
args = parser.parse_args()

# Check that you're running as root.
if os.geteuid() != 0:
    print 'Must be run as root so calibration files can be updated!'
    print 'Try running with sudo, for example: sudo ./pitft_touch_cal.py'
    sys.exit(1)

# Determine display type if not specified in parameters.
display_type = args.type
if display_type is None:
    display_type = determine_type()
    if display_type is None:
        print 'Could not detect display type!'
        print ''
        print 'Make sure PiTFT software is configured and run again.'
        print 'Alternatively, run with the --type parameter to'
        print 'specify an explicit display type value.'
        print ''
        parser.print_help()
        sys.exit(1)

# Check display type is allowed value.
if display_type not in ALLOWED_TYPES:
    print 'Unsupported display type: {0}'.format(display_type)
    parser.print_help()
    sys.exit(1)

# Determine rotation if not specified in parameters.
rotation = args.rotation
if rotation is None:
    rotation = determine_rotation()
    if rotation is None:
        # Error if rotation couldn't be determined.
        print 'Could not detect screen rotation!'
        print ''
        print 'Make sure PiTFT software is configured and run again.'
        print 'Alternatively, run with the --rotation parameter to'
        print 'specify an explicit rotation value.'
        print ''
        parser.print_help()
        sys.exit(1)

# Check rotation is allowed value.
rotation = rotation.strip()
if rotation not in ALLOWED_ROTATIONS:
    print 'Unsupported rotation value: {0}'.format(rotation)
    parser.print_help()
    sys.exit(1)

print '---------------------------------'
print 'USING DISPLAY: {0}'.format(display_type)
print ''
print '---------------------------------'
print 'USING ROTATION: {0}'.format(rotation)
print ''

# Print current calibration values.
print '---------------------------------'
print 'CURRENT CONFIGURATION'
print ''
for cal_file in [POINTERCAL_FILE, XORGCAL_FILE]:
    cal = read_file(cal_file)
    if cal is None:
        print 'Could not determine {0} configuration.'.format(cal_file)
    else:
        print 'Current {0} configuration:'.format(cal_file)
        print cal.strip()
        print ''

# Determine new calibration values.
new_pointercal = CAL_CONFIG[display_type]['pointercal'][rotation]
new_xorgcal    = CAL_CONFIG[display_type]['xorg'][rotation]

# Print new calibration values.
print '---------------------------------'
print 'NEW CONFIGURATION'
print ''
for cal, filename in [(new_pointercal, POINTERCAL_FILE), 
                      (new_xorgcal, XORGCAL_FILE)]:
    print 'New {0} configuration:'.format(filename)
    print cal.strip()
    print ''

# Confirm calibration change with user.
if not args.force:
    confirm = raw_input('Update current configuration to new configuration? [y/N]: ')
    print '---------------------------------'
    print ''
    if confirm.lower() not in ['y', 'yes']:
        print 'Exiting without updating configuration.'
        sys.exit(0)

# Change calibration.
status = 0
for cal, filename in [(new_pointercal, POINTERCAL_FILE), 
                      (new_xorgcal, XORGCAL_FILE)]:
    if not write_file(filename, cal):
        print 'Failed to update {0}'.format(filename)
        status = 1
    else:
        print 'Updated {0}'.format(filename)
sys.exit(status)
