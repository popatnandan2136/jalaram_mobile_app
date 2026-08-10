import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';

class AddRetailerScreen extends StatefulWidget {
  const AddRetailerScreen({super.key});

  @override
  State<AddRetailerScreen> createState() => _AddRetailerScreenState();
}

class _AddRetailerScreenState extends State<AddRetailerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Retailer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Retailer / Shop Name',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryIndigo),
                  hintText: 'Enter retailer or shop name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the retailer name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Mobile Field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primaryIndigo),
                  hintText: 'Enter 10-digit mobile number',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the mobile number';
                  }
                  // Basic 10-digit regex check
                  final phoneRegExp = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegExp.hasMatch(value.trim())) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // Save Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text.trim();
                    final mobile = _mobileController.text.trim();
                    final provider = Provider.of<ShopProvider>(context, listen: false);

                    await provider.addRetailer(name, mobile);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Retailer "$name" added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save Retailer'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
