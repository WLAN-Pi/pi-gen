# A/B partition 

## Typical A/B update workflow

0. Update the inactive partition: `sudo update-alternate-partition <image.img.gz>`
0. Test the update: `sudo tryboot-alternate` 
0. Verify functionality: `sudo boot-info`
0. Make permanent: `sudo commit-current-partition`

You can also verify the update was applied by checking the traceability information in `/etc/rpi-issue`.

## Partition structure

The A/B partition layout uses:
- `p1`: CONFIGFS partition containing autoboot.txt and tryboot.txt
- `p2/p5`: Partition set A (boot/root)
- `p3/p6`: Partition set B (boot/root)
- `p7`: Home partition (shared)

Boot configuration is controlled by autoboot.txt in the CONFIGFS partition (p1), which determines which partition set boots by default.

## Management tools

0. `boot-info`: Shows current partition set, CONFIGFS configuration, and boot history
0. `update-alternate-partition <image.img.gz>`: Updates the inactive partition set from compressed OS image
0. `tryboot-alternate`: Configures CONFIGFS tryboot.txt for testing the alternate partition set
0. `commit-current-partition`: Updates CONFIGFS autoboot.txt to make current partition set the default

Manual trigger tryboot:

- `sudo reboot '2 tryboot'`: reboots and tests booting to partition set **A** (boot p2, root p5)
- `sudo reboot '3 tryboot'`: reboots and tests booting to partition set **B** (boot p3, root p6)

Notes:

- Tryboot tests are temporary - failed boots automatically revert to the original partition
- The home partition (p7) is shared between both partition sets
- CONFIGFS autoboot.txt controls default boot behavior after power loss

## `tryboot-alternate` usage

- `sudo tryboot-alternate --check`: See what would happen without applying changes
- `sudo tryboot-alternate`: Apply tryboot configuration and immediately reboot to test alternate partition
- After successful test: `sudo commit-current-partition`
