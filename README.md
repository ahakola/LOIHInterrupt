[![Build Status](https://travis-ci.com/ahakola/LOIHInterrupt.svg?branch=master)](https://travis-ci.com/ahakola/LOIHInterrupt)

# LOIHInterrupt

Interrupt manager for guild &lt;Lords of Ironhearts&gt; of Arathor EU.

Addon creates bars for player and party- or raidgroup members showing availability of players' interrupt spells to help you keep track of interrupt rotations. Players with green bars saying 'Ready' are able to interrupt. Players with red bar with countdown have their interrupt spell on CD until the timer runs out and the bar turns green again. Dead players' bars are black and addon checks once per second for if players have been ressurrected some how.

Interrupters can be easily configured via GUI or slash commands and interrupt lists can be shared to other users of the addon as well printed to party or raid chat. Addon can also be set to announce when player interrupts spell.

Interrupt lists are saved per character, but other settings are saved on profiles.

Use `/lint` or `/loihint` to bring out the custom rotation list setup and `/lint config` or `/loihint config` to bring out the config GUI for example to **alter the size and position of the bars and when they should be visible**. Use `/lint help` or `/loihint help` to get more information about slash commands.

Thanks to Bloodline for suggesting interrupt announcements feature.

---

* New in 8.0.0: You can now change the alpha-values of bars, texts and icons in config.
* New in 7.2.2: Offline members should now be marked similar to dead members, but with gray bars and 'Offline' text.
* New in 7.1.0: New mode: *Cooldown Tracking*, only shows your own interrupt bar all the time and adds bars when group or raid members use their CDs and hide them again when they are usable once more.
* New in 7.1.0: You can change bar looks: Postiotion, width, height, spacing, text size, enable class colors, shorten realm names on bars and hide bars for specs without interrupt spell.
* New in 7.1.0: Settings are now saved in profiles instead of shared between all characters. Lists are still saved per character.
* New in 7.1.0: All specs with interrupt should be working now (even Warlocks with *Command Demon* and Balance Druids with *Solar Beam*)
* New in 1.4: Warlocks should work now with *Command Demon* on Felhunter and Doomguard. While in party, the list should autofill with party members.

---

**Translators:**

Language | Translator(s)
-------- | -------------
koKR (Korean) | yuk6196
ruRU (Russian) | Dysphorio
zhTW (Traditional Chinese) | sopgri

---

**Known issues/bugs:**

* No known issues atm. PM me if you have any!

**Todo:**

- [x] Waiting for bug reports to flow in
- [x] Waiting for translations to flow in

---

Sending your bug reports/feature suggestions using CurseForge ticket-tool at https://wow.curseforge.com/projects/loihinterrupt/issues/ (use your Curse account to login) or PM me at Curse or CurseForge gets them noticed faster by me than using comments section.

---