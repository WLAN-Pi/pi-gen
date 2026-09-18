#!/bin/bash -e

on_chroot << EOF

CONFIG="/boot/firmware/config.txt"

# Section to modify
SECTION="cm4"

# Lines to add if missing
LINES_TO_ADD=(
    "dtoverlay=disable-wifi"
    "dtoverlay=disable-bt"
    "dtoverlay=uart3"
    "dtoverlay=uart2"
    "dtoverlay=uart0"
    "gpio=27=op,dh"
    "dtoverlay=max3421-hcd"
)

# Check if the section exists
if grep -q "^\[\$SECTION\]" "\$CONFIG"; then

    echo "[\$SECTION] section found in \$CONFIG. Checking for missing lines."

    for LINE in "\${LINES_TO_ADD[@]}"; do
        # Check if the line exists in the section
        if ! sed -n "/^\[\$SECTION\]/,/^\[/p" "\$CONFIG" | grep -q "\$LINE"; then
            echo "Adding '\$LINE' to [\$SECTION] section in \$CONFIG"
            sed -i "/^\[\$SECTION\]/a \$LINE" "\$CONFIG"
        else
            echo "'\$LINE' already exists in [\$SECTION] section. Skipping."
        fi
    done

else
    echo "No [\$SECTION] section found in \$CONFIG. Skipping addition of lines."
fi

EOF
