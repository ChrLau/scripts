# To be run after FAI installation
# Test with:
# - Debian Bookworm
# Configures:
# - Timezone
# - Keyboard layout
# - Locales
# - $EDITOR variable
# - .bashrc

export DEBIAN_FRONTEND=noninteractive

# Timezone: UTC
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections
# Keyboard Layout: DE
echo "keyboard-configuration keyboard-configuration/xkb-keymap select de" | debconf-set-selections
# Choose UTF-8 locale to be generated
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
# Set UTF-8 as locale
echo "console-setup console-setup/charmap47 select UTF-8" | debconf-set-selections
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections

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
