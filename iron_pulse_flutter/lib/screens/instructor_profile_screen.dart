import 'dart:ui';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/classes_service.dart';

class InstructorProfileScreen extends StatefulWidget {
  final Profile profile;

  const InstructorProfileScreen({super.key, required this.profile});

  @override
  State<InstructorProfileScreen> createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color primaryColor = const Color(0xFF17A1CF);
  final Color textMain = const Color(0xFFE0E4EB);
  final Color textMuted = const Color(0xFF7A8490);

  bool _isLoading = true;
  Instructor? _instructorData;

  @override
  void initState() {
    super.initState();
    _loadInstructorData();
  }

  Future<void> _loadInstructorData() async {
    final name = widget.profile.fullName ?? '';
    final instructor = await ClassesService().getInstructorDetailsByName(name);
    
    if (mounted) {
      setState(() {
        _instructorData = instructor;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final String name = widget.profile.fullName ?? _instructorData?.name ?? 'Instructor';
    final String bio = _instructorData?.bio ?? 'With over 8 years of dedicated practice, this instructor brings a calming yet challenging approach to sessions. They believe in the power of mindful movement to transform both body and mind.';
    final double rating = _instructorData?.rating ?? 4.9;
    final String avatar = widget.profile.avatarUrl ?? _instructorData?.avatarUrl ?? 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80';

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur layer for background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
          
          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                pinned: true,
                backgroundColor: bgDark,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceDark.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surfaceDark.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.favorite_border, color: Colors.white),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: surfaceDark),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              bgDark,
                              bgDark.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "YOGA",
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "PILATES",
                                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.verified, color: primaryColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "Certified Instructor",
                                  style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About
                      const Text("About", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: TextStyle(color: textMuted, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      
                      // Stats Grid
                      Row(
                        children: [
                          Expanded(child: _buildStatBox("8+", "Years Exp.")),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatBox("2k+", "Classes")),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: surfaceDark,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(
                                children: [
                                  Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text("RATING", style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Reviews
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Recent Reviews", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("View all", style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildReviewCard(
                              "Mike T.", 
                              "https://ui-avatars.com/api/?name=Mike&background=1A1D21&color=fff",
                              "Sarah's energy is incredible! The flow was perfect for a Monday morning. Highly recommend.", 5
                            ),
                            const SizedBox(width: 16),
                            _buildReviewCard(
                              "Jessica L.", 
                              "https://ui-avatars.com/api/?name=Jessica&background=1A1D21&color=fff",
                              "Great attention to form. I really felt the burn in the core section. Will come back!", 4
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Upcoming Classes
                      const Text("Upcoming Classes", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildUpcomingClass("Fri", "14", "Morning Vinyasa Flow", "08:00 AM", "60 min"),
                      const SizedBox(height: 12),
                      _buildUpcomingClass("Sat", "15", "Power Pilates", "10:30 AM", "45 min"),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24, 
                    right: 24, 
                    top: 16, 
                    bottom: 16 + MediaQuery.of(context).padding.bottom
                  ),
                  decoration: BoxDecoration(
                    color: surfaceDark.withOpacity(0.9),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: surfaceDark,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text("Message", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Book a Private",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String avatar, String review, int stars) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    )),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$review"',
            style: TextStyle(color: textMuted, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClass(String dayName, String dayNum, String title, String time, String duration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayName, style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(dayNum, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, color: textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(color: textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(duration, style: TextStyle(color: textMuted, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
