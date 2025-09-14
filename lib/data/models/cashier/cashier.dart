// class Todo {
//   final int? id;
//   final String title;
//   final String? description;
//   final bool isDone;
//   final DateTime createdAt;

//   Todo({
//     this.id,
//     required this.title,
//     this.description,
//     this.isDone = false,
//     DateTime? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now();

//   Todo copyWith({
//     int? id,
//     String? title,
//     String? description,
//     bool? isDone,
//     DateTime? createdAt,
//   }) {
//     return Todo(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       description: description ?? this.description,
//       isDone: isDone ?? this.isDone,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }

//   factory Todo.fromMap(Map<String, dynamic> map) {
//     return Todo(
//       id: map['id'] as int?,
//       title: map['title'] as String,
//       description: map['description'] as String?,
//       isDone: (map['is_done'] as int) == 1,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'is_done': isDone ? 1 : 0,
//       'created_at': createdAt.millisecondsSinceEpoch,
//     };
//   }
// }
class Batch {
  final String batchID;
  final double pprice;
  final double price;
  final int quantity;
  final double discountAmount;

  Batch({
    required this.batchID,
    required this.pprice,
    required this.price,
    required this.quantity,
    required this.discountAmount,
  });

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      batchID: map['batchID'],
      pprice: (map['pprice'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      discountAmount: (map['discountAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'batchID': batchID,
    'pprice': pprice,
    'price': price,
    'quantity': quantity,
    'discountAmount': discountAmount,
  };
}

class Item {
  final int id;
  final String itemcode;
  final String name;
  final String colorCode;
  final List<Batch> batches;

  Item({
    required this.id,
    required this.itemcode,
    required this.name,
    required this.colorCode,
    this.batches = const [],
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      itemcode: map['itemcode'],
      name: map['name'],
      colorCode: map['colorCode'],
      batches: (map['batches'] as List)
          .map((b) => Batch.fromMap(b))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemcode': itemcode,
    'name': name,
    'colorCode': colorCode,
    'batches': batches.map((b) => b.toMap()).toList(),
  };
}

class Category {
  final int id;
  final String category;
  final String colorCode;
  final String? categoryImage;
  final List<Item> items;

  Category({
    required this.id,
    required this.category,
    required this.colorCode,
    this.categoryImage,
    this.items = const [],
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      category: map['category'],
      colorCode: map['colorCode'],
      categoryImage: map['categoryImage'],
      items: (map['items'] as List)
          .map((i) => Item.fromMap(i))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'colorCode': colorCode,
    'categoryImage': categoryImage,
    'items': items.map((i) => i.toMap()).toList(),
  };
}

class Payment {
  final int id;
  final double amount;
  final double remainAmount;
  final int date; // stored as epoch ms
  final String fileName;
  final String type;
  final int saleInvoiceId;
  final int userId;
  final String? customerContact;

  Payment({
    required this.id,
    required this.amount,
    required this.remainAmount,
    required this.date,
    required this.fileName,
    required this.type,
    required this.saleInvoiceId,
    required this.userId,
    this.customerContact,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      amount: map['amount'],
      remainAmount: map['remain_amount'],
      date: map['date'],
      fileName: map['file_name'],
      type: map['type'],
      saleInvoiceId: map['sale_invoice_id'],
      userId: map['user_id'],
      customerContact: map['customer_contact'],
    );
  }
}

// Future<List<Payment>> getAllPaymentsAsModel() async {
//   final db = await DatabaseHelper.instance.database;
//   final results = await db.query('payment', orderBy: 'date DESC');
//   return results.map((row) => Payment.fromMap(row)).toList();
// }
