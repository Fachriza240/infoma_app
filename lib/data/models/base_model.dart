abstract class BaseModel {
  Map<String, dynamic> toJson();

  static T fromJson<T>(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented');
  }
}
