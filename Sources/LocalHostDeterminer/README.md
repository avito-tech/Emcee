# HostDeterminer

This module attempts to determine a host name which other machines can use to communicate to current host. 
If your DNS is configured correctly and IP addresses are static, everything is expected to work properly without any configurations. 
Otherwise, you can always force the host name of a machine using the following bash command:

```
sudo scutil --set HostName machine.example.com
```
