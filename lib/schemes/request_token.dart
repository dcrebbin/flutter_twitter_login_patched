import 'package:http/http.dart' as http;
import 'package:twitter_login/schemes/request_header.dart';
import 'package:twitter_login/src/signature.dart';
import 'package:twitter_login/src/utils.dart';

///
class RequestToken {
  /// Oauth token
  final String _token;

  /// Oauth token secret
  final String _tokenSecret;

  ///
  final String _callbackConfirmed;

  String get token => _token;
  String get tokenSecret => _tokenSecret;
  String get callbackConfirmed => _callbackConfirmed;
  String get authorizeURI => '$authorizeURI?oauth_token=$_token';

  /// constract
  RequestToken._(Map<String, dynamic> params)
      : this._token = params['oauth_token'],
        this._tokenSecret = params['oauth_token_secret'],
        this._callbackConfirmed = params['oauth_callback_confirmed'];

  /// Request user authorization token
  static Future<RequestToken> getRequestToken(
    String apiKey,
    String apiSecretKey,
    String redirectURI,
  ) async {
    final authParams = RequestHeader.authorizeHeaderParams(
      apiKey,
      redirectURI,
    );
    final _signature = Signature(
      url: requestTokenURI,
      method: 'POST',
      params: authParams,
      apiKey: apiKey,
      apiSecretKey: apiSecretKey,
      tokenSecretKey: '',
    );
    authParams['oauth_signature'] = _signature.signatureHmacSha1(
      _signature.getSignatureKey(),
      _signature.signatureDate(),
    );
    final String header = authHeader(authParams);
    final http.BaseClient _httpClient = http.Client();
    final http.Response res = await _httpClient.post(
      requestTokenURI,
      headers: <String, String>{'Authorization': header},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed ${res.reasonPhrase}");
    }

    final params = Uri.splitQueryString(res.body);
    final requestToken = RequestToken._(params);
    if (requestToken.callbackConfirmed.toLowerCase() != 'true') {
      throw StateError('oauth_callback_confirmed mast be true');
    }

    return requestToken;
  }
}
