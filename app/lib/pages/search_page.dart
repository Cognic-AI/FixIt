import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import '../models/service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 500);
  List<String> _selectedFilters = [];

  final List<String> categories = [
    'All',
    'Accommodation',
    'Events',
    'Home Services',
    'Professional Services'
  ];

  final List<String> filters = [
    'Shoes',
    'Jacket',
    'Pants',
    'Electronics',
    'Books',
    'Sports'
  ];

  final List<Service> searchResults = [
    Service(
      id: '1',
      title: 'Great Apartment',
      price: 150.0,
      location: 'Recife',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
      dates: 'Mar 12 – Mar 15',
      hostName: 'Karen Roe',
      category: 'accommodation',
      description: 'A beautiful apartment in the heart of the city.',
      reviewCount: 120,
      hostId: 'host1',
      amenities: ['Wi-Fi', 'Air Conditioning', 'Kitchen'],
      latitude: -8.0476,
      longitude: -34.8770,
      active: true,
    ),
    Service(
      id: '2',
      title: 'Professional Photography',
      price: 200.0,
      location: 'Olinda',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400',
      dates: 'Available',
      hostName: 'Maria Santos',
      category: 'professional',
      description: 'Capture your moments with a professional photographer.',
      reviewCount: 85,
      hostId: 'host2',
      amenities: ['High Resolution', 'Editing', 'Outdoor Shooting'],
      latitude: -8.0089,
      longitude: -34.8550,
      active: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Category Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor:
                              const Color(0xFF2563EB).withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Filters Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFiltersBottomSheet,
                    icon: const Icon(Icons.tune),
                    label: const Text('Filters'),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${searchResults.length} results',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ServiceCard(
                    service: searchResults[index],
                    isHorizontal: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _priceRange = const RangeValues(0, 500);
                        _selectedFilters.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Price Range
              const Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '€${_priceRange.start.round()} - €${_priceRange.end.round()}',
                style: const TextStyle(color: Colors.grey),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 500,
                divisions: 50,
                onChanged: (values) {
                  setModalState(() {
                    _priceRange = values;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Tags
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filters.map((filter) {
                  final isSelected = _selectedFilters.contains(filter);
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          _selectedFilters.add(filter);
                        } else {
                          _selectedFilters.remove(filter);
                        }
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Apply filters logic here
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
