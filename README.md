# om-notifier
Send an SMS on ops manager apply changes. Uses the [om](https://github.com/pivotal-cf/om) cli to retrieve installation status.

# setup

* You will need a [twilio](https://www.twilio.com/) acccount. Sign up for a free preview, after which each message is < 1c. 

* Using your twilio account information edit the creds.json file.

* Also add one or more opsman configurations 

* To create a credhub service instance with the creds information run

```
./create-credhub-service.sh
```

* To deploy the app

```
cf push
```





