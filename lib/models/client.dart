class Client {
  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String city;
  final String phone;
  final String email;
  final DateTime registeredAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.city,
    required this.phone,
    required this.email,
    required this.registeredAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName $middleName';

  Client copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    String? city,
    String? phone,
    String? email,
    DateTime? registeredAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      registeredAt: registeredAt ?? this.registeredAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
