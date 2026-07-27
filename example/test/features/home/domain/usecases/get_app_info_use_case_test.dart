import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/core/error/failure.dart';
import 'package:example/features/home/domain/entities/app_info.dart';
import 'package:example/features/home/domain/repositories/app_info_repository.dart';
import 'package:example/features/home/domain/usecases/get_app_info_use_case.dart';

class _FakeAppInfoRepository implements AppInfoRepository {
  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async {
    return const Right(
      AppInfo(title: 'Ready', description: 'AgentKit is configured'),
    );
  }
}

void main() {
  test('returns app info from the repository', () async {
    final useCase = GetAppInfoUseCase(_FakeAppInfoRepository());

    final result = await useCase();

    result.fold(
      (failure) => fail('Expected app info, got: ${failure.message}'),
      (info) {
        expect(info.title, 'Ready');
        expect(info.description, 'AgentKit is configured');
      },
    );
  });
}
