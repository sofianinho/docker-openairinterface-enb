# docker-openairinterface-enb
Simple recipe to build and run a 4G SDR eNodeB from [OpenAirInterface project](https://gitlab.eurecom.fr/oai/openairinterface5g/wikis/home) develop code base. Kernel tweaks might be required on the host machine. A working EPC reachable from the host and a USRP is required in this particular config.

## Configure 

Edit enb.conf to reflect your IP and cellular network configuration.

Variables for cellular: 
>eNB_ID, eNB_name, tracking_area_code, mobile_country_code, mobile_network_code, eutra_band, downlink_frequency, uplink_frequency_offset, rx_gain, tx_gain

Variables for eNodeB IP config:
> ENB_IPV4_ADDRESS_FOR_S1_MME, ENB_IPV4_ADDRESS_FOR_S1U

Variables for 4G EPC:
> mme_ip_address

## Build
Different flavours, all equivalent, your choice:

### using compose
> docker-compose build --no-cache

### no git clone
> docker build -t oai:enb-master https://github.com/sofianinho/docker-openairinterface-enb.git#master

### after git clone 
> docker build -t oai:enb-master .

_`NB:`_ currently the oai-enodeB docker build is done against the master branch of eurecom's openairinterface5g repo. If you want to select another branch, no need to modify the Dockerfile, just specify your branch as a build-arg to your docker build command. Example: If I wanted to build against develop:
> docker build --build-arg OAI_BRANCH=develop -t oai:enb-master .

This works if the dependencies in your branch are the same as the master. If you notice build fails, please report it in the issues with your command, the complete log, and the branch it happened.

## Run 

Write a configuration file (./enb.conf) that matches the configuration of your EPC and IP interfaces. change the $PWD variable (if necessary), if you want to point to another path (I suppose you know what you are doind at this point :-) )

> docker-compose up

or:
> docker run -it --privileged --net=host -v $PWD:/config -v /dev/bus/usb:/dev/bus/usb oai:enb-master

## LICENSE

Original work from @ravens, of which this repo is a fork and modification, was unlicensed. I added an MIT license.
