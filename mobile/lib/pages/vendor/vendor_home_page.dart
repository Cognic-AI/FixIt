import 'package:fixit/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../widgets/vendor_service_card.dart';
import '../../widgets/service_request_card.dart';
import '../../models/service.dart';
import '../../models/service_request.dart';
import '../../models/message.dart';
import 'add_service_page.dart';
import 'chat_page.dart';
import 'edit_profile_page.dart';

class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key, required this.user, required this.token});

  final User user;
  final String token;

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('[VENDOR_HOME] initState called');
    _tabController = TabController(length: 3, vsync: this);
    developer.log('VendorHomePage initialized', name: 'VendorHomePage');

    // Initialize vendor service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[VENDOR_HOME] addPostFrameCallback executing');
      final vendorService = Provider.of<VendorService>(context, listen: false);
      print('[VENDOR_HOME] Got VendorService instance');
      print('[VENDOR_HOME] About to call vendorService.initialize()');
      vendorService.initialize(
        widget.user.id,
        widget.token,
      );
      print('[VENDOR_HOME] vendorService.initialize() called');
    });
    print('[VENDOR_HOME] initState completed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[VENDOR_HOME] build method called');
    print('[VENDOR_HOME] _selectedIndex: $_selectedIndex');
    developer.log('Building VendorHomePage', name: 'VendorHomePage');

    return Scaffold(
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildServices()
              : _selectedIndex == 2
                  ? _buildRequests()
                  : _selectedIndex == 3
                      ? _buildMessages()
                      : _buildProfile(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddServiceDialog,
              backgroundColor: const Color(0xFF006FD6),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      selectedItemColor: const Color(0xFF006FD6),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    print('[VENDOR_HOME] _buildDashboard called');
    return Consumer<VendorService>(
      builder: (context, vendorService, child) {
        print('[VENDOR_HOME] Consumer builder called');
        print(
            '[VENDOR_HOME] vendorService.isLoading: ${vendorService.isLoading}');
        print(
            '[VENDOR_HOME] vendorService.myServices.length: ${vendorService.myServices.length}');
        print(
            '[VENDOR_HOME] vendorService.pendingRequests.length: ${vendorService.pendingRequests.length}');
        print(
            '[VENDOR_HOME] vendorService.activeServices.length: ${vendorService.activeServices.length}');
        print(
            '[VENDOR_HOME] vendorService.completedServices.length: ${vendorService.completedServices.length}');

        return CustomScrollView(
          slivers: [
            _buildAppBar('Dashboard'),

            // Quick Stats
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Services',
                        vendorService.myServices.length.toString(),
                        Icons.build,
                        const Color(0xFF006FD6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Pending Requests',
                        vendorService.pendingRequests.length.toString(),
                        Icons.pending,
                        const Color(0xFF006FD6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active Services',
                        vendorService.activeServices.length.toString(),
                        Icons.work,
                        const Color(0xFF006FD6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        vendorService.completedServices.length.toString(),
                        Icons.check_circle,
                        const Color(0xFF006FD6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AI Assistant Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF006FD6),
                          Color(0xFF006FD6),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'AI Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Get help with optimizing your services, pricing strategies, and customer engagement tips.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAIAssistant,
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Chat with AI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF006FD6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            // Recent Requests
            if (vendorService.pendingRequests.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final request = vendorService.pendingRequests[index];
                    return ServiceRequestCard(
                      request: request,
                      onAccept: () => _acceptRequest(request.id),
                      onReject: () => _rejectRequest(request.id),
                    );
                  },
                  childCount: vendorService.pendingRequests.take(3).length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildServices() {
    print('[VENDOR_HOME] _buildServices called');
    return Consumer<VendorService>(
      builder: (context, vendorService, child) {
        print('[VENDOR_HOME] Services Consumer builder called');
        print(
            '[VENDOR_HOME] Services - vendorService.isLoading: ${vendorService.isLoading}');
        print(
            '[VENDOR_HOME] Services - vendorService.myServices.length: ${vendorService.myServices.length}');

        if (vendorService.myServices.isNotEmpty) {
          print('[VENDOR_HOME] Services list:');
          for (int i = 0; i < vendorService.myServices.length; i++) {
            print(
                '[VENDOR_HOME] Service $i: ${vendorService.myServices[i].title}');
          }
        }

        return CustomScrollView(
          slivers: [
            _buildServicesAppBar(vendorService),

            // Loading indicator
            if (vendorService.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading services...'),
                      ],
                    ),
                  ),
                ),
              ),

            if (!vendorService.isLoading && vendorService.myServices.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No services yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first service to get started',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddServicePage(
                                    token: widget.token,
                                    vendorId: widget.user.id,
                                  )),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006FD6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!vendorService.isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = vendorService.myServices[index];
                    print(
                        '[VENDOR_HOME] Building service card for: ${service.title}');
                    return VendorServiceCard(
                      service: service,
                      onEdit: () => _editService(service),
                      onDelete: () => _deleteService(service.id),
                      onToggleStatus: () => _toggleServiceStatus(service),
                      onViewDetails: () => _viewServiceDetails(service),
                    );
                  },
                  childCount: vendorService.myServices.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildRequests() {
    return Consumer<VendorService>(
      builder: (context, vendorService, child) {
        return Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF006FD6),
                    Color(0xFF006FD6),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Service Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      vendorService.loadServiceRequests(
                        widget.token,
                      );
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF006FD6),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF006FD6),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsList(vendorService.pendingRequests, 'pending'),
                  _buildRequestsList(vendorService.activeServices, 'active'),
                  _buildRequestsList(
                      vendorService.completedServices, 'completed'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessages() {
    return Consumer<VendorService>(
      builder: (context, vendorService, child) {
        return CustomScrollView(
          slivers: [
            _buildAppBar('Messages'),
            if (vendorService.conversations.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start providing services to chat with clients',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conversation = vendorService.conversations[index];
                    return _buildConversationTile(conversation);
                  },
                  childCount: vendorService.conversations.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildProfile() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;

        return CustomScrollView(
          slivers: [
            _buildAppBar('Profile'),

            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF006FD6).withOpacity(0.1),
                      child: user?.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              user?.firstName[0].toUpperCase() ?? 'V',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006FD6),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'Vendor Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'vendor@example.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Options
            SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileOption(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: _editProfile,
                ),
                _buildProfileOption(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: _openSettings,
                ),
                _buildProfileOption(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: _openSupport,
                ),
                _buildProfileOption(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: _logout,
                  textColor: Colors.red,
                ),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(String title) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF006FD6),
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildServicesAppBar(VendorService vendorService) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF006FD6),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () async {
            print('[VENDOR_HOME] Refresh button pressed');
            await vendorService.loadMyServices(
              widget.token,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Services refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh services',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<ServiceRequest> requests, String type) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending'
                  ? Icons.pending_actions
                  : type == 'active'
                      ? Icons.work_outline
                      : Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $type requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return ServiceRequestCard(
          request: request,
          onAccept: request.isPending ? () => _acceptRequest(request.id) : null,
          onReject: request.isPending ? () => _rejectRequest(request.id) : null,
          onUpdateStatus: (request.isAccepted || request.isInProgress)
              ? () => _updateRequestStatus(request)
              : null,
          onViewDetails: () => _viewRequestDetails(request),
        );
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF006FD6).withOpacity(0.1),
        child: Text(
          conversation.clientName.isNotEmpty
              ? conversation.clientName[0].toUpperCase()
              : 'C',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF006FD6),
          ),
        ),
      ),
      title: Text(
        conversation.clientName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation.serviceTitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF006FD6),
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openConversation(conversation),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Action Methods
  void _showAddServiceDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AddServicePage(token: widget.token, vendorId: widget.user.id)),
    );
  }

  void _editService(Service service) {
    // TODO: Navigate to edit service page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: Text(
            'Edit ${service.title} functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteService(String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final vendorService =
                  Provider.of<VendorService>(context, listen: false);
              vendorService.deleteService(
                serviceId,
                widget.token,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleServiceStatus(Service service) {
    final vendorService = Provider.of<VendorService>(context, listen: false);
    vendorService.updateService(
        service.id, {'availability': !service.availability}, widget.token);
  }

  void _viewServiceDetails(Service service) {
    // TODO: Navigate to service details page
  }

  void _acceptRequest(String requestId) {
    final vendorService = Provider.of<VendorService>(context, listen: false);
    vendorService.acceptServiceRequest(requestId, widget.token, widget.user.id);
  }

  void _rejectRequest(String requestId) {
    final vendorService = Provider.of<VendorService>(context, listen: false);
    vendorService.rejectServiceRequest(requestId, widget.token, widget.user.id);
  }

  void _updateRequestStatus(ServiceRequest request) {
    final vendorService = Provider.of<VendorService>(context, listen: false);
    if (request.isAccepted) {
      vendorService.updateServiceStatus(
        request.id,
        ServiceRequestStatus.inProgress,
        widget.token,
        widget.user.id,
      );
    } else if (request.isInProgress) {
      vendorService.updateServiceStatus(request.id,
          ServiceRequestStatus.completed, widget.token, widget.user.id);
    }
  }

  void _viewRequestDetails(ServiceRequest request) {
    // TODO: Navigate to request details page
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: conversation,
          token: widget.token,
        ),
      ),
    );
  }

  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006FD6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF006FD6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'AI Assistant Chat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI chatbot functionality will be implemented here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _openSettings() {
    // TODO: Navigate to settings page
  }

  void _openSupport() {
    // TODO: Navigate to support page
  }

  void _logout() async {
    try {
      await Provider.of<AuthService>(context, listen: false).signOut();
    } catch (e) {
      developer.log('❌ Error during logout: $e', name: 'VendorHomePage');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
