import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
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
        title: const Text('Add New Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryIndigo),
                  hintText: 'Enter customer name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the customer name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
                  final phoneRegExp = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegExp.hasMatch(value.trim())) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text.trim();
                    final mobile = _mobileController.text.trim();
                    final provider = Provider.of<ShopProvider>(context, listen: false);

                    await provider.addCustomer(name, mobile);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Customer "$name" added successfully!'),
                          backgroundColor: AppTheme.creditGreen,
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
                    Text('Save Customer'),
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
