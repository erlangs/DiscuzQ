import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as extended;

import 'package:discuzq/router/route.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/appbar/appbarExt.dart';
import 'package:discuzq/widgets/common/discuzListTile.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/utils/authHelper.dart';
import 'package:discuzq/widgets/users/yetNotLogon.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/views/users/profileDelegate.dart';
import 'package:discuzq/views/users/myCollectionDelegate.dart';
import 'package:discuzq/views/users/follows/followingDelegate.dart';
import 'package:discuzq/widgets/common/discuzDialog.dart';
import 'package:discuzq/utils/global.dart';
import 'package:discuzq/views/users/blackListDelegate.dart';
import 'package:discuzq/widgets/users/userAccountBanner.dart';
import 'package:discuzq/router/routers.dart';
import 'package:discuzq/providers/userProvider.dart';
import 'package:discuzq/widgets/common/discuzButton.dart';

class AccountDelegate extends StatefulWidget {
  const AccountDelegate({Key key}) : super(key: key);
  @override
  _AccountDelegateState createState() => _AccountDelegateState();
}

class _AccountDelegateState extends State<AccountDelegate> {
  final List<_AccountMenuItem> _menus = [
    const _AccountMenuItem(
        label: '我的资料', icon: 0xe78e, child: const ProfileDelegate()),
    // const _AccountMenuItem(
    //     label: '我的钱包',
    //     icon: CupertinoIcons.money_yen_circle,
    //     child: const WalletDelegate()),
    const _AccountMenuItem(
        label: '我的收藏', icon: 0xe7b7, child: const MyCollectionDelegate()),
    const _AccountMenuItem(
        label: '我的关注', icon: 0xe7aa, child: const FollowingDelegate()),
    const _AccountMenuItem(
        label: '屏蔽/黑名单', icon: 0xe7d7, child: const BlackListDelegate()),
  ];

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
  Widget build(BuildContext context) => Consumer<UserProvider>(
      builder: (BuildContext context, UserProvider user, Widget child) =>
          Scaffold(
            body: NestedScrollView(
              // pinnedHeaderSliverHeightBuilder: () {
              //   return MediaQuery.of(context).padding.top;
              // },
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  DiscuzSliverAppBar(
                    title: "个人中心",
                    elevation: 10,
                    actions: [const _SettingButton()],
                    expandedHeight: 0,
                    brightness: Brightness.light,
                    backgroundColor: DiscuzApp.themeOf(context).backgroundColor,
                    floating: true,
                    stretch: true,
                  ),
                ];
              },
              body: user.user == null
                  ? const YetNotLogon()
                  : ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: <Widget>[
                        /// 构造登录信息页
                        const UserAccountBanner(),

                        /// 菜单构造

                        Container(
                          margin: const EdgeInsets.only(
                              top: 20, left: 10, right: 10),
                          child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                              child: Column(
                                children: _buildMenus(),
                              )),
                        ),

                        const Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 20),
                            child: const _LogoutButton())
                      ],
                    ),
            ),
          ));

  ///
  /// 生成个人中心滑动菜单
  ///
  List<Widget> _buildMenus() => _menus
      .map((el) => Container(
            decoration: BoxDecoration(
                border: const Border(bottom: Global.border),
                color: DiscuzApp.themeOf(context).backgroundColor),
            child: Column(
              children: <Widget>[
                DiscuzListTile(
                  title: DiscuzText(el.label),
                  leading: DiscuzIcon(
                    el.icon,
                    size: 28,
                  ),

                  /// 如果item中设置了运行相关的方法，则运行相关的方法，如果有child的话则在路由中打开
                  onTap: () => el.method != null
                      ? el.method(context: context)
                      : el.child == null
                          ? DiscuzToast.failed(
                              context: context, message: '暂时不支持')
                          : DiscuzRoute.navigate(
                              context: context, widget: el.child),
                ),
              ],
            ),
          ))
      .toList();
}

/// 退出按钮
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();
  @override
  Widget build(BuildContext context) {
    return DiscuzButton(
      label: "退出",
      onPressed: () async => await showDialog(
          context: context,
          builder: (BuildContext context) {
            return DiscuzDialog(
                title: '提示',
                message: '是否退出登录？',
                isCancel: true,
                onConfirm: () => AuthHelper.logout(context: context));
            }
    ),
    );
  }
}

///
/// 设置按钮
class _SettingButton extends StatelessWidget {
  const _SettingButton();

  @override
  Widget build(BuildContext context) => IconButton(
        icon: DiscuzIcon(0xe7f7,
            size: 30, color: DiscuzApp.themeOf(context).textColor),
        onPressed: () => DiscuzRoute.navigate(
          context: context,
          path: Routers.preferences,
        ),
      );
}

/// 菜单列表
class _AccountMenuItem {
  /// 标签
  final String label;

  /// 路由跳转
  final Widget child;

  /// 图标
  final dynamic icon;

  /// 函数
  final Function method;

  /// 显示分割线
  final bool showDivider;

  const _AccountMenuItem(
      {@required this.label,
      @required this.icon,
      this.method,
      this.showDivider = true,
      this.child});
}
