#!/bin/bash
# Description: this patch is used to connect bluetooth headset that can support both external mic and external audio
# Author: An Pham
# Date: Sun 19 Jun 2022 10:15:08 PM PDT

blue_headset='E8_EE_CC_23_BD_5A'

connect_bluetooth () {
  local blue_device="$(echo "$blue_headset" | sed "s/_/:/g") "
  bluetoothctl -- connect  $blue_device; pactl set-sink-volume 0 20%
}

disconnect_bluetooth () {
  local blue_device="$(echo "$blue_headset" | sed "s/_/:/g") "
  bluetoothctl -- disconnect $blue_device; pactl set-sink-volume 0 0%
}

restart_bluetooth () {
  disconnect_bluetooth 
  systemctl restart bluetooth
  connect_bluetooth
}

set_audio_only () {
  # add profile to the card 
  pactl set-card-profile "bluez_card.$blue_headset" a2dp-sink
  pactl set-sink-volume 0 70%
  echo "Volme has been switched to audio mode"
}

check_if_device_available () {
  local device_name="$(bluetoothctl -- devices) | grep $blue_headset)"; 
  [ "$?" = 0 ] && echo "Deviced Found"
  grep -i [$bluetooth_headset]  
}

check_if_profile_available () {
  local profile_name=''
}

set_mic_only () {
  # add mic and audion 
  pactl set-card-profile "bluez_card.$blue_headset" headset-head-unit
  pactl set-sink-volume 0 40%
  echo "Volume has been switched to audio and mic mode"
}

main () {
  while [ -n "$1" ]
  do
     case "$1" in
       --reset | -r)
	 restart_bluetooth
	 shift
	 ;;
       --version | -v)
	 echo '1.0'
	 ;;
       -c | --connect)
	 connect_bluetooth
	 shift
	 ;;
       -d | --disconnect)
	 disconnect_bluetooth
	 shift
	 ;;
       --audio | -a)
	 set_audio_only 
	 shift
	 ;;
       --mic | -ac)
	 set_mic_only
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
  echo "Usuage: $(basename $0) <-c|-r|-l> "
  echo ''
  echo 'Where:'
  echo '  -c,--check       check if the bluetooth headset is connected'
  echo '  -r,--restart     restart the bluetooth headset connection' 
  echo '  -l,--list        show current bluetooth devices'
  echo '  -d,--disconnect  disconnect bluetooth headset'
  echo '  -a,--audio       connect with audio only'
  echo '  -ac,--audio-mic  connect with both audio and mic'
  echo '' 
  echo 'Example:'
  echo "  $(basename $0) -c | --check   Check if the device is connected"
}                      

main "$@"
