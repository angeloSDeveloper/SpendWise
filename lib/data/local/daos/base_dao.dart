import 'package:drift/drift.dart';
import 'package:spendwise/data/local/database.dart';

/// Shared, map-based CRUD used by the small table-specific DAOs.
abstract class BaseDao {
  BaseDao(this.db, this.table, {this.syncColumn = false});
  final AppDatabase db;
  final String table;
  final bool syncColumn;
  Future<List<Map<String, Object?>>> all() async => (await db.customSelect('SELECT * FROM $table').get()).map((row) => row.data).toList();
  Future<Map<String, Object?>?> find(String id) async => (await db.customSelect('SELECT * FROM $table WHERE id = ?', variables: [Variable(id)]).getSingleOrNull())?.data;
  Future<void> insert(Map<String, Object?> values) async { final columns=values.keys.toList(); await db.customStatement('INSERT OR REPLACE INTO $table (${columns.join(',')}) VALUES (${List.filled(columns.length,'?').join(',')})',values.values.toList()); }
  Future<void> update(String id,Map<String,Object?> values) async { if(values.isEmpty)return; await db.customStatement('UPDATE $table SET ${values.keys.map((key)=>'$key = ?').join(',')} WHERE id = ?',[...values.values,id]); }
  Future<void> delete(String id)=>db.customStatement('DELETE FROM $table WHERE id = ?',[id]);
  Future<List<Map<String,Object?>>> between(String column,DateTime from,DateTime to)async=>(await db.customSelect('SELECT * FROM $table WHERE $column BETWEEN ? AND ? ORDER BY $column DESC',variables:[Variable(from),Variable(to)]).get()).map((row)=>row.data).toList();
  Future<List<Map<String,Object?>>> pending()async=>syncColumn?(await db.customSelect('SELECT * FROM $table WHERE synced = 0').get()).map((row)=>row.data).toList():const [];
}
