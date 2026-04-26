import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackWidget extends StatelessWidget{
  const BackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child: IconButton(onPressed:() {
        // Navigator.of(context).pop();
        context.go("/");
      }, icon: Icon(Icons.arrow_back),)
    );
  }
}