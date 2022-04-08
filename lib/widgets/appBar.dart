import 'package:flutter/material.dart';
import 'package:instagramlesson/services/colors_service.dart';

AppBar appBar({required String text, required bool isCentered, Widget? leading, Widget? action, void Function()? onPressedLeading, void Function()? onPressedAction, bool? isLoading}) {
  return AppBar(
    toolbarHeight: 50,
    leading:
    leading != null
          ?  IconButton(
            splashRadius: 1,
            icon: leading,
            onPressed: onPressedLeading,
            )
          : null,
    title: Text(
        text,
        style: const TextStyle(
          fontFamily: 'instagramFont',
          fontSize: 30,
        )
    ),
    centerTitle: isCentered,
    actions: [
      if (action != null)
        IconButton(
          splashRadius: 1,
          icon: action,
          onPressed: onPressedAction,
        )
    ],
  );
}
