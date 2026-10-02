class JobCustomer {
  const JobCustomer({
    required this.id,
    required this.name,
    this.company = '',
    this.phone = '',
    this.notes = '',
  });

  factory JobCustomer.fromJson(Map<String, dynamic> json) => JobCustomer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        company: json['company'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  final String id;
  final String name;
  final String company;
  final String phone;
  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
        'notes': notes,
      };
}
