import random
import threading
import time
import winrm

hosts=[
    "dvc-808",
] + ["dvc-%02d"%n for n in range(25)]

cmd="ipconfig"
cmd_args=[]
#cmd="shutdown"
#cmd_args=["/s", "/t", "5"]
def do_shutdown(host, **kwargs):
    time.sleep(3*random.random())
    winrmsession = winrm.Session(host, auth=("PTA_admin", ""), transport="ntlm")
    r=winrmsession.run_cmd(cmd, cmd_args)
    print("%s\n\n%s\n------------\n%s\n" % (
        host, r.std_out.decode('ascii'), r.std_err.decode('ascii')))
    if r.status_code:
        print("Host %s\nFAILED")

failures={}
def log_failed_hosts(args):
    failures[args.thread.name] = "%s" % args.exc_value
    
def main():
    print("Stating Shutdown")
    threading.excepthook=log_failed_hosts
    threads = []
    for host in hosts:
        threads.append(threading.Thread(
            target=do_shutdown, name=host, args=(host,)))
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
