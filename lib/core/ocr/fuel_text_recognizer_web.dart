import 'dart:js_interop';

@JS('recognizeFuelImage')
external JSPromise<JSString?> _recognizeFuelImage(JSString imageUrl);

Future<String?> recognizeFuelText(String path) async {
  final result = await _recognizeFuelImage(path.toJS).toDart;
  return result?.toDart;
}
