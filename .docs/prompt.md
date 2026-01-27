# Original Requirements Prompt

to make this a truely cool kali installation i want to use whiptail or a better menu system. i want the menu to be generated from a folder structure, where the folder is the menu name, the scripts contained in the folder are the menu items, and any sub folders are submenus, folders / files that are . are hidden from the menu Currently the menu is formated like this pwd && tree -a
/home/alistair/menu-installer
.
├── .configs
├── mainmenu
│   ├── llm
│   │   ├── cli
│   │   └── ide
│   └── postsetup-kali
├── .postinstalls
└── .preinstalls
The pre and post installs are for installation of required packages .config is if there are any json, xml, text files required to make things work. the scripts to execute need a yaml identifier at the top, Neme, decsriotion, root privs needed, order in the list. to make this work ther is a .docs folder for templates user_manuals technical_manuals, we need a template for the scripts that will be called by the menu to isntall, configure things. what we need is a .claude CLAUDE.MD, TODO agents, sckills. we need to create a template so we know how to author scipts. the scripts must output to .docs/logs this is do the menu system can display the install logs if required for a command, we need a way of indicating if a script is installed and therefore and option to unistall if required, i am going with a boolean in the header yaml. there should be a script in the menu_installer called install_menu.sh this should include all of the softare needed to install the software for the menu to work, there should be a tag in the yaml header called hidden boolean type if true then do not show int he menu system this script needs true as it is only ti install the manu software eg whipttail etc.. this menu system can the be expaneded massively and be used to install kali tools, get scripts working etc...    i do not want you to detroy the scipts and work you jabe done, but convert it into this new format. descide what menu to do, how to create the menu system, is this a sepearte build scipt or on the fly. I want to use the modern menu system and not hide behine bash, bash is to install the menu it to present. we need docs and all the parts, to install the menu softeare create the intsall-menu.sh and use this as the tester to install what is needed, do not do anything by the backdoor as we need to make this repeatable. create .cluade and all the project files as well. Write this prompt out verbatim so we have a refernce to prompt.md as well
