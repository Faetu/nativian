#!/bin/sh




install_nativian () {
	rm -rf "/home/$1/.local/share/nativian"
	mkdir "/home/$1/.local/share/nativian"
	cp ./icons/nativian.svg "/home/$1/.local/share/nativian"
	chown -R $1 "/home/$1/.local/share/nativian"
	cp ./icons/obsidian.svg /usr/share/pixmaps/
	cp ./rundian/rundian.sh /usr/bin/
	chmod +x /usr/bin/rundian.sh
	cp ./rundian/obsidian.desktop /usr/share/applications/
	zenity --info --text="Succesfully installed\!" --title="Done" --width=500 --width=200 --icon-name=checkmark
}

remove_nativian () {
	rm /usr/share/applications/obsidian.desktop
	rm /usr/share/pixmaps/obsidian.svg
	rm /usr/bin/rundian.sh
	rm -rf "/home/$1/.local/share/nativian"
	zenity --info --text="Succesfully removed\!" --title="Done" --width=500 --width=200 --icon-name=checkmark
}

action=$(zenity --info --title 'Nativian installer' \
      --text 'What do you want to do?' \
      --ok-label install \
      --extra-button uninstall --extra-button nothing \
      )

username=`logname`
case $action in
	nothing)
		exit 0
		;;
	uninstall)
		remove_nativian "$username"
		;;
	*)
		install_nativian "$username"
		;;
esac
