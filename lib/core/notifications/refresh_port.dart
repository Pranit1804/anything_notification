import 'dart:isolate';
import 'dart:ui';

/// Lets a background isolate (a notification action, the boot worker) tell the
/// running UI isolate that the database changed underneath it.
abstract final class RefreshPort {
  static const _name = 'com.bytecode.anything_notification/refresh';

  /// Calls [onRefresh] whenever another isolate sends [notify]. Call
  /// [RefreshListener.dispose] to stop.
  static RefreshListener listen(void Function() onRefresh) {
    // Replace a mapping left behind by a previous (hot-restarted) isolate.
    IsolateNameServer.removePortNameMapping(_name);
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _name);
    port.listen((_) => onRefresh());
    return RefreshListener._(port);
  }

  /// Does nothing when no UI isolate is listening.
  static void notify() => IsolateNameServer.lookupPortByName(_name)?.send(null);
}

class RefreshListener {
  RefreshListener._(this._port);

  final ReceivePort _port;

  void dispose() {
    IsolateNameServer.removePortNameMapping(RefreshPort._name);
    _port.close();
  }
}
