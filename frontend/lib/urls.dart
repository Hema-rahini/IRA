
class api {
  // Default local backend endpoint.
  // - Real Android phone (connected via USB): Works seamlessly with `adb reverse tcp:8080 tcp:8080`
  // - Web / Windows Desktop: Works directly with 127.0.0.1:8080
  // - If using Android Studio Emulator without adb reverse: change to "http://10.0.2.2:8080"
  static String get ip => "http://127.0.0.1:8080";

  static String get login => "$ip/login";
  static String get signup => "$ip/signup";
  static String get getall => "$ip/get_all_names";
  static String get update_details => '$ip/update_details';
  static String get get_doctor_details => '$ip/get_doctor_details';
  static String get update_doctor_profile => '$ip/update_doctor_profile';
}


