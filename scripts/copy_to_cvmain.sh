#!/bin/bash

# Copies (not moves) this app's local auth.json/mq.json into cvmain's
# root-owned config directory, via sudo, to get around the permission
# issue where cnc_dual_screen (running as `pi`) can't overwrite cvmain's
# root-owned files directly.
#
# Deliberately `cp`, not `mv`: cnc_dual_screen keeps reading its own local
# copies of these two files after this runs — on every app startup (to
# show "Registered as ..."), every "Refresh JWT" tap, every MQTT
# connect/reconnect, and every automatic settings/db push to the cloud.
# Moving them would silently break all of that the first time this script
# ran, even though cvmain itself would end up with a correct copy — see
# UnitRegistrationService.initialize()/refreshJwt(), MqttSyncService.start(),
# and SettingsSyncService._readJwt(), which all read the local files, not
# cvmain's. `mv` was the original version of this script; changed to `cp`
# for exactly this reason.
sudo cp -f /home/pi/cv/cnc_dual_screen/config/auth.json /home/pi/cv/cvmain/config/auth.json
sudo cp -f /home/pi/cv/cnc_dual_screen/config/mq/mq.json /home/pi/cv/cvmain/config/mq/mq.json