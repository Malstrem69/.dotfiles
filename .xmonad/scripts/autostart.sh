#!/bin/bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# Display Resolution
#xrandr --output DisplayPort-0 --primary --mode 2560x1440 --rate 144.00 --output HDMI-A-1 --mode 1920x1080 --rate 75.00 --right-of DisplayPort-0 --output HDMI-A-0 --mode 1920x1080 --rate 75.00 --above DisplayPort-0 &

# Cursor active at boot
xsetroot -cursor_name left_ptr &

# Disable FN function
# echo 0 | sudo tee -a /sys/module/hid_apple/parameters/fnmode &

# Starting utility applications at boot time
# run variety &
run nm-applet &
run pamac-tray &
run flameshot &
#picom --config $HOME/.xmonad/scripts/picom.conf &
picom -b --experimental-backends --config $HOME/.xmonad/scripts/picom.conf
# Some ways to set your wallpaper besides variety or nitrogen
feh --randomize --bg-fill /home/kenaya/Pictures/Wallpapers/ &

# Conky
#(sleep 5; conky -c $HOME/.config/conky/conky) &

# Polybar
#(sleep 2; run $HOME/.config/polybar/launch.sh) &

# starting user applications at boot time

#run caffeine &
#run insync start &
#run ckb-next -b &
