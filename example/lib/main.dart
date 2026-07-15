import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:example/app.dart';
import 'package:example/features/home/data/repositories/app_info_repository_impl.dart';
import 'package:example/features/home/data/sources/app_info_local_source.dart';
import 'package:example/features/home/domain/usecases/get_app_info_use_case.dart';
import 'package:example/features/home/presentation/providers/app_info_provider.dart';

void main() {
  final dataSource = AppInfoLocalSource();
  final repository = AppInfoRepositoryImpl(dataSource);
  final getAppInfo = GetAppInfoUseCase(repository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppInfoProvider(getAppInfo)..load(),
        ),
      ],
      child: const App(),
    ),
  );
}
