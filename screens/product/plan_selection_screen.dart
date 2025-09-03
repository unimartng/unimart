import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/screens/product/mock_payment_screen.dart';
import 'package:unimart/widgets/custom_button.dart';

class PlanSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final List<dynamic> images;

  const PlanSelectionScreen({
    required this.productData,
    required this.images,
    super.key,
  });

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  String? _selectedPlan;
  Map<String, double> _planPrices = {};
  bool _isLoading = true;
  Map<String, PlanData> _plans = {};

  @override
  void initState() {
    super.initState();
    _fetchPlanPrices();
  }

  Future<void> _fetchPlanPrices() async {
    try {
      final response = await Supabase.instance.client
          .from('featured_plans')
          .select('name, days, price')
          .order('days', ascending: true);

      if (response.isNotEmpty) {
        final Map<String, double> prices = {};
        final Map<String, PlanData> updatedPlans = {};

        for (final plan in response) {
          final planName = plan['name'] as String;
          final days = plan['days'] as int;
          final price = (plan['price'] as num).toDouble();

          prices[planName] = price;
          updatedPlans[planName] = PlanData(
            days: days,
            title: planName,
            isPopular: days == 3,
          );
        }

        setState(() {
          _planPrices = prices;
          _plans = updatedPlans;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _planPrices = {'1 Day': 9.99, '3 Days': 24.99, '1 Week': 49.99};
        _plans = {
          '1 Day': PlanData(days: 1, title: '1 Day'),
          '3 Days': PlanData(days: 3, title: '3 Days', isPopular: true),
          '1 Week': PlanData(days: 7, title: '1 Week'),
        };
        _isLoading = false;
      });
    }
  }

  void _continue() {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedDays = _plans[_selectedPlan]!.days;
    final selectedPrice = _planPrices[_selectedPlan] ?? 0.0;

    Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => MockPaymentScreen(
          days: selectedDays,
          price: selectedPrice,
          planName: _selectedPlan!,
        ),
      ),
    ).then((paidDays) {
      if (paidDays != null) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, paidDays);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Choose Plan'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feature Your Product',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how long you want your product featured',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final entry = _plans.entries.elementAt(index);
                        final planKey = entry.key;
                        final planData = entry.value;
                        final price = _planPrices[planKey] ?? 0.0;
                        final isSelected = _selectedPlan == planKey;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlan = planKey;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Theme.of(context).colorScheme.tertiary,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryBlue
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              planData.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            if (planData.isPopular)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Popular',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (planData.days > 1)
                                          Text(
                                            '₦${(price / planData.days).toStringAsFixed(0)} per day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₦${price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  CustomButton(
                    width: double.infinity,
                    onPressed: _continue,
                    child: Text(
                      _selectedPlan == null
                          ? 'Select a Plan'
                          : 'Continue - ₦${_planPrices[_selectedPlan]?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class PlanData {
  final int days;
  final String title;
  final bool isPopular;

  PlanData({required this.days, required this.title, this.isPopular = false});
}
