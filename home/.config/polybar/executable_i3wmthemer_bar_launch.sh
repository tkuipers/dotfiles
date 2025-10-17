#!/bin/sh
pkill polybar
mon=$(xrandr | grep " connected " | awk '{ print$1 }' | wc -l)
if [ $mon == "3" ]; then
	xrandr --output eDP-1 --off
fi
sleep 1;
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload i3wmthemer_bar &
  done
else
  polybar --reload i3wmthemer_bar &
fi
