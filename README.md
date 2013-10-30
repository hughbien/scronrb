Description
===========

Scron is a scheduler for laptops/machines which aren't on 24/7.

Installation
============

    $ gem install scron

Then configure cron to run it.  I recommend every 2 hours, but you can put any
interval here:

    $ crontab -e
    0 */2 * * * scron -r

Usage
=====

Configure jobs in `$HOME/.scron` (`scron -e` to edit). This example means run
`cmd arg1 arg2` at least once every 30 days:

    30d cmd arg1 arg2

You can also specify lower bounds like day of week (Su, Mo, Tu, We, Th, Fr, Sa),
day of month (23rd), or day of year (4/15):

    Mo,Fr    cmd1
    1st,23rd cmd2
    4/15     cmd3

`cmd1` will attempt to run on Monday and Friday.  If your machine is off the
entire day, it will run as soon as possible.  Here's an example timeline:

* Mo: machine is off, nothing happens
* Tu: machine is on, cmd1 runs to make up for Monday
* We: already ran, nothing happens
* Th: already ran, nothing happens
* Fr: machine is on, cmd1 runs

Notes
=====

An exit status of 0 is considered a success.  Anything else is considered a
failure and scron will attempt to re-run it again in 2 hours.

`$HOME/.scrondb` keeps the timestamps of the last run commands.

`$HOME/.scronlog` has the stdout, timestamps, and exit status of last 
scheduled commands.

TODO
====

* rename process to scron

License
=======

Copyright Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
