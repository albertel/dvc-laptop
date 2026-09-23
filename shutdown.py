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
        prepend('machine_output', "%s\n\n%s\n------------\n%s\n" % (
            host, r.std_out.decode('ascii'), r.std_err.decode('ascii')))
    if r.status_code:
        prepend('machine_output', "Host %s\nFAILED" % host)

failures={}
def log_failed_hosts(args):
    failures[args.thread.name] = "%s" % args.exc_value

def output(line):
    global o, is_interactive
    if is_interactive:
        print(line)
    else:
        print(line)
        o += "<pre>" + line + "</pre>\n"

def replace(which, line):
    global o
    print(line)
    o += '''<script type="text/javascript">
    ''' + which + '''.innerHTML = "<pre>''' + line + '''</pre>";
    </script>\n
    '''

def append(which, line):
    global o
    print(line)
    o += '''<script type="text/javascript">
    ''' + which + '''.insertAdjacentHTML("beforeend", "<pre>''' + line + '''</pre>");
    </script>\n
    '''

def prepend(which, line):
    global o
    print(line)
    o += '''<script type="text/javascript">
    ''' + which + '''.insertAdjacentHTML("afterbegin", "<pre>''' + line + '''</pre>");
    </script>\n
    '''

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

    for t in threads:
        t.start()

    alive = threads
    while alive:
        still_alive = []
        for t in alive:
            if t.is_alive():
                still_alive.append(t)
            else:
                t.join()
                append('status', "Finished %s" % t.name)
        alive = still_alive
        if alive:
            replace('status',
                    "%d todo" % len(alive))
        if failures:
            append('status',
                   "%d failed" % len(failures.keys()))
        time.sleep(1)

    if failures:
        append('failures', "Failed: %s" % (', '.join(sorted(failures.keys()))))
        for k in sorted(failures):
            append('failures',
                   "Host %s: %s" % (k, failures[k]))

def output_header():
    return """
    <html>
      <head>
        <style>
         #status {
           border-style: outset;
           display: inline-block;
           padding: 0 30px 0 30px; 
         }
         #failures {
           overflow: scroll;
           max-height: 100px;
           border-style: groove;
         }
         #machine_output {
           overflow: scroll;
           max-height: 100px;
           border-style: groove;
         }
        </style>
      </head>
      <body>
        <marquee behavior="alternate">
        <div id="status">
        </div></marquee>
        <p>
          Failure messages:
        </p>
        <div id="failures">
        </div>
        <p>
          Output from machines:
        </p>
        <div id="machine_output">
        </div>
        <script type='text/javascript'>
          const status = document.getElementById("status");
          const failures = document.getElementById("failures");
        </script>
    """

@app.route("/", methods=['POST'])
def webmain():
    global o, failures, is_interactive
    o=''
    failures={}
    is_interactive = False
    if "NO" in request.form:
        return "Okay, Have a nice day!"

    if ("username" in request.form and
        "min" in request.form and
        "max" in request.form and
        "command" in request.form):
        f = open(request.form['username'])
        password = f.read()
        f.close()
        main_t = threading.Thread(
            target=do_command,
            name="main",
            args=(request.form['username'],
                  password,
                  int(request.form['min']),
                  int(request.form['max']),
                  request.form['command']))
        main_t.start()
        def generate():
            global o
            yield output_header()
            while main_t.is_alive():
                if o:
                    to_show = o
                    o = ''
                    yield to_show
                else:
                    time.sleep(0.1)
            main_t.join()
            replace('status', "Completed")
            yield o
        return stream_with_context(generate())

    else:
        return "<p>Missing Data</p>"
    return "Command result: " + o

@app.route("/", methods=['GET'])
def webentry():
    return """<h1>DVC PHONEBANK SHUTDOWN</h1>
    <div>
    Are you sure? All selected laptops will automatically shutdown stopping any ongoing phonebanking.<br/><br/>

    Turn off power (using phone app) AFTER shutdown completes.<br/><br/>

    Thank you.<br/><br/>
    </div>
    
    <form action='/' method='POST'>
      Which machines:<br/>
      <input type='number' name='min' value='1' min='1' max='41'> through
      <input type='number' name='max' value='41' min='1' max='41'><br/><br/>
      
      <input type='submit' name='YES' value='YES' />
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <input type='submit' name='NO' value='NO' />
      <hr/>
      <div style="position: fixed; bottom: 0;">
      <p>Some Options for Guy/Lawerance:</p>
    
      <label>Username:<input type='text' name='username' value='PTA_admin'></label><br/>
      <fieldset>
        <legend>Which Command?</legend>
        <div>
           <label>Shutdown <input type='radio' name='command' value='shutdown' checked/></label>
           <label>IpConfig <input type='radio' name='command' value='ipconfig'/></label>
        </div>
      </fieldset>
      </div>
    </form>"""

def main():
    args = parser.parse_args()
    output("Stating Shutdown as user %s pw %s" % (args.username, args.password))
    do_command(args.username, args.password, args.min, args.max)
    
#main()
