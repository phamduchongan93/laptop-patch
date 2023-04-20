#!/bin/bash
# Description: this patch is used to connect bluetooth headset that can support both external mic and external audio
# Author: An Pham
# Date: Sun 19 Jun 2022 10:15:08 PM PDT

# Add or change bluetooth device name here
blue_headset='E8:EE:CC:23:BD:5A'

# 
sudo_checker () {
  pass
}

string_convert () {
  local input_string="$1"
  # convert the '3B:64:D2:73:B4:C3' string to 3B_64_D2_73_B4_C3
  echo "$input_string" | sed -e 's/:/_/g'
}

connect_bluetooth () {
  hcitool con | grep $blue_headset &> /dev/null
  if [ $? == 1 ] 
  then
    while ! bluetoothctl -- connect "$blue_headset"
    do 
      echo "Waiting for bluetooth connection"
      sleep 1
    done
  fi
}

setting_audio_profile () {
  pactl set-sink-volume 0 20% 
  local blue_device="$(string_convert $blue_headset)"
  #check audio profile
  pactl set-default-sink "bluez_output.$blue_device.a2dp-sink" && notify-send "Audio connected!"
}

disconnect_bluetooth () {
  local blue_device="$(echo "$blue_headset" | sed "s/_/:/g") "
  bluetoothctl -- disconnect $blue_headset; pactl set-sink-volume 0 0%
  pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo
}

restart_bluetooth () {
  disconnect_bluetooth 
  systemctl --user daemon-reload
  connect_bluetooth
}

install_dependency () {
  # Installing pipewire audio library (on top of pulseaudio)
  add-apt-repository ppa:pipewire-debian/pipewire-upstream
  apt-get update
  apt install pipewire pipewire-audio-client-libraries
  apt install gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,media-session,bin,locales,tests}}
  # Installing notifier
  apt install dunst
}

repatch_bluetooth () {
  apt install libspa-0.2-bluetooth 
  systemctl --user --now disable pulseaudio.service pulseaudio.socket
  systemctl --user --now disable pulseaudio.service 
  systemctl --user --now disable pulseaudio.socket 
  systemctl --user mask pulseaudio
  systemctl --user --now enable pipewire-media-session.service
  systemctl --user restart pipewire
}

set_audio_only () {
  # add profile to the card 
  local bluetooth_dev="$(string_convert $blue_headset)"
  pactl set-card-profile "bluez_card.$bluetooth_dev" a2dp-sink && notify-send "Bluetooth headset has been switched to audio mode" 
  if [ $? == 0 ] 
  then
    pactl set-sink-volume 0 70%
    pactl set-default-sink "bluez_output.$bluetooth_dev.a2dp-sink"
  else 
    notify-send "Error: can't find audio source"
  fi
}

increase_volume () {
  pactl set-sink-volume 0 +10%
  notify-send "Volume has been increased"
}

decrease_volume () {
  pactl set-sink-volume 0 -10%
  notify-send "Volume has been decreased"
}

check_if_device_available () {
  local device_name="$(bluetoothctl -- devices) | grep $blue_headset)"; 
  [ "$?" = 0 ] && echo "Deviced Found"
  grep -i [$bluetooth_headset]  
  # WIP
}

set_mic_only () {
  # add mic and audion 
  local bluetooth_dev="$(string_convert $blue_headset)"

  pactl set-card-profile "bluez_card.$bluetooth_dev" headset-head-unit
  pactl set-sink-volume 0 40%
  echo "Volume has been switched to audio and mic mode"
  notify-send "Volume has been switched to audio and mic mode"
}

mute_audio () {
  pactl set-sink-volume 0 0%
}

unmute_audio () {
  pactl set-sink-volume 0 40%
}

main () {
  while [ -n "$1" ]
  do
     case "$1" in
       --reset | -r)
	 restart_bluetooth
	 shift
	 ;;
       --install-dependency )
	 install_dependency
	 shift
	 ;;
       --version | -v)
	 echo '1.0'
	 ;;
       --con | --connect)
	 connect_bluetooth
	 shift
	 ;;
       --dis | --disconnect)
	 disconnect_bluetooth
	 shift
	 ;;
       --audio | -a)
	 connect_bluetooth && sleep 3s && set_audio_only || echo "Fail: Unable to connect the bluetooth device"
	 shift
	 ;;
       -m)
	 mute_audio
	 shift
	 ;;
       -um)
	 unmute_audio
	 shift
	 ;;
       --mic | -ac)
	 connect_bluetooth && set_mic_only || echo "Fail: Unable to connect the bluetooth device"
	 shift
	 ;;
       -i | --inc)
         increase_volume 
	 shift
	 ;;
       --dec)
         decrease_volume 
	 shift
	 ;;
       * | -*)
	 echo 'Invalid argument'
	 help
	 exit 1
	 break
	 ;;
     esac
  done 
}

help () {
  echo "Usuage: $(basename $0) <--con|--dis|-a|-ac>. First, edit the variable to match your bluetooth interface MAC  address. "
  echo ''
  echo 'Where:'
  echo '  --con,--connect       connect to bluetooth device from the script'
  echo '  -r,--restart          restart the bluetooth headset connection' 
  echo '  -l,--list             show current bluetooth devices'
  echo '  --dis,--disconnect       disconnect bluetooth headset'
  echo '  -a,--audio            connect with audio only'
  echo '  -ac,--audio-mic       connect with both audio and mic'
  echo '  -m,--mute	        mute the audio'
  echo '  -um,--unmute	        unmute the audio'
  echo '  -i,--install	        install dependency'

  echo '' 
  echo 'Example:'
  echo "  $(basename $0) -c | --check   Check if the device is connected"
}                      

main "$@"
