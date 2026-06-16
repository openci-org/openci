import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/storage.dart';
import 'package:test/test.dart';

import 'storage_unit_test.mocks.dart';

@GenerateMocks([Minio, MinioByteStream])
void main() {
  group('StorageManager Unit Tests with Mock', () {
    late MockMinio mockMinio;
    late StorageManager storage;
    const settings = StorageSettings(
      endPoint: 'localhost',
      port: 8000,
      useSSL: false,
      accessKey: 'access',
      secretKey: 'secret',
      bucket: 'test-bucket',
    );

    setUp(() {
      mockMinio = MockMinio();
      storage = StorageManager(settings, client: mockMinio);
    });

    test('initialize creates bucket if it does not exist', () async {
      when(
        mockMinio.bucketExists('test-bucket'),
      ).thenAnswer((_) async => false);
      when(mockMinio.makeBucket('test-bucket')).thenAnswer((_) async {});

      await storage.initialize();

      verify(mockMinio.bucketExists('test-bucket')).called(1);
      verify(mockMinio.makeBucket('test-bucket')).called(1);
    });

    test('initialize does not create bucket if it already exists', () async {
      when(mockMinio.bucketExists('test-bucket')).thenAnswer((_) async => true);

      await storage.initialize();

      verify(mockMinio.bucketExists('test-bucket')).called(1);
      verifyNever(mockMinio.makeBucket('test-bucket'));
    });

    test('uploadObject calls putObject with correct parameters', () async {
      final stream = Stream.value(Uint8List.fromList([1, 2, 3]));
      when(
        mockMinio.putObject(
          'test-bucket',
          'test.txt',
          stream,
          size: 3,
          metadata: anyNamed('metadata'),
        ),
      ).thenAnswer((_) async => 'etag');

      await storage.uploadObject('test.txt', stream, size: 3);

      verify(
        mockMinio.putObject('test-bucket', 'test.txt', stream, size: 3),
      ).called(1);
    });

    test('downloadObject calls getObject and returns stream', () async {
      final mockMinioByteStream = MockMinioByteStream();
      when(
        mockMinio.getObject('test-bucket', 'test.txt'),
      ).thenAnswer((_) async => mockMinioByteStream);

      final result = await storage.downloadObject('test.txt');

      expect(result, equals(mockMinioByteStream));
      verify(mockMinio.getObject('test-bucket', 'test.txt')).called(1);
    });

    test('getPresignedUrl returns generated url', () async {
      when(
        mockMinio.presignedGetObject(
          'test-bucket',
          'test.txt',
          expires: anyNamed('expires'),
        ),
      ).thenAnswer((_) async => 'https://signed-url.com');

      final url = await storage.getPresignedUrl('test.txt');

      expect(url, equals('https://signed-url.com'));
      verify(
        mockMinio.presignedGetObject('test-bucket', 'test.txt', expires: 3600),
      ).called(1);
    });

    test('verifyConnection returns true on success', () async {
      when(mockMinio.bucketExists('test-bucket')).thenAnswer((_) async => true);

      final result = await storage.verifyConnection();

      expect(result, isTrue);
      verify(mockMinio.bucketExists('test-bucket')).called(1);
    });

    test('verifyConnection returns false on failure', () async {
      when(
        mockMinio.bucketExists('test-bucket'),
      ).thenThrow(Exception('failed'));

      final result = await storage.verifyConnection();

      expect(result, isFalse);
      verify(mockMinio.bucketExists('test-bucket')).called(1);
    });
  });
}
