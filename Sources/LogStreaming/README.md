# Log Streaming

## Terminology

- Queue — EmceeQueue process, the one that owns queue of buckets and processes results of their execution
- Worker - EmceeWorker process, the one that fetches buckets from queue, executes them and provides results back to the queue
- Client — Emcee process that reads user input, schedules buckets into the queue for execution, and fetches back the results.

## Problem

Queue and workers usually reside on different hosts. Obtaining logs for distributed system like Emcee usually is painful.

Administrators are encouraged to use Kibana, but if there is no such system available, then they can utilize log streaming feature.

Log streaming feature allows to stream all job related logs into a client that created that job.

## Implementation Details

### `LogStreamer`

This protocol and set of classes define the basic set of log streamers. 

### Common Entry Point

Default logger in Emcee is `ContextualLogger`. Logger can accept metadata - values that define a cooordinate system for loggable messages.
These metadata values are used to understand the source of message being logged:

- `ContextualLogger.ContextKeys.workerId` - defines which logger has logged a message

- `ContextualLogger.ContextKeys.bucketId` - defines which bucket the logged message belongs to

### Streaming Logs into Queue

Worker may add `SendLogsToQueueLoggerHandler` by using `LoggingSetup`. This will enable streaming of all logged message into the queue over network.

All logs are sent into queue's `/logEntry`, which is handled by `LogEntryEndpoint`. Endpoint will then pass these logs into a given `LogStreamer`:

- Queue will determine the target client for these logs. It will look at `ContextualLogger.ContextKeys.bucketId` metadata value and then determine what client created bucket. It uses `ClientDetailsHolder` for this. Stream of log entries happens into client's `/logEntry`, which is also handled by `LogEntryEndpoint`.

- Client will just stream logs into its `LoggingSetup.rootLoggerHandler`.

If there is no `bucketId` attached into log messages, these logs are considered to be global. They can be re-streamed into all clients.
