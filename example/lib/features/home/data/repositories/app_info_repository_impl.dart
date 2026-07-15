import 'package:dartz/dartz.dart';

import 'package:example/core/error/failure.dart';
import 'package:example/features/home/data/sources/app_info_local_source.dart';
import 'package:example/features/home/domain/entities/app_info.dart';
import 'package:example/features/home/domain/repositories/app_info_repository.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  const AppInfoRepositoryImpl(this._source);

  final AppInfoLocalSource _source;

  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async {
    try {
      final model = await _source.load();
      return Right(model.toEntity());
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
