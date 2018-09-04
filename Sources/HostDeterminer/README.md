#  HostDeterminer

This module allows you to determine the current host's name. It is important to set up the queue server, so clients would be able to connect.
You can set the host name of each machine using the following bach command:

```
sudo scutil --set HostName machine.example.com
```

This will ensure you will get the consistent results. `Host.current()` API that we use as a fallback returns an array of `names` 
that probably can give you wrong host name.
