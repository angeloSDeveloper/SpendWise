import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class CategoriesDao extends BaseDao {
  CategoriesDao(AppDatabase db) : super(db, 'categories');
}
