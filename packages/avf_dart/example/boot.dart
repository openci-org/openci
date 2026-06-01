import 'package:avf_dart/avf_dart.dart';

void main() async {
  const name = 'tahoe-base';
  try {
    // 起動成功するまで非同期待機（起動完了した時点でここに進む ＝ true）
    final vm = await VirtualMachine.boot(name: name);
    print('起動成功！ IP: ${vm.ipAddress}');

    // VM のプロセス制御（停止や終了コードの待機など）
    final code = await vm.exitCode;
    print('VM exited with code: $code');
  } catch (e) {
    // 起動失敗した場合は即座にここに来る（＝ false）
    print('起動失敗: $e');
  }
}
