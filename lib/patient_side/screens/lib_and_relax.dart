import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Library & Relaxation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.primary,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.menu_book_rounded), text: 'Reading List'),
              Tab(icon: Icon(Icons.headphones_rounded), text: 'Relaxing Audio'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TabBarView(
              children: [
                // Books Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: bookList.length,
                  itemBuilder: (context, index) {
                    final book = bookList[index];
                    return _buildResourceCard(
                      theme: theme,
                      title: book['title'] ?? 'Unknown Title',
                      subtitle: book['author'] ?? 'Unknown Author',
                      // Safely falls back if 'description' is missing in your array
                      description:
                          book['description'] ??
                          'Tap to view this book online for more details.',
                      icon: Icons.auto_stories_outlined,
                      url: book['url'] ?? '',
                      actionText: 'View Book',
                    );
                  },
                ),
                // Music Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: songList.length,
                  itemBuilder: (context, index) {
                    final song = songList[index];
                    return _buildResourceCard(
                      theme: theme,
                      title: song['title'] ?? 'Unknown Title',
                      subtitle: song['artist'] ?? 'Unknown Artist',
                      // Safely falls back if 'description' is missing in your array
                      description:
                          song['description'] ??
                          'Tap to listen to this relaxing track.',
                      icon: Icons.music_note_outlined,
                      url: song['url'] ?? '',
                      actionText: 'Listen Now',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String url,
    required String actionText,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _launchURL(url),
                icon: Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  actionText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return; // Prevents crash if URL is missing

    final Uri uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $urlString');
    }
  }
}

// --- Enhanced Data with Descriptions ---

final List<Map<String, String>> bookList = [
  {
    'title': 'What to Expect When You\'re Expecting',
    'author': 'By Heidi Murkoff',
    'description':
        'The classic, comprehensive guide covering physical and emotional changes week by week.',
    'url':
        'https://www.amazon.com/What-Expect-When-Youre-Expecting/dp/0761187488',
  },
  {
    'title': 'The Expectant Father',
    'author': 'By Armin A. Brott',
    'description':
        'A fantastic perspective on the 9-month journey specifically tailored for dads-to-be.',
    'url':
        'https://www.amazon.com/Expectant-Father-Ultimate-Dads-Be/dp/0789213445',
  },
  {
    'title': 'Ina May\'s Guide to Childbirth',
    'author': 'By Ina May Gaskin',
    'description':
        'Empowering stories and practical advice focusing on natural childbirth methods.',
    'url':
        'https://www.amazon.com/Ina-Mays-Guide-Childbirth-Gaskin/dp/0553381156',
  },
  {
    'title': 'Expecting Better',
    'author': 'By Emily Oster',
    'description':
        'A data-driven approach to pregnancy myths, helping you make informed, relaxed decisions.',
    'url':
        'https://www.amazon.com/Expecting-Better-Conventional-Pregnancy-Wrong/dp/0143125702',
  },
  {
    'title': 'The Whole 9 Months',
    'author': 'By Jennifer Lang',
    'description':
        'A week-by-week nutritional guide and cookbook for a healthy pregnancy.',
    'url':
        'https://www.amazon.com/Whole-9-Months-Healthy-Pregnancy/dp/1940358931',
  },
];

final List<Map<String, String>> songList = [
  {
    'title': 'Beautiful Day',
    'artist': 'U2',
    'description':
        'An uplifting, energetic track to start your morning with positive vibes.',
    'url': 'https://www.youtube.com/watch?v=co6WMzDOh1o',
  },
  {
    'title': 'Three Little Birds',
    'artist': 'Bob Marley',
    'description':
        'A relaxing reggae classic reminding you that "every little thing is gonna be alright."',
    'url': 'https://www.youtube.com/watch?v=zaGUr6wzyT8',
  },
  {
    'title': 'Here Comes the Sun',
    'artist': 'The Beatles',
    'description':
        'A gentle, soothing acoustic melody perfect for afternoon relaxation.',
    'url': 'https://www.youtube.com/watch?v=KQetemT1sWc',
  },
  {
    'title': 'A Thousand Years',
    'artist': 'Christina Perri',
    'description':
        'A beautiful, emotional ballad to connect with your growing baby.',
    'url': 'https://www.youtube.com/watch?v=rtOvBOTyX00',
  },
  {
    'title': 'Isn\'t She Lovely',
    'artist': 'Stevie Wonder',
    'description': 'A joyous celebration of new life and parenthood.',
    'url': 'https://www.youtube.com/watch?v=wDZFf0pm0SE',
  },
];
