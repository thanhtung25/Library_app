
class CategoryModel{
  final int id_category;
  final String name;
  final String description;

  CategoryModel({
    required this.id_category,
    required this.name,
    required this.description
  });

  factory CategoryModel.fromJson(Map<String,dynamic> json){
    return CategoryModel(
        id_category: json["id_category"] ?? 0,
        name: json["name"] ?? "",
        description: json["description"] ?? ""
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id_category' : id_category,
      'name' : name,
      'description' : description,
    };
  }
}