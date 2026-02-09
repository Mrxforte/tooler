import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.index});
  final int index; // Placeholder index for demonstration purposes

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              "https://wallpapercave.com/wp/wp13395609.jpg",
              width: 140,
              height: 200,
              fit: BoxFit.cover,
            ),
            // title and description
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: Text(
                    "Tool Name $index",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: SizedBox(height: 8),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    "This is a description of the tool. It provides useful information about the tool's features and functionalities.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.justify,
                    softWrap: true,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // list of icon buttons  to actions
            Spacer(),
            Column(
              children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                IconButton(
                  icon: Icon(Icons.move_up_outlined),
                  onPressed: () {},
                ),
                IconButton(icon: Icon(Icons.delete), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
