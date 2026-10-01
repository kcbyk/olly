import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../../../../core/errors/failures.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({required String email, required String password});
  Future<Either<Failure, UserEntity>> signUpWithEmail({required String email, required String password, required String username});
  Future<Either<Failure, void>> signOut();
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
}
