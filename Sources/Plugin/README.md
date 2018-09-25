#  Plugin

This module provides a basic class that plugin can use to create a bridge between main executable and the plugin.

Currently, `EventBus` is being bridged between main executable and all plugins. 
All events are broadcasted from main executable into running plugins, but not backwards.

```
Main Executable Event Bus Events     --------->     Plugin
```

## Using `Plugin`

The main class for plugin is `Plugin`. The most common scenario is:

```
// Create an event bus that will get the events from the main executable:
let eventBus = EventBus()

// Subscribe to the event bus by providing an instance of EventStream: 
let listener = SomeEventStreamListener()
eventBus.add(stream: listener)

// Plugin class will stream all events into that event bus:
let plugin = Plugin(eventBus: eventBus)
plugin.streamPluginEvents()

// Wait for plugin to finish:
plugin.join()
```

`Plugin` will automatically stop streaming events when event bus will deliver `tearDown` event, making `join()` method able to return.
