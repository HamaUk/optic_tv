import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _channelNameController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _channelCategoryController = TextEditingController();

  Future<void> _addChannel() async {
    if (_channelNameController.text.isEmpty || _channelUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // Logic for RTDB: Add to 'sync/global/managedPlaylist'
      final dbRef = FirebaseDatabase.instance.ref('sync/global/managedPlaylist');
      final newChannelRef = dbRef.push();
      
      await newChannelRef.set({
        'name': _channelNameController.text,
        'url': _channelUrlController.text,
        'group': _channelCategoryController.text.isEmpty ? 'General' : _channelCategoryController.text,
      });

      _channelNameController.clear();
      _channelUrlController.clear();
      _channelCategoryController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel added to Realtime Database!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding channel: $e')),
      );
    }
  }

  Future<void> _deleteChannel(String key) async {
    try {
      await FirebaseDatabase.instance.ref('sync/global/managedPlaylist/$key').remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel (RTDB)'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Channel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_channelNameController, 'Channel Name'),
                  const SizedBox(height: 16),
                  _buildTextField(_channelUrlController, 'Stream URL (M3U8)'),
                  const SizedBox(height: 16),
                  _buildTextField(_channelCategoryController, 'Group (e.g. Sports)'),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addChannel,
                      child: const Text('ADD CHANNEL'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    'Live Database Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('sync/global/managedPlaylist').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text('No channels yet'));
                
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final items = data.entries.toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final entry = items[index];
                    final val = entry.value as Map;
                    
                    return ListTile(
                      title: Text(val['name'] ?? 'No Name'),
                      subtitle: Text(val['group'] ?? 'General'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteChannel(entry.key),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
