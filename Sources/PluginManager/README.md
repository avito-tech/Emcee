#  PluginManager

`PluginManager` class supports the plugin infrastructure. 
It starts plugin processes, broadcasts event bus event and terminates plugins.
Manager acts as a `EventStream` and broadcasts all the events it receives from the event bus into plugins.

## Using `PluginManager`

```
// Get all the plugins, as an URL or as a local path
let pluginLocations = ResourceLocation.from(...) 

// Create manager and let it start the plugins
let manager = PluginManager(pluginLocations: pluginLocations)
manager.startPlugins()

// Subscribe plugin manager to the event bus which events should be streamed to the plugins:
eventBus.add(stream: manager)
```

