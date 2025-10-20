import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(String url) async {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }

  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
    );
  } else {
    throw 'Tidak dapat membuka $url';
  }
}
