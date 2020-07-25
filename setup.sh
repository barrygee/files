#!/bin/bash

##################################################
#                                                #
#            define software to install          #
#            and set variable values             #
#                                                #
##################################################

# /etc/rc.local
usb_buffer_memory='500'

# .bash_aliases
create_and_configure_bash_aliases=true
aprs_alias='executeaprs'
sdr_alias='executesdr'
launch_command='launchsequence'

# RTL_SDR
install_rtl_sdr_tools=true

# Direwolf (APRS)
install_direwolf=true
callsign='XXXXXX-XX'
callsign_pin='XXXXX'
igserver='euro.aprs2.net'

# HackRF tools
install_hackrf_tools=false

# SoapySDR
install_soapy_sdr=false

# RX tools
install_rx_tools=false # requires SoapySDR

# Dump1090 (ADS-B)
install_dump1090=false

# RTL_433
install_rtl_433=false

# RTLSDR_Airband
install_rtl_sdr_airband=false



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
sudo apt autoremove -y



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
echo "$usb_buffer_memory > /sys/module/usbcore/parameters/usbfs_memory_mb" >> /etc/rc.local &&

sudo chmod 644 /etc/rc.local



##################################################
#                                                #
#             install dependencies               #
#                                                #
##################################################

echo 'Installing 3rd party dependencies'

sudo apt-get install build-essential cmake pkg-config libusb-1.0-0-dev screen pulseaudio libfftw3-dev libtclap-dev librtlsdr-dev pkg-config sox vlc browser-plugin-vlc liblog4cpp5-dev libboost-dev libboost-system-dev libboost-thread-dev libboost-program-options-dev swig socat lame libsox-fmt-all g++ libpython-dev python-numpy libhidapi-dev libasound2-dev airspy libairspy-dev avahi-daemon libavahi-client-dev libmp3lame-dev libshout3-dev libconfig++-dev libraspberrypi-dev libfftw3-dev libpulse-dev -y &&



##################################################
#                                                #
#         create directory for SDR tools         #
#                                                #
##################################################

echo 'Creating sdr_tools directory'

cd ~/ &&
mkdir sdr_tools && 
chmod 777 sdr_tools &&
cd ./sdr_tools



##################################################
#                                                #
#                 RTL-SDR Tools                  #
#                                                #
##################################################

if $install_rtl_sdr_tools ; then

    echo 'Installing RTL_SDR tools'

    cd ~/sdr_tools &&
    git clone git://git.osmocom.org/rtl-sdr.git &&
    cd rtl-sdr/ &&
    mkdir build &&
    cd build/ &&
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON &&
    make &&
    sudo make install &&
    sudo ldconfig

fi # end - install dependencies



##################################################
#                                                #
#                Direwolf (APRS)                 #
#                                                #
##################################################

if $install_direwolf ; then

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
        sed -i 's/MYCALL NOCALL/MYCALL $callsign/g' ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i 's/#IGSERVER noam.aprs2.net/IGSERVER $igserver/g' ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i 's/#IGLOGIN WB2OSZ-5 123456/IGLOGIN $callsign $callsign_pin/g' ~/sdr_tools/direwolf/direwolf.conf
    fi

fi # end - install Direwolf (APRS)



##################################################
#                                                #
#               .bash_aliases                    #
#                                                #
##################################################

if $create_and_configure_bash_aliases &&
   $sdr_alias && 
   $aprs_alias && 
   $install_rtl_sdr_tools && 
   $install_direwolf ; then

    # if /home/pi/.bash_aliases file does not exist
    if [ ! -e ~/.bash_aliases ]; then

        echo 'Creating .bash_aliases file'

        # create ./bash_aliases file within the /home/pi directory
        touch ~/.bash_aliases &&


        echo 'Adding aliases to .bash_aliases file'

        # append content to the end of the .bash_aliases file
        echo "alias $aprs_alias='screen -d -m -S $aprs_alias sh -c \"rtl_fm -d 1 -f 144.800M | direwolf -c ~/sdr_tools/direwolf/direwolf.conf -r 24000 -D 1 -\"'" >> ~/.bash_aliases &&
        echo "alias $sdr_alias='screen -d -m -S $sdr_alias sh -c \"rtl_tcp -d 0 -a 10.0.4.2 -s 2048000 -b 100\"'" >> ~/.bash_aliases &&
        echo "alias launchsequence='$aprs_alias && $sdr_alias'" >> ~/.bash_aliases

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

if $install_hackrf_tools ; then

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

if $install_soapy_sdr ; then
    # to do

    echo 'Installing SoapySDR'

fi # end - install SoapySDR



##################################################
#                                                #
#                     RX Tools                   #
#                                                #
##################################################

if $install_soapy_sdr && $install_rx_tools ; then

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

if $install_dump1090 ; then

    echo 'Installing Dump1090'

fi # end - install Dump1090



##################################################
#                                                #
#                     RTL433                     #
#                                                #
##################################################

if $install_rtl_433 ; then

    echo 'Installing RTL433'

fi # end - install RTL433



##################################################
#                                                #
#                 RTL_SDR_Airband                #
#                                                #
##################################################

if $install_rtl_sdr_airband ; then

    echo 'Installing RTLSDR Airband'

fi # end - install RTL_SDR_Airband
