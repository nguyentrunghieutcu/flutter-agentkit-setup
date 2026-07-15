import 'package:dartz/dartz.dart';

import 'package:example/core/error/failure.dart';
import 'package:example/features/home/domain/entities/app_info.dart';
import 'package:example/features/home/domain/repositories/app_info_repository.dart';

class GetAppInfoUseCase {
  const GetAppInfoUseCase(this._repository);

  final AppInfoRepository _repository;

  Future<Either<Failure, AppInfo>> call() => _repository.getAppInfo();
}
