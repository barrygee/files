#!/bin/bash

##################################################
#                                                #
#          select the software to install        #
#          and set variable values               #
#                                                #
##################################################

# Host
rpi_ip_address='XX.X.X.X'
latitude='XX.XXX'
longitude='-X.XXX'

# Raspi-config
host_name='RPi_HOST_NAME'
password='PI_USER_PASSWORD'
resolution='82' # DMT Mode 82 1920x1080 60Hz 16:9
enable_vnc=1    # 1 = true | 0 = false

# /etc/rc.local
usb_buffer_memory='1000'

# screen multi-window config file name
screenrc_config_file_name='.screenrc-sdr' # .screenrc-sdr | .screenrc-sdr-paul

# .bash_aliases
create_and_configure_bash_aliases=true
aprs_alias='startaprs'
sdr_alias='startsdr'
adsb_alias='startadsb'
launchsdr='launchsdr' # uses 'screen' config for output layout

# RTL_SDR
install_rtl_sdr_tools=true
rtl_tcp_sample_rate='2048000'

# Direwolf (APRS)
install_direwolf=true
direwolf_conf_file=sdr.conf # sdr.conf = RX only | direwolf.conf RX and TX
callsign='XXXXX-XX'
callsign_pin='XXXXX'
igserver='euro.aprs2.net'

# Dump1090 (ADS-B)
install_dump1090=true
dump1090_port=9999

# SoapySDR
install_soapy_sdr=false

# RX tools
install_rx_tools=false # requires SoapySDR

# RTL_433
install_rtl_433=false

# RTLSDR_Airband
install_rtl_sdr_airband=false

# Used during setup only - do not manually update
raspi_config_updated=false


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


if [ "$raspi_config_updated" = false ]; then

    ##################################################
    #                                                #
    #               Update raspi-config              #
    #     Automates making changes that would be     #
    #       made by running sudo raspi-config        #
    #                                                #
    ##################################################

    echo 'Updating raspi-config'

    echo 'Setting Hostname'
    sudo raspi-config nonint do_hostname $host_name

    echo 'Setting new password for pi user'
    echo "pi:$password" | sudo chpasswd

    echo 'Setting WiFi country to GB'
    sudo raspi-config nonint do_wifi_country GB

    echo 'Setting Resolution to DMT Mode 82 1920x1080 60Hz 16:9'
    sudo raspi-config nonint do_resolution 2 $resolution

    echo 'Expanding the file system'
    sudo raspi-config nonint do_expand_rootfs

    echo 'Setting VNC'
    sudo raspi-config nonint do_vnc $enable_vnc

    echo 'Updating Radio-RPi-Setup.sh - raspi_config_updated variable'
    sed -i "s/raspi_config_updated=false/raspi_config_updated=true/g" ~/Radio-RPi-Setup.sh

    echo 'Rebooting RPi'
    sudo reboot now

else

    ##################################################
    #                                                #
    #           allocate USB buffer memory           #
    #                                                #
    ##################################################

    echo 'Allocating USB buffer memory'

    sudo chmod 777 ~/.bashrc &&

    sudo sh -c "echo $usb_buffer_memory > /sys/module/usbcore/parameters/usbfs_memory_mb" >> ~/.bashrc



    ##################################################
    #                                                #
    #             install dependencies               #
    #                                                #
    ##################################################

    echo 'Installing 3rd party dependencies'

    sudo apt-get install build-essential cmake pkg-config libusb-1.0-0-dev screen pulseaudio libfftw3-dev libtclap-dev librtlsdr-dev pkg-config sox vlc browser-plugin-vlc liblog4cpp5-dev libboost-dev libboost-system-dev libboost-thread-dev libboost-program-options-dev swig socat lame libsox-fmt-all g++ libpython-dev python-numpy libhidapi-dev libasound2-dev airspy libairspy-dev avahi-daemon libavahi-client-dev libmp3lame-dev libshout3-dev libconfig++-dev libraspberrypi-dev libfftw3-dev libpulse-dev -y &&



    ##################################################
    #                                                #
    #        create .screenrc-sdr config file        #
    #                                                #
    ##################################################

    echo 'Creating .screenrc-sdr'

    cd ~/ &&
    touch .screenrc-sdr &&
    chmod 777 .screenrc-sdr &&

    echo 'Adding content to .screenrc-sdr'

    echo "screen bash" >> .screenrc-sdr
    echo "title 'Command line'" >> .screenrc-sdr
    echo "split -v" >> .screenrc-sdr
    echo "split" >> .screenrc-sdr
    echo "focus" >> .screenrc-sdr
    echo "screen bash -ic 'rtl_tcp -d 1 -a $rpi_ip_address -s 2048000 -b 100'" >> .screenrc-sdr
    echo "title 'SDR available for remote connection'" >> .screenrc-sdr
    echo "focus" >> .screenrc-sdr
    echo "screen ./sdr_tools/dump1090/dump1090 --device-index 0 --enable-agc --aggressive --interactive --net --net-http-port 9999" >> .screenrc-sdr
    echo "title 'ADS-B'" >> .screenrc-sdr
    echo "focus" >> .screenrc-sdr
    echo "focus up" >> .screenrc-sdr
    echo "focus left" >> .screenrc-sdr


    cd ~/ &&
    touch .screenrc-sdr-paul &&
    chmod 777 .screenrc-sdr-paul &&

    echo 'Adding content to .screenrc-sdr-paul'

    echo "screen bash -ic startaprs" >> .screenrc-sdr-paul
    echo "split -v" >> .screenrc-sdr-paul
    echo "focus right" >> .screenrc-sdr-paul
    echo "split" >> .screenrc-sdr-paul
    echo "screen bash -ic startsdr" >> .screenrc-sdr-paul
    echo "focus down" >> .screenrc-sdr-paul
    echo "focus right" >> .screenrc-sdr-paul
    echo "screen bash" >> .screenrc-sdr-paul



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
        git clone https://github.com/wb2osz/direwolf.git &&
        chmod 775 ./direwolf
        cd direwolf &&
        make &&
        sudo make install &&
        make install-conf &&
        make install-rpi &&

        #########################################
        #                                       #
        #         update configuration          #
        #                                       #
        #########################################

        # sdr.conf is used if the APRS station is receive only so does not rebroadcast APRS packets over RF
        # does not beacon and works as an iGate
        echo 'Configuring Direwolf sdr.conf'

        # update sdr.conf configuration
        sed -i "s/MYCALL xxx/MYCALL $callsign/g" ~/sdr_tools/direwolf/sdr.conf &&
        sed -i "s/IGSERVER noam.aprs2.net/IGSERVER $igserver/g" ~/sdr_tools/direwolf/sdr.conf &&
        sed -i "s/IGLOGIN xxx 123456/IGLOGIN $callsign $callsign_pin/g" ~/sdr_tools/direwolf/sdr.conf &&

        # requires updating only if sdr.conf | RX only is being used      
        echo 'Updating dw-start.sh'

        sed -i 's/DWCMD="$DIREWOLF -a 100"/#DWCMD="$DIREWOLF -a 100"/g' ~/sdr_tools/direwolf/dw-start.sh &&
        sed -i "s/#DWCMD=\"bash -c 'rtl_fm -f 144.39M - | direwolf -c sdr.conf -r 24000 -D 1 -'\"/DWCMD=\"bash -c 'rtl_fm -f 144.80M - | direwolf -c sdr.conf -r 24000 -D 1 -'\""
            
        

        # direwolf.conf is used if the APRS station both receives and transmits APRS packets over RF,
        # beacons and works as an iGate
        echo 'Configuring Direwolf direwolf.conf'

        # update direwolf configuration
        sed -i "s/MYCALL N0CALL/MYCALL $callsign/g" ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i "s/#IGSERVER noam.aprs2.net/IGSERVER $igserver/g" ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i "s/#IGLOGIN WB2OSZ-5 123456/IGLOGIN $callsign $callsign_pin/g" ~/sdr_tools/direwolf/direwolf.conf &&
        sed -i "s/#PBEACON sendto=IG delay=0:30 every=60:00 symbol=\"igate\" overlay=R lat=42^37.14N long=071^20.83W/PBEACON sendto=IG delay=0:30 every=60:00 symbol=\"igate\" overlay=R lat=$latitude long=$longitude/g" ~/sdr_tools/direwolf/direwolf.conf
            

        echo 'Deleting unneeded Direwolf files'

        cd ~/ &&
        rm dw-start.sh &&
        rm sdr.conf &&
        rm direwolf.conf &&
        rm telem-balloon.conf &&
        rm telem-m0xer-3.txt &&
        rm telem-volts.conf

    fi # end - install Direwolf (APRS)



    ##################################################
    #                                                #
    #                Dump1090 (ADS-B)                #
    #                                                #
    ##################################################

    if $install_dump1090 ; then

        echo 'Installing Dump1090'

        cd ~/sdr_tools &&
        git clone https://github.com/antirez/dump1090.git &&
        cd dump1090 &&
        echo 'Updating Dump1090 Makefile'
        chmod 775 ~/sdr_tools/dump1090/ -R &&
        make

    fi # end - install Dump1090



    ##################################################
    #                                                #
    #               .bash_aliases                    #
    #                                                #
    ##################################################

    if $create_and_configure_bash_aliases ; then

        # if /home/pi/.bash_aliases file does not exist
        if [ ! -e ~/.bash_aliases ]; then

            echo 'Creating .bash_aliases file'

            # create ./bash_aliases file within the /home/pi directory
            touch ~/.bash_aliases &&

            echo 'Adding aliases to .bash_aliases file'

            # append content to the end of the .bash_aliases file
            if $install_dump1090 ; then
                echo "alias $adsb_alias='screen ./sdr_tools/dump1090/dump1090 --device-index 2 --enable-agc --aggressive --interactive --net --net-http-port $dump1090_port'" >> ~/.bash_aliases
            fi

            if $install_rtl_sdr_tools ; then
                echo "alias $sdr_alias='screen -d -m -S $sdr_alias sh -c \"rtl_tcp -d 1 -a $rpi_ip_address -s $rtl_tcp_sample_rate -b 100\"'" >> ~/.bash_aliases
            fi

            if $install_direwolf ; then
                echo "alias $aprs_alias='screen -d -m -S $aprs_alias sh -c \"rtl_fm -d 0 -f 144.800M | direwolf -c ~/sdr_tools/direwolf/$direwolf_conf_file -r 24000 -D 1 -\"'" >> ~/.bash_aliases
            fi

            echo "alias $launchsdr='screen -c $screenrc_config_file_name'" >> ~/.bash_aliases

            echo "alias rpitemp='vcgencmd measure_temp'" >> ~/.bash_aliases
        fi

        # if the ~/.bash_aliases file exists
        if [ -e ~/.bash_aliases ]; then
            echo 'Sourcing .bash_aliases file'
            
            source ~/.bash_aliases
        fi

    fi # end - .bash_aliases 

    echo 'Rebooting the RPi'
    sudo reboot now

fi # end



# ******************* TO DO  ******************* #


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
#                     RTL433                     #
#                                                #
##################################################

if $install_rtl_433 ; then

    echo 'Installing RTL433'

fi # end - install RTL433



##################################################
#                                                #
#                RTL_SDR_Airband                 #
#                                                #
##################################################

if $install_rtl_sdr_airband ; then

    echo 'Installing RTLSDR Airband'

fi # end - install RTL_SDR_Airband
