#!/bin/bash
# Description: this patch is used to connect bluetooth headset that can support both external mic and external audio
# Author: An Pham
# Date: Sun 19 Jun 2022 10:15:08 PM PDT

# Add or change bluetooth device name here
blue_headset='E8:EE:CC:23:BD:5A'

sudo_checker () {
  pass
}

string_convert () {
  local input_string="$1"
  # convert the '3B:64:D2:73:B4:C3' string to 3B_64_D2_73_B4_C3
  echo "$input_string" | sed -e 's/:/_/g'
}

connect_bluetooth () {
  local blue_device="$(echo "$blue_headset" | sed "s/_/:/g") "
  bluetoothctl -- connect  $blue_headset; pactl set-sink-volume 0 20% 
}

setting_audio_profile () {
  pactl set-sink-volume 0 20% 
  local blue_device="$(string_convert $blue_headset)"
  pactl set-default-sink "bluez_output.$blue_device.a2dp-sink"
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
  add-apt-repository ppa:pipewire-debian/pipewire-upstream
  apt-get update
  apt install pipewire pipewire-audio-client-libraries
  apt install gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,media-session,bin,locales,tests}}
}

install_notifier () {
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
  pactl set-card-profile "bluez_card.$bluetooth_dev" a2dp-sink && notify-send "Bluetooth headset has been switched to audio mode" || notify-send "Unable to switch to audio sink";

  pactl set-sink-volume 0 70%
  pactl set-default-sink bluez_output.$bluetooth_dev.a2dp-sink
  notify-send "Volume has been switched to 70 percent"
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
  bluetooth_dev="$(string_convert $blue_headset)"

  pactl set-card-profile "bluez_card.$blue_headset" headset-head-unit
  pactl set-sink-volume 0 40%
  echo "Volume has been switched to audio and mic mode"
  notify-send "Volume has been switched to audio and mic mode"
}

main () {
  while [ -n "$1" ]
  do
     case "$1" in
       --reset | -r)
	 restart_bluetooth
	 shift
	 ;;
       --install | -i)
	 install_dependency
	 shift
	 ;;
       --version | -v)
	 echo '1.0'
	 ;;
       -c | --connect)
	 restart_bluetooth 
	 connect_bluetooth
	 shift
	 ;;
       -d | --disconnect)
	 disconnect_bluetooth
	 shift
	 ;;
       --audio | -a)
	 connect_bluetooth && set_audio_only || echo "Fail: Unable to connect the bluetooth device"
	 shift
	 ;;
       --mic | -ac)
	 connect_bluetooth && set_mic_only || echo "Fail: Unable to connect the bluetooth device"
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
  echo "Usuage: $(basename $0) <-c|-d|-a|-ac>. First, edit the variable to match your bluetooth interface MAC  address. "
  echo ''
  echo 'Where:'
  echo '  -c,--check       check if the bluetooth headset is connected'
  echo '  -r,--restart     restart the bluetooth headset connection' 
  echo '  -l,--list        show current bluetooth devices'
  echo '  -d,--disconnect  disconnect bluetooth headset'
  echo '  -a,--audio       connect with audio only'
  echo '  -ac,--audio-mic  connect with both audio and mic'
  echo '  -i,--install	   install dependency'
  echo '' 
  echo 'Example:'
  echo "  $(basename $0) -c | --check   Check if the device is connected"
}                      

main "$@"
