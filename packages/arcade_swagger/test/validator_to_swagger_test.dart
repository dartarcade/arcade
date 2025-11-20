import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:arcade_swagger/src/utils/validator_to_swagger.dart';
import 'package:luthor/luthor.dart';
import 'package:test/test.dart';

// Self-referential schema definitions must be at top level
// Direct self-reference: tree node with children
Validator treeNode = l
    .schema({
      'id': l.int().required(),
      'value': l.string().required(),
      'children': l.list(validators: [forwardRef(() => treeNode)]),
    })
    .withName('TreeNode');

// Indirect self-reference: person and company reference each other
Validator person = l
    .schema({
      'id': l.int().required(),
      'name': l.string().required(),
      'friends': l.list(validators: [forwardRef(() => person)]),
      'company': forwardRef(() => company),
    })
    .withName('Person');

Validator company = l
    .schema({
      'id': l.int().required(),
      'name': l.string().required(),
      'employees': l.list(validators: [forwardRef(() => person)]),
    })
    .withName('Company');

// Optional self-reference
Validator optionalSelfRef = l
    .schema({
      'id': l.int().required(),
      'parent': forwardRef(() => optionalSelfRef),
    })
    .withName('OptionalSelfRef');

void main() {
  group('validatorToSwagger', () {
    group('basic types', () {
      test('converts string validator to Schema.string', () {
        final validator = l.string();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.string));
      });

      test('converts int validator to Schema.integer', () {
        final validator = l.int();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.integer));
      });

      test('converts double validator to Schema.number', () {
        final validator = l.double();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.number));
      });

      test('converts number validator to Schema.number', () {
        final validator = l.number();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.number));
      });

      test('converts bool validator to Schema.boolean', () {
        final validator = l.boolean();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.boolean));
      });

      test('converts any validator to Schema.string with example', () {
        final validator = l.any();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.string));
      });

      test('converts null validator to Schema.string with null example', () {
        final validator = l.nullValue();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.string));
      });

      test('converts map validator to Schema.map', () {
        final validator = l.map();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.map));
      });
    });

    group('list validators', () {
      test('converts empty list validator to array with any items', () {
        final validator = l.list();
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.array));
      });

      test('converts list of strings to array with string items', () {
        final validator = l.list(validators: [l.string()]);
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.array));
        expect(schema, isA<SchemaArray>());
        final arraySchema = schema as SchemaArray;
        expect(arraySchema.items.type, equals(SchemaType.string));
      });

      test('converts list of integers to array with integer items', () {
        final validator = l.list(validators: [l.int()]);
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.array));
        expect(schema, isA<SchemaArray>());
        final arraySchema = schema as SchemaArray;
        expect(arraySchema.items.type, equals(SchemaType.integer));
      });

      test('converts list of objects to array with object items', () {
        final validator = l.list(
          validators: [
            l.schema({'id': l.int(), 'name': l.string()}),
          ],
        );
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.array));
        expect(schema, isA<SchemaArray>());
        final arraySchema = schema as SchemaArray;
        expect(arraySchema.items.type, equals(SchemaType.object));
      });
    });

    group('schema validators', () {
      test('converts simple schema to object with properties', () {
        final validator = l.schema({'name': l.string(), 'age': l.int()});
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.object));
        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties, isNotNull);
        expect(objectSchema.properties!.keys, containsAll(['name', 'age']));
        expect(
          objectSchema.properties!['name']!.type,
          equals(SchemaType.string),
        );
        expect(
          objectSchema.properties!['age']!.type,
          equals(SchemaType.integer),
        );
      });

      test('converts nested schema correctly', () {
        final validator = l.schema({
          'user': l.schema({'name': l.string(), 'email': l.string()}),
          'posts': l.list(
            validators: [
              l.schema({'title': l.string(), 'content': l.string()}),
            ],
          ),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.object));
        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties, isNotNull);
        expect(objectSchema.properties!.keys, containsAll(['user', 'posts']));
        expect(
          objectSchema.properties!['user']!.type,
          equals(SchemaType.object),
        );
        expect(
          objectSchema.properties!['posts']!.type,
          equals(SchemaType.array),
        );
      });

      test('handles deeply nested schemas', () {
        final validator = l.schema({
          'level1': l.schema({
            'level2': l.schema({'level3': l.string()}),
          }),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<Schema>());
        expect(schema.type, equals(SchemaType.object));
        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(
          objectSchema.properties!['level1']!.type,
          equals(SchemaType.object),
        );
        final level1 = objectSchema.properties!['level1']! as SchemaObject;
        expect(level1.properties!['level2']!.type, equals(SchemaType.object));
        final level2 = level1.properties!['level2']! as SchemaObject;
        expect(level2.properties!['level3']!.type, equals(SchemaType.string));
      });
    });

    group('required fields', () {
      test('marks required string field correctly', () {
        final validator = l.schema({
          'name': l.string().required(),
          'optional': l.string(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, isNotNull);
        expect(objectSchema.required, contains('name'));
        expect(objectSchema.required, isNot(contains('optional')));
      });

      test('marks multiple required fields correctly', () {
        final validator = l.schema({
          'name': l.string().required(),
          'email': l.string().required(),
          'age': l.int().required(),
          'bio': l.string(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, isNotNull);
        expect(objectSchema.required, containsAll(['name', 'email', 'age']));
        expect(objectSchema.required, isNot(contains('bio')));
      });

      test('handles required nested objects', () {
        final validator = l.schema({
          'user': l.schema({
            'name': l.string().required(),
            'email': l.string(),
          }).required(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('user'));

        final userSchema = objectSchema.properties!['user']! as SchemaObject;
        expect(userSchema.required, contains('name'));
        expect(userSchema.required, isNot(contains('email')));
      });

      test('handles required arrays', () {
        final validator = l.schema({
          'tags': l.list(validators: [l.string()]).required(),
          'optionalList': l.list(validators: [l.int()]),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('tags'));
        expect(objectSchema.required, isNot(contains('optionalList')));
      });

      test('marks required int field correctly', () {
        final validator = l.schema({
          'id': l.int().required(),
          'optionalId': l.int(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, isNotNull);
        expect(objectSchema.required, contains('id'));
        expect(objectSchema.required, isNot(contains('optionalId')));
      });

      test('marks required double field correctly', () {
        final validator = l.schema({
          'price': l.double().required(),
          'discount': l.double(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('price'));
        expect(objectSchema.required, isNot(contains('discount')));
      });

      test('marks required number field correctly', () {
        final validator = l.schema({
          'value': l.number().required(),
          'optionalValue': l.number(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('value'));
        expect(objectSchema.required, isNot(contains('optionalValue')));
      });

      test('marks required boolean field correctly', () {
        final validator = l.schema({
          'isActive': l.boolean().required(),
          'isVerified': l.boolean(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('isActive'));
        expect(objectSchema.required, isNot(contains('isVerified')));
      });

      test('marks required map field correctly', () {
        final validator = l.schema({
          'metadata': l.map().required(),
          'optionalMetadata': l.map(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('metadata'));
        expect(objectSchema.required, isNot(contains('optionalMetadata')));
      });

      test('marks required any field correctly', () {
        final validator = l.schema({
          'data': l.any().required(),
          'optionalData': l.any(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('data'));
        expect(objectSchema.required, isNot(contains('optionalData')));
      });

      test('handles deeply nested required fields', () {
        final validator = l.schema({
          'level1': l.schema({
            'level2': l.schema({
              'level3': l.string().required(),
              'optional': l.string(),
            }).required(),
            'sibling': l.int(),
          }).required(),
          'topLevel': l.string(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('level1'));
        expect(objectSchema.required, isNot(contains('topLevel')));

        final level1Schema =
            objectSchema.properties!['level1']! as SchemaObject;
        expect(level1Schema.required, contains('level2'));
        expect(level1Schema.required, isNot(contains('sibling')));

        final level2Schema =
            level1Schema.properties!['level2']! as SchemaObject;
        expect(level2Schema.required, contains('level3'));
        expect(level2Schema.required, isNot(contains('optional')));
      });

      test('handles required fields in array items', () {
        final validator = l.schema({
          'items': l
              .list(
                validators: [
                  l.schema({
                    'id': l.int().required(),
                    'name': l.string().required(),
                    'description': l.string(),
                  }),
                ],
              )
              .required(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('items'));

        final itemsSchema = objectSchema.properties!['items']! as SchemaArray;
        final itemSchema = itemsSchema.items as SchemaObject;
        expect(itemSchema.required, containsAll(['id', 'name']));
        expect(itemSchema.required, isNot(contains('description')));
      });

      test('handles all fields as required', () {
        final validator = l.schema({
          'stringField': l.string().required(),
          'intField': l.int().required(),
          'doubleField': l.double().required(),
          'boolField': l.boolean().required(),
          'listField': l.list(validators: [l.string()]).required(),
          'mapField': l.map().required(),
          'objectField': l.schema({'nested': l.string().required()}).required(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, hasLength(7));
        expect(
          objectSchema.required,
          containsAll([
            'stringField',
            'intField',
            'doubleField',
            'boolField',
            'listField',
            'mapField',
            'objectField',
          ]),
        );
      });

      test('marks required field with named schema ref correctly', () {
        final address = l
            .schema({
              'street': l.string().required(),
              'city': l.string().required(),
              'zipCode': l.string(),
            })
            .withName('Address');

        final validator = l.schema({
          'name': l.string().required(),
          'address': address.required(),
          'alternateAddress': address,
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, contains('name'));
        expect(objectSchema.required, contains('address'));
        expect(objectSchema.required, isNot(contains('alternateAddress')));

        final addressProperty = objectSchema.properties!['address']!;
        expect(addressProperty, isA<SchemaObject>());
        final addressSchema = addressProperty as SchemaObject;
        expect(addressSchema.ref, equals('Address'));
      });

      test('marks required field with nested named schema refs', () {
        final coordinates = l
            .schema({
              'lat': l.double().required(),
              'lng': l.double().required(),
            })
            .withName('Coordinates');

        final location = l
            .schema({
              'name': l.string().required(),
              'coords': coordinates.required(),
            })
            .withName('Location');

        final validator = l.schema({
          'id': l.int().required(),
          'primaryLocation': location.required(),
          'secondaryLocation': location,
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, containsAll(['id', 'primaryLocation']));
        expect(objectSchema.required, isNot(contains('secondaryLocation')));

        final primaryLoc = objectSchema.properties!['primaryLocation']!;
        expect(primaryLoc, isA<SchemaObject>());
        expect((primaryLoc as SchemaObject).ref, equals('Location'));
      });

      test('marks required named schemas in list items', () {
        final tag = l
            .schema({'id': l.int().required(), 'name': l.string().required()})
            .withName('Tag');

        final validator = l.schema({
          'title': l.string().required(),
          'tags': l.list(validators: [tag]).required(),
          'optionalTags': l.list(validators: [tag]),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, containsAll(['title', 'tags']));
        expect(objectSchema.required, isNot(contains('optionalTags')));

        final tagsProperty = objectSchema.properties!['tags']!;
        expect(tagsProperty, isA<SchemaArray>());
        final tagsArray = tagsProperty as SchemaArray;
        expect(tagsArray.items, isA<SchemaObject>());
        expect((tagsArray.items as SchemaObject).ref, equals('Tag'));
      });

      test('handles mix of required refs and regular fields', () {
        final address = l
            .schema({
              'street': l.string().required(),
              'city': l.string().required(),
            })
            .withName('Address');

        final validator = l.schema({
          'id': l.int().required(),
          'name': l.string().required(),
          'email': l.string(),
          'address': address.required(),
          'billingAddress': address,
          'age': l.int(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, containsAll(['id', 'name', 'address']));
        expect(
          objectSchema.required,
          isNot(containsAll(['email', 'billingAddress', 'age'])),
        );
      });
    });

    group('complex scenarios', () {
      test('converts schema with mixed types', () {
        final validator = l.schema({
          'id': l.int().required(),
          'name': l.string().required(),
          'email': l.string(),
          'age': l.int(),
          'score': l.double(),
          'active': l.boolean().required(),
          'tags': l.list(validators: [l.string()]),
          'metadata': l.map(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties!.keys.length, equals(8));
        expect(objectSchema.required, containsAll(['id', 'name', 'active']));
        expect(
          objectSchema.properties!['id']!.type,
          equals(SchemaType.integer),
        );
        expect(
          objectSchema.properties!['name']!.type,
          equals(SchemaType.string),
        );
        expect(
          objectSchema.properties!['score']!.type,
          equals(SchemaType.number),
        );
        expect(
          objectSchema.properties!['active']!.type,
          equals(SchemaType.boolean),
        );
        expect(
          objectSchema.properties!['tags']!.type,
          equals(SchemaType.array),
        );
        expect(
          objectSchema.properties!['metadata']!.type,
          equals(SchemaType.map),
        );
      });

      test('converts realistic user profile schema', () {
        final validator = l.schema({
          'id': l.int().required(),
          'username': l.string().required(),
          'email': l.string().required(),
          'profile': l.schema({
            'firstName': l.string().required(),
            'lastName': l.string().required(),
            'age': l.int(),
            'bio': l.string(),
          }).required(),
          'posts': l.list(
            validators: [
              l.schema({
                'id': l.int().required(),
                'title': l.string().required(),
                'content': l.string().required(),
                'published': l.boolean().required(),
                'tags': l.list(validators: [l.string()]),
              }),
            ],
          ),
          'settings': l.map(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(
          objectSchema.required,
          containsAll(['id', 'username', 'email', 'profile']),
        );

        final profileSchema =
            objectSchema.properties!['profile']! as SchemaObject;
        expect(profileSchema.required, containsAll(['firstName', 'lastName']));
        expect(profileSchema.required, isNot(contains('age')));

        final postsSchema = objectSchema.properties!['posts']! as SchemaArray;
        final postItemSchema = postsSchema.items as SchemaObject;
        expect(
          postItemSchema.required,
          containsAll(['id', 'title', 'content', 'published']),
        );
      });
    });

    group('error cases', () {
      test('throws StateError when validator has no validations', () {
        final validator = Validator(initialValidations: []);

        expect(() => validatorToSwagger(validator), throwsStateError);
      });

      test(
        'throws StateError when first validation is not a type validation',
        () {
          final validator = l.required();

          expect(() => validatorToSwagger(validator), throwsStateError);
        },
      );
    });

    group('edge cases', () {
      test('handles empty schema', () {
        final validator = l.schema({});
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties, isEmpty);
      });

      test('handles schema with only optional fields', () {
        final validator = l.schema({
          'field1': l.string(),
          'field2': l.int(),
          'field3': l.boolean(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.required, isEmpty);
      });

      test('handles schema with only required fields', () {
        final validator = l.schema({
          'field1': l.string().required(),
          'field2': l.int().required(),
          'field3': l.boolean().required(),
        });
        final schema = validatorToSwagger(validator);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(
          objectSchema.required,
          containsAll(['field1', 'field2', 'field3']),
        );
      });
    });

    group('self-referential schemas', () {
      test('handles direct self-reference with \$ref', () {
        final schema = validatorToSwagger(treeNode);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties, isNotNull);
        expect(
          objectSchema.properties!.keys,
          containsAll(['id', 'value', 'children']),
        );
        expect(objectSchema.required, containsAll(['id', 'value']));

        final childrenProperty = objectSchema.properties!['children']!;
        expect(childrenProperty, isA<SchemaArray>());
        final arraySchema = childrenProperty as SchemaArray;
        expect(arraySchema.items, isA<SchemaObject>());
        final itemsSchema = arraySchema.items as SchemaObject;
        expect(itemsSchema.ref, isNotNull);
        expect(itemsSchema.ref, equals('TreeNode'));
      });

      test('handles indirect self-reference (mutual recursion)', () {
        final personSchema = validatorToSwagger(person);

        expect(personSchema, isA<SchemaObject>());
        final personObject = personSchema as SchemaObject;
        expect(personObject.properties, isNotNull);
        expect(
          personObject.properties!.keys,
          containsAll(['id', 'name', 'friends', 'company']),
        );

        final friendsProperty = personObject.properties!['friends']!;
        expect(friendsProperty, isA<SchemaArray>());
        final friendsArray = friendsProperty as SchemaArray;
        expect(friendsArray.items, isA<SchemaObject>());
        final friendsItems = friendsArray.items as SchemaObject;
        expect(friendsItems.ref, equals('Person'));

        final companyProperty = personObject.properties!['company']!;
        expect(companyProperty, isA<SchemaObject>());
        final companyObject = companyProperty as SchemaObject;
        expect(companyObject.ref, equals('Company'));
      });

      test('company schema references person correctly', () {
        final companySchema = validatorToSwagger(company);

        expect(companySchema, isA<SchemaObject>());
        final companyObject = companySchema as SchemaObject;
        expect(companyObject.properties, isNotNull);
        expect(
          companyObject.properties!.keys,
          containsAll(['id', 'name', 'employees']),
        );

        final employeesProperty = companyObject.properties!['employees']!;
        expect(employeesProperty, isA<SchemaArray>());
        final employeesArray = employeesProperty as SchemaArray;
        expect(employeesArray.items, isA<SchemaObject>());
        final employeesItems = employeesArray.items as SchemaObject;
        expect(employeesItems.ref, equals('Person'));
      });

      test('reuses same ref for identical validator instances', () {
        final schema1 = validatorToSwagger(treeNode);
        final schema2 = validatorToSwagger(treeNode);

        expect(schema1, isA<SchemaObject>());
        expect(schema2, isA<SchemaObject>());

        final obj1 = schema1 as SchemaObject;
        final obj2 = schema2 as SchemaObject;

        final children1 = obj1.properties!['children']! as SchemaArray;
        final children2 = obj2.properties!['children']! as SchemaArray;

        final items1 = children1.items as SchemaObject;
        final items2 = children2.items as SchemaObject;

        expect(items1.ref, equals(items2.ref));
        expect(items1.ref, equals('TreeNode'));
      });

      test('handles optional self-references', () {
        final schema = validatorToSwagger(optionalSelfRef);

        expect(schema, isA<SchemaObject>());
        final objectSchema = schema as SchemaObject;
        expect(objectSchema.properties!['parent'], isA<SchemaObject>());
        final parentSchema =
            objectSchema.properties!['parent']! as SchemaObject;
        expect(parentSchema.ref, equals('OptionalSelfRef'));
        expect(objectSchema.required, isNot(contains('parent')));
      });
    });
  });
}
