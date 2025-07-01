/// Base class for pub-sub events
sealed class PubSubEvent<T> {
  final String channel;

  const PubSubEvent(this.channel);
}

/// Event emitted when a message is received on a subscribed channel
class PubSubMessage<T> extends PubSubEvent<T> {
  final T data;

  const PubSubMessage(super.channel, this.data);
}

/// Event emitted when successfully subscribed to a channel
class PubSubSubscribed extends PubSubEvent<Never> {
  final int subscriberCount;

  const PubSubSubscribed(super.channel, this.subscriberCount);
}

/// Event emitted when successfully unsubscribed from a channel
class PubSubUnsubscribed extends PubSubEvent<Never> {
  final int subscriberCount;

  const PubSubUnsubscribed(super.channel, this.subscriberCount);
}
