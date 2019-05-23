import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'pusher.g.dart';

class Pusher {
  Pusher._();

  static const _channel = const MethodChannel('pusher');
  static const _eventChannel = const EventChannel('pusherStream');

  static void Function(ConnectionStateChange) _onConnectionStateChange;
  static void Function(ConnectionError) _onError;

  static Future init(String appKey, PusherOptions options) async {
    assert(appKey != null);
    assert(options != null);

    _eventChannel.receiveBroadcastStream().listen(_handleEvent);

    final initArgs = jsonEncode(_InitArgs(appKey, options).toJson());
    await _channel.invokeMethod('init', initArgs);
  }

  static void _handleEvent([dynamic arguments]) {
    if (arguments == null || !(arguments is String)) {
      //TODO log
    }

    var message = PusherEventStreamMessage.fromJson(jsonDecode(arguments));

    if (message.isEvent) {
      print(message.event.data);
    } else if (message.isConnectionStateChange) {
      if (_onConnectionStateChange != null) {
        _onConnectionStateChange(message.connectionStateChange);
      }
    } else if (message.isConnectionError) {
      if (_onError != null) {
        _onError(message.connectionError);
      }
    }
  }

  /// Connect the client to pusher
  static Future connect(
      {void Function(ConnectionStateChange) onConnectionStateChange,
      void Function(ConnectionError) onError}) async {
    _onConnectionStateChange = onConnectionStateChange;
    _onError = onError;
    await _channel.invokeMethod('connect');
  }

  /// Disconnect the client from pusher
  static Future disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  /// Subscribe to a channel
  /// Use the returned [Channel] to bind events
  static Future<Channel> subscribe(String channelName) async {
    await _channel.invokeMethod('subscribe', channelName);
    return Channel(name: channelName);
  }

  /// Subscribe to a channel
  /// Use the returned [Channel] to bind events
  static Future unsubscribe(String channelName) async {
    await _channel.invokeMethod('unsubscribe', channelName);
  }

  static Future _bind(String channelName, String eventName,
      {Function(Event) onEvent}) async {
    final bindArgs = jsonEncode(
        _BindArgs(channelName: channelName, eventName: eventName).toJson());
    await _channel.invokeMethod('bind', bindArgs);
  }
}

@JsonSerializable()
class _InitArgs {
  String appKey;
  PusherOptions options;

  _InitArgs(this.appKey, this.options);

  factory _InitArgs.fromJson(Map<String, dynamic> json) =>
      _$_InitArgsFromJson(json);

  Map<String, dynamic> toJson() => _$_InitArgsToJson(this);
}

@JsonSerializable()
class _BindArgs {
  String channelName;
  String eventName;

  _BindArgs({this.channelName, this.eventName});

  factory _BindArgs.fromJson(Map<String, dynamic> json) =>
      _$_BindArgsFromJson(json);

  Map<String, dynamic> toJson() => _$_BindArgsToJson(this);
}

@JsonSerializable()
class PusherOptions {
  String cluster;

  PusherOptions({this.cluster});

  factory PusherOptions.fromJson(Map<String, dynamic> json) =>
      _$PusherOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$PusherOptionsToJson(this);
}

@JsonSerializable()
class ConnectionStateChange {
  String currentState;
  String previousState;

  ConnectionStateChange({this.currentState, this.previousState});

  factory ConnectionStateChange.fromJson(Map<String, dynamic> json) =>
      _$ConnectionStateChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionStateChangeToJson(this);
}

@JsonSerializable()
class ConnectionError {
  String message;
  String code;
  String exception;

  ConnectionError({this.message, this.code, this.exception});

  factory ConnectionError.fromJson(Map<String, dynamic> json) =>
      _$ConnectionErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionErrorToJson(this);
}

@JsonSerializable()
class Event {
  String channel;
  String event;
  String data;

  Event({this.channel, this.event, this.data});

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}

class Channel {
  String name;

  Channel({this.name});

  Future bind(String eventName, Function(Event) onEvent) async {
    await Pusher._bind(name, eventName);
  }

  void unbind(String eventName) {}
}

@JsonSerializable()
class PusherEventStreamMessage {
  Event event;
  ConnectionStateChange connectionStateChange;
  ConnectionError connectionError;

  bool get isEvent => event != null;
  bool get isConnectionStateChange => connectionStateChange != null;
  bool get isConnectionError => connectionError != null;

  PusherEventStreamMessage(
      {this.event, this.connectionStateChange, this.connectionError});

  factory PusherEventStreamMessage.fromJson(Map<String, dynamic> json) =>
      _$PusherEventStreamMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PusherEventStreamMessageToJson(this);
}
