#!/bin/bash

# This script installs ntp in your system, creates cron task which every 5 minutes will check 
# if the service is running and its config file is unchanged.
# If the service is stopped it will be launched by cron job and the /etc/ntp.conf will be returned
# in the initial state.
# Author: Serhii itrainik@gmail.com
#

varpath=/opt/ntp

apt-get update && apt-get -y install ntp

# edit the NTP conf file
sed -i 's/0.ubuntu.pool.ntp.org/ua.pool.ntp.org/' /etc/ntp.conf && sed -i '/ubuntu.pool.ntp.org/d' /etc/ntp.conf

# check the folder existance and copy there our etalon file for the future comparcings
if [ -d "$varpath" ]
  then
    cp /etc/ntp.conf $varpath/ntp.conf.etalon
  else
    mkdir -p $varpath && cp /etc/ntp.conf $varpath/ntp.conf.etalon
fi

# create ntp_verify.sh file and add it to the root crontab

cat <<"EOF" > $varpath/ntp_verify.sh
#!/bin/bash

vardiff=$(diff -u /etc/ntp.conf /opt/ntp/ntp.conf.etalon)

if [[ -z "$vardiff" ]]
   then
      if pidof ntpd
	       then
	          echo "Ntp service is running"
	       else
	          echo "Ntp service isn't running. Restarting... "  | mail -s "NTP config was changed" root@localhost
        	  /etc/init.d/ntp restart
      fi
   else
      echo -e "NOTICE: /etc/ntp.conf was changed. Calculated diff:\n $vardiff" | mail -s "NTP config was changed" root@localhost
      cp /opt/ntp/ntp.conf.etalon /etc/ntp.conf
      /etc/init.d/ntp restart
fi
EOF

# makes ntp_verify executable
chmod +x $varpath/ntp_verify.sh

# modifying root cron file
echo -e "*/5 * * * * $varpath/ntp_verify.sh 2>&1" | crontab -u root -
/etc/init.d/cron restart
