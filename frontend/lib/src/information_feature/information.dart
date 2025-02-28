class Information {
  Information({
    required this.id,
    required this.userName,
    required this.password,
    required this.website,
  });

  final int id;
  String userName;
  String password;
  String website;

  factory Information.fromJson(Map<String, dynamic> json) {
    return Information(
      id: json['id'],
      userName: json['userName'],
      password: json['password'],
      website: json['website'],
    );
  }
}
