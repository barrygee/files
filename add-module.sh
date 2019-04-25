#!/bin/bash

# To run: ./add-module https://some.host/some-account/some-repo.git

# This script will git clone a repo from the URL provided when the script is run
# If modules already exist, the script will exit

# get the first argument passed into the script ./add-module.sh THIS_ARGUMENT
moduleSourceURL=$1

if [[ ! -z $moduleSourceURL ]]; then

    cd ./app

    echo 'Cloning repo: ' $moduleSourceURL

    # clone repo from the provided URL, if clone fails / repo is not found, exit 
    git clone $moduleSourceURL || exit 1
    echo 'Successfully cloned repo: ' $moduleSourceURL

    dir=${moduleSourceURL%.git} && dir=${dir##*/}

    cd $dir
        echo 'Checking out Master branch'
        git checkout master
        echo 'Successfully checked out Master branch'

        echo 'Pulling latest code from remote Master branch'
        git pull origin master
        echo 'Successfully pulled latest code from remote Master branch'
    
    cd ../../
else
    echo 'A module source URL is required'
fi
