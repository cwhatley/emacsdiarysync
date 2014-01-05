emacsdiarysync
==============

Emacs Diary Sync - Dump OSX Calendars to Emacs Diary File

This is a quick and dirty menubar/status menu app that dumps events
between yesterday and 10 days from now to an emacs diary-compatible file.

EDS depends upon the EventKit framework which is, OSX 10.8 or later (though I've only tried it on 10.9).

WARNING: Destructive to Your Emacs Diary File
---------------------------------------------

If you fire this app up, it will mercilessly destroy your diary file with no prompting or regret. My use case is all about getting data into the file.

Use in conjunction with Org-Mode in Emacs
-----------------------------------------

The primary purpose of this app is to integrate OSX/iOS calendars into my
org-mode agenda views.

For more about org mode, visit http://orgmode.org

Refreshing Data
---------------

EDS subscribes to event store notifications and will update your diary file every time a change is made to the calendar.

This app will put an "EDS" menu in your menubar that has a "force refresh" menu you can use if needed.

EDS will do a SunOS boot spinner in the menu while it is refreshing the diary and will say "EDS!" if there's a problem. Check the console.

Refreshing Diary File within Emacs
----------------------------------

Since this app is the only writer to the diary file, I set up my emacs to load the diary file on startup
and then put the buffer into auto-revert-mode so that every time EDS updates the file, emacs will reload it.

You can put something like this in your init.el to enable that:

```
(when (file-exists-p diary-file)
      (save-excursion
        (let ((buf (find-file diary-file)))
          (diary-mode)
          (auto-revert-mode 1)
          (bury-buffer buf)
          )))
```

Diary File Location:
--------------------

Default location is ~/diary

Change the default location by doing this in the shell:

``defaults write com.rionueces.EmacsDiarySync ~/Dropbox/diary``
  
