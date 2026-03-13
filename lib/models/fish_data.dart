// models/fish_data.dart
// Each fish is a unique bold vector silhouette
// Stored as CustomPainter descriptions for Flutter rendering

class FishData {
  final int id;
  final String name; // internal label
  final FishDirection direction;
  final FishShape shape;

  const FishData({
    required this.id,
    required this.name,
    required this.direction,
    required this.shape,
  });
}

enum FishDirection { left, right, up, down }
enum FishShape { round, long, tall, wide, slim, chubby, diamond, arrow }

// All 8 fish used in the memory test
const List<FishData> allFish = [
  FishData(id: 0, name: 'tuna',    direction: FishDirection.right, shape: FishShape.round),
  FishData(id: 1, name: 'flounder', direction: FishDirection.left,  shape: FishShape.wide),
  FishData(id: 2, name: 'eel',     direction: FishDirection.right, shape: FishShape.long),
  FishData(id: 3, name: 'puffer',  direction: FishDirection.left,  shape: FishShape.chubby),
  FishData(id: 4, name: 'angel',   direction: FishDirection.up,    shape: FishShape.tall),
  FishData(id: 5, name: 'sword',   direction: FishDirection.right, shape: FishShape.slim),
  FishData(id: 6, name: 'ray',     direction: FishDirection.left,  shape: FishShape.diamond),
  FishData(id: 7, name: 'arrow',   direction: FishDirection.right, shape: FishShape.arrow),
];
