import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

import 'package:discuzq/ui/ui.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/common/discuzLogo.dart';
import 'package:discuzq/widgets/forum/floatLoginButton.dart';
import 'package:discuzq/utils/global.dart';
import 'package:discuzq/widgets/appbar/appbar.dart';
import 'package:discuzq/widgets/appbar/nightModeSwitcher.dart';
import 'package:discuzq/models/appModel.dart';
import 'package:discuzq/widgets/common/discuzNetworkError.dart';
import 'package:discuzq/widgets/forum/bootstrapForum.dart';

/// 论坛首页
class ForumDelegate extends StatefulWidget {
  const ForumDelegate({Key key}) : super(key: key);

  @override
  _ForumDelegateState createState() => _ForumDelegateState();
}

class _ForumDelegateState extends State<ForumDelegate> {
  /// states
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
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    this._getForumData();
  }

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<AppModel>(
      rebuildOnChange: false,
      builder: (context, child, model) => Scaffold(
            appBar: DiscuzAppBar(
              elevation: 10,
              centerTitle: true,
              leading: const NightModeSwitcher(),
              title: const Center(
                  child: const DiscuzAppLogo(
                color: Colors.transparent,
              )),
              actions: _actions(context),
            ),
            drawerEdgeDragWidth: Global.drawerEdgeDragWidth,
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                /// 是否显示网络错误组件
                _buildNetwordError(model),

                /// 显示论坛帖子

                /// 显示底部悬浮登录提示组件
                Positioned(
                  bottom: 20,
                  width: MediaQuery.of(context).size.width,
                  child: const FloatLoginButton(),
                )
              ],
            ),
          ));

  /// 创建网络错误提示组件，尽在加载失败的时候提示
  Widget _buildNetwordError(AppModel model) => _loaded && model.forum == null
      ? const SizedBox()
      : Center(
          child: DiscuzNetworkError(
            onRequestRefresh: () => _getForumData(force: true),
          ),
        );

  /// forum actions
  List<Widget> _actions(BuildContext context) => [
        Row(
          children: <Widget>[
            // 搜索
            IconButton(
              icon: DiscuzIcon(
                SFSymbols.plus,
                color: DiscuzApp.themeOf(context).textColor,
              ),
              onPressed: () => null,
            ),
            // 弹出菜单
          ],
        )
      ];

  /// 获取论坛启动信息
  /// force 为true时，会忽略_loaded
  /// 如果在初始化的时候将loaded设置为true, 则会导致infinite loop
  Future<void> _getForumData({bool force = false}) async {
    /// 避免重复加载
    if (_loaded && !force) {
      return;
    }

    final bool result = await BootstrapForum(context).getForum();
    if (result) {
      setState(() {
        _loaded = result;
      });
    }
  }
}
