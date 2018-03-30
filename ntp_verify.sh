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
