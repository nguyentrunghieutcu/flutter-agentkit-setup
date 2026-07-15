import 'package:example/core/utils/json_map.dart';
import 'package:example/features/home/domain/entities/app_info.dart';

class AppInfoModel {
  const AppInfoModel({required this.title, required this.description});

  final String title;
  final String description;

  factory AppInfoModel.fromJson(JsonMap json) => AppInfoModel(
    title: json['title'] as String,
    description: json['description'] as String,
  );

  JsonMap toJson() => {'title': title, 'description': description};

  AppInfo toEntity() => AppInfo(title: title, description: description);
}
