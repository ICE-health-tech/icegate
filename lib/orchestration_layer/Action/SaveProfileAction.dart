import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/EmailAddressProtocol.dart';
// import 'package:ice_gate/data_layer/Protocol/User/PersonProtocols.dart';
import 'package:ice_gate/data_layer/Protocol/User/ProfileProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> saveProfileAction(
  String name,
  String email,
  String phone,
  String address,
  String city,
  String country,
  String postalCode,
  String bio,
  String occupation,
  String company,
  String gender,
  String website,
  String username,
  DateTime? birthday,

  PersonManagementDAO dao,
) async {
  // Create person protocol
  PersonProtocol insertedPerson = PersonProtocol.create(
    firstName: name,
    lastName: '',
    phoneNumber: phone,
    dateOfBirth: birthday,
    gender: gender,
    isActive: true,
  );

  // Create user account protocol
  UserAccountProtocol insertedAccount = UserAccountProtocol.create(
    personID: Supabase.instance.client.auth.currentUser?.id ?? "",
    username: username,
    primaryEmail: email,
    role: 'user',
    isLocked: false,
    lastLoginAt: null,
  );

  // Create email address protocol
  EmailAddressProtocol insertedEmail = EmailAddressProtocol.create(
    personID: Supabase.instance.client.auth.currentUser?.id ?? "",
    emailAddress: email,
  );

  // Create CV address protocol
  CVAddressProtocol insertedCVAddress = CVAddressProtocol.create(
    personID: Supabase.instance.client.auth.currentUser?.id ?? "",
    githubUrl: '',
    websiteUrl: website,
    company: company,
    university: '',
    location: '$address, $city, $country $postalCode',
    bio: bio,
    occupation: occupation,
    educationLevel: '',
    linkedinUrl: '',
  );

  // Create profile protocol
  ProfileProtocol insertedProfile = ProfileProtocol.create(
    personID: Supabase.instance.client.auth.currentUser?.id ?? "",
    bio: bio,
    occupation: occupation,
    websiteUrl: website,
    location: '$address, $city, $country $postalCode',
  );

  // Save to database
  dao.createFullProfile(
    person: insertedPerson,
    email: insertedEmail,
    account: insertedAccount,
    profile: insertedProfile,
    cvAddress: insertedCVAddress,
  );
  return Supabase.instance.client.auth.currentUser?.id ?? "";
}
