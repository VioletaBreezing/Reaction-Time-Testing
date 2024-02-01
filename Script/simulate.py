import os, sys, subprocess

source_dir    = "./Src"
build_dir     = "./Build"
testbench_dir = "./TestBench"

iverilog_path = "D:/VioletaWorkZone/iverilog/bin/iverilog.exe"
vvp_path      = "D:/VioletaWorkZone/iverilog/bin/vvp.exe"
gtkwave_path  = "D:/VioletaWorkZone/iverilog/gtkwave/bin/gtkwave.exe"

arguments = sys.argv[1:]

source_list = arguments if arguments else [testbench_file[3:-2] for testbench_file in os.listdir(testbench_dir)]

for source_name in source_list:
    
    commands = [
                f"{iverilog_path} -o {build_dir}/TB_{source_name}.out {testbench_dir}/TB_{source_name}.v {source_dir}/{source_name}.v",
                f"{vvp_path} {build_dir}/TB_{source_name}.out",
                f"{gtkwave_path} {build_dir}/TB_{source_name}.vcd"
               ]

    if source_name == "RGB_LED":
        commands[0] += f" {source_dir}/PWM.v"
    elif (source_name == "Top"):
        for f in os.listdir(source_dir):
            if (f == "Top.v"): continue
            commands[0] += f" {source_dir}/{f}"

    print(f"\n============ Simulating {source_name}.v ============\n")
    for cmd in commands:
        _ = print("command    : ", cmd)
        result = subprocess.run(cmd, shell = True, capture_output = True, text = True)
        _ = print("returncode : ", result.returncode) if (result.returncode != 0)  else 0
        _ = print("stderr     : ", result.stderr)     if (result.stderr     != "") else 0
        _ = print("stdout     : ", result.stdout)     if (result.stdout     != "") else 0

        if (result.returncode != 0) : break
    print(f"\n======= End of Simulation of {source_name}.v =======\n")