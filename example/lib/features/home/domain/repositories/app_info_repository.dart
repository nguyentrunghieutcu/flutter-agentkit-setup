import 'package:dartz/dartz.dart';

import 'package:example/core/error/failure.dart';
import 'package:example/features/home/domain/entities/app_info.dart';

abstract interface class AppInfoRepository {
  Future<Either<Failure, AppInfo>> getAppInfo();
}
