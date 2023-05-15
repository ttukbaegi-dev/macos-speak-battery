# BatteryReminder
The Intel-only application located in /Outputs will remind you every ten minutes either
to charge your battery when it goes below 30% charge or to unplug your device
when the battery goes above 95%.

Installation instructions are as follows:
1. Make sure to Ctrl-C (SIGINT) the console application before logging out or
   shutting down, as I cannot catch a SIGTERM which is sent upon force-
   terminating a process.
2. Copy the BatteryReminder application into /Applications/Utilities.
3. Open Users & Groups in System Preferences.app and go to the Login Items
   tab. Add a login item, navigating to /Applications/Utilities and finding
   BatteryReminder. Select it and andd as a login item.
4. Log out and back in to your Mac.