String normalizeProductType(String? raw, {String fallback = 'physical'}) {
  final value = raw?.trim().toLowerCase() ?? '';
  if (value.isEmpty) {
    return fallback;
  }

  final compact = value.replaceAll(RegExp(r'[^a-z0-9]+'), '');

  const physicalAliases = <String>{
    'physical',
    'fisik',
    'barang',
    'productbarang',
    'barangfisik',
    'produkbarang',
  };

  const digitalAliases = <String>{
    'digital',
    'produkdigital',
    'stickerdigital',
    'template',
    'subscription',
    'langganan',
    'renewal',
  };

  if (physicalAliases.contains(compact) ||
      compact.contains('physical') ||
      compact.contains('fisik') ||
      compact.contains('barang')) {
    return 'physical';
  }

  if (digitalAliases.contains(compact) ||
      compact.contains('digital') ||
      compact.contains('sticker') ||
      compact.contains('template') ||
      compact.contains('langganan') ||
      compact.contains('subscription') ||
      compact.contains('renewal')) {
    return 'digital';
  }

  return fallback;
}

bool isDigitalProductType(String? raw) {
  return normalizeProductType(raw) == 'digital';
}

bool isPhysicalProductType(String? raw) {
  return !isDigitalProductType(raw);
}
