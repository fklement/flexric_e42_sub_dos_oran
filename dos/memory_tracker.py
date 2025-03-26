import matplotlib.pyplot as plt
# import tikzplotlib
import time
import subprocess
import sys
import os

def get_process_pid(process_name):
    """Retrieve the PID of a process by its name."""
    try:
        pid = subprocess.check_output(["pgrep", "-f", process_name]).decode().strip().split('\n')[0]
        return int(pid)
    except subprocess.CalledProcessError:
        return None

def get_ps_output(pid):
    """Retrieve the CPU usage of a specific process."""
    try:
        result = subprocess.check_output(["ps", "-p", str(pid), "-o", "%cpu,%mem"])
        return result.decode().split("\n")[1].strip().split("  ")
    except subprocess.CalledProcessError:
        return None

def monitor_resources(processes, duration=120, interval=0.2, output_file_cpu='cpu_usage.txt'):
    """Monitor the CPU usage of processes for a given period."""
    start_time = time.time()

    with open(output_file_cpu, 'w') as file_cpu:
        while time.time() - start_time < duration:
            current_time = time.time()

            for label, pid in processes.items():
                # print(f"{label} - {pid}")
                if pid is not None:
                    ps_output = get_ps_output(pid)
                    if ps_output is not None:
                        cpu_usage = float(ps_output[0])
                        mem_usage = float(ps_output[1])
                        file_cpu.write(f"Time: {(current_time - start_time)}, Process: {label}, PID: {pid}, CPU: {cpu_usage}, MEM: {mem_usage}%\n")
                    else:
                        file_cpu.write(f"Time: {(current_time - start_time)}, Process: {label}, PID: {pid}, CPU: Error, MEM: Error\n")
                        if(label == "RIC"):
                            pid = get_process_pid("./examples/ric/nearRT-RIC")
                            # print(pid)
                            processes.update({'RIC': pid})
                        
                else:
                    file_cpu.write(f"Time: {(current_time - start_time)}, Process: {label}, PID: Not found, CPU: Error, MEM: Error\n")
                    if(label == "RIC"):
                        pid = get_process_pid("./examples/ric/nearRT-RIC")
                        # print(pid)
                        processes.update({'RIC': pid})
                    
            time.sleep(interval)

def plot_combined_cpu_usage(input_file, output_folder, ylabel):
    """Read data from file and create a combined graph for CPU usage."""
    data = {'RIC': [], 'CU': [], 'DU': []}
    times = {'RIC': [], 'CU': [], 'DU': []}
    colors = {'RIC': 'red', 'CU': 'green', 'DU': 'blue'}

    with open(input_file, 'r') as file:
        for line in file:
            parts = line.strip().split(',')
            time_stamp = float(parts[0].split(':')[1].strip())  # Time in minutes
            process_name = parts[1].split(':')[1].strip()
            usage_part = parts[3].split(':')[1].strip()

            # Use 0 to represent errors
            usage = float(usage_part.replace('%', '').strip()) if usage_part != 'Error' else 0

            times[process_name].append(time_stamp)
            data[process_name].append(usage)

    plt.figure()
    for process, color in colors.items():
        if times[process]:  # Check if there is data for the process
            plt.plot(times[process], data[process], marker='o', color=color, label=process)
    plt.xlabel('Time (in seconds)')
    plt.ylabel(ylabel)
    plt.title('Combined CPU Usage Over Time')
    plt.grid(True)
    plt.tight_layout()
    plt.legend()
    plt.savefig(f'{folder_path}/combined_cpu_usage.png')
    # tikzplotlib.save(f'{folder_path}/combined_cpu_usage.tex')

# Associate each process name with a label
processes_to_monitor = {
    "RIC": "./examples/ric/nearRT-RIC",  # Replace with actual process name of RIC
    "CU": "./examples/emulator/agent/emu_agent_gnb_cu",    # Replace with actual process name of CU
    "DU": "./examples/emulator/agent/emu_agent_gnb_du"     # Replace with actual process name of DU
}

# Convert process names to PIDs
process_pids = {label: get_process_pid(name) for label, name in processes_to_monitor.items()}

if len(sys.argv) < 2:
        print("Usage: python3 memory_tracker.py folder_path")
        sys.exit(1)

folder_path = sys.argv[1]

if not os.path.isdir(folder_path):
    print("Error: Invalid folder path.")
    sys.exit(1)

monitor_resources(process_pids, 120, 0.2, f"{folder_path}/cpu_usage.txt")
plot_combined_cpu_usage(f"{folder_path}/cpu_usage.txt", folder_path, 'CPU Usage (%)')
