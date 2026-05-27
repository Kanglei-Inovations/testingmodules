// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_session_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPeerSessionCollectionCollection on Isar {
  IsarCollection<PeerSessionCollection> get peerSessionCollections =>
      this.collection();
}

const PeerSessionCollectionSchema = CollectionSchema(
  name: r'PeerSessionCollection',
  id: -6739183197757395804,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 1,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastConnectedAt': PropertySchema(
      id: 2,
      name: r'lastConnectedAt',
      type: IsarType.dateTime,
    ),
    r'lastKnownSignal': PropertySchema(
      id: 3,
      name: r'lastKnownSignal',
      type: IsarType.double,
    ),
    r'lastSdp': PropertySchema(
      id: 4,
      name: r'lastSdp',
      type: IsarType.string,
    ),
    r'lastSeen': PropertySchema(
      id: 5,
      name: r'lastSeen',
      type: IsarType.dateTime,
    ),
    r'latitude': PropertySchema(
      id: 6,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 7,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'originPeerId': PropertySchema(
      id: 8,
      name: r'originPeerId',
      type: IsarType.string,
    ),
    r'peerId': PropertySchema(
      id: 9,
      name: r'peerId',
      type: IsarType.string,
    ),
    r'peerName': PropertySchema(
      id: 10,
      name: r'peerName',
      type: IsarType.string,
    ),
    r'peerPhoto': PropertySchema(
      id: 11,
      name: r'peerPhoto',
      type: IsarType.string,
    ),
    r'reconnectEnabled': PropertySchema(
      id: 12,
      name: r'reconnectEnabled',
      type: IsarType.bool,
    ),
    r'sessionState': PropertySchema(
      id: 13,
      name: r'sessionState',
      type: IsarType.byte,
      enumMap: _PeerSessionCollectionsessionStateEnumValueMap,
    )
  },
  estimateSize: _peerSessionCollectionEstimateSize,
  serialize: _peerSessionCollectionSerialize,
  deserialize: _peerSessionCollectionDeserialize,
  deserializeProp: _peerSessionCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'peerId': IndexSchema(
      id: -9089303509033685807,
      name: r'peerId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'peerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _peerSessionCollectionGetId,
  getLinks: _peerSessionCollectionGetLinks,
  attach: _peerSessionCollectionAttach,
  version: '3.1.0+1',
);

int _peerSessionCollectionEstimateSize(
  PeerSessionCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastSdp;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.originPeerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.peerId.length * 3;
  {
    final value = object.peerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.peerPhoto;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _peerSessionCollectionSerialize(
  PeerSessionCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeBool(offsets[1], object.isSynced);
  writer.writeDateTime(offsets[2], object.lastConnectedAt);
  writer.writeDouble(offsets[3], object.lastKnownSignal);
  writer.writeString(offsets[4], object.lastSdp);
  writer.writeDateTime(offsets[5], object.lastSeen);
  writer.writeDouble(offsets[6], object.latitude);
  writer.writeDouble(offsets[7], object.longitude);
  writer.writeString(offsets[8], object.originPeerId);
  writer.writeString(offsets[9], object.peerId);
  writer.writeString(offsets[10], object.peerName);
  writer.writeString(offsets[11], object.peerPhoto);
  writer.writeBool(offsets[12], object.reconnectEnabled);
  writer.writeByte(offsets[13], object.sessionState.index);
}

PeerSessionCollection _peerSessionCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PeerSessionCollection();
  object.address = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[1]);
  object.lastConnectedAt = reader.readDateTime(offsets[2]);
  object.lastKnownSignal = reader.readDoubleOrNull(offsets[3]);
  object.lastSdp = reader.readStringOrNull(offsets[4]);
  object.lastSeen = reader.readDateTime(offsets[5]);
  object.latitude = reader.readDoubleOrNull(offsets[6]);
  object.longitude = reader.readDoubleOrNull(offsets[7]);
  object.originPeerId = reader.readStringOrNull(offsets[8]);
  object.peerId = reader.readString(offsets[9]);
  object.peerName = reader.readStringOrNull(offsets[10]);
  object.peerPhoto = reader.readStringOrNull(offsets[11]);
  object.reconnectEnabled = reader.readBool(offsets[12]);
  object.sessionState = _PeerSessionCollectionsessionStateValueEnumMap[
          reader.readByteOrNull(offsets[13])] ??
      SessionState.online;
  return object;
}

P _peerSessionCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (_PeerSessionCollectionsessionStateValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SessionState.online) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PeerSessionCollectionsessionStateEnumValueMap = {
  'online': 0,
  'lastSeen': 1,
  'reconnecting': 2,
  'offline': 3,
  'unknown': 4,
};
const _PeerSessionCollectionsessionStateValueEnumMap = {
  0: SessionState.online,
  1: SessionState.lastSeen,
  2: SessionState.reconnecting,
  3: SessionState.offline,
  4: SessionState.unknown,
};

Id _peerSessionCollectionGetId(PeerSessionCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _peerSessionCollectionGetLinks(
    PeerSessionCollection object) {
  return [];
}

void _peerSessionCollectionAttach(
    IsarCollection<dynamic> col, Id id, PeerSessionCollection object) {
  object.id = id;
}

extension PeerSessionCollectionByIndex
    on IsarCollection<PeerSessionCollection> {
  Future<PeerSessionCollection?> getByPeerId(String peerId) {
    return getByIndex(r'peerId', [peerId]);
  }

  PeerSessionCollection? getByPeerIdSync(String peerId) {
    return getByIndexSync(r'peerId', [peerId]);
  }

  Future<bool> deleteByPeerId(String peerId) {
    return deleteByIndex(r'peerId', [peerId]);
  }

  bool deleteByPeerIdSync(String peerId) {
    return deleteByIndexSync(r'peerId', [peerId]);
  }

  Future<List<PeerSessionCollection?>> getAllByPeerId(
      List<String> peerIdValues) {
    final values = peerIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'peerId', values);
  }

  List<PeerSessionCollection?> getAllByPeerIdSync(List<String> peerIdValues) {
    final values = peerIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'peerId', values);
  }

  Future<int> deleteAllByPeerId(List<String> peerIdValues) {
    final values = peerIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'peerId', values);
  }

  int deleteAllByPeerIdSync(List<String> peerIdValues) {
    final values = peerIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'peerId', values);
  }

  Future<Id> putByPeerId(PeerSessionCollection object) {
    return putByIndex(r'peerId', object);
  }

  Id putByPeerIdSync(PeerSessionCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'peerId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPeerId(List<PeerSessionCollection> objects) {
    return putAllByIndex(r'peerId', objects);
  }

  List<Id> putAllByPeerIdSync(List<PeerSessionCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'peerId', objects, saveLinks: saveLinks);
  }
}

extension PeerSessionCollectionQueryWhereSort
    on QueryBuilder<PeerSessionCollection, PeerSessionCollection, QWhere> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PeerSessionCollectionQueryWhere on QueryBuilder<PeerSessionCollection,
    PeerSessionCollection, QWhereClause> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      peerIdEqualTo(String peerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'peerId',
        value: [peerId],
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterWhereClause>
      peerIdNotEqualTo(String peerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'peerId',
              lower: [],
              upper: [peerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'peerId',
              lower: [peerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'peerId',
              lower: [peerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'peerId',
              lower: [],
              upper: [peerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PeerSessionCollectionQueryFilter on QueryBuilder<
    PeerSessionCollection, PeerSessionCollection, QFilterCondition> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastConnectedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastConnectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastConnectedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastConnectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastConnectedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastConnectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastConnectedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastConnectedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastKnownSignal',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastKnownSignal',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastKnownSignal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastKnownSignal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastKnownSignal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastKnownSignalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastKnownSignal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSdp',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSdp',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSdp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      lastSdpContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastSdp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      lastSdpMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastSdp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSdp',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSdpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastSdp',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSeenEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSeenGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSeenLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> lastSeenBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originPeerId',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originPeerId',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originPeerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      originPeerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originPeerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      originPeerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originPeerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originPeerId',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> originPeerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originPeerId',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'peerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'peerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerId',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'peerId',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'peerName',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'peerName',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'peerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'peerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'peerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'peerPhoto',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'peerPhoto',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peerPhoto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerPhotoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'peerPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
          QAfterFilterCondition>
      peerPhotoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'peerPhoto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerPhoto',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> peerPhotoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'peerPhoto',
        value: '',
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> reconnectEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reconnectEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> sessionStateEqualTo(SessionState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionState',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> sessionStateGreaterThan(
    SessionState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionState',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> sessionStateLessThan(
    SessionState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionState',
        value: value,
      ));
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection,
      QAfterFilterCondition> sessionStateBetween(
    SessionState lower,
    SessionState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionState',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PeerSessionCollectionQueryObject on QueryBuilder<
    PeerSessionCollection, PeerSessionCollection, QFilterCondition> {}

extension PeerSessionCollectionQueryLinks on QueryBuilder<PeerSessionCollection,
    PeerSessionCollection, QFilterCondition> {}

extension PeerSessionCollectionQuerySortBy
    on QueryBuilder<PeerSessionCollection, PeerSessionCollection, QSortBy> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastKnownSignal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownSignal', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastKnownSignalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownSignal', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastSdp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSdp', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastSdpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSdp', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByOriginPeerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originPeerId', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByOriginPeerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originPeerId', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerId', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerId', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPhoto', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByPeerPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPhoto', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByReconnectEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reconnectEnabled', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortByReconnectEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reconnectEnabled', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortBySessionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      sortBySessionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.desc);
    });
  }
}

extension PeerSessionCollectionQuerySortThenBy
    on QueryBuilder<PeerSessionCollection, PeerSessionCollection, QSortThenBy> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastKnownSignal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownSignal', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastKnownSignalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownSignal', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastSdp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSdp', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastSdpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSdp', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByOriginPeerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originPeerId', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByOriginPeerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originPeerId', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerId', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerId', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPhoto', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByPeerPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPhoto', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByReconnectEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reconnectEnabled', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenByReconnectEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reconnectEnabled', Sort.desc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenBySessionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.asc);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QAfterSortBy>
      thenBySessionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.desc);
    });
  }
}

extension PeerSessionCollectionQueryWhereDistinct
    on QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct> {
  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastConnectedAt');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLastKnownSignal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastKnownSignal');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLastSdp({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSdp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeen');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByOriginPeerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originPeerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByPeerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByPeerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByPeerPhoto({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerPhoto', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctByReconnectEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reconnectEnabled');
    });
  }

  QueryBuilder<PeerSessionCollection, PeerSessionCollection, QDistinct>
      distinctBySessionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionState');
    });
  }
}

extension PeerSessionCollectionQueryProperty on QueryBuilder<
    PeerSessionCollection, PeerSessionCollection, QQueryProperty> {
  QueryBuilder<PeerSessionCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PeerSessionCollection, String?, QQueryOperations>
      addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<PeerSessionCollection, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<PeerSessionCollection, DateTime, QQueryOperations>
      lastConnectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastConnectedAt');
    });
  }

  QueryBuilder<PeerSessionCollection, double?, QQueryOperations>
      lastKnownSignalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastKnownSignal');
    });
  }

  QueryBuilder<PeerSessionCollection, String?, QQueryOperations>
      lastSdpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSdp');
    });
  }

  QueryBuilder<PeerSessionCollection, DateTime, QQueryOperations>
      lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeen');
    });
  }

  QueryBuilder<PeerSessionCollection, double?, QQueryOperations>
      latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<PeerSessionCollection, double?, QQueryOperations>
      longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<PeerSessionCollection, String?, QQueryOperations>
      originPeerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originPeerId');
    });
  }

  QueryBuilder<PeerSessionCollection, String, QQueryOperations>
      peerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerId');
    });
  }

  QueryBuilder<PeerSessionCollection, String?, QQueryOperations>
      peerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerName');
    });
  }

  QueryBuilder<PeerSessionCollection, String?, QQueryOperations>
      peerPhotoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerPhoto');
    });
  }

  QueryBuilder<PeerSessionCollection, bool, QQueryOperations>
      reconnectEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reconnectEnabled');
    });
  }

  QueryBuilder<PeerSessionCollection, SessionState, QQueryOperations>
      sessionStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionState');
    });
  }
}
