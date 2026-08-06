class PhotoTile {
  final int index;
  final int width;
  final int height;

  const PhotoTile(this.index, this.width, this.height);
}

List<PhotoTile> generatePhotoLayout(int count) {
  if (count == 1) {
    return const [PhotoTile(0, 3, 3)];
  }

  if (count == 2) {
    return const [PhotoTile(0, 1, 1), PhotoTile(1, 1, 1)];
  }

  if (count == 3) {
    return const [PhotoTile(0, 2, 2), PhotoTile(1, 1, 1), PhotoTile(2, 1, 1)];
  }

  final tiles = <PhotoTile>[];

  const pattern = <List<int>>[
    [2, 2],
    [1, 1],
    [1, 1],
    [1, 1],
    [1, 1],
    [1, 1],
    [1, 1],
    [2, 2],
    [1, 1],
    [1, 1],
    [1, 1],
    [1, 1],
  ];

  for (int i = 0; i < count; i++) {
    final tile = pattern[i % pattern.length];
    tiles.add(PhotoTile(i, tile[0], tile[1]));
  }

  return tiles;
}
