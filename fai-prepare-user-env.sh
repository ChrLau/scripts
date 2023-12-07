# To be included into your FAI image (https://fai-project.org)
# Source: https://github.com/ChrLau/scripts/edit/master/fai-prepare-user-env.sh
#
# Tested with:
# - Debian 12 (Bookworm)
# Configures:
# - Timezone
# - Keyboard layout
# - Locales
# - $EDITOR variable
# - .bashrc / .vimrc / .htoprc
# - Static IPv4 network config
# - /etc/hosts & /etc/hostname

# Packages included in FAI:
# tmux htop mc unzip vim nmap sudo debconf-utils qemu-guest-agent
# - nmap is needed for network config
# - debconf-utils for debconf-set-selections
# - qemu-guest-agent for Proxmox VMs


export DEBIAN_FRONTEND=noninteractive

# Debconf selections DB is: /var/cache/debconf/config.dat

# MAYBE: cat into separate file and run "debconf-set-selections -c" before to check for errors??
# Timezone: UTC
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections
# Keyboard Layout: DE
echo "keyboard-configuration keyboard-configuration/layoutcode string  de" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/optionscode string ctrl:nocaps,terminate:ctrl_alt_bksp" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/variant select German" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/variantcode string" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/xkb-keymap select de" | debconf-set-selections
# Set UTF-8 as locale
echo "console-setup console-setup/charmap47 select UTF-8" | debconf-set-selections
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
# Choose UTF-8 locale to be re-generated
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections

# Set vim as texteditor
update-alternatives --set editor /usr/bin/vim.basic

# Thanks StackOverflow! ;-)
# Search for TEXT_TO_BE_REPLACED and replace it with the text "This line is removed by the admin."
#sed -i '/TEXT_TO_BE_REPLACED/c\This line is removed by the admin.' /tmp/foo

#To append after the pattern: (-i is for in place replace).
#line1 and line2 are the lines you want to append(or prepend)
#
#sed -i '/pattern/a \
#line1 \
#line2' inputfile
#Output:
#cat inputfile
# pattern
# line1 line2

#To prepend the lines before:
#sed -i '/pattern/i \
#line1 \
#line2' inputfile
#Output:
#cat inputfile
# line1 line2
# pattern

for BASHRC in /home/clauf/.bashrc; do

  # Set HISTTIMEFORMAT
  sed -i "/^HISTCONTROL=/a \
#Add timestamps and linenumbers to .bash_history\n\
HISTTIMEFORMAT='%F %T '" $BASHRC

  # Change HISTCONTROL
  sed -i 's/^HISTCONTROL=ignoreboth/HISTCONTROL=ignoredups/' $BASHRC

  # Append history immediately
  sed -i '/^shopt -s histappend/a \
# and write it immediately to .bash_history not only when the shell exists \(cleanly\) \
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"' $BASHRC

  # Change HISTSIZE
  sed -i 's/^HISTSIZE=1000/HISTSIZE=10000/' $BASHRC

  # Change HISTFILESIZE
  sed -i 's/^HISTFILESIZE=2000/HISTFILESIZE=20000/' $BASHRC

  # Enable color prompts
  sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' $BASHRC

  # Configure PS1
  # The 4 spaces in front of PS1 are important
  # Used: https://dwaves.de/tools/escape/
  # \x27 are single ticks. Only then this works correctly.
  sed -i '/^    PS1=.*033.*/c\    PS1=\x27\${debian_chroot:+(\$debian_chroot)}\\\[\\033\[1;34m\\\]\\u\\\[\\033\[0m\\\]@\\\[\\033\[1;35m\\\]\\h\\\[\\033\[0m\\\]:\\\[\\033\[1;32m\\\]\\w\\\[\\033\[0m\\\]\\\$ \x27' $BASHRC;

done


# Update package lists
apt-get update

# Simulate git install
apt-get -y -q -s install git

if [ "$?" -eq 0 ]; then

  # Install Git, download dotfiles repo and set Symlinks
  apt-get -yq install git

  # Create directories
  mkdir -p /home/clauf/git/github/chrlau/
  cd /home/clauf/git/github/chrlau/
  
  # Checkout repository
  git clone https://github.com/ChrLau/dotfiles.git
  
  # Adjust ownership
  chown -R clauf:clauf /home/clauf/git

  for DOTFILEUSER in root clauf; do

    HOMEDIR=$(getent passwd $DOTFILEUSER | cut -d: -f6 )

    # Symlink dotfiles
    ln -s /home/clauf/git/github/chrlau/.tmuxrc $HOMEDIR/.tmuxrc
    ln -s /home/clauf/git/github/chrlau/.htoprc $HOMEDIR/.htoprc
    ln -s /home/clauf/git/github/chrlau/.screenrc $HOMEDIR/.screenrc
    ln -s /home/clauf/git/github/chrlau/.vimrc $HOMEDIR/.vimrc
    
  ; done

fi

# FAI website can't set SSH-Keys for individual users. So we use this.
mkdir /home/clauf/.ssh && chmod 0700 /home/clauf/.ssh && cp /root/.ssh/authorized_keys /home/clauf/.ssh/authorized_keys && chown clauf:clauf -R /home/clauf/.ssh && chmod 0640 /home/clauf/.ssh/authorized_keys

# Generate static IPv4 network config
# We use nmap to scan a given static IPv4-Range and use the first IP marked as DOWN which has an DNS-Record
NMAP="$(which nmap)"
# Test if nmap is present and executeable
if [ ! -x "$NMAP" ]; then
  echo "This script requires nmap. Exiting."
  exit 2;
fi

# -R is important, else no DNS-Resolution for hosts marked as DOWN
FIRST_DOWN_HOST=$(nmap -v -sn -R 192.168.178.21-49 -oG - | grep -m1 -oP "^Host:[[:space:]]192\.168\.178\.[0-9]{2}[[:space:]]\([a-zA-Z0-9\-]+\.lan\)[[:space:]]Status: Down")
#echo "FIRST_DOWN_HOST: $FIRST_DOWN_HOST"

IP=$(awk '{print $2}' <<<$FIRST_DOWN_HOST)
#echo "IP: $IP"

FQDN=$(awk -F'[()]' '{print $2}' <<<$FIRST_DOWN_HOST)
#echo "FQDN: $FQDN"

GATEWAY=$(ip -o -4 route show to default | awk '{print $3}')
#echo "GATEWAY: $GATEWAY"

INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
#echo "INTERFACE: $INTERFACE"

# Save old network config
if [ -f /etc/network/interfaces.d/$INTERFACE ]; then
  cp /etc/network/interfaces.d/$INTERFACE /etc/network/interface-$INTERFACE.scriptcopy
fi

# Write new config
# FAI uses /etc/network/interfaces.d/$INTERFACE and not /etc/network/interfaces
cat <<NETWORKEOF > /etc/network/interfaces.d/$INTERFACE
# Generated by fai-prepare-user-env.sh

# The primary network interface
auto $INTERFACE
allow-hotplug $INTERFACE
iface $INTERFACE inet static
  address $IP
  netmask 255.255.255.0
  gateway $GATEWAY
  dns-nameservers 192.168.178.9

#iface $INTERFACE inet6 static
#  address fd00::b4fd:51ff:fe7b:XXXX
#  netmask 64
#  gateway fe80::1
NETWORKEOF

# Set /etc/hosts
# Only add if not already present
grep -q "$IP[[:blank:]]$FQDN[[:blank:]]$HOST" /etc/hosts

if [ "$?" -ne 0 ]; then
  echo "$IP\t$FQDN\t$HOST" >> /etc/hosts
#else
#  echo "/etc/hosts entry already present"
fi

# Set Hostname - only if variable is not empty
if [ ! -z $FQDN ]; then
  echo "$FQDN" > /etc/hostname
#else
#  echo "FQDN is empty"
fi
