#!/bin/bash

if ! (locale | grep -i "utf-8" > /dev/null); then
        echo -e "\a\n\n\n\t!!!!ATTENTION!!!!\n\nIt seems that your locale setting is ^[[31mnot^[[0m using an UTF-8 character set.\nPlease check with command 'locale'.\n\n"
fi

