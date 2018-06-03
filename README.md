# Speech Recognition Flutter in 2018

This project intends to instruct Flutter developers to use Speech Recognition.

This project gives credit to [rxlabz/sytody](https://github.com/rxlabz/sytody)

[X] Android Setup

1. The first thing you should do is add permission in AndroidManifest.xml in [android/app/src/main](./android/app/src/main/AndroidManifest.xml)

2. Next thing to do is to add Platform Channel in dart. Refer to [recognizer.dart](./lib/recognizer.dart).

3. Add Platform Channel solution to MainActivity.java in [android/app/src/main/java/com/example/speechrecognition/MainActivity.java](android/app/src/main/java/com/example/speechrecognition/MainActivity.java).

4. The folder under /main/java may be different, it depends on your java configuration.

5. The only essential difference in MainActivity.java is **requestRecordAudioPermission** function, since android sdk increase the permission security level in sdk 27.

6. Add custom layout and styling to your flutter frontend.

[ ] IOS Setup

1. Not implemented yet.
