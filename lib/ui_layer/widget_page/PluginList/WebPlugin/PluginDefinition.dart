import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';

/// Base class for plugin definitions
/// @deprecated Use BasePluginDefinition instead for enhanced functionality
@Deprecated(
  'Use BasePluginDefinition instead. This class is kept for backward compatibility.',
)
class PluginDefinitionCard extends BasePluginProtocol {
  const PluginDefinitionCard({
    required super.name,
    required super.description,
    required super.icon,
    required super.protocol,
    required super.host,
    required super.url,
    super.imageUrl,
    super.category,
    super.tags,
    super.requiresAuth,
  });
}
