// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorValue,
    iconKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final int colorValue;
  final String iconKey;
  final int sortOrder;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, iconKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int colorValue,
    required String iconKey,
    required int sortOrder,
  }) : name = Value(name),
       colorValue = Value(colorValue),
       iconKey = Value(iconKey),
       sortOrder = Value(sortOrder);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<String>? iconKey,
    Value<int>? sortOrder,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startLocal =
      GeneratedColumn<int>(
        'start_local',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RemindersTable.$converterstartLocal);
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceRule?, String>
  recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RecurrenceRule?>($RemindersTable.$converterrecurrencen);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeliveryMode, int> delivery =
      GeneratedColumn<int>(
        'delivery',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DeliveryMode>($RemindersTable.$converterdelivery);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ReminderStatus>($RemindersTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  resolvedThroughLocal = GeneratedColumn<int>(
    'resolved_through_local',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($RemindersTable.$converterresolvedThroughLocaln);
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    startLocal,
    recurrence,
    categoryId,
    delivery,
    status,
    resolvedThroughLocal,
    snoozedUntil,
    revision,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      startLocal: $RemindersTable.$converterstartLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_local'],
        )!,
      ),
      recurrence: $RemindersTable.$converterrecurrencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recurrence'],
        ),
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      delivery: $RemindersTable.$converterdelivery.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}delivery'],
        )!,
      ),
      status: $RemindersTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      resolvedThroughLocal: $RemindersTable.$converterresolvedThroughLocaln
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}resolved_through_local'],
            ),
          ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartLocal =
      const NaiveDateTimeConverter();
  static TypeConverter<RecurrenceRule, String> $converterrecurrence =
      const RecurrenceRuleConverter();
  static TypeConverter<RecurrenceRule?, String?> $converterrecurrencen =
      NullAwareTypeConverter.wrap($converterrecurrence);
  static JsonTypeConverter2<DeliveryMode, int, int> $converterdelivery =
      const EnumIndexConverter<DeliveryMode>(DeliveryMode.values);
  static JsonTypeConverter2<ReminderStatus, int, int> $converterstatus =
      const EnumIndexConverter<ReminderStatus>(ReminderStatus.values);
  static TypeConverter<DateTime, int> $converterresolvedThroughLocal =
      const NaiveDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterresolvedThroughLocaln =
      NullAwareTypeConverter.wrap($converterresolvedThroughLocal);
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final int id;
  final String title;
  final String? note;

  /// Naive wall-clock time of the first occurrence.
  final DateTime startLocal;
  final RecurrenceRule? recurrence;

  /// Not a foreign key: deleting a category clears this by hand.
  final int? categoryId;
  final DeliveryMode delivery;
  final ReminderStatus status;
  final DateTime? resolvedThroughLocal;
  final DateTime? snoozedUntil;
  final int revision;
  final DateTime createdAt;
  const ReminderRow({
    required this.id,
    required this.title,
    this.note,
    required this.startLocal,
    this.recurrence,
    this.categoryId,
    required this.delivery,
    required this.status,
    this.resolvedThroughLocal,
    this.snoozedUntil,
    required this.revision,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['start_local'] = Variable<int>(
        $RemindersTable.$converterstartLocal.toSql(startLocal),
      );
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(
        $RemindersTable.$converterrecurrencen.toSql(recurrence),
      );
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    {
      map['delivery'] = Variable<int>(
        $RemindersTable.$converterdelivery.toSql(delivery),
      );
    }
    {
      map['status'] = Variable<int>(
        $RemindersTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || resolvedThroughLocal != null) {
      map['resolved_through_local'] = Variable<int>(
        $RemindersTable.$converterresolvedThroughLocaln.toSql(
          resolvedThroughLocal,
        ),
      );
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      startLocal: Value(startLocal),
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      delivery: Value(delivery),
      status: Value(status),
      resolvedThroughLocal: resolvedThroughLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedThroughLocal),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      revision: Value(revision),
      createdAt: Value(createdAt),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      startLocal: serializer.fromJson<DateTime>(json['startLocal']),
      recurrence: serializer.fromJson<RecurrenceRule?>(json['recurrence']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      delivery: $RemindersTable.$converterdelivery.fromJson(
        serializer.fromJson<int>(json['delivery']),
      ),
      status: $RemindersTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      resolvedThroughLocal: serializer.fromJson<DateTime?>(
        json['resolvedThroughLocal'],
      ),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'startLocal': serializer.toJson<DateTime>(startLocal),
      'recurrence': serializer.toJson<RecurrenceRule?>(recurrence),
      'categoryId': serializer.toJson<int?>(categoryId),
      'delivery': serializer.toJson<int>(
        $RemindersTable.$converterdelivery.toJson(delivery),
      ),
      'status': serializer.toJson<int>(
        $RemindersTable.$converterstatus.toJson(status),
      ),
      'resolvedThroughLocal': serializer.toJson<DateTime?>(
        resolvedThroughLocal,
      ),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReminderRow copyWith({
    int? id,
    String? title,
    Value<String?> note = const Value.absent(),
    DateTime? startLocal,
    Value<RecurrenceRule?> recurrence = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    DeliveryMode? delivery,
    ReminderStatus? status,
    Value<DateTime?> resolvedThroughLocal = const Value.absent(),
    Value<DateTime?> snoozedUntil = const Value.absent(),
    int? revision,
    DateTime? createdAt,
  }) => ReminderRow(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    startLocal: startLocal ?? this.startLocal,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    delivery: delivery ?? this.delivery,
    status: status ?? this.status,
    resolvedThroughLocal: resolvedThroughLocal.present
        ? resolvedThroughLocal.value
        : this.resolvedThroughLocal,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      startLocal: data.startLocal.present
          ? data.startLocal.value
          : this.startLocal,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      delivery: data.delivery.present ? data.delivery.value : this.delivery,
      status: data.status.present ? data.status.value : this.status,
      resolvedThroughLocal: data.resolvedThroughLocal.present
          ? data.resolvedThroughLocal.value
          : this.resolvedThroughLocal,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('startLocal: $startLocal, ')
          ..write('recurrence: $recurrence, ')
          ..write('categoryId: $categoryId, ')
          ..write('delivery: $delivery, ')
          ..write('status: $status, ')
          ..write('resolvedThroughLocal: $resolvedThroughLocal, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    startLocal,
    recurrence,
    categoryId,
    delivery,
    status,
    resolvedThroughLocal,
    snoozedUntil,
    revision,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.startLocal == this.startLocal &&
          other.recurrence == this.recurrence &&
          other.categoryId == this.categoryId &&
          other.delivery == this.delivery &&
          other.status == this.status &&
          other.resolvedThroughLocal == this.resolvedThroughLocal &&
          other.snoozedUntil == this.snoozedUntil &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<DateTime> startLocal;
  final Value<RecurrenceRule?> recurrence;
  final Value<int?> categoryId;
  final Value<DeliveryMode> delivery;
  final Value<ReminderStatus> status;
  final Value<DateTime?> resolvedThroughLocal;
  final Value<DateTime?> snoozedUntil;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.startLocal = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.delivery = const Value.absent(),
    this.status = const Value.absent(),
    this.resolvedThroughLocal = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required DateTime startLocal,
    this.recurrence = const Value.absent(),
    this.categoryId = const Value.absent(),
    required DeliveryMode delivery,
    required ReminderStatus status,
    this.resolvedThroughLocal = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       startLocal = Value(startLocal),
       delivery = Value(delivery),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? startLocal,
    Expression<String>? recurrence,
    Expression<int>? categoryId,
    Expression<int>? delivery,
    Expression<int>? status,
    Expression<int>? resolvedThroughLocal,
    Expression<DateTime>? snoozedUntil,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (startLocal != null) 'start_local': startLocal,
      if (recurrence != null) 'recurrence': recurrence,
      if (categoryId != null) 'category_id': categoryId,
      if (delivery != null) 'delivery': delivery,
      if (status != null) 'status': status,
      if (resolvedThroughLocal != null)
        'resolved_through_local': resolvedThroughLocal,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? note,
    Value<DateTime>? startLocal,
    Value<RecurrenceRule?>? recurrence,
    Value<int?>? categoryId,
    Value<DeliveryMode>? delivery,
    Value<ReminderStatus>? status,
    Value<DateTime?>? resolvedThroughLocal,
    Value<DateTime?>? snoozedUntil,
    Value<int>? revision,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      startLocal: startLocal ?? this.startLocal,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
      delivery: delivery ?? this.delivery,
      status: status ?? this.status,
      resolvedThroughLocal: resolvedThroughLocal ?? this.resolvedThroughLocal,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (startLocal.present) {
      map['start_local'] = Variable<int>(
        $RemindersTable.$converterstartLocal.toSql(startLocal.value),
      );
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(
        $RemindersTable.$converterrecurrencen.toSql(recurrence.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (delivery.present) {
      map['delivery'] = Variable<int>(
        $RemindersTable.$converterdelivery.toSql(delivery.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $RemindersTable.$converterstatus.toSql(status.value),
      );
    }
    if (resolvedThroughLocal.present) {
      map['resolved_through_local'] = Variable<int>(
        $RemindersTable.$converterresolvedThroughLocaln.toSql(
          resolvedThroughLocal.value,
        ),
      );
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('startLocal: $startLocal, ')
          ..write('recurrence: $recurrence, ')
          ..write('categoryId: $categoryId, ')
          ..write('delivery: $delivery, ')
          ..write('status: $status, ')
          ..write('resolvedThroughLocal: $resolvedThroughLocal, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences
    with TableInfo<$OccurrencesTable, OccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> scheduledLocal =
      GeneratedColumn<int>(
        'scheduled_local',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($OccurrencesTable.$converterscheduledLocal);
  @override
  late final GeneratedColumnWithTypeConverter<OccurrenceOutcome, int> outcome =
      GeneratedColumn<int>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<OccurrenceOutcome>($OccurrencesTable.$converteroutcome);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryColorMeta = const VerificationMeta(
    'categoryColor',
  );
  @override
  late final GeneratedColumn<int> categoryColor = GeneratedColumn<int>(
    'category_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderId,
    title,
    scheduledLocal,
    outcome,
    at,
    categoryId,
    categoryName,
    categoryColor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('category_color')) {
      context.handle(
        _categoryColorMeta,
        categoryColor.isAcceptableOrUnknown(
          data['category_color']!,
          _categoryColorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OccurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      scheduledLocal: $OccurrencesTable.$converterscheduledLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}scheduled_local'],
        )!,
      ),
      outcome: $OccurrencesTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      categoryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_color'],
      ),
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterscheduledLocal =
      const NaiveDateTimeConverter();
  static JsonTypeConverter2<OccurrenceOutcome, int, int> $converteroutcome =
      const EnumIndexConverter<OccurrenceOutcome>(OccurrenceOutcome.values);
}

class OccurrenceRow extends DataClass implements Insertable<OccurrenceRow> {
  final int id;
  final int reminderId;
  final String title;
  final DateTime scheduledLocal;
  final OccurrenceOutcome outcome;
  final DateTime at;
  final int? categoryId;
  final String? categoryName;
  final int? categoryColor;
  const OccurrenceRow({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.scheduledLocal,
    required this.outcome,
    required this.at,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reminder_id'] = Variable<int>(reminderId);
    map['title'] = Variable<String>(title);
    {
      map['scheduled_local'] = Variable<int>(
        $OccurrencesTable.$converterscheduledLocal.toSql(scheduledLocal),
      );
    }
    {
      map['outcome'] = Variable<int>(
        $OccurrencesTable.$converteroutcome.toSql(outcome),
      );
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || categoryColor != null) {
      map['category_color'] = Variable<int>(categoryColor);
    }
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      reminderId: Value(reminderId),
      title: Value(title),
      scheduledLocal: Value(scheduledLocal),
      outcome: Value(outcome),
      at: Value(at),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryColor: categoryColor == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryColor),
    );
  }

  factory OccurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceRow(
      id: serializer.fromJson<int>(json['id']),
      reminderId: serializer.fromJson<int>(json['reminderId']),
      title: serializer.fromJson<String>(json['title']),
      scheduledLocal: serializer.fromJson<DateTime>(json['scheduledLocal']),
      outcome: $OccurrencesTable.$converteroutcome.fromJson(
        serializer.fromJson<int>(json['outcome']),
      ),
      at: serializer.fromJson<DateTime>(json['at']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryColor: serializer.fromJson<int?>(json['categoryColor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderId': serializer.toJson<int>(reminderId),
      'title': serializer.toJson<String>(title),
      'scheduledLocal': serializer.toJson<DateTime>(scheduledLocal),
      'outcome': serializer.toJson<int>(
        $OccurrencesTable.$converteroutcome.toJson(outcome),
      ),
      'at': serializer.toJson<DateTime>(at),
      'categoryId': serializer.toJson<int?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryColor': serializer.toJson<int?>(categoryColor),
    };
  }

  OccurrenceRow copyWith({
    int? id,
    int? reminderId,
    String? title,
    DateTime? scheduledLocal,
    OccurrenceOutcome? outcome,
    DateTime? at,
    Value<int?> categoryId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<int?> categoryColor = const Value.absent(),
  }) => OccurrenceRow(
    id: id ?? this.id,
    reminderId: reminderId ?? this.reminderId,
    title: title ?? this.title,
    scheduledLocal: scheduledLocal ?? this.scheduledLocal,
    outcome: outcome ?? this.outcome,
    at: at ?? this.at,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    categoryColor: categoryColor.present
        ? categoryColor.value
        : this.categoryColor,
  );
  OccurrenceRow copyWithCompanion(OccurrencesCompanion data) {
    return OccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      title: data.title.present ? data.title.value : this.title,
      scheduledLocal: data.scheduledLocal.present
          ? data.scheduledLocal.value
          : this.scheduledLocal,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      at: data.at.present ? data.at.value : this.at,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryColor: data.categoryColor.present
          ? data.categoryColor.value
          : this.categoryColor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRow(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('title: $title, ')
          ..write('scheduledLocal: $scheduledLocal, ')
          ..write('outcome: $outcome, ')
          ..write('at: $at, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryColor: $categoryColor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reminderId,
    title,
    scheduledLocal,
    outcome,
    at,
    categoryId,
    categoryName,
    categoryColor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceRow &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.title == this.title &&
          other.scheduledLocal == this.scheduledLocal &&
          other.outcome == this.outcome &&
          other.at == this.at &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.categoryColor == this.categoryColor);
}

class OccurrencesCompanion extends UpdateCompanion<OccurrenceRow> {
  final Value<int> id;
  final Value<int> reminderId;
  final Value<String> title;
  final Value<DateTime> scheduledLocal;
  final Value<OccurrenceOutcome> outcome;
  final Value<DateTime> at;
  final Value<int?> categoryId;
  final Value<String?> categoryName;
  final Value<int?> categoryColor;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.title = const Value.absent(),
    this.scheduledLocal = const Value.absent(),
    this.outcome = const Value.absent(),
    this.at = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryColor = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    this.id = const Value.absent(),
    required int reminderId,
    required String title,
    required DateTime scheduledLocal,
    required OccurrenceOutcome outcome,
    required DateTime at,
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryColor = const Value.absent(),
  }) : reminderId = Value(reminderId),
       title = Value(title),
       scheduledLocal = Value(scheduledLocal),
       outcome = Value(outcome),
       at = Value(at);
  static Insertable<OccurrenceRow> custom({
    Expression<int>? id,
    Expression<int>? reminderId,
    Expression<String>? title,
    Expression<int>? scheduledLocal,
    Expression<int>? outcome,
    Expression<DateTime>? at,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? categoryColor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (title != null) 'title': title,
      if (scheduledLocal != null) 'scheduled_local': scheduledLocal,
      if (outcome != null) 'outcome': outcome,
      if (at != null) 'at': at,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryColor != null) 'category_color': categoryColor,
    });
  }

  OccurrencesCompanion copyWith({
    Value<int>? id,
    Value<int>? reminderId,
    Value<String>? title,
    Value<DateTime>? scheduledLocal,
    Value<OccurrenceOutcome>? outcome,
    Value<DateTime>? at,
    Value<int?>? categoryId,
    Value<String?>? categoryName,
    Value<int?>? categoryColor,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      scheduledLocal: scheduledLocal ?? this.scheduledLocal,
      outcome: outcome ?? this.outcome,
      at: at ?? this.at,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (scheduledLocal.present) {
      map['scheduled_local'] = Variable<int>(
        $OccurrencesTable.$converterscheduledLocal.toSql(scheduledLocal.value),
      );
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(
        $OccurrencesTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryColor.present) {
      map['category_color'] = Variable<int>(categoryColor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('title: $title, ')
          ..write('scheduledLocal: $scheduledLocal, ')
          ..write('outcome: $outcome, ')
          ..write('at: $at, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryColor: $categoryColor')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    reminders,
    occurrences,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required int colorValue,
      required String iconKey,
      required int sortOrder,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> colorValue,
      Value<String> iconKey,
      Value<int> sortOrder,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                iconKey: iconKey,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int colorValue,
                required String iconKey,
                required int sortOrder,
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                iconKey: iconKey,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> note,
      required DateTime startLocal,
      Value<RecurrenceRule?> recurrence,
      Value<int?> categoryId,
      required DeliveryMode delivery,
      required ReminderStatus status,
      Value<DateTime?> resolvedThroughLocal,
      Value<DateTime?> snoozedUntil,
      Value<int> revision,
      required DateTime createdAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> note,
      Value<DateTime> startLocal,
      Value<RecurrenceRule?> recurrence,
      Value<int?> categoryId,
      Value<DeliveryMode> delivery,
      Value<ReminderStatus> status,
      Value<DateTime?> resolvedThroughLocal,
      Value<DateTime?> snoozedUntil,
      Value<int> revision,
      Value<DateTime> createdAt,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startLocal =>
      $composableBuilder(
        column: $table.startLocal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<RecurrenceRule?, RecurrenceRule, String>
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeliveryMode, DeliveryMode, int>
  get delivery => $composableBuilder(
    column: $table.delivery,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderStatus, ReminderStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int>
  get resolvedThroughLocal => $composableBuilder(
    column: $table.resolvedThroughLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLocal => $composableBuilder(
    column: $table.startLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get delivery => $composableBuilder(
    column: $table.delivery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedThroughLocal => $composableBuilder(
    column: $table.resolvedThroughLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startLocal =>
      $composableBuilder(
        column: $table.startLocal,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<RecurrenceRule?, String> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => column,
      );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DeliveryMode, int> get delivery =>
      $composableBuilder(column: $table.delivery, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get resolvedThroughLocal =>
      $composableBuilder(
        column: $table.resolvedThroughLocal,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            ReminderRow,
            BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
          ),
          ReminderRow,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> startLocal = const Value.absent(),
                Value<RecurrenceRule?> recurrence = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<DeliveryMode> delivery = const Value.absent(),
                Value<ReminderStatus> status = const Value.absent(),
                Value<DateTime?> resolvedThroughLocal = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                note: note,
                startLocal: startLocal,
                recurrence: recurrence,
                categoryId: categoryId,
                delivery: delivery,
                status: status,
                resolvedThroughLocal: resolvedThroughLocal,
                snoozedUntil: snoozedUntil,
                revision: revision,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required DateTime startLocal,
                Value<RecurrenceRule?> recurrence = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required DeliveryMode delivery,
                required ReminderStatus status,
                Value<DateTime?> resolvedThroughLocal = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                note: note,
                startLocal: startLocal,
                recurrence: recurrence,
                categoryId: categoryId,
                delivery: delivery,
                status: status,
                resolvedThroughLocal: resolvedThroughLocal,
                snoozedUntil: snoozedUntil,
                revision: revision,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, ReminderRow>(table),
                  BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (
        ReminderRow,
        BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
      ),
      ReminderRow,
      PrefetchHooks Function()
    >;
typedef $$OccurrencesTableCreateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<int> id,
      required int reminderId,
      required String title,
      required DateTime scheduledLocal,
      required OccurrenceOutcome outcome,
      required DateTime at,
      Value<int?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryColor,
    });
typedef $$OccurrencesTableUpdateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<int> id,
      Value<int> reminderId,
      Value<String> title,
      Value<DateTime> scheduledLocal,
      Value<OccurrenceOutcome> outcome,
      Value<DateTime> at,
      Value<int?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryColor,
    });

class $$OccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get scheduledLocal =>
      $composableBuilder(
        column: $table.scheduledLocal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<OccurrenceOutcome, OccurrenceOutcome, int>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledLocal => $composableBuilder(
    column: $table.scheduledLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get scheduledLocal =>
      $composableBuilder(
        column: $table.scheduledLocal,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<OccurrenceOutcome, int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => column,
  );
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          OccurrenceRow,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (
            OccurrenceRow,
            BaseReferences<_$AppDatabase, $OccurrencesTable, OccurrenceRow>,
          ),
          OccurrenceRow,
          PrefetchHooks Function()
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reminderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> scheduledLocal = const Value.absent(),
                Value<OccurrenceOutcome> outcome = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryColor = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                reminderId: reminderId,
                title: title,
                scheduledLocal: scheduledLocal,
                outcome: outcome,
                at: at,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryColor: categoryColor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reminderId,
                required String title,
                required DateTime scheduledLocal,
                required OccurrenceOutcome outcome,
                required DateTime at,
                Value<int?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryColor = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                reminderId: reminderId,
                title: title,
                scheduledLocal: scheduledLocal,
                outcome: outcome,
                at: at,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryColor: categoryColor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrencesTable, OccurrenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OccurrencesTable,
                    OccurrenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      OccurrenceRow,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (
        OccurrenceRow,
        BaseReferences<_$AppDatabase, $OccurrencesTable, OccurrenceRow>,
      ),
      OccurrenceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$OccurrencesTableTableManager get occurrences =>
      $$OccurrencesTableTableManager(_db, _db.occurrences);
}
