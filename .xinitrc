#!/usr/bin/env bash

# if we are on MacOSX, just stop here:
if [ "$(uname -s)" == "Darwin" ]; then
	quartz-wm
	exit
fi

#settings
xset -b
xrdb -merge ~/.i3/xresources

#multiple screen setup
[ -e ~/.screen_setup ] && source ~/.screen_setup

#background
[ -e ~/.fehbg ] && source ~/.fehbg

#hide mouse coursor when it isn't used
#unclutter -root -visible &

#dbus instance
eval `dbus-launch --sh-syntax --exit-with-session`

#apps
#start-pulseaudio-x11
#mpd &
#urxvtd &

#keyboard layout
#setxkbmap -layout pl
#setxkbmap -option ctrl:nocaps
#xmodmap ~/.i3/xmodmap
#[ -e ~/.xmodmap_local ] && xmodmap ~/.xmodmap_local

#color temperature adjustment, set for Gdańsk
#redshift -l 54.35:18.65 -m randr -t 5500:4500 -g 0.75:0.75:0.75 &

#notification
#dunst -config ~/.i3/dunstrc &

#disks automounting
#udiskie &

#other
[ -e /usr/bin/dropboxd ] && /usr/bin/dropboxd &

#creating gpg agent
GPG_ENVFILE="$HOME/.gnupg/gpg-agent.env"
if [ -x $(which gpg-agent) ]; then
eval "$(gpg-agent --enable-ssh-support --daemon --write-env-file "$GPG_ENVFILE")"
    export GPG_AGENT_INFO
fi

#composition manager
#compton --config ~/.i3/compton.conf &

# Capslocks is Ctrl
setxkbmap -option ctrl:nocaps

# Make printsrc as Windows key to use with i3 in the thinkpad
xmodmap -e "keycode 107 = Super_L"

/usr/bin/gnome-settings-daemon &

/usr/bin/gnome-do &

/usr/bin/nautilus -n &

i3


#getting rid of gpg agent
[ -x $(which gpg-agent) ] && kill $(grep GPG_AGENT_INFO "$GPG_ENVFILE" | cut -d: -f 2) 2>/dev/null

true


