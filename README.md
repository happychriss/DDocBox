
![logo](https://github.com/happychriss/DocumentBox-Server/blob/master/app/assets/images/documentbox_pic.jpg)

DocumentBox
===========

DocumentBox is a OpenSource „home use“ Document Management system that helps you to
easy scan, file and find your documents. Its running on a mini computer
as small as a Raspberry Pi 3. A scanner connected to the mini-computers
allows you to quickly scan your documents and file them directly from
your mobile phone or tablet.

**DocumentBox is made for the paranoid** 

All data is stored locally – only
sending your files fully encrypted for backup to the the cloud (Amazon
S3). The database and all configuration data is also automatically
encrypted and uploaded to S3.

**DocumentBox is made to save your time**

A unique work-flow keeps your desk clean and lets you find your documents in a second.

**DocumentBox is made to make fun**

Check out, how it looks and feels:
https://www.youtube.com/watch?v=xCD8ukdc4cc

**DocumentBox is flexible and mobile**

I have also developed a mobile-app that allows uploading documents using the camera of your mobile phone. 
The scanned files are stored on the phone and will be uploaded to the DocumentBox server only in your local
Wifi network to assure your data privacy. This mobile app is not part of this repository and may be published later.

Technical Overview
==================

DocumentBox is running as a Linux RoR Web Service on the Pi 3. All
documents are indexed in a DB and stored locally (e.g. on SD card) .
Also OCR and image processing needs some computer power, the PI 3 is
able to process the data. But the design also allows to “outsource” this
action to any PC via a daemon program (communicating with the PI). An
optional configurable hardware depending component allows to control the
scanner and some LEDs for the print process.

The application is using Docker.

Installation
============

Prepare the PI
--------------

### General Preparation
Assure Raspian Stretch Light is installed
 
It is also important to name the RPI as "pi" !!!
```bash
File: //etc/hosts  

# fixed IP address for PI, add line:  
127.0.1.1   pi
```

You will need to configure the PI with a fixed IP address, to make it
possible for the SW services to work and to reach the DocumentBox from
your home network. Update following file
```bash
File: //etc/dhcpcd.con  

# fixed IP address for PI  
interface wlan0  
static ip_address=192.168.1.105/24 #enter your IP address  
static routers=192.168.1.1 # enter your gateway IP address
```

### Setup the user ‘docbox’

The installation instructions is assuming a user ‘docbox’ and a folder
structure as //home/docbox for the file system.

```bash
sudo adduser docbox
sudo adduser docbox sudo
```

Little tip, when using ssh to connect to pi, run 
```bash
ssh-copy-id docbox@pi
```
to directly connect to the pi without repeating password and passphrase.


Install Docker
---------------------------

* Login with user docbox into pi 
* Install Docker
* Install Docker Compose

Install Docbox
---------------------------
Login with user docbox.

```bash
cd
git clone https://github.com/happychriss/DDocBox.git
docker-compose up
```

This will date a long time to download the image and to start the app initial


Run Docbox
---------------------------
Open your browser: http://pi:8082/