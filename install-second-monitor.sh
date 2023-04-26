#!/bin/bash
# if you want to using laptop with lid is closed, consider adding the following line to 
#  /etc/systemd/logind.conf file

# HandleLideSwtich=ignore
change_second_monitor () {
  xrandr --auto
  xrandr --output DP1 --primary --auto
  xrandr --output eDP1 --left-of DP1 --auto 
}

turn_off_screen_light () {
  xbacklight -set 0
}

change_second_monitor
turn_off_screen_light

