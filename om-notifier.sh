#!/bin/bash
echo $VCAP_SERVICES | jq .
# credentials are created in a credhub service instance which is bound to the app
# at runtime values are available in $VCAP_SERVICES
creds=`echo $VCAP_SERVICES | jq -j .credhub[0].credentials`
opsman=""
last_install=""

get_last_install() {
	echo $1
	# $opsman = $1
	opsman_url=`echo $1 | jq -j .opsman_url`
	opsman_user=`echo $1 | jq -j .opsman_user`
	opsman_pw=`echo $1 | jq -j .opsman_pw`
	# get the id of the last completed installation
	# om -t "${opsman_url}"  -u "${opsman_user}" -p "${opsman_pw}" installations -f json
	last_install=`om -t "${opsman_url}"  -u "${opsman_user}" -p "${opsman_pw}" installations -f json | jq '.[0]'`
}

send_sms() {
	last_log=`echo "$2 -- $1"`
	echo "send_sms:$last_log"
	# send it to twilio
	curl -s -X POST -d "Body=${last_log}" \
	-d "From=${from_number}" -d "To=${to_number}" \
	"https://api.twilio.com/2010-04-01/Accounts/${account_sid}/Messages" \
	-u "${account_sid}:${auth_token}"
}

account_sid=`echo $creds | jq -j .account_sid`
auth_token=`echo $creds  | jq -j .auth_token`
from_number=`echo $creds | jq -j .from_number`
to_number=`echo $creds   | jq -j .to_number`

# continuous loop
while : 
do
	i=0
	opsman=`echo $creds | jq -j .opsman[$i]`
	while [ "$opsman" != "null" ] 
	do
		echo "opsman:$opsman"
		get_last_install "$opsman"
		echo "last:$last_install"
		# get the id of the last saved run
			last_run=`echo $last_install | jq -j .id`
			# hash the opsman config to create a unique file name
			chkfile=`cksum <<< "$opsman" | cut -f 1 -d ' '`
			last_id=`cat $chkfile`
			echo "last run:$last_run:$last_id"
			# if not equal, then there must be a new installation
			if [ "$last_id" != "$last_run" ]  ; then
				echo $last_id
			 	# make sure it has finished
			 	finished_at=`echo $last_install | jq -j .finished_at`
				if [ "$finished_at" != "null" ]  ; then
			 		# send as sms
					send_sms "$last_install" "`echo $opsman | jq -j .env`"
			 	    # save the id to the file.
					echo "$last_run" > "$chkfile"
				fi
			fi
		i=$((i+1))
		opsman=`echo $creds | jq -j .opsman[$i]`
	done
	# sleep for one minute
	sleep 1m
done