import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../widgets/service_card.dart';
import '../models/service.dart';
import '../services/user_service.dart';
import './client/request_service_page.dart'; 

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.token, required this.uid});
  final String uid; 
  final String token;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 500);
  final List<String> _selectedFilters = [];
  List<Service> _services = [];
  bool _isLoading = false;

  final List<String> categories = [
    'cleaning',
    'plumbing',
    'electrical',
    'painting',
    'gardening',
    'handyman',
    'moving',
    'tutoring',
    'beauty',
    'photography',
    'catering',
    'other'
  ];

  final List<String> filters = [
    'Shoes',
    'Jacket',
    'Pants',
    'Electronics',
    'Books',
    'Sports'
  ];

  @override
  void initState() {
    super.initState();
    developer.log('🔍 SearchPage initialized', name: 'SearchPage');

    // Load services when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
    });
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final services = await UserService().loadServices(widget.token);
      setState(() {
        _services = services;
        _isLoading = false;
      });
      developer.log('📊 Services loaded: ${_services.length}',
          name: 'SearchPage');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading services: $e', name: 'SearchPage');
      // Optionally show an error message to the user
    }
  }

  List<Service> get searchResults {
    return _services.where((service) {
      // Apply search filters
      final matchesSearch = _searchController.text.isEmpty ||
          service.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || service.category == _selectedCategory;
      final matchesPrice = service.price >= _priceRange.start &&
          service.price <= _priceRange.end;
      final matchesTags = _selectedFilters.isEmpty ||
          _selectedFilters
              .any((tag) => service.tags.contains(tag.toLowerCase()));

      return matchesSearch && matchesCategory && matchesPrice && matchesTags;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No services found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
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
                              if (isSelected) {
                                _selectedCategory = 'All';
                              } else {
                                _selectedCategory = category;
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor:
                              const Color(0xFF2563EB).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey[700],
                          ),
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
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => StatefulBuilder(
                          builder: (context, setModalState) {
                            final TextEditingController _tagController =
                                TextEditingController();
                            return Container(
                              padding: const EdgeInsets.all(24),
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            _priceRange =
                                                const RangeValues(0, 500);
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
                                    activeColor: const Color(0xFF2563EB),
                                    inactiveColor: const Color(0xFF2563EB)
                                        .withOpacity(0.2),
                                    onChanged: (values) {
                                      setModalState(() {
                                        _priceRange = values;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Custom Tags
                                  const Text(
                                    'Tags',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _tagController,
                                          decoration: InputDecoration(
                                            hintText: 'Add a tag...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final tag =
                                              _tagController.text.trim();
                                          if (tag.isNotEmpty &&
                                              !_selectedFilters.contains(tag)) {
                                            setModalState(() {
                                              _selectedFilters.add(tag);
                                              _tagController.clear();
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2563EB),
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                        ),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedFilters.map((filter) {
                                      return Chip(
                                        label: Text(filter),
                                        onDeleted: () {
                                          setModalState(() {
                                            _selectedFilters.remove(filter);
                                          });
                                        },
                                        backgroundColor: Colors.grey.shade100,
                                        deleteIcon: const Icon(Icons.close),
                                      );
                                    }).toList(),
                                  ),

                                  const Spacer(),

                                  // Apply Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: const Text(
                                        'Apply Filters',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  )
                : searchResults.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        color: const Color(0xFF2563EB),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to RequestServicePage on tap
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestServicePage(
                                        token: widget.token,
                                        uid: widget.uid,
                                        category: searchResults[index]
                                            .category, // Pass the category here
                                        title: searchResults[index]
                                            .title, // Pass the title
                                        price: searchResults[index]
                                            .price
                                      ),
                                    ),
                                  );
                                },
                                child: ServiceCard(
                                  service: searchResults[index],
                                  userId: widget.uid,
                                  token: widget.token,
                                  isHorizontal: true,
                                  onMessageTap: () => {},
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
