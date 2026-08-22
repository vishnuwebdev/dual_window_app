#!/bin/bash

# Overwrites cvmain's live auth.json/mq.json with its own factory-reset
# template files (auth.json-reset / mq/mq.json-reset), entirely within
# cvmain's root-owned config directory — used by
# UnitRegistrationService.resetToFactoryDefaults()'s "Reset to factory
# defaults" button. Same permission problem as copy_to_cvmain.sh (this
# app runs as `pi`, cvmain's config directory is root-owned), same `sudo
# cp -f` fix.
#
# NEEDS ITS OWN sudoers NOPASSWD entry on the unit, separate from
# copy_to_cvmain.sh's — sudoers rules match by exact script path, so
# authorizing that script does not also authorize this one.
sudo cp -f /home/pi/cv/cvmain/config/auth.json-reset /home/pi/cv/cvmain/config/auth.json
sudo cp -f /home/pi/cv/cvmain/config/mq/mq.json-reset /home/pi/cv/cvmain/config/mq/mq.json
