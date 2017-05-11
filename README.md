Introduction
------------
This is HOWTO for building a wireless print server for a AxiDraw v3 pen plotter.


Hardware Parts
--------------
* [Raspberry Pi Zero W](https://www.adafruit.com/product/3400) system board
* [Power Supply](http://a.co/26ZpROt)
* [Micro-USB to USB OTG adapter](http://a.co/i04myNU); connect the pen plotter's USB cable
* [MicroSD card](http://a.co/3a2ZoW6); minimum 8GB
* (optional) [Case](http://a.co/1DJdba2)

Preparing the MicroSD Card with the Raspberry Pi boot image
----------------------------------------------------------
1) Download latest [Raspbian Jessie](https://www.raspberrypi.org/downloads/raspbian/) ISO image

2) [Write the ISO](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) onto the MicroSD card

3) Configure the Raspberry Pi boot image to connect to your [wireless network](https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=161202) by creating a new text file named `wpa_supplicant.conf` in the `/boot` folder of the MicroSD card. Its contents should look something like this:

```
network={
    ssid="YourNetworkSSID"
    psk="Your Network's Passphrase"
    key_mgmt=WPA-PSK
}
```

4) Enable SSH access by creating an empty file named `ssh` in the `/boot` folder of the MicroSD card

(These steps are Mac OS)
```
touch /Volumes/boot/ssh
```

5) Unmount the MicroSD card and insert it into the Raspberry Pi

6) Connect the Raspberry Pi to a power supply

7) Find out the IP address of the Raspberry Pi. One way is to look at your WiFi access point to find the IP address of a device named "raspberrypi". Another way is to connect the Raspberry Pi to an HDMI display, keyboard and mouse and use the Pixel GUI to find out its IP address.

8) Copy your SSH key to the Raspberry Pi

```
brew install ssh-copy-id
ssh-copy-id pi@<ip_address>
```

9) Test the SSH login. You should not be prompted for the password.

```
ssh pi@<ip_address>
exit # from the SSH
```

Installing the Application Software
-----------------------------------
These steps will finish the software installation onto the MicroSD now inserted in the Raspberry Pi.

1) Clone this github repo

```
cd <work_dir>
git clone git@github.com:tjotala/weyland.git
cd weyland
```

2) Install [bundler](https://bundler.io/)

```
gem install bundler
```

3) Install all the required gems

```
cd <work_dir>/weyland
bundle install
```

4) Configure deployment to the target Raspberry Pi

```
nano config/deploy/staging.rb
# change IP address to match
```

5) Prepare the Raspberry Pi for deployment (only needs to be done once)

```
cap staging deploy:prepare:system
```

6) Deploy the code to the Raspberry Pi

```
cap staging deploy
```
