import 'dart:collection';
import "package:mutex/mutex.dart";

class MessageBus {
  //DI as singleton
  MessageBus._privateConstructor();

  static final MessageBus _instance = MessageBus._privateConstructor();

  factory MessageBus() {


    return _instance;
  }

  static final MessageBus instance = _instance;

  static const String Channel_CurrentAudio_State = "CurrentAudio_State";

  static const String Queue_App_Time_Elapsed =
      "Queue_App_Time_Elapsed_Testing_How_To_Use_Queue_Globally";

  var _channel = Map<String, Map<String, Future<void> Function(dynamic)>>();

  Future<void> debug_loopStatistic() async {
    while (true) {
      // for (var c in _channel.keys) {
      //   print("|-$c");
      //   for (var s in _channel[c]!.keys) {
      //     print("|--Sub: $s");
      //   }
      // }
      for(var q in _queueMap.values){
        print("qsize: ${q.length}");
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  final _queueMap = Map<String, Queue<dynamic>>();
  var _queueLocker = false;

  //todo: have do test using Lock()
  final _queueLockerMutex = Mutex();

  Future<bool> Enqueue<T>(String queueName, T data, {limitTo: 1000}) async {
    try {
      var getLock = await _queueLockerMutex.acquire();
      //if (getLock == null) return false; //some how can not talk to cpu get lock

      //if (_queueLocker == true) return false;
      _queueLocker = true;

      if (_queueMap.containsKey(queueName) == false) {
        _queueMap[queueName] = Queue<dynamic>();
      }
      var qlen = _queueMap[queueName]?.length ?? 0;
      if (qlen > limitTo) {
        //prevent stuck queue or over ram consume
        var toRemove = qlen - limitTo;
        for (var i = 0; i < toRemove; i++) {
          _queueMap[queueName]?.removeFirst();
        }
      }

      _queueMap[queueName]?.add(data);
      return true;
    } finally {
      _queueLockerMutex.release();
      _queueLocker = false;
    }
  }

  Future<T?> Dequeue<T>(String queueName) async {
    try {
      var getLock = await _queueLockerMutex.acquire();
      //if (getLock == null) return null;
      //if (_queueLocker == true) return null;
      _queueLocker = true;

      if (_queueMap.containsKey(queueName) == false) {
        _queueMap[queueName] = Queue<dynamic>();
      }

      var qlen = _queueMap[queueName]?.length ?? 0;
      if (qlen == 0) return null;

      T itm = _queueMap[queueName]?.first;
      _queueMap[queueName]?.remove(itm);
      return itm;
    } finally {
      _queueLockerMutex.release();
      _queueLocker = false;
    }
  }

  Future<void> Subscribe(String channelName, String subscriberName,
      Future<void> Function(dynamic) handle) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = <String, Future<void> Function(dynamic)>{};
    }
    _channel[channelName]?[subscriberName] = handle;
  }

  Future<void> Unsubscribe(String channelName, String subscriberName) async {
    _channel[channelName]!.remove(subscriberName);
  }

  Future<void> ClearChannel(String channelName) async {
    _channel.remove(channelName);
  }

  Future<void> Publish(String channelName, dynamic data) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = <String, Future<void> Function(dynamic)>{};
    }
    for (var h in _channel[channelName]!.values) {
      h(data);
    }
  }
}
