/// Platform seams picked at compile time: the Android build uses Google
/// Play (AdMob, Billing, Play Games); the web build has none of them.
library;

export 'platform_services_mobile.dart'
    if (dart.library.js_interop) 'platform_services_web.dart';
