import 'package:flutter/material.dart';
import 'package:my_app/add_product.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/models/product.dart';
import 'package:provider/provider.dart';

class ProductOptionsMenu extends StatelessWidget {
  final Product product;

  const ProductOptionsMenu({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appwriteService = Provider.of<AppwriteService>(context, listen: false);
    final isOwner = authService.currentUser?.id == product.profileId;

    void handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await appwriteService.deleteProduct(product.id);
          if (context.mounted) {
            // Pop the dialog and the detail page
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product deleted successfully!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete product: $e')),
            );
          }
        }
      }
    }

    void handleEdit() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddProductScreen(
            profileId: product.profileId,
            product: product,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 22),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text('Product Setting',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const ListTile(
                  leading: Icon(Icons.high_quality),
                  title: Text('Quality Setting'),
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('Translate and Transcript'),
                ),
                if (isOwner) ...[
                  const Divider(),
                  const ListTile(
                    title: Text('Owner Setting',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      handleEdit();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      handleDelete();
                    },
                  ),
                ],
                const Divider(),
                const ListTile(
                  title: Text('Caution',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const ListTile(
                  leading: Icon(Icons.not_interested),
                  title: Text('Not Interested'),
                ),
                const ListTile(
                  leading: Icon(Icons.warning),
                  title: Text('NSFW Content'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
