import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Relational DB schema Definition
class TodosTable extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0: Low, 1: Medium, 2: High

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TodosTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented schema version

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(todosTable, todosTable.dueDate);
        await m.addColumn(todosTable, todosTable.priority);
      }
    },
  );

  // Streams real-time updates directly to Riverpod UI listeners
  Stream<List<TodosTableData>> watchTodos() => select(todosTable).watch();

  // Cache or update server items locally using stable upsert logic
  Future<void> cacheTodos(List<TodosTableData> todos) async {
    await batch((batch) {
      batch.insertAll(todosTable, todos, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> insertTodoLocal(
    String title, {
    DateTime? dueDate,
    int priority = 0,
  }) async {
    final lastTodo =
        await (select(todosTable)
              ..orderBy([
                (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

    final nextId = (lastTodo?.id ?? 0) + 1;
    await into(todosTable).insert(
      TodosTableCompanion.insert(
        id: Value(nextId),
        title: title,
        completed: Value(false),
        dueDate: Value(dueDate),
        priority: Value(priority),
      ),
    );
    return nextId;
  }

  Future<void> insertTodoLocalWithId(
    int id,
    String title,
    bool completed, {
    DateTime? dueDate,
    int priority = 0,
  }) async {
    await into(todosTable).insert(
      TodosTableCompanion.insert(
        id: Value(id),
        title: title,
        completed: Value(completed),
        dueDate: Value(dueDate),
        priority: Value(priority),
      ),
    );
  }

  Future<TodosTableData?> deleteTodoLocal(int id) async {
    final todo = await (select(
      todosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (todo != null) {
      await (delete(todosTable)..where((t) => t.id.equals(id))).go();
    }
    return todo;
  }

  Future<void> toggleTodoLocal(int id, bool completed) async {
    await (update(todosTable)..where((t) => t.id.equals(id))).write(
      TodosTableCompanion(completed: Value(completed)),
    );
  }

  Future<void> updateTodoTitle(int id, String title) async {
    await (update(todosTable)..where((t) => t.id.equals(id))).write(
      TodosTableCompanion(title: Value(title)),
    );
  }

  Future<void> updateTodoPriority(int id, int priority) async {
    await (update(todosTable)..where((t) => t.id.equals(id))).write(
      TodosTableCompanion(priority: Value(priority)),
    );
  }

  Future<void> updateTodoDueDate(int id, DateTime? dueDate) async {
    await (update(todosTable)..where((t) => t.id.equals(id))).write(
      TodosTableCompanion(dueDate: Value(dueDate)),
    );
  }
}

final appDatabase = AppDatabase();

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
