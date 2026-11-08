# Rise: on-device happy-flow tests

Author: Pratham Motwaney

These cover the acceptance criteria that cannot be checked in CI (real AlarmKit alerts, intents, sound, sensors). Happy flow only. Run them on the iPhone (iOS 26+) with the latest `Rise.ipa` sideloaded.

Tip: for every test, set the alarm 2 minutes ahead so you have time to lock the phone.

| Test Case Summary | Description | Actions | Expected Result |
|---|---|---|---|
| Verify if a one-time alarm rings on the Lock Screen with a Start Mission button | Ensure that a new one-time alarm is scheduled with AlarmKit and rings through Silent mode while Rise is closed. Pre-requisites: 1. Rise is installed and trusted (Developer Mode on, VPN & Device Management trusted). 2. Ring/Silent switch is set to Silent. 3. No other Rise alarms are enabled. | Open Rise | Rise opens on a dark "Rise" list. On first launch the Alarms permission prompt appears |
| | | Tap Allow on the Alarms permission prompt | The prompt closes and no "Alarms are off" banner is shown |
| | | Tap + | The "New alarm" editor opens with a time wheel, day chips, label, mission cards and Try mission |
| | | Set the time 2 minutes ahead, leave all days off, choose Math, tap Save | The editor closes. The list shows the alarm with "Once" and the header says "Next alarm in 2m" (or 1m) |
| | | Swipe Rise away in the app switcher and lock the phone | The phone locks with no error |
| | | Wait for the alarm time | The alarm rings in Silent mode on the Lock Screen, shows the alarm title, a Stop control and a Start Mission button |
| Verify if Start Mission opens the mission and solving it turns everything off | Ensure that Start Mission opens Rise straight into the mission, the in-app tone loops until the mission is solved, and a solved one-time alarm is turned off with no backup alarms left. Pre-requisites: 1. Previous test's setup (permission allowed, Silent mode on). 2. A one-time Math alarm (3 problems) set 2 minutes ahead, phone locked. | Open Rise and confirm the alarm is listed, then lock the phone | The alarm is listed as enabled |
| | | Wait for the alarm to ring | The system alarm rings with Start Mission |
| | | Tap Start Mission and unlock the phone | Rise opens directly into the Math mission. The system alert stops, Rise's own beeping tone plays in Silent mode and the screen stays awake |
| | | Try to swipe the mission screen down | The mission screen does not move and has no close button |
| | | Solve the 3 problems and tap Submit after each | Progress goes 1/3, 2/3, 3/3, then "Good morning" shows and the tone stops |
| | | Wait for the list to appear | The alarm list shows the alarm switched off |
| | | Lock the phone and wait 11 minutes | No backup alarm ("mission not done") rings |
| Verify if backup alarms keep ringing after Stop and opening Rise forces the mission | Ensure that pressing the system Stop control silences only that alert, backup alarms ring every minute, and opening Rise during that time goes straight into the mission. Pre-requisites: 1. Permission allowed. 2. A one-time Math alarm set 2 minutes ahead, phone locked. | Wait for the alarm to ring | The system alarm rings with Stop and Start Mission |
| | | Press Stop (slide on iOS 26.1+) | The alert stops |
| | | Wait about 1 minute | A backup alarm titled "Rise: mission not done (1/10)" rings with Start Mission |
| | | Press Stop on the backup alarm | The backup alert stops |
| | | Wait about 1 minute | Backup "(2/10)" rings |
| | | Press Stop, unlock the phone and open Rise from the Home Screen | Rise opens straight into the mission with its tone playing; the alarm list cannot be reached |
| | | Solve the mission | "Good morning" shows, the tone stops and no further backup alarms ring |
| Verify if backup alarms still ring after Rise is force-quit | Ensure that backup alarms are scheduled in advance and ring even when Rise is not running. Pre-requisites: 1. Permission allowed. 2. A one-time alarm set 2 minutes ahead. | Open Rise and confirm the alarm is listed | The alarm is listed as enabled |
| | | Swipe Rise away in the app switcher and lock the phone | Rise is closed |
| | | Wait for the alarm and press Stop | The alert stops |
| | | Wait about 1 minute | Backup "(1/10)" rings even though Rise was force-quit |
| | | Tap Start Mission on the backup and solve the mission | Rise opens into the mission; after solving, "Good morning" shows and no more backups ring |
| Verify if a repeating alarm rings again the next day with its backup alarms | Ensure that a repeating alarm keeps its weekly schedule after its mission is solved and the next occurrence again has backup alarms. Pre-requisites: 1. Permission allowed. 2. A Weekdays (or Every day) Math alarm set 2 minutes ahead on a day it repeats. | Wait for the alarm, tap Start Mission and solve the mission | "Good morning" shows; the alarm stays enabled in the list with its repeat days |
| | | Check the list header | "Next alarm in" shows the next repeat day at the same time |
| | | Next repeat day, wait for the alarm without opening Rise beforehand | The alarm rings at the set time |
| | | Press Stop | The alert stops |
| | | Wait about 1 minute | Backup "(1/10)" rings for the new day |
| | | Tap Start Mission and solve the mission | Mission completes and no more backups ring |
| Verify if editing and then deleting an alarm removes its alarms | Ensure that editing reschedules an alarm at the new time and deleting it removes the alarm and its backups. Pre-requisites: 1. Permission allowed. 2. An enabled one-time alarm exists, set at least 10 minutes ahead. | Open Rise and tap the alarm | The "Edit alarm" editor opens with the saved time, days, label and mission |
| | | Change the time to 2 minutes ahead and tap Save | The list shows the new time and the header updates |
| | | Lock the phone and wait for the new time | The alarm rings at the new time, not the old one |
| | | Tap Start Mission and solve the mission | Mission completes |
| | | Create another alarm 3 minutes ahead, then swipe it left in the list and tap Delete | The alarm disappears from the list |
| | | Lock the phone and wait 15 minutes | Nothing rings: no main alarm and no backups |
| Verify if the Shake and Type phrase missions can be completed on the phone | Ensure that the Shake mission counts real shakes and the Type phrase mission accepts the shown phrase typed on the iPhone keyboard. Pre-requisites: 1. Permission allowed. | Open Rise and tap + | The editor opens |
| | | Choose Shake, set 10 shakes and tap Try mission | The practice mission opens with a "0 of 10 shakes" ring and no Simulate button |
| | | Shake the phone firmly 10 times | The counter goes up once per shake with a haptic tap, reaches 10 and "Nice work" shows |
| | | Choose Type phrase, set 1 phrase and tap Try mission | The practice mission shows a phrase and the keyboard opens with no auto-capital or autocorrect |
| | | Type the phrase exactly as shown | The field turns green and Done becomes active |
| | | Tap Done | "Nice work" shows and the practice closes back to the editor |
