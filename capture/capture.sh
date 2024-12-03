#!/bin/bash
PATH='/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games'
#capture.sh pid CH directory [ch in esadecimale]
#capture.sh 0x0D49 09 /dev/shm/scansioni/10-06-2021-12/immagini
pid=$1
Ch=$2
directory_img=$3
if (($Ch <= 12))
then
    echo "$(date +%H-%M) scansione VHF screenshot CH ${Ch} PID $pid"
	tsp -I dvb --bandwidth 7 --vhf-channel $Ch \
	-P until --seconds 10 \
	-P zap $pid \
	-O file $directory_img/ts_capture.ts
fi
if (($Ch >= 21))
then
	echo "$(date +%H-%M) scansione UHF screenshot CH ${Ch} PID $pid"
	tsp -I dvb --delivery-system DVB-T2 --uhf-channel $Ch \
	-P until --seconds 10 \
	-P zap $pid \
	-O file $directory_img/ts_capture.ts

	if [ $(stat -c%s "$directory_img/ts_capture.ts") -gt 100 ]; then
		echo "--> trovato TS DVB-T2 salto la scansione DVB-T"
	else
	
		tsp -I dvb --delivery-system DVB- --uhf-channel $Ch \
		-P until --seconds 10 \
		-P zap $pid \
		-O file $directory_img/ts_capture.ts
	
	fi


fi
echo "----> $(date +%H-%M) elaborazione mediante ffmpeg"
PIDdecimale=$(printf "%d" $pid)
ffmpeg -hide_banner -loglevel error -i $directory_img/ts_capture.ts -vf scale=iw*sar:ih  -ss 00:00:05 -frames:v 1  $directory_img/$Ch-$PIDdecimale.jpg > /dev/null 2>&1 
echo "-> inserimento watermark"
composite -dissolve 30% -gravity Center /home/pi/scan/capture/watermark.png $directory_img/$Ch-$PIDdecimale.jpg $directory_img/$Ch-$PIDdecimale.jpg
#echo "-i $directory_img/ts_capture.ts -ss 00:00:05 -frames:v 1 $directory_img/$Ch-$PIDdecimale.jpg"
echo "--->generato screenshot ${Ch}-${PIDdecimale}.jpg "
rm $directory_img/ts_capture.ts
echo "rimosso file temporaneo TS"
