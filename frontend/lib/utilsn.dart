import 'dart:convert';
import 'package:flutter/material.dart';

/// Safely decodes base64 image strings without throwing FormatException
/// when filenames or invalid strings are returned from the backend.
ImageProvider getSafeImageProvider(dynamic imageSource, {String fallbackAsset = 'assets/drpat.png'}) {
  if (imageSource == null) {
    return AssetImage(fallbackAsset);
  }
  final str = imageSource.toString().trim();
  if (str.isEmpty) {
    return AssetImage(fallbackAsset);
  }
  // Check if string is a filename rather than raw base64 data
  if (str.endsWith('.jpg') || str.endsWith('.png') || str.endsWith('.jpeg')) {
    return AssetImage(fallbackAsset);
  }
  try {
    final cleanB64 = str.contains(',') ? str.split(',').last.trim() : str;
    return MemoryImage(base64Decode(cleanB64));
  } catch (_) {
    return AssetImage(fallbackAsset);
  }
}
