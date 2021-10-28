#!/bin/bash

sudo rm /dev/centurion
sudo rmmod myDriver
sudo insmod myDriver.ko
sudo mknod /dev/centurion c 64 0
sudo chgrp wheel /dev/centurion 
sudo chmod 664 /dev/centurion 
