# About Worker Sharing

## Feature Overview

When a queue starts, it spawns its set of workers. Worker hosts are passed via queue configuration.

When two queues start, e.g. due to Emcee update, each queue will spawn its own set of workers. In most cases these sets are identical. It means that each worker machine will run two workers - one for the older version of Emcee, and another one for newer.

Machine resources are limited, in order to avoid overloading machine with simulators, tests, processes, worker sharing feature splits all workers between all running queues, such that each queue gets its dedicated subset of workers. These subsets do not overlap between queues. If any queue has some specific workers assigned to it, and other queues do not have them, that queue will still operate those workers.

When one of the queues dies, rebalancing occurs. For instance, if there is a single alive queue left, will start utilizing all workers.

## How to Balance

Emcee needs to decide how to split workers between queues randomly, but still stably. It means that for any given time, for set of running queues, the result of rebalancing must be the same.

To achieve this, a working Emcee queue picks a master queue which will perform rebalancing operation. All other queues, including master queue itself, will detect a master queue using the same algorithm. Master queue will consider itself as a master queue. Thus, all queues will speak to the same master queue.

Then each queue will ask master queue for subset of workers it can utilize. Master queue will query all running queues for their initial workers and then calculate the subset of workers for each queue.

This worker rebalancing happens periodically and fully automatically.

# Implementation Details

## Determining Master Queue

`RemoteQueueDetector` is used to determine a master queue.

## Determining What Workers Can Be Utilized

Each queue queries master queue for workers that can be utilized by that queue via `QueueCommunicationService.workersToUtilize()`.

On the master queue side: it runs `WorkersToUtilizeService` attached a to REST endpoint (`/workersToUtilize` as of writing).

When other queue asks for workers, `WorkersToUtilizeService.workersToUtilize()` is invoked. It:

- scans for all running queues on hosts that are specified in master queue config. `RemotePortDeterminer` is used for scanning purposes.

- queries all queues for their initial workers via `QueueCommunicationService.deploymentDestinations()`

- calculates the non overlapping sets for each queue via `WorkersToUtilizeCalculator`

To avoid scanning remote queues on each request, `WorkersToUtilizeService` has built-in cache (`WorkersMappingCache`) with previously computed balancing information per each qeueue. Cache is automatically invalidated after some time, causing the balancing information to be recomputed.
