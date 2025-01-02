import 'package:flutter_svg/flutter_svg.dart';

class Subject {
  final String name;
  final int id;

  Subject(this.name, this.id);
}

class SubjectIconProvider {
  static const Map<int, String> subjectIcons = {
    1: 'assets/subject/math.svg', // ID 1 for Toán
    2: 'assets/subject/it.svg', // ID 2 for Tin
    3: 'assets/subject/chemistry.svg', // ID 3 for Hóa
    4: 'assets/subject/biology.svg', // ID 4 for Sinh
    5: 'assets/subject/physics.svg', // ID 5 for Vật lí
    6: 'assets/subject/languages.svg',
    7: 'assets/subject/history.svg',
    8: 'assets/subject/geography.svg',
    9: 'assets/subject/tech.svg',
    10: 'assets/subject/economicandlaw.svg'
  };

  static SvgPicture getSubjectIcon(int subjectId) {
    print(subjectId);
    String? iconPath = subjectIcons[subjectId];
    print(iconPath);

    if (iconPath != null) {
      return SvgPicture.asset(iconPath, height: 200);
    } else {
      return SvgPicture.asset(
        'assets/subject/default.svg',
        height: 200,
      );
    }
  }
}
