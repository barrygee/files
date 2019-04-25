#!/bin/bash

# This script will set up all NodeSDR core modules
# If modules already exist, they will be rebased back to their master. Merge conflicts should be resolved manually
# You can skip the building of any modules by commenting them out in the list below
NodeSDR_CORE_MODULES=(
    # NodeSDR-Core-SDR-Controls
    # NodeSDR-Core-Frontend
    # NodeSDR-ADSB-Decoder
    NodeSDR-Shipping-Movements
)

for module in "${NodeSDR_CORE_MODULES[@]}"; do

    cd ./app

    if [ ! -d $module ]; then
        git clone https://github.com/barrygee/$module.git
    fi
        
    cd $module
        git checkout master
        git pull origin master
    
    cd ../../

done


NodeSDR_CUSTOM_MODULES=(
    https://github.com/barrygee/ES6.git
    https://github.com/barrygee/NodeLogger.git
    https://github.com/barrygee/prototyping-101.git
)

for moduleSourceURL in "${NodeSDR_CUSTOM_MODULES[@]}"; do

	cd ./app

	if [ ! -d $moduleSourceURL ]; then
        git clone $moduleSourceURL
    fi
        
    # Get module name
    # Regex gets text between final '/' and '.git' in each NodeSDR_CUSTOM_MODULES URL
    # ${moduleSourceURL%.git} gets all text upto but not including '.git'
    # ${dir##*/} gets all text from but not including the final '/'
    dir=${moduleSourceURL%.git} && dir=${dir##*/}

   	cd $dir
    	git checkout master
    	git pull origin master

    cd ../../

done
