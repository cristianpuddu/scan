#!/bin/bash
JSON="$1";
SRVCOUNT=$(jq <$JSON -r ".services | length");
echo "[";
for ((i=0; i<$SRVCOUNT; i++)); do
	SRVNAME=$(jq <$JSON -r ".services[$i].name")
	PIDCOUNT=$(jq <$JSON -r ".services[$i].pids | length")
	printf "{\"ServID\": \"$SRVNAME\",\n"; 
	
	echo "\"Parametri\":[";
	for ((p=0; p<$PIDCOUNT; p++)); do
		PID=$(jq <$JSON -r ".services[$i].pids[$p]")
		DESC=$(jq <$JSON -r ".pids[] | select(.id==$PID) | .description")
		RATE=$(jq <$JSON -r ".pids[] | select(.id==$PID) | .bitrate")
		if (("$p" == "$PIDCOUNT"-1))
		then
			printf "{\"Pid\": \"%s\",\"Text\": \"%s\",\"Bitrate\": \"%s\"}\n" "$PID" "$DESC" "$RATE"
		else
			printf "{\"Pid\": \"%s\",\"Text\": \"%s\",\"Bitrate\": \"%s\"},\n" "$PID" "$DESC" "$RATE"
		fi
	done
		if (("$i" == "$SRVCOUNT"-1))
		then
        	echo "]}";
		else
			echo "]},";	
		fi
done
echo "]";

