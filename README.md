# repo: saptune_update

Shellscript 'migrate2saptune.sh' to update SLES-for-SAP saptune v1 installation to the new saptune v2 layout.  This script tries to migrate a host running saptune v1 to saptune v2, see:  man 7 saptune

This script was tested on different environments in Europe and Asia.

## Updates

* 14. April 2020 - Workaround for saved_state bug added

* 16. June 2020 - additional tuned daemon restart added (see below)

## ToDo/Open

### 29. May 2020, feedback by SS

Please be aware, that tuned gets removed from sapconf and saptune with one of the next updates.
It would be better if you use the commands

    "saptune daemon start|stop"

instead of restarting tuned directly to be compatible with the change.

Also there will be a v3 (this year?) and maybe v4, etc.
You should at least have a test to exit if a version > 2 has been found.
