import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final bool isLocalImage;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.isLocalImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
      backgroundImage: imageUrl != null
          ? isLocalImage 
              ? FileImage(File(imageUrl!))
              : CachedNetworkImageProvider(imageUrl!) as ImageProvider
          : null,
      child: imageUrl == null
          ? Icon(
              Icons.person,
              size: radius * 1.2,
              color: Theme.of(context).primaryColor,
            )
          : null,
    );
  }
} 