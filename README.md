﻿# MiniProject
  ## Secure data transfer 
    Here we use NS3 for simulating our implementation of crypotographic algorithm

  ## Step 1:
    sudo apt install build-essential g++ python3 qtbase5-dev qt5-qmake
    git clone https://gitlab.com/nsnam/ns-3-allinone.git
  ## step 2:
    cd ns-3-allinone
    ./download.py
  ## step 3:
    cd ns-3-dev
    ./ns3 configure
    ./ns3 build
  ## step 4:
    cd scratch
    vim secure_comm.cc

  ## step 5:
    cd ..
    ./ns3 build
    ./ns3 run secure_comm
    
    
    
  
    
