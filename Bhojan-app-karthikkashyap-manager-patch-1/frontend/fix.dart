import 'dart:io';

void main() {
  final dir = Directory('lib/admin_app');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll("import 'providers/admin_auth_provider.dart';", "import '../providers/admin_auth_provider.dart';");
    content = content.replaceAll("import '../auth/providers/admin_auth_provider.dart';", "import '../../auth/providers/admin_auth_provider.dart';");
    content = content.replaceAll("import '../dashboard/screens/widgets/dashboard_shared_components.dart';", "import '../../dashboard/screens/widgets/dashboard_shared_components.dart';");
    
    content = content.replaceAll("AppTextStyles.titleMedium", "AppTextStyles.headlineSmall");
    content = content.replaceAll("AppTextStyles.titleLarge", "AppTextStyles.headlineMedium");
    
    content = content.replaceAll("BorderSide(color: AppColors.primary, width: 2) : BorderSide.none", "Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.transparent, width: 0)");
    content = content.replaceAll("BorderSide(color: AppColors.primary, width: 2) : BorderSide(color: Colors.grey.shade200)", "Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.grey.shade200)");
    content = content.replaceAll("BorderSide(color: AppColors.primary, width: 2) : BorderSide(color: Colors.grey.shade200)", "Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.grey.shade200)");

    if (content != original) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
