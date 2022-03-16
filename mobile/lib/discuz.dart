import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:fluro/fluro.dart';
import 'package:provider/provider.dart';

import 'package:discuzq/utils/buildInfo.dart';
import 'package:discuzq/utils/global.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/views/accountDelegate.dart';
import 'package:discuzq/views/forumDelegate.dart';
import 'package:discuzq/widgets/bottomNavigator/bottomNavigator.dart';
import 'package:discuzq/views/notificationsDelegate.dart';
import 'package:discuzq/api/forum.dart';
import 'package:discuzq/router/routers.dart';
import 'package:discuzq/views/exploreDelagate.dart';
import 'package:discuzq/providers/appConfigProvider.dart';
import 'package:discuzq/widgets/settings/privacyConfirm.dart';

import 'widgets/ui/ui.dart';

class Discuz extends StatefulWidget {
  const Discuz({Key key}) : super(key: key);

  @override
  _DiscuzState createState() => _DiscuzState();
}

class _DiscuzState extends State<Discuz> {
  _DiscuzState() {
    final router = FluroRouter();
    Routers.configureRoutes(router);
    Routers.router = router;
  }

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
        builder: (BuildContext context, AppConfigProvider conf, Widget child) {
      debugPrint('---------APP WIDGET TREE HAS BEEN REBUILT--------');
      return DiscuzApp(
          theme: _buildTheme(conf),
          child: Builder(
            builder: (BuildContext context) {
              /// 生成故事与DiscuzApp一致
              final ThemeData _themeData = ThemeData(
                  primaryColor: DiscuzApp.themeOf(context).primaryColor,
                  backgroundColor: DiscuzApp.themeOf(context).backgroundColor,
                  scaffoldBackgroundColor:
                      DiscuzApp.themeOf(context).scaffoldBackgroundColor,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent);

              return MaterialApp(
                  title: Global.appname,
                  theme: _themeData,
                  debugShowCheckedModeBanner:
                      BuildInfo().info().debugShowCheckedModeBanner,

                  /// 如果用户在Build.yaml禁止了这项，这直接不要允许开启
                  showPerformanceOverlay:
                      BuildInfo().info().enablePerformanceOverlay
                          ? conf.appConf['showPerformanceOverlay']
                          : false,
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate
                  ],
                  supportedLocales: [
                    const Locale('zh', 'CH'),
                    const Locale('en', 'US'),
                  ],
                  localeResolutionCallback:
                      (Locale locale, Iterable<Locale> supportedLocales) {
                    //print("change language");
                    return locale;
                  },
                  onGenerateRoute: (RouteSettings settings) =>
                      MaterialWithModalsPageRoute(
                          builder: (_) => Builder(

                                  /// 不在 MaterialApp 使用theme属性
                                  /// 这里rebuild的时候会有问题，所以使用Theme去包裹
                                  /// 其实在MaterialApp里直接用theme也可以，但是flutter rebuild的时候有BUG， scaffoldBackgroundColor并未更新
                                  /// 这样会造成黑暗模式切换时有问题
                                  /// https://github.com/lukepighetti/fluro/blob/master/example/lib/components/app/app_component.dart
                                  builder: (BuildContext context) {
                                /// 初始化Fluro路由
                                Routers.router.generator(settings);
                                return const AppMediaQueryManager(
                                    child: const _DiscuzAppDelegate());
                              }),
                          settings: settings));
            },
          ));
    });
  }

  // build discuz app theme
  DiscuzTheme _buildTheme(dynamic conf) => conf.appConf['darkTheme']
      ? DiscuzTheme(
          primaryColor: Color(conf.appConf['themeColor']),
          textColor: Global.textColorDark,
          greyTextColor: Global.greyTextColorDark,
          scaffoldBackgroundColor: Global.scaffoldBackgroundColorDark,
          backgroundColor: Global.backgroundColorDark,
          brightness: Brightness.dark)
      : DiscuzTheme(
          primaryColor: Color(conf.appConf['themeColor']),
        );
}

/// 统一的字体管理
/// 防止用户设置导致的字体大小不一致的问题
class AppMediaQueryManager extends StatelessWidget {
  const AppMediaQueryManager({this.child}) : assert(child != null);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(boldText: false, textScaleFactor: 1),
      child: child,
    );
  }
}

///
/// 这里相当于一个Tabbar，托管了一些顶级页面的views
/// 并包含bottom navigator，全局的drawer等
///
///
class _DiscuzAppDelegate extends StatefulWidget {
  const _DiscuzAppDelegate({Key key}) : super(key: key);
  @override
  __DiscuzAppDelegateState createState() => __DiscuzAppDelegateState();
}

class __DiscuzAppDelegateState extends State<_DiscuzAppDelegate> {
  final CancelToken _cancelToken = CancelToken();

  final PageController _pageController = PageController();

  /// 页面集合
  static const List<Widget> _views = [
    const ForumDelegate(),
    ExploreDelegate(),
    const SizedBox(),

    /// 发布按钮占位
    const NotificationsDelegate(),
    const AccountDelegate()
  ];

  /// 底部按钮菜单
  final List<NavigatorItem> _items = [
    const NavigatorItem(icon: 0xe78f),
    const NavigatorItem(icon: 0xe605, size: 27),//, shouldLogin: true),
    const NavigatorItem(isPublishButton: true),
    const NavigatorItem(icon: 0xe604, size: 23),// shouldLogin: true),
    const NavigatorItem(icon: 0xe7c7, size: 22),//, shouldLogin: true)
  ];

  /// 使用global key
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  /// _loaded means user forum api already requested! not means success or fail to load data
  bool _loaded = false;

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    this._getForumData();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<AppConfigProvider>(builder:
          (BuildContext context, AppConfigProvider conf, Widget child) {
        if (conf.appConf != null && conf.appConf['confrimedPrivacy'] == false) {
          return const PrivacyConfirm();
        }

        return Theme(
          data: Theme.of(context).copyWith(
              // This makes the visual density adapt to the platform that you run
              // the app on. For desktop platforms, the controls will be smaller and
              // closer together (more dense) than on mobile platforms.
              visualDensity: VisualDensity.adaptivePlatformDensity,
              primaryColor: DiscuzApp.themeOf(context).primaryColor,
              backgroundColor: DiscuzApp.themeOf(context).backgroundColor,
              //platform: TargetPlatform.iOS,
              scaffoldBackgroundColor:
                  DiscuzApp.themeOf(context).scaffoldBackgroundColor,
              canvasColor: DiscuzApp.themeOf(context).scaffoldBackgroundColor),
          child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: true,
            body: PageView(
              controller: _pageController,
              children: _views,
              physics: const NeverScrollableScrollPhysics(),
            ),
            // resizeToAvoidBottomPadding: true,
            bottomNavigationBar: DiscuzBottomNavigator(
              items: _items,
              onItemSelected: (index) {
                _pageController.jumpToPage(index);
              },
            ),
          ),
        );
      });

  /// 获取论坛启动信息
  /// force 为true时，会忽略_loaded
  /// 如果在初始化的时候将loaded设置为true, 则会导致infinite loop
  Future<void> _getForumData({bool force = false}) async {
    /// 避免重复加载
    if (_loaded && !force) {
      return;
    }

    await ForumAPI(context).getForum(_cancelToken);

    /// 加载完了就可以将_loaded 设置为true了其实，因为_loaded只做是否请求过得判断依据
    setState(() {
      _loaded = true;
    });
  }
}
