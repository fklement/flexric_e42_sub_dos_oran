#!/bin/bash

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

echo "—–––––––––––––––––––"
echo "| Subscription DoS |"
echo "—–––––––––––––––––––"

start_monitoring() {
    folder_name="/flexric/dos/measurements/$timestamp"
    mkdir -p "$folder_name"
    echo "-> Starting KPM Monitoring..."
    /flexric/build/examples/xApp/c/monitor/xapp_kpm_moni > $folder_name/kpm_moni.txt &
    echo "-> Starting MAC/RLC/PDCP/GTP Monitoring..."
    python3 /flexric/build/examples/xApp/python3/xapp_moni_dos.py $folder_name  > /dev/null&
    echo "-> Starting MEM/CPU Tracker..."
    python3 /flexric/dos/memory_tracker.py $folder_name &
}

execute_dos() {
    folder_name="/flexric/dos/logs/$timestamp"
    mkdir -p "$folder_name"
    /flexric/build/examples/xApp/c/sub_dos/xapp_dos_adv > $folder_name/dos_xApp.log &
    PID=$!
    wait $PID
}

start_nrtric() {
    echo "--> Starting the nearRT-RIC + gNB-DU/CU"
     /flexric/build/examples/ric/nearRT-RIC  > $1/nearRT.log &
    pid_near_rt_ric=$!
    sleep 3
    /flexric/build/examples/emulator/agent/emu_agent_gnb_du > $1/gnb_du.log &
    pid_gnb_du=$!
    /flexric/build/examples/emulator/agent/emu_agent_gnb_cu > $1/gnb_cu.log &
    pid_gnb_cu=$!
}

cleanup_nrtric() {
    kill $pid_near_rt_ric
    kill $pid_gnb_du
    kill $pid_gnb_cu
}

folder_name="/flexric/dos/logs/$timestamp"
mkdir -p "$folder_name"

if [ "$1" = "--baseline" -o "$1" = "-b" ]; then
    echo "/// BASELINE Measurement ///"
    start_nrtric $folder_name
    start_monitoring

    echo -e "\nWait for measurements to be done...\n"
    sleep 130 # Wait until all measurements are done

    cleanup_nrtric
    echo -e "Measurement completed.\n You can now stop the conatiner."

elif [ "$1" = "--dos" -o "$1" = "-d" ]; then
    echo "/// Executing DoS-Attack ///"
    start_nrtric $folder_name
    
    start_monitoring
    sleep 20 # Wait for a short amount before the attack begins
    
    echo -e "\nStarting the DoS Attack...\n"
    execute_dos
    echo "/// DoS-Attack Successfully ///"
    sleep 110

    cleanup_nrtric
fi
