import 'package:flutter/material.dart';

class ListOfToolsScreen extends StatelessWidget {
  const ListOfToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemBuilder: (context, index) {
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
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          "Tool Name $index",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 150,
                          child: Text(
                            "This is a description of the tool. It provides useful information about the tool's features and functionalities.",
                            style: TextStyle(fontSize: 16),
                          ),
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
        },
        separatorBuilder: (context, index) => SizedBox(height: 4),
        itemCount: 10,
      ),
    );
  }
}
