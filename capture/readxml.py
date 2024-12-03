import sys
import os
import subprocess
linkfile = sys.argv[1]
ch = sys.argv[2]
directory = sys.argv[3]
from xml.dom.minidom import parse, parseString
dom1 = parse(linkfile)
node1 =  dom1.getElementsByTagName("service")
for i in node1:
    id= i.getAttribute("id")
    type = i.getAttribute("type")
    cas = i.getAttribute("cas")
    if (type!='0x02') and (type!='0x0C')  and (type!="") and (cas=='false') :
        list_dir = subprocess.Popen(["/home/pi/scan/capture/capture.sh", id, ch, directory ])
        list_dir.wait()