# API Reference

> Read before writing any API call, creating a model, or handling HTTP errors.
> Update this file whenever a new endpoint is integrated.

## HTTP Client

File: `lib/core/network/api_client.dart`
Base URL: `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart`
Auth: Bearer token injected by `AuthInterceptor` — do not add headers manually.
Errors: handled centrally in `ApiErrorInterceptor` — do not wrap calls in try/catch in providers.

```dart
class ProductRemoteSource {
  final ApiClient _client;
  ProductRemoteSource(this._client);

  Future<List<ProductModel>> getProducts() async {
    final response = await _client.get('/products');
    return (response.data['data'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }
}
```

## Response envelope

```json
{ "success": true, "data": {}, "message": "OK", "errors": null }
```

Paginated:
```json
{ "data": [], "meta": { "current_page": 1, "last_page": 5, "per_page": 20, "total": 98 } }
```

## File upload

```dart
final formData = FormData.fromMap({
  'avatar': await MultipartFile.fromFile(path, filename: 'avatar.jpg'),
  'user_id': userId,
});
await _client.post('/user/avatar', data: formData);
```

Never embed file bytes as base64 in a JSON body.

## Endpoint Registry

### Auth
| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/login` | `{email, password}` | `{token, user}` |
| POST | `/auth/logout` | — | `{message}` |
| GET | `/auth/me` | — | `UserModel` |
| POST | `/auth/refresh` | `{refresh_token}` | `{token}` |

> Add feature endpoints below as they are integrated.

## HTTP Error Codes

| Status | Meaning | Handled by |
|---|---|---|
| 401 | Unauthenticated | Interceptor → redirect to login |
| 403 | Forbidden | Show error, do not redirect |
| 422 | Validation | Parse `errors` field, show per-field |
| 500 | Server error | Show generic message |
