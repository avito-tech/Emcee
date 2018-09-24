#  EventBus

`EventBus` class is a bus that delivers events that you send into it. It delivers them asynchronously. 
You can subscribe to the events by providing your own implementation of the `EventStream`.

This is kind of replacement for the `NotificationCenter`, but it uses strict method names and signatures to deliver the events.
Because this module can be used in various places around the project, it should not contain any other module specific dependencies.
