#!/bin/bash

all_releases="https://api.github.com/repos/obsidianmd/obsidian-releases/releases"


architecture=`uname -m`
# filter list for arm or x86
regex='(https:\/\/).*(arm64\.AppImage)'
if [[ "$architecture" != "aarch64" ]]; then
	regex='(https:\/\/).*((?<!arm64)\.AppImage)'
fi
release_list=`curl -Lis $all_releases | grep -o -P $regex`

# get release list
IFS=$'\n' read -rd '' -a arr_release_list <<< "$release_list"
# get latest release for the architecture
latest_release_url=${arr_release_list[0]}
latest_release_version=`echo $latest_release_url | grep -o -P '(?<=download\/v).*(?=\/Obsidian)'`

# download specific release to ~/.local/share/nativian
download_obsidian () {
	echo "download from $1"
	(
	wget "$1" -P ~/.local/share/nativian |& grep -o -P "(?<=\s)[0-9]{0,3}(?=%)"
	echo "# Finished!"
	) | zenity --progress --title="Downloading Obsidian..." --auto-close
}

# make native window decoration
enable_frame () {
	(
	echo "# extract appimage"
	echo 20
	cd ~/.local/share/nativian/
	chmod +x "$1"
	"$1" --appimage-extract
	echo "# extract asar"
	echo 40
	npx asar extract ./squashfs-root/resources/obsidian.asar ./squashfs-root/resources/obsidian.asar.extracted
	echo "# replace frame value to true"
	echo 60
	sed -i 's/frame: false/frame: true/' ./squashfs-root/resources/obsidian.asar.extracted/main.js
	echo "# pack asar again"
	echo 80
	npx asar pack ./squashfs-root/resources/obsidian.asar.extracted ./squashfs-root/resources/obsidian.asar
	rm ~/.config/obsidian/obsidian-*.asar
	echo "# create new appimage"
	echo 99
	rm "$1"
	appimagetool ./squashfs-root "$1"
	rm -rf ./squashfs-root
	) | zenity --progress --title="build obsidian" --auto-close --window-icon=~/.local/share/nativian/nativian.svg --width=500 --width=200
	echo "build it to $1"
}

# ask for specific release version to install
choose_version () {
	version_dialog_list=""
	for idx in "${!arr_release_list[@]}"
	do
		version_only=`echo "${arr_release_list[$idx]}" | grep -o -P '(?<=Obsidian-)[0-9]{0,2}\.[0-9]{0,2}\.[0-9]{0,2}'`
		version_dialog_list="$version_dialog_list $idx $version_only"
	done
	dialog=`zenity --list --hide-header $version_dialog_list --column "index" --column "version" --hide-column=1 --print-column=1`
	echo "${arr_release_list[$dialog]}"
}



# check if obsidian installed
appImage=`ls ~/.local/share/nativian/Obsidian*AppImage`

if [[ ! $# -eq 0 && ($1 == "-s" || $1 == "--select-version") ]]; then
	choosen_version=$(choose_version)
	if [[ -f "$appImage" ]]; then
		rm "$appImage"
	fi
	download_obsidian $choosen_version
	appImage=`ls ~/.local/share/nativian/Obsidian*AppImage`
	enable_frame "$appImage"
	"$appImage"
else
	if [[ -f "$appImage" ]]; then
		current_version=`echo $appImage | grep -o -P '(?<=Obsidian-)[0-9]{0,2}\.[0-9]{0,2}\.[0-9]{0,2}'`
		if [[ $current_version == $latest_release_version || `printf "$latest_release_version\n$current_version" | sort -V | tail -1` == $current_version ]]; then
			"$appImage"
		else
			if zenity --question --title="Obsidian $latest_release_version" --text="A new version of Obsidian ($latest_release_version) is available!\nDo you want to upgrade now?" --no-wrap --icon-name=obsidian --width=500 --width=200
	    		then
	    			rm "$appImage"
	    			download_obsidian "$latest_release_url"
	    			appImage=`ls ~/.local/share/nativian/Obsidian*AppImage`
	    			enable_frame "$appImage"
			fi
			"$appImage"
		fi
	else
		if zenity --question --title="Nativian not found" --text="It seems that nativian is not installed.\nWant to install it?" --no-wrap --icon-name=obsidian --width=500 --width=200
		then
			myname=`whoami`
			notify-send "$myname"
			download_obsidian "$latest_release_url"
			appImage=`ls ~/.local/share/nativian/Obsidian*AppImage`
			enable_frame "$appImage"
			"$appImage"
		fi
		exit 0
	fi
fi
