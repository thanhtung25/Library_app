class AuthorModel{
  final int id_author;
  final String full_name;
  final String biography;

  AuthorModel({
    required this.id_author,
    required this.full_name,
    required this.biography
  });

  factory AuthorModel.fromJson(Map<String,dynamic> json){
    return AuthorModel(
        id_author: json["id_author"] ?? 0,
        full_name: json["full_name"] ?? "",
        biography: json["biography"] ?? ""
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id_author' : id_author,
      'full_name' : full_name,
      'biography' : biography,
    };
  }
}