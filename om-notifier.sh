#!/bin/bash

echo $VCAP_SERVICES | jq .

# credentials are created in a credhub service instance which is bound to the app
# at runtime values are available in $VCAP_SERVICES

account_sid=`echo $VCAP_SERVICES | jq -j .credhub[0].credentials.account_sid`
auth_token=`echo $VCAP_SERVICES | jq -j  .credhub[0].credentials.auth_token`
from_number=`echo $VCAP_SERVICES | jq -j .credhub[0].credentials.from_number`
to_number=`echo $VCAP_SERVICES | jq -j   .credhub[0].credentials.to_number`
opsman_user=`echo $VCAP_SERVICES | jq -j .credhub[0].credentials.opsman_user`
opsman_url=`echo $VCAP_SERVICES | jq -j  .credhub[0].credentials.opsman_url`
opsman_pw=`echo $VCAP_SERVICES | jq -j   .credhub[0].credentials.opsman_pw`

# continuous loop
while :

do
	# get the id of the last completed installation
	last_id=$(om -t "${opsman_url}"  -u "${opsman_user}" -p "${opsman_pw}" installations -f json | jq '.[0].id')
	# get the id of the last saved run
	last_run=$(cat last.txt)

	# if not equal, then there must be a new installation
	if [ "$last_id" != "$last_run" ]  ; then
		# get the log of the last installation
		last_log=$(om -t "${opsman_url}"  -u "${opsman_user}" -p "${opsman_pw}" installations -f json | jq '.[0]')
		echo $last_log
		# send it to twilio
		curl -s -X POST -d "Body=${last_log}" \
	    -d "From=${from_number}" -d "To=${to_number}" \
	    "https://api.twilio.com/2010-04-01/Accounts/${account_sid}/Messages" \
	    -u "${account_sid}:${auth_token}"
	    # save the id to the file.
	    echo $last_id > last.txt
	fi
	echo $last_id
	# sleep for one minute
	sleep 1m
done



