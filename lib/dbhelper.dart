import 'dart:io';

import 'package:sqflite/sqflite.dart';

final String table = 'tellMe';
final String columnId = 'id';
final String columnTitle = 'tell';
final String columnTime = 'time';

class Tell {
  int id;
  String tell;
  String time;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTitle: tell,
      columnTime:
          '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}'
    };
    map[columnId] = null;
    return map;
  }

  Tell();

  Tell.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    tell = map[columnTitle];
    time = map[columnTime];
  }
}

class DbProvider {
  Database db;
  String dbPath;
  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $table ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text not null,
  $columnTime text not null)
''');
    });
  }

  Future<List<Tell>> getAll() async {
    print(db.isOpen);
    print(db.path);
    List<Map> maps = await db.rawQuery('SELECT * FROM $table');
    //await this.close();
    if (maps.length > 0) {
      var genList = List<Tell>();
      for (var it in maps) {
        genList.add(Tell.fromMap(it));
        print(it);
      }
      return genList;
    }
    return null;
  }

  Future<String> getDbPath(table) async {
    String plainPath = await getDatabasesPath();
    String path = '${plainPath}/${table}.db';
    return path;
  }

  Future<bool> creat() async {
    String plainPath = await getDatabasesPath();
    String path = '${plainPath}/${table}.db';
    dbPath = path;
    print('init db $path');
    if (!await Directory(plainPath).exists()) {
      print('creating db $path');
      try {
        await Directory(plainPath).create(recursive: true);
        await this.open(path);
        return true;
      } catch (e) {
        print(e);
        return false;
      }
    } else {
      this.open(path);
    }
  }

  Future<Tell> insert(Tell todo) async {
    todo.id = await db.insert(table, todo.toMap());
    return todo;
  }

  Future<Tell> getTodo(int id) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnTime, columnTitle],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Tell.fromMap(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Tell todo) async {
    return await db.update(table, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future close() async => db.close();
}
