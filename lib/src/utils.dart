/// Builds a URL with query parameters.
Uri buildUrl(String baseUrl, Map<String, dynamic>? queryParams) {
  if (queryParams == null) {
    return Uri.parse(baseUrl);
  }
  final uri = Uri.parse(baseUrl);
  final newUri = uri.replace(queryParameters: queryParams);
  return newUri;
}
