/// Which main categories are open in the Danh mục list, kept on this device
/// only. Failures are ignored: the list just starts collapsed.
abstract class CategoryExpansionRepository {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}
