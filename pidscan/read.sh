#!/bin/bash
#$1="07-04-2021-21";

dir="/dev/shm/scansioni/$1/";
#declare -a arrFiles
for file in ${dir}analyze-*.json;
do
	#arrFiles=("${arrFiles[@]}" "$file");
	
	#estrae dal percorso completo trovato il nome file analyze ed il canale da salvare come file CHpid,json
	nomeFile=${file##*/}
	>&2 echo "nomeFile READ $nomeFile"
	ch=${nomeFile//[^0-9]/}
	#invia il percorso trovato allo script e reindirizza stdout al file con il nome canale
	#sh ./analisi.sh $file >> "${ch}pid.json"
	bash /home/pi/scan/pidscan/analisi.sh $file > "/dev/shm/scansioni/$1/${ch}pid.json" 2>/home/pi/scan/LOGERPIDJSON.log
done