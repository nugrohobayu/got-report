import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Home screen sliced from Figma "iPhone 11 Pro / X - 1" (node 113:177).
///
/// Content is still static placeholder data from the design; replace it with
/// real data once the feature is wired up.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _TopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 40, bottom: 40),
                  children: const [
                    _SectionTitle('News'),
                    SizedBox(height: 15),
                    // Carousel already ends with 40px (shadow room).
                    _NewsCarousel(),
                    _SectionTitle('Daily Tasks:'),
                    SizedBox(height: 15),
                    _DailyTasks(),
                    SizedBox(height: 15),
                    _OverallProgress(progress: 0.6),
                    SizedBox(height: 40),
                    _InfoCard(
                      icon: _HomeAssets.calendar,
                      arrow: _HomeAssets.arrowRightPurple,
                      title: 'How was your day?',
                      subtitle: 'Lorem ipsum dolor sit amet, consectetur '
                          'adipscing elit. Ut vel odio en urna ultrices',
                      background: _HomeColors.purpleTint,
                      titleColor: _HomeColors.textDark,
                      subtitleColor: _HomeColors.textDark,
                      subtitleOpacity: 0.5,
                    ),
                    SizedBox(height: 10),
                    _InfoCard(
                      icon: _HomeAssets.clock,
                      arrow: _HomeAssets.arrowRightRed,
                      title: 'Current Transist: 3rd House',
                      subtitle: 'This is demonstrate siblings, hobbies, '
                          'efforts, confidence, friends and short trips',
                      background: _HomeColors.redTint,
                      titleColor: _HomeColors.red,
                      subtitleColor: _HomeColors.redMuted,
                      subtitleOpacity: 0.7,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _navIndex,
          onSelected: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

class _HomeColors {
  _HomeColors._();

  static const Color title = Color(0xFF595085);
  static const Color textDark = Color(0xFF403572);
  static const Color purpleTint = Color(0xFFF6F5FB);
  static const Color red = Color(0xFFFF5648);
  static const Color redLabel = Color(0xFFFF3726);
  static const Color redTint = Color(0xFFFFF4F4);
  static const Color redMuted = Color(0xFFA27A7A);
  static const Color teal = Color(0xFF479696);
  static const Color tealTint = Color(0xFFF5F9F9);
  static const Color taskLabelPurple = Color(0xFF61598B);
  static const Color pink = Color(0xFFC93F8D);
  static const Color progressTrack = Color(0xFFFDF9FB);
  static const Color navActive = Color(0xFF3D3270);
  static const Color navInactive = Color(0xFF8B97A8);
}

class _HomeAssets {
  _HomeAssets._();

  static const _dir = 'assets/images/home';
  static const menu = '$_dir/menu.svg';
  static const settings = '$_dir/settings.svg';
  static const calendar = '$_dir/calendar.svg';
  static const clock = '$_dir/clock.svg';
  static const arrowRightPurple = '$_dir/arrow_right_purple.svg';
  static const arrowRightRed = '$_dir/arrow_right_red.svg';
  static const newsStars1 = '$_dir/news_stars_1.svg';
  static const newsStars2 = '$_dir/news_stars_2.svg';
  static const newsStars3 = '$_dir/news_stars_3.svg';
  static const badgePurple = '$_dir/task_badge_purple.svg';
  static const badgeRed = '$_dir/task_badge_red.svg';
  static const badgeTeal = '$_dir/task_badge_teal.svg';
  static const navIcons = [
    '$_dir/nav_home.svg',
    '$_dir/nav_user.svg',
    '$_dir/nav_message.svg',
    '$_dir/nav_book.svg',
    '$_dir/nav_moon.svg',
  ];
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(
        children: [
          _IconTap(asset: _HomeAssets.menu, onTap: () {}),
          Expanded(
            child: Text(
              'Home',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _HomeColors.title,
                  ),
            ),
          ),
          _IconTap(asset: _HomeAssets.settings, onTap: () {}),
        ],
      ),
    );
  }
}

/// 24px SVG icon with a 48px touch target.
class _IconTap extends StatelessWidget {
  const _IconTap({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SvgPicture.asset(asset, width: 24, height: 24),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          color: _HomeColors.title,
        ),
      ),
    );
  }
}

class _NewsItem {
  const _NewsItem(this.title, this.endColor, this.shadowColor, this.stars);

  final String title;
  final Color endColor;
  final Color shadowColor;
  final String stars;
}

class _NewsCarousel extends StatelessWidget {
  const _NewsCarousel();

  static const _items = [
    _NewsItem(
      'Short news title will be here',
      Color(0xFFD994A7),
      Color(0x26734E85),
      _HomeAssets.newsStars1,
    ),
    _NewsItem(
      'Short news title will be here',
      Color(0xFF94D9B4),
      Color(0x265A748E),
      _HomeAssets.newsStars3,
    ),
    _NewsItem(
      'Short news title will be here',
      Color(0xFF7497EF),
      Color(0x265C4E85),
      _HomeAssets.newsStars2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Extra height so the card drop shadow isn't clipped by the list.
    return SizedBox(
      height: 70 + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
        clipBehavior: Clip.none,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _NewsCard(item: _items[i]),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final _NewsItem item;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return Container(
      width: 153,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [const Color(0xFF25196B), item.endColor],
        ),
        boxShadow: [
          BoxShadow(
            color: item.shadowColor,
            offset: const Offset(0, 15),
            blurRadius: 25,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {},
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(item.stars, width: 153, height: 70),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 30, 0),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTasks extends StatelessWidget {
  const _DailyTasks();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: _TaskCard(
              label: 'Daily astromeditation',
              count: 3,
              background: _HomeColors.purpleTint,
              labelColor: _HomeColors.taskLabelPurple,
              countColor: _HomeColors.textDark,
              badge: _HomeAssets.badgePurple,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _TaskCard(
              label: 'Daily sleep astromeditation',
              count: 1,
              background: _HomeColors.redTint,
              labelColor: _HomeColors.redLabel,
              countColor: _HomeColors.red,
              badge: _HomeAssets.badgeRed,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _TaskCard(
              label: 'Daily mantra',
              count: 2,
              background: _HomeColors.tealTint,
              labelColor: _HomeColors.teal,
              countColor: _HomeColors.teal,
              badge: _HomeAssets.badgeTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.label,
    required this.count,
    required this.background,
    required this.labelColor,
    required this.countColor,
    required this.badge,
  });

  final String label;
  final int count;
  final Color background;
  final Color labelColor;
  final Color countColor;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: () {},
        borderRadius: radius,
        child: SizedBox(
          height: 90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: -0.2,
                    color: labelColor,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        color: countColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset(badge, width: 10.4, height: 10.4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.progress});

  /// 0.0 – 1.0
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: _HomeColors.title,
              ),
              children: [
                const TextSpan(text: 'Your overall progress is '),
                TextSpan(
                  text: '$percent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: _HomeColors.pink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Container(
            height: 8,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _HomeColors.progressTrack,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _HomeColors.pink,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.arrow,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.titleColor,
    required this.subtitleColor,
    required this.subtitleOpacity,
  });

  final String icon;
  final String arrow;
  final String title;
  final String subtitle;
  final Color background;
  final Color titleColor;
  final Color subtitleColor;
  final double subtitleOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: () {},
          borderRadius: radius,
          child: SizedBox(
            height: 105,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 23, 15, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(icon, width: 24, height: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, color: titleColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor.withValues(
                                alpha: subtitleOpacity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    // Vertically centers the 12px arrow in the 105px card.
                    padding: const EdgeInsets.only(top: 23),
                    child: SvgPicture.asset(arrow, width: 12, height: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 4, 18, bottomInset + 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _HomeAssets.navIcons.length; i++)
              InkResponse(
                onTap: () => onSelected(i),
                radius: 24,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SvgPicture.asset(
                      _HomeAssets.navIcons[i],
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        i == selectedIndex
                            ? _HomeColors.navActive
                            : _HomeColors.navInactive,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
