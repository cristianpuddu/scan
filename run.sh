#!/bin/bash
# Carica le variabili dal file .env
export TERM=xterm
if [ -f .env ]; then
    source .env
else
    echo "Errore: file .env non trovato nella directory corrente"
    exit 1
fi

START=$(date +%s) #per calcolare il tempo script
clear
DATE=$(date +%d-%m-%Y-%H)
ORA=$(date +%H)
directory="/dev/shm/scansioni/${DATE}"
dirImage="${directory}/immagini"
#NON MODIFICARE QUANTO SEGUE

echo "$(date +%H-%M) creazione ${directory}"
mkdir -p $directory
mkdir -p $dirImage
#echo "debug copio file"
#cp /home/pi/scan/capture/logosh.jpg $dirImage/prova.jpg

echo "$(date +%H-%M) inizio scansione"

#canaliVHF="5 6 7 8 9 10 11"
canaliUHF="21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49"
# --- enable for only test:
#canaliVHF="9"
#canaliUHF="39 40"

function scansionetts() {
	echo "====> $(date +%H-%M) Tsscan su  $1 - CH $2 "
	echo "TSSCAN DVB-T2"

	tsscan $1 --delivery-system DVB-T2 --first-channel $2 --last-channel $2 --show-modulation --default-pds eacem --save-channels $directory/tsscan$2.xml >/dev/null
	#echo "tsscan $1 --delivery-system DVB-T2 --first-channel $2 --last-channel $2 --show-modulation --default-pds eacem --save-channels $directory/tsscan$2.xml"

	if [ $(stat -c%s "$directory/tsscan$2.xml") -gt 100 ]; then
		echo "--> Trovato mux DVB-T2 salto la scansione DVB-T "
	else
		echo "TSSCAN DVB-T"
		tsscan $1 --delivery-system DVB-T --first-channel $2 --last-channel $2 --show-modulation --default-pds eacem --save-channels $directory/tsscan$2.xml >/dev/null
	fi

	filesize=$(stat -c%s "$directory/tsscan$2.xml")

	if (($filesize > 50)); then
		if (($ORA >= 11 && $ORA < 17)); 
			echo "ho trovato delle emittenti!"
			echo "$(date +%H-%M) chiamo script readxml per creare sccreenshot"
			python3 /home/pi/scan/capture/readxml.py $directory/tsscan$2.xml $2 $dirImage
		fi
	else
		echo "----> $(date +%H-%M) rimuovo perché <30 tsscan$2.xml"
		rm $directory/tsscan$2.xml
	fi

}

function scansione() {
	#$1=canale $2=tipo
	ch=$2
	if [ -n "$(find "$directory/tsscan$ch.xml")" ]; then
		echo "====> $(date +%H-%M) dvb $1 -- $2"

		tsp -I dvb --delivery-system DVB-T2 $1 $2 \
			-P skip 5000 \
			-P until -s 100 \
			-P pcrbitrate \
			-P analyze --json -o $directory/analyze-$ch.json \
			-P analyze -o $directory/analyze-$ch.txt \
			-P tables --default-pds eacem --pid 16 --json-output $directory/nid-$ch.json \
			-P psi -a --default-pds eacem -o $directory/psi-$ch.txt \
			-O drop

		if [ $(stat -c%s "$directory/analyze-$ch.json") -gt 100 ]; then
			echo "--> Trovato mux DVB-T2 salto la scansione DVB-T "
		else

			tsp -I dvb --delivery-system DVB-T $1 $2 \
				-P skip 5000 \
				-P until -s 100 \
				-P pcrbitrate \
				-P analyze --json -o $directory/analyze-$ch.json \
				-P analyze -o $directory/analyze-$ch.txt \
				-P tables --default-pds eacem --pid 16 --json-output $directory/nid-$ch.json \
				-P psi -a --default-pds eacem -o $directory/psi-$ch.txt \
				-O drop
		fi

		#conversione in pdf
		echo "----> $(date +%H-%M) conversione file pdf eliminazione txt originali"
		if [ -n "$(find "$directory/analyze-$ch.txt" -prune -size +2)" ]; then
			python3 /home/pi/scan/pdf.py $directory/analyze-$ch
		fi
		if [ -n "$(find "$directory/psi-$ch.txt" -prune -size +2)" ]; then
			python3 /home/pi/scan/pdf.py $directory/psi-$ch
		fi
	fi

}
#echo "**** scansione canali VHF ****"
#for canale in $canaliVHF
#do
#	scansionetts "--bandwidth 7 -l --vhf-band" $canale;

#	scansione "--bandwidth 7 --vhf-channel" $canale
#done

echo "**** scansione canali UHF ****"
for canale in $canaliUHF; do
	scansionetts "-l --uhf-band" $canale

	scansione "--uhf-channel" $canale
done
echo "$(date +%H-%M) elimino file inutili"
find $directory -size -2 -delete
echo "====> $(date +%H-%M) chiamo script creazione json pid"
bash /home/pi/scan/pidscan/read.sh "${DATE}"
echo "creazione cartella inout"
inout=/dev/shm/scansioni/inout
mkdir -p $inout
echo "$(date +%H-%M) comprimo i files"
tar -czvf "${inout}/${SONDA}-${DATE}.tar.gz" -C $directory .
filesizeTar=$(stat -c%s "${inout}/${SONDA}-${DATE}.tar.gz")
if (($filesizeTar > 2000)); then
	echo "----> $(date +%H-%M) tentativo per upload file"
	for tentativi in {1..3}; do
		response="$(curl --form upload="@${inout}/${SONDA}-${DATE}.tar.gz" ${UPLOAD})"
		
		if [ "${response}" = "ok" ]; then
			echo "ok file caricato"
			echo "procedo con pulizia cartella"
			rm -R /dev/shm/scansioni
			break
		else
			echo "errore! tentativo ${tentativi} su 3 Fallito! Prossimo tra 15  minuti"
			echo "il server ha risposto con: ${response}"
			sleep 15m
		fi
	done
else
	echo >&2 "errore! file tgz non inviato perché troppo piccolo"
	rm -R /dev/shm/scansioni
fi
#calcolo tempo richiesto
END=$(date +%s)
echo "tempo richiesto in minuti"
echo $echo $((END - START)) | awk '{print int($1/60)":"int($1%60)}'
echo "--------------------------------Fine!"