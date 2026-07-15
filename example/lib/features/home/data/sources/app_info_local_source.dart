import 'package:example/features/home/data/models/app_info_model.dart';

class AppInfoLocalSource {
  Future<AppInfoModel> load() async {
    return const AppInfoModel(
      title: 'Clean Architecture is ready',
      description: 'Presentation, Domain and Data are separated by feature.',
    );
  }
}
