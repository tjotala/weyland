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

Software Installation
---------------------
1) Download latest [Raspbian Jessie](https://www.raspberrypi.org/downloads/raspbian/) ISO image
2) [Write the ISO](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) onto the MicroSD card
3) Configure the Raspberry Pi Zero W boot image to connect to your [wireless network](https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=161202) by creating a new text file named `wpa_supplicant.conf` in the `/boot` folder of the MicroSD card. Its contents should look something like this:

```
network={
    ssid="YourNetworkSSID"
    psk="Your Network's Passphrase"
    key_mgmt=WPA-PSK
}
```

4) Enable SSH access by creating an empty file named `ssh` in the `/boot` folder of the MicroSD card:

```bash
$ touch /boot/ssh
```

5) Connect the Raspberry Pi Zero W to power supply
6) Login to the Raspberry Pi Zero W via SSH to install the rest of the software

```bash
ssh pi@<ip-address>
```

7) Update & upgrade the system image; this may take a while

```bash
sudo apt-get -y update
sudo apt-get -y upgrade
```

8) Install & configure `ntpdate` to maintain accurate time & date

```bash
sudo apt-get install -y ntpdate
sudo ntpdate -u pool.ntp.org
```

9) Install [Inkscape](https://inkscape.org); this may take a while

```bash
sudo apt-get -y install inkscape
```

10) Install [AxiDraw Inkscape extensions](https://github.com/evil-mad/axidraw/releases)

```bash
sudo apt-get -y install unzip python-lxml
wget -P /tmp https://github.com/evil-mad/axidraw/releases/download/v1.2.2/AxiDraw_122_MacLinux.zip
mkdir -p ~/.config/inkscape/extensions
unzip /tmp/AxiDraw_122_MacLinux.zip -d ~/.config/inkscape/extensions
rm /tmp/AxiDraw_122_MacLinux.zip
```
