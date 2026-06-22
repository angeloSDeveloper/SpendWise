import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class SyncQueueDao extends BaseDao {
  SyncQueueDao(AppDatabase db) : super(db, 'sync_queue');
}
