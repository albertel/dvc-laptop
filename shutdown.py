import argparse
import random
import sys
import threading
import time
import winrm

from flask import Flask, request, stream_with_context

parser = argparse.ArgumentParser(
    prog="shutdown.py",
    description="Remote Command Execution script")
parser.add_argument('-i', '--interactive', action='store_true')
parser.add_argument('-u', '--username', required=True)
parser.add_argument('-p', '--password', required=True)
parser.add_argument('-m', '-min', default="21")
parser.add_argument('-x', '-max', default="21")

cmd = {
    "ipconfig": [],
    "shutdown": ["/s", "/t", "5"],
    }

max_connections=3
semaphore=threading.Semaphore(max_connections)
is_interactive=True
o=''
app = Flask(__name__)

def do_shutdown(host, username, password, which_command, **kwargs):
    with semaphore:
        winrmsession = winrm.Session(host,
                                     auth=(username, password),
                                     transport="ntlm")
        r=winrmsession.run_cmd(which_command, cmd[which_command])
    if r.std_out or r.std_err:
        output("%s\n\n%s\n------------\n%s\n" % (
            host, r.std_out.decode('ascii'), r.std_err.decode('ascii')))
    if r.status_code:
        output("Host %s\nFAILED")

failures={}
def log_failed_hosts(args):
    failures[args.thread.name] = "%s" % args.exc_value

def output(line):
    global o, is_interactive
    if is_interactive:
        print(line)
    else:
        print(line)
        o += "<pre>" + line + "\n</pre>"

def do_command(username, password, min, max, which_command):
    threading.excepthook=log_failed_hosts
    threads = []
    hosts=[
        #"dvc-808",
        #"10.50.36.67",
    ] + ["10.50.8.%d"%n for n in range(min, max+1)]


    for host in hosts:
        threads.append(threading.Thread(
            target=do_shutdown,
            name=host,
            args=(host, username, password, which_command)))
    output("Created")

    for t in threads:
        t.start()
    output("Started")

    alive = threads
    while alive:
        still_alive = []
        for t in alive:
            if t.is_alive():
                still_alive.append(t)
            else:
                t.join()
                output("Finished %s" % t.name)
        alive = still_alive
        if alive:
            output("Still running: " + ', '.join(t.name for t in alive))
        if failures:
            output("Fail count: %d" % len(failures.keys()))
        time.sleep(1)

    if failures:
        output("Failures")
        for k in sorted(failures):
            output("Host %s: %s" % (k, failures[k]))

@app.route("/", methods=['POST'])
def webmain():
    global o, is_interactive
    is_interactive = False
    if "NO" in request.form:
        return "Okay, Have a nice day!"

    if ("username" in request.form and
        "password" in request.form and
        "min" in request.form and
        "max" in request.form and
        "command" in request.form):
        #do_command(request.form['username'],
        #          request.form['password'],
        #          int(request.form['min']),
        #          int(request.form['max']),
        #          request.form['command']))
        main_t = threading.Thread(
            target=do_command,
            name="main",
            args=(request.form['username'],
                  request.form['password'],
                  int(request.form['min']),
                  int(request.form['max']),
                  request.form['command']))
        main_t.start()
        def generate():
            global o
            print("1", main_t, main_t.is_alive())
            while main_t.is_alive():
                print("2", threading.active_count())
                for t in threading.enumerate():
                    print(t.name)
                if o:
                    print("3")
                    to_show = o
                    o = ''
                    yield to_show
                else:
                    print("4")
                    time.sleep(0.1)
            print("5")
            main_t.join()
            yield o
        return stream_with_context(generate())

    else:
        output("<p>Missing Data</p>")
    return "Command result: " + o

@app.route("/", methods=['GET'])
def webentry():
    return """<h1>Do Shutdown?</h1>
    <form action='/' method='POST'>
      <label>Username:<input type='text' name='username' value='PTA_admin'></label><br/>
      <input type='hidden' name='password' value='unicycle'><br/>
      <label>Min:<input type='number' name='min' value='21' min='1' max='35'></label><br/>
      <label>Max:<input type='number' name='max' value='21' min='1' max='35'></label><br/>
      <fieldset>
        <legend>Which Command?</legend>
        <div>
           <label>Shutdown <input type='radio' name='command' value='shutdown' /></label>
           <label>IpConfig <input type='radio' name='command' value='ipconfig' checked/></label>
        </div>
      </fieldset>
      <br/>
      <input type='submit' name='YES' value='YES'>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <input type='submit' name='NO' value='NO'>
    </form>"""

def main():
    args = parser.parse_args()
    output("Stating Shutdown as user %s pw %s" % (args.username, args.password))
    do_command(args.username, args.password, args.min, args.max)
    
#main()
