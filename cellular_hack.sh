#!/bin/bash

ttl_hack () {
  echo "Enable ttl Hack ..."
  iptables -t mangle -I POSTROUTING 1 -j TTL --ttl-set 66
}


display_interface () {
  echo "Displaying the interface monitoring ...."
  iftop -m 5MB -i wlp2s0
}

ttl_hack
display_interface 
