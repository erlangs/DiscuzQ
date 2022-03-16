import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:md2_tab_indicator/md2_tab_indicator.dart';
import 'package:provider/provider.dart';

import 'package:discuzq/widgets/appbar/appbarExt.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/forum/forumCategoryFilter.dart';
import 'package:discuzq/models/categoryModel.dart';
import 'package:discuzq/widgets/skeleton/discuzSkeleton.dart';
import 'package:discuzq/widgets/threads/theadsList.dart';
import 'package:discuzq/widgets/categories/discuzCategories.dart';
import 'package:discuzq/providers/categoriesProvider.dart';
import 'package:discuzq/widgets/search/searchActionButton.dart';
import 'package:discuzq/widgets/search/searchTypeItemsColumn.dart';
import 'package:discuzq/widgets/appbar/appbarLeadings.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as extended;

/// 注意：
/// 从我们的设计上来说，要加载了forum才显示这个组件，所以forum请求自然就在category之前
/// 这样做的目的是为了不要一次性请求过多，来尽量避免阻塞，所以在使用这个组件到其他地方渲染的时候，你也需要这样做
class ForumDelegate extends StatefulWidget {
  ///
  /// onAppbarState
  final Function onAppbarState;

  const ForumDelegate({Key key, this.onAppbarState}) : super(key: key);
  @override
  _ForumDelegateState createState() => _ForumDelegateState();
}

class _ForumDelegateState extends State<ForumDelegate>
    with SingleTickerProviderStateMixin {
  /// states
  /// tab controller
  TabController _tabController;

  /// _loading will be true when request categories, but not tell you success or failed to load
  /// default should be true, so that you can make a loading animation for users
  bool _loading = true;

  /// categories is empty
  bool _isEmptyCategories = false;

  /// 筛选条件状态
  ForumCategoryFilterItem _filterItem;

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

    /// 延迟加载
    this._getCategories().then((bool result) {
      if (result) {
        this._initTabController();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriesProvider>(
        builder: (BuildContext context, CategoriesProvider cats, Widget child) {
      /// 返回加载中的视图
      if (_loading) {
        return const DiscuzSkeleton();
      }

      /// 返回没有可用分类
      if (_isEmptyCategories) {
        const Center(child: const DiscuzText('暂无可用分类'));
      }

      final Widget _tabs = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DiscuzApp.themeOf(context).backgroundColor,
          ),
          child: TabBar(
              //生成Tab菜单
              controller: _tabController,
              labelStyle: TextStyle(
                //up to your taste
                fontSize: DiscuzApp.themeOf(context).mediumTextSize,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: DiscuzApp.themeOf(context).mediumTextSize,
                fontWeight: FontWeight.w600,
              ),
              indicatorSize: TabBarIndicatorSize.tab, //makes it better
              labelColor:
                  DiscuzApp.themeOf(context).textColor, //Google's sweet blue
              unselectedLabelColor: DiscuzApp.themeOf(context)
                  .textColor
                  .withOpacity(.68), //niceish grey
              isScrollable: true, //up to your taste
              indicatorPadding: const EdgeInsets.all(0),
              indicator: MD2Indicator(
                  //it begins here
                  indicatorHeight: 2,
                  indicatorColor: DiscuzApp.themeOf(context).primaryColor,
                  indicatorSize:
                      MD2IndicatorSize.tiny //3 different modes tiny-normal-full
                  ),
              tabs: cats.forumDelegateCategories
                  .map<Widget>(
                      (CategoryModel e) => Tab(text: e.attributes.name))
                  .toList()));

      /// 生成论坛分类和内容区域
      return Container();

      //   Scaffold(
      //     body: extended.NestedScrollView(
      //   pinnedHeaderSliverHeightBuilder: () {
      //     return MediaQuery.of(context).padding.top;
      //   },
      //   headerSliverBuilder: (context, innerBoxIsScrolled) {
      //     return <Widget>[
      //       DiscuzSliverAppBar(
      //         title: const LogoLeading(),
      //         elevation: 10,
      //         actions: [_actionButtons],
      //         centerTitle: false,
      //         expandedHeight: 0,
      //         bottom: PreferredSize(
      //           child: _tabs,
      //           preferredSize: const Size.fromHeight(45),
      //         ),
      //         brightness: Brightness.light,
      //         backgroundColor: DiscuzApp.themeOf(context).backgroundColor,
      //         floating: true,
      //         stretch: true,
      //       ),
      //     ];
      //   },
      //   body: Column(
      //     children: [
      //       Expanded(
      //           child: extended.NestedScrollViewInnerScrollPositionKeyWidget(
      //         const Key("tabKey"),
      //         ForumDelegateContent(
      //           controller: _tabController,
      //           filter: _filterItem,
      //           onAppbarState: widget.onAppbarState,
      //         ),
      //       ))
      //     ],
      //   ),
      // ));
    });
  }

  /// 搜索按钮
  Widget get _actionButtons => const DiscuzAppSearchActionButton(
        type: DiscuzAppSearchType.thread,
        dark: false,
      );

  /// 初始化 tab controller
  ///
  /// 该方法将会请求查询分类接口以构造一个 tabs 列表
  ///
  Future<void> _initTabController() async {
    try {
      final List<CategoryModel> categories =
          context.read<CategoriesProvider>().forumDelegateCategories;

      /// 没有分类
      if (categories == null || categories.length == 0) {
        setState(() {
          _isEmptyCategories = true;
        });
      }

      /// 初始化tabber
      _tabController = TabController(
          length: categories == null ? 0 : categories.length, vsync: this);
    } catch (e) {
      throw e;
    }
  }

  ///
  /// _getCategories
  /// force should never be true on didChangeDependencies life cycle
  /// that would make your ui rendering loop and looping to die
  ///
  /// 新逻辑： 先从本地缓存取得分类列表，如果本地存储了分类列表直接取出
  /// 如果没有缓存，那么还是向接口请求
  ///
  Future<bool> _getCategories() async {
    setState(() {
      _loading = true;
      _isEmptyCategories = false;
    });

    List<CategoryModel> categories =
        await DiscuzCategories(context: context).getCategories();

    categories.insert(
        0,
        const CategoryModel(
            attributes: const CategoryModelAttributes(
                name: '时下最新', canViewThreads: true)));
    categories.insert(
        1,
        const CategoryModel(
            attributes: const CategoryModelAttributes(
                name: '关注',
                canViewThreads: true,
                showOnlyFollowedUsers: true)));

    categories.removeWhere((element) => !element.attributes.canViewThreads);

    context.read<CategoriesProvider>().updateCategories(categories);

    setState(() {
      _loading = false;
    });

    ///
    /// 异步请求，不在乎结果，因为本地有可用数据
    _requestCategories();

    return Future.value(true);
  }

  /// request Categories Data
  ///
  Future<bool> _requestCategories() async {
    List<CategoryModel> categories =
        await DiscuzCategories(context: context).requestCategories();

    setState(() {
      _loading = false;
    });

    categories.insert(
        0,
        const CategoryModel(
            attributes: const CategoryModelAttributes(
                name: '时下最新', canViewThreads: true)));
    categories.insert(
        1,
        const CategoryModel(
            attributes: const CategoryModelAttributes(
                name: '关注',
                canViewThreads: true,
                showOnlyFollowedUsers: true)));
    categories.removeWhere((element) => !element.attributes.canViewThreads);

    /// 重新更新状态
    context.read<CategoriesProvider>().updateCategories(categories);

    return Future.value(true);
  }
}

///
///
/// 构造ThreadList列表
class ForumDelegateContent extends StatefulWidget {
  ///
  /// 滑动控制
  final TabController controller;

  ///
  /// 筛选器
  final ForumCategoryFilterItem filter;

  ///
  /// 状态变化
  final Function onAppbarState;

  ForumDelegateContent(
      {@required this.controller, @required this.filter, this.onAppbarState});

  @override
  _ForumDelegateContentState createState() => _ForumDelegateContentState();
}

class _ForumDelegateContentState extends State<ForumDelegateContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<CategoriesProvider>(
        builder: (BuildContext context, CategoriesProvider cats,
                Widget child) =>
            TabBarView(
              controller: widget.controller,
              //physics: const NeverScrollableScrollPhysics(),
              children: cats.forumDelegateCategories
                  .map<Widget>((CategoryModel cat) => ThreadsList(
                        category: cat,
                        onAppbarState: widget.onAppbarState,

                        /// 初始化的时候，用户没有选择，则默认使用第一个筛选条件
                        filter:
                            widget.filter ?? ForumCategoryFilter.conditions[0],
                      ))
                  .toList(),
            ));
  }
}
