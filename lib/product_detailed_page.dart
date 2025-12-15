import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/widgets/product_options_menu.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? _ownerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerId();
  }

  Future<void> _fetchOwnerId() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final appwriteService = context.read<AppwriteService>();
      final profileDoc = await appwriteService.getProfile(widget.product.profileId);
      final profile = Profile.fromRow(profileDoc);
      if (mounted) {
        setState(() {
          _ownerId = profile.ownerId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error, maybe show a snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    final appwriteService = Provider.of<AppwriteService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          if (!_isLoading && _ownerId != null)
            ProductOptionsMenu(product: widget.product, ownerId: _ownerId!),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.imageId != null)
              CachedNetworkImage(
                imageUrl: appwriteService.getFileViewUrl(widget.product.imageId!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\u20b9${widget.product.price}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.location,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
