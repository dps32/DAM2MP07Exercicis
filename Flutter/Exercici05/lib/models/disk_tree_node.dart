class DiskTreeNode {
  DiskTreeNode({
    required this.name,
    required this.path,
    required this.size,
    List<DiskTreeNode>? children,
  }) : children = children ?? <DiskTreeNode>[];


  final String name;
  final String path;
  final int size;
  final List<DiskTreeNode> children;
}
