xset s off
xset -dpms
~/scripts/screenlayout_default.sh &
~/scripts/GoXLR_loopback.sh &
dbus-update-activation-environment --systemd --all &
dunst &
/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 &
feh --randomize --bg-fill ~/Bilder/backgrounds/* &
flameshot &
nm-applet &
goxlr-daemon &
kdeconnectd &
#dbus-run-session -- sh -c 'exec dwm'
