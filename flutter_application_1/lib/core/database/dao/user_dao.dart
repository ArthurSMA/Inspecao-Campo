import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<void> saveUser(UsersCompanion user) async {
    await into(users).insertOnConflictUpdate(user);
  }

  Future<User?> getUser() async {
    return select(users).getSingleOrNull();
  }

  Future<void> deleteUser() async {
    await delete(users).go();
  }
}
