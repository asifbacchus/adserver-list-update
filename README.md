# adserver-list-update
bash-script to download updated adserver list files, deduplicate them and format the combined output file for use with DNSMASQ external hosts file.

This script downloads several popular, well maintained, lists of known adservers then amalagates those lists into one large list, removes duplicate entries and formats the whole thing to point to a configurable IP address in a format usable as a general hosts file or with DNSMASQ as an external hosts file. 

Let me first say this is made for my personal use on my ad-blocking DNSMASQ server (I'll link to my blog detailing full setup later).  I don't script often and the whole ad-blocking server is my way of better learning linux.  That being said, ANY suggestions (with explanations, please, so I can learn!) would be appreciated.  Otherwise, if this helps you too, then awesome!
Obviously no warranties or guantees are made by me in any form nor do I accept any responsibility if this destroys your computer, your personal life, your country or the world in general.

Script overview:

Variables:
Location for downloaded files ($locationSourcefiles) - removed after script completion
Location for working temp files ($locationWorkingfiles) - removed after script completion
Location for output file ($listpath) - where the final output file should be saved
Desired IP address for adservers to resolve ($dummyaddr) - recommend using 0.0.0.0 here or yor pixelserv address, etc.

This script downloads a set of known adserver addresses/hosts files from the following sources:
  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  https://mirror1.malwaredomains.com/files/justdomains
  http://sysctl.org/cameleon/hosts
  https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
  https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
  https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
  https://hosts-file.net/ad_servers.txt

The files are then parsed individually as needed to remove comments, interface addresses and target IP addresses.  A working copy of just domain names is saved in the working directory.

All individual lists are combined into one list, sorted alphabetically for ease of reading and duplicates are removed.

Finally, the desired $dummyaddr is prepended to each line so each adserver resolves to it.

The script then deletes the $locationSourcefiles and $locationWorkingfiles directories and their contents so that future updates start 'clean'.

To Do:
- Make it prettier
- Add chron entries to run this script at user-specified interval?
  - Restart DNSMASQ automatically after script is run to read newly updated/created hosts file

Let me know if you have any suggestions!  Thanks for checking out this script :-)
