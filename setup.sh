#!/bin/bash

##################################################
#                                                #
#            define software to install          #
#            and set variable values             #
#                                                #
##################################################

# /etc/rc.local
USB_BUFFER_MEMORY='500'

# .bash_aliases
CREATE_AND_CONFIGURE_BASH_ALIASES=true
APRS_ALIAS='executeaprs'
SDR_ALIAS='executesdr'
LAUNCH_COMMAND='launchsequence'

# RTL_SDR
INSTALL_RTL_SDR_TOOLS=true

# Direwolf (APRS)
INSTALL_DIREWOLF=true
CALLSIGN='XXXXXX-XX'
CALLSIGN_PIN='XXXXX'
IGSERVER='euro.aprs2.net'

# HackRF tools
INSTALL_HACKRF_TOOLS=false

# SoapySDR
INSTALL_SOAPY_SDR=false

# RX tools
INSTALL_RX_TOOLS=false # requires SoapySDR

# Dump1090 (ADS-B)
INSTALL_DUMP1090=false

# RTL_433
INSTALL_RTL_433=false

# RTLSDR_Airband
INSTALL_RTL_SDR_AIRBAND=false



##################################################
#                                                #
#     update and upgrade the OS dependencies     #
#                                                #
##################################################

echo 'Updating OS dependencies'
sudo apt-get update &&

echo 'Upgrading OS dependencies'
sudo apt-get -y upgrade &&

echo 'Removing unused OS dependencies'
sudo apt autoremove



##################################################
#                                                #
#           allocate USB buffer memory           #
#                                                #
##################################################

echo 'Updating /etc/rc.local - allocating USB buffer memory'

# enable write permissions to the /etc/rc.local
sudo chmod 777 /etc/rc.local &&

# append to the end of the file
# allocates sufficiant buffer memory for the usb device (SDR dongle)
echo "$USB_BUFFER_MEMORY > /sys/module/usbcore/parameters/usbfs_memory_mb" >> /etc/rc.local &&

sudo chmod 644 /etc/rc.local


##################################################
#                                                #
#             install dependencies               #
#                                                #
##################################################

echo 'Installing 3rd party dependencies'

sudo apt-get install build-essential cmake pkg-config libusb-1.0-0-dev screen -y &&
sudo apt-get install pulseaudio libfftw3-dev libtclap-dev librtlsdr-dev pkg-config &&
sudo apt-get install sox vlc browser-plugin-vlc liblog4cpp5-dev libboost-dev && 
sudo apt-get install libboost-system-dev libboost-thread-dev &&
sudo apt-get install libboost-program-options-dev swig socat lame libsox-fmt-all &&
sudo apt-get install g++ libpython-dev python-numpy libhidapi-dev &&
sudo apt-get install libasound2-dev airspy libairspy-dev avahi-daemon &&
sudo apt-get install libavahi-client-dev libmp3lame-dev libshout3-dev &&
sudo apt-get install libconfig++-dev libraspberrypi-dev libfftw3-dev libpulse-dev



##################################################
#                                                #
#         create directory for SDR tools         #
#                                                #
##################################################

echo 'Creating sdr_tools directory'

​mkdir ~/sdr_tools && 
cd ~/sdr_tools &&



##################################################
#                                                #
#                 RTL-SDR Tools                  #
#                                                #
##################################################

if [ $INSTALL_RTL_SDR_TOOLS ]; then

    echo 'Installing RTL_SDR tools'

    cd ~/sdr_tools &&
    git clone git://git.osmocom.org/rtl-sdr.git &&
    cd rtl-sdr/ &&
    mkdir build &&
    cd build &&
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON make &&
    sudo make install &&
    sudo ldconfig

fi # end - install dependencies



##################################################
#                                                #
#                Direwolf (APRS)                 #
#                                                #
##################################################

if [ $INSTALL_DIREWOLF ]; then

    echo 'Installing Direwolf'

    cd ~/sdr_tools &&
    ​git clone https://www.github.com/wb2osz/direwolf &&
    cd direwolf &&
    ​make &&
    sudo make install &&
    ​make install-conf &&
    ​make install-rpi &&

    # if /home/pi/.bash_aliases file does not exist
    if [ ! -e ~/sdr_tools/direwolf/direwolf.conf ]; then

        ##################################################
        #                                                #
        #         update Direwolf configuration          #
        #                                                #
        ##################################################

        echo 'Configuring Direwolf'

        # update direwolf configuration
        sed -i 's/MYCALL NOCALL/MYCALL $CALLSIGN/g' ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i 's/#IGSERVER noam.aprs2.net/IGSERVER $IGSERVER/g' ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i 's/#IGLOGIN WB2OSZ-5 123456/IGLOGIN $CALLSIGN $CALLSIGN_PIN/g' ~/sdr_tools/direwolf/direwolf.conf
    fi

fi # end - install Direwolf (APRS)



##################################################
#                                                #
#               .bash_aliases                    #
#                                                #
##################################################

if [ $CREATE_AND_CONFIGURE_BASH_ALIASES && $SDR_ALIAS && $APRS_ALIAS && $INSTALL_RTL_SDR_TOOLS && $INSTALL_DIREWOLF ]; then

    # if /home/pi/.bash_aliases file does not exist
    if [ ! -e ~/.bash_aliases ]; then

        echo 'Creating .bash_aliases file'

        # create ./bash_aliases file within the /home/pi directory
        touch ~/.bash_aliases &&


        echo 'Adding aliases to .bash_aliases file'

        # append content to the end of the .bash_aliases file
        echo "alias $APRS_ALIAS='screen -d -m -S $APRS_ALIAS sh -c \"rtl_fm -d 1 -f 144.800M | direwolf -c ~/sdr_tools/direwolf/direwolf.conf -r 24000 -D 1 -\"'" >> ~/.bash_aliases &&
        echo "alias $SDR_ALIAS='screen -d -m -S $SDR_ALIAS sh -c \"rtl_tcp -d 0 -a 10.0.4.2 -s 2048000 -b 100\"'" >> ~/.bash_aliases &&
        echo "alias launchsequence='$APRS_ALIAS && $SDR_ALIAS'" >> ~/.bash_aliases

    fi

    # if the ~/.bash_aliases file exists
    if [ -e ~/.bash_aliases ]; then
        echo 'Sourcing .bash_aliases file'
        
        source ~/.bash_aliases
    fi

fi # end - .bash_aliases 



##################################################
#                                                #
#                 HACKRF Tools                   #
#                                                #
##################################################

if [ $INSTALL_HACKRF_TOOLS ]; then

    echo 'Installing HackRF tools'

    cd ~/sdr_tools &&
    git clone https://github.com/mossmann/hackrf.git &&
    cd hackrf/host &&
    mkdir build && 
    cd build &&
    cmake ../ -DINSTALL_UDEV_RULES=ON make &&
    sudo make install &&
    sudo ldconfig

fi # end - install HackRF tools



##################################################
#                                                #
#                   SoapySDR                     #
#                                                #
##################################################

if [ $INSTALL_SOAPY_SDR ]; then
    # to do

    echo 'Installing SoapySDR'

fi # end - install SoapySDR



##################################################
#                                                #
#                     RX Tools                   #
#                                                #
##################################################

if [ $INSTALL_SOAPY_SDR && $INSTALL_RX_TOOLS ]; then

    echo 'Installing RX tools'

    cd ~/sdr_tools &&
    git clone https://github.com/rxseger/rx_tools.git &&
    cmake . &&
    make &&

    # add the following to the end of the ~/.profile file
    # set PATH to rx_tools
    echo "if [ -d \"~/sdr_tools/rx_tools\" ]; then" >> ~/.profile &&
    echo "PATH=\"~/sdr_tools/rx_tools:$PATH\"" >> ~/.profile &&
    echo "fi" >> ~/.profile &&

    # source 
    source ~/.profile

fi # end - install RX tools



##################################################
#                                                #
#                Dump1090 (ADS-B)                #
#                                                #
##################################################

if [ $INSTALL_DUMP1090 ]; then

    echo 'Installing Dump1090'

fi # end - install Dump1090



##################################################
#                                                #
#                     RTL433                     #
#                                                #
##################################################

if [ $INSTALL_RTL_433 ]; then

    echo 'Installing RTL433'

fi # end - install RTL433



##################################################
#                                                #
#                 RTL_SDR_Airband                #
#                                                #
##################################################

if [ $INSTALL_RTL_SDR_AIRBAND ]; then

    echo 'Installing RTLSDR Airband'

fi # end - install RTL_SDR_Airband
