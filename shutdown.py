import argparse
import random
import sys
import threading
import time
import winrm

parser = argparse.ArgumentParser(
    prog="shutdown.py",
    description="Remote Command Execution script")
parser.add_argument('-i', '--interactive', action='store_true')
parser.add_argument('-u', '--username', required=True)
parser.add_argument('-p', '--password', required=True)

hosts=[
    #"dvc-808",
] + ["10.50.8.%d"%n for n in range(21,22)]

cmd="ipconfig"
cmd_args=[]
#cmd="shutdown"
#cmd_args=["/s", "/t", "5"]
max_connections=3
semaphore=threading.Semaphore(max_connections)

def do_shutdown(host, args, **kwargs):
    with semaphore:
        winrmsession = winrm.Session(host,
                                     auth=(args.username, args.password),
                                     transport="ntlm")
        r=winrmsession.run_cmd(cmd, cmd_args)
    if r.std_out or r.std_err:
        print("%s\n\n%s\n------------\n%s\n" % (
            host, r.std_out.decode('ascii'), r.std_err.decode('ascii')))
    if r.status_code:
        print("Host %s\nFAILED")

failures={}
def log_failed_hosts(args):
    failures[args.thread.name] = "%s" % args.exc_value
    
def main():
    args = parser.parse_args()
    print("Stating Shutdown as user %s pw %s" % (args.username, args.password))

    threading.excepthook=log_failed_hosts
    threads = []
    for host in hosts:
        threads.append(threading.Thread(
            target=do_shutdown, name=host, args=(host, args)))
    print("Created")

    for t in threads:
        t.start()
    print("Started")

    alive = threads
    while alive:
        still_alive = []
        for t in alive:
            if t.is_alive():
                still_alive.append(t)
            else:
                t.join()
                print("Finished ", t.name)
        alive = still_alive
        if alive:
            print("Still running: ", ', '.join(t.name for t in alive))
        if failures:
            print("Fail count: ", len(failures.keys()))
        time.sleep(1)

    if failures:
        print("Failures")
        for k in sorted(failures):
            print("Host %s: %s" % (k, failures[k]))
                
main()
