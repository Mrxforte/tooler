import 'package:flutter/material.dart';
import 'package:tooler/views/widgets/product_card.dart';

class ListOfProjects extends StatelessWidget {
  const ListOfProjects({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemBuilder: (context, index) {
          return ProductCard(index: index);
        },
        separatorBuilder: (context, index) => SizedBox(height: 4),
        itemCount: 10,
      ),
    );
  }
}
