import argparse
import winrm

parser = argparse.ArgumentParser(
    prog="cleanup.py",
    description="Remote Cleanup")
parser.add_argument('-i', '--ip')
parser.add_argument('-u', '--username', required=True)
parser.add_argument('-p', '--password', required=True)
parser.add_argument('-f', '--file', required=True)

def clean(u, pw, ip, cmd):
    winrmsess = winrm.Session(ip,
                              auth=(u, pw),
                              transport="ntlm")
    r = winrmsess.run_ps(cmd)
    if r.std_out or r.std_err:
        print("%s\n\n%s\n\n----------------\n%s\n" % (
            ip, r.std_out.decode('ascii'), r.std_err.decode('ascii')))
    if r.status_code:
        print("%s: %s" % (ip, r.status_code))
        
def main():
    args = parser.parse_args()
    print("Cleaning up %s" % (args.ip,))
    f = open(args.file)
    cmds = f.read()
    f.close()
    clean(args.username, args.password, args.ip, cmds)
    
main()
