import BucketQueue
import Foundation
import Models

/// Balancing bucket queue is a wrapper on top of multiple BucketQueue objects - each wrapped by JobQueue instance.
/// It will provide buckets for dequeueing by querying all jobs.
public protocol BalancingBucketQueue:
    BucketResultAccepter,
    DequeueableBucketSource,
    EnqueueableBucketReceptor,
    JobManipulator,
    JobResultsProvider,
    JobStateProvider,
    QueueStateProvider,
    StuckBucketsReenqueuer
{}
