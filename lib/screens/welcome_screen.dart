import 'package:flutter/material.dart';
import 'package:stayclose/services/image_service.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const WelcomeScreen({this.onComplete});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  final ImageService _imageService = ImageService();
  int _currentPage = 0;
  
  final List<WelcomePageData> _pages = [
    WelcomePageData(
      icon: Icons.favorite,
      title: "Welcome to StayClose",
      description: "Never lose touch with the people who matter most. StayClose helps you maintain meaningful relationships through gentle daily reminders.",
      color: Colors.teal,
    ),
    WelcomePageData(
      icon: Icons.today,
      title: "Daily Kindred",
      description: "Each day, StayClose selects a 'kindred of the day' from your contacts, encouraging you to reach out and stay connected.",
      color: Colors.blue,
    ),
    WelcomePageData(
      icon: Icons.event,
      title: "Never Miss Important Dates",
      description: "Add birthdays, anniversaries, and other special dates. Get notified in advance so you can show you care.",
      color: Colors.orange,
    ),
    WelcomePageData(
      icon: Icons.contact_phone,
      title: "Easy Contact Management",
      description: "Import contacts from your device or add them manually. Add photos and organize your most important relationships.",
      color: Colors.green,
    ),
    WelcomePageData(
      icon: Icons.security,
      title: "Your Privacy Matters",
      description: "All your data stays on your device. No cloud storage, no tracking, no sharing. Your relationships remain private.",
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                      'assets/favicon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () => _skipToEnd(),
                      child: Text('Skip', style: TextStyle(color: Colors.grey[600])),
                    )
                  else
                    SizedBox(width: 60),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.teal : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            
            SizedBox(height: 20),
            
            // Navigation buttons
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text('Previous'),
                        )
                      : SizedBox(width: 80),
                  
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _complete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(WelcomePageData page) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          
          SizedBox(height: 40),
          
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _complete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class WelcomePageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  WelcomePageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}