/// Builds a URL with query parameters.
///
/// Merge the base query parameters with the query parameters (base are overridden by the method's)
Uri buildUrl(String baseUrl, Map<String, dynamic>? baseQueryParams,
    Map<String, dynamic>? queryParams) {
  final uri = Uri.parse(baseUrl);

  final Map<String, String> mergedQueryParams =
      mergeMaps(baseQueryParams, queryParams)
          .map((key, value) => MapEntry(key, value.toString()));

  return uri.replace(queryParameters: mergedQueryParams);
}

/// Merges two maps, returning a new map. If both maps have the same key, the value from map2 is used.
Map<String, dynamic> mergeMaps(
    Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
  return {...?map1, ...?map2};
}
