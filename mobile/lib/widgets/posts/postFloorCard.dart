import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:discuzq/models/userModel.dart';
import 'package:discuzq/router/route.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/utils/dateUtil.dart';
import 'package:discuzq/views/users/userHomeDelegate.dart';
import 'package:discuzq/widgets/common/discuzAvatar.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/models/attachmentsModel.dart';
import 'package:discuzq/models/postModel.dart';
import 'package:discuzq/widgets/htmRender/htmlRender.dart';
import 'package:discuzq/widgets/threads/threadsCacher.dart';
import 'package:discuzq/widgets/users/userLink.dart';
import 'package:discuzq/widgets/posts/postLikeButton.dart';
import 'package:discuzq/widgets/common/discuzImage.dart';
import 'package:discuzq/views/gallery/discuzGalleryDelegate.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/common/discuzDialog.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/api/posts.dart';
import 'package:discuzq/widgets/editor/discuzEditorHelper.dart';
import 'package:discuzq/widgets/editor/discuzEditorRequestResult.dart';
import 'package:discuzq/views/reports/reportsDelegate.dart';

class PostFloorCard extends StatefulWidget {
  ///
  /// 关联的用户
  final PostModel post;

  ///
  ///
  final ThreadsCacher threadsCacher;

  ///
  /// 故事模型
  final ThreadModel thread;

  ///
  /// 被删除
  ///
  final Function onDelete;

  const PostFloorCard(
      {@required this.post,
      @required this.threadsCacher,
      @required this.thread,
      this.onDelete});

  @override
  _PostFloorCardState createState() => _PostFloorCardState();
}

class _PostFloorCardState extends State<PostFloorCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// dio
  final CancelToken _cancelToken = CancelToken();

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ///
    /// post.relationships.user会存在为null的情况，这是因为数据中存在fistPost,但这不是一个回复
    ///
    if (widget.post.relationships.user == null) {
      return const SizedBox();
    }

    final List<UserModel> user = widget.threadsCacher.users
        .where((UserModel u) =>
            u.id == int.tryParse(widget.post.relationships.user['data']['id']))
        .toList();

    final List<UserModel> replyUser = widget.threadsCacher.users
        .where((UserModel u) => u.id == widget.post.attributes.replyUserID)
        .toList();

    /// 遍历图片
    final List<dynamic> getPostImages = widget.post.relationships.images;
    List<AttachmentsModel> attachmentsModels = [];
    if (getPostImages.length > 0) {
      getPostImages.forEach((e) {
        final int id = int.tryParse(e['id']);
        final AttachmentsModel attachment = widget.threadsCacher.attachments
            .where((AttachmentsModel find) => find.id == id)
            .toList()[0];
        if (attachment != null) {
          attachmentsModels.add(attachment);
        }
      });
    }

    ///
    /// 找不到相关用户
    if (user.length == 0 || user == null) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(left: 5, right: 5, top: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: DiscuzApp.themeOf(context).backgroundColor,
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ///
          /// 用户顶部信息
          _buildHeader(
              context: context,
              user: user[0],
              replyUser: replyUser == null || replyUser.length == 0
                  ? null
                  : replyUser[0]),

          const SizedBox(height: 10),

          ///
          /// 显示评论的内容
           Padding(
        padding: const EdgeInsets.only(left: 5, top: 5),
          child: HtmlRender(
            html: widget.post.attributes.contentHtml,
          ),),

          /// 显示图片
          ...attachmentsModels
              .map((AttachmentsModel a) => Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: DiscuzImage(
                        attachment: a,
                        enbleShare: true,
                        isThumb: false,
                        thread: widget.thread,
                        onWantOriginalImage: (String targetUrl) {
                          /// 显示原图图集
                          /// targetUrl是用户点击到的要查看的图片
                          /// 调整数组，将targetUrl置于第一个，然后传入图集组件
                          ///
                          /// 原图所有图片Url 图集
                          final List<String> originalImageUrls =
                              attachmentsModels
                                  .map((e) => e.attributes.url)
                                  .toList();

                          /// 显示原图图集
                          /// targetUrl是用户点击到的要查看的图片
                          /// 调整数组，将targetUrl置于第一个，然后传入图集组件
                          originalImageUrls.remove(a.attributes.url);
                          originalImageUrls.insert(0, a.attributes.url);
                          return DiscuzRoute.navigate(
                              context: context,
                              fullscreenDialog: true,
                              widget: DiscuzGalleryDelegate(
                                  gallery: originalImageUrls));
                        }),
                  ))
              .toList(),

          ///
          /// 显示评论的附件
          const SizedBox(height: 10),

          Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ///
                /// 显示点赞按钮
                ///
                PostLikeButton(
                  post: widget.post,
                ),

                IconButton(
                  padding: EdgeInsets.zero,
                  icon: DiscuzIcon(
                    0xe624,
                    size: 23,
                    color: DiscuzApp.themeOf(context).textColor,
                  ),
                  onPressed: () async {
                    final DiscuzEditorRequestResult res =
                        await DiscuzEditorHelper(context: context).reply(
                            post: widget.post,
                            thread: widget.thread,
                            isFirstPost: false);
                    if (res != null) {
                      widget.threadsCacher.posts = res.posts;
                      widget.threadsCacher.users = res.users;
                      DiscuzToast.toast(context: context, message: '回复成功');
                    }
                  },
                ),

                IconButton(
                  padding: const EdgeInsets.only(top: 2),
                  icon: const DiscuzIcon(
                    0xe77f,
                    size: 30,
                  ),
                  onPressed: () async {
                    List<SheetAction<String>> actions = [
                      // const SheetAction(
                      //   icon: Icons.info,
                      //   label: '回复',
                      //   key: 'reply',
                      // ),
                      const SheetAction(
                        icon: Icons.flag,
                        label: '举报',
                        key: 'report',
                      ),
                    ];

                    if (widget.post.attributes.canEdit) {
                      actions.add(const SheetAction(
                          icon: Icons.delete,
                          label: '删除',
                          key: 'delete',
                          isDestructiveAction: true));
                    }

                    final result = await showModalActionSheet<String>(
                      context: context,
                      title: '更多操作',
                      cancelLabel: "取消",
                      actions: actions,
                    );

                    if (result == "delete") {
                      await showDialog(
                          context: context,
                      builder: (BuildContext context) {
                        return DiscuzDialog(
                              title: '提示',
                              message: '是否删除评论？',
                              isCancel: true,
                              onConfirm: () async {
                                final bool result =
                                    await PostsAPI(context: context).delete(
                                        _cancelToken,
                                        postID: widget.post.id);
                                if (result && widget.onDelete != null) {
                                  /// 删除成功，隐藏该项目
                                  widget.onDelete();
                                }
                              });}
                      );
                      return;
                    }

                    if (result == "reply") {
                      final DiscuzEditorRequestResult res =
                          await DiscuzEditorHelper(context: context).reply(
                              post: widget.post,
                              thread: widget.thread,
                              isFirstPost: false);
                      if (res != null) {
                        widget.threadsCacher.posts = res.posts;
                        widget.threadsCacher.users = res.users;
                        DiscuzToast.toast(context: context, message: '回复成功');
                      }

                      return;
                    }

                    if (result == "report") {
                      DiscuzRoute.navigate(
                        context: context,
                        shouldLogin: true,
                        fullscreenDialog: true,
                        widget: Builder(
                          builder: (context) => ReportsDelegate(
                              type: ReportType.thread, post: widget.post),
                        ),
                      );
                      return;
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  /// 用户顶部
  Widget _buildHeader(
          {BuildContext context,
          @required UserModel user,
          UserModel replyUser}) =>
      Padding(
        padding: const EdgeInsets.only(left: 5, top: 5),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () => DiscuzRoute.navigate(
                context: context,
                shouldLogin: true,
                widget: UserHomeDelegate(
                  user: user,
                )),
            child: DiscuzAvatar(
              size: 35,
              url: user.attributes.avatarUrl,
            ),
          ),

          /// userinfo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(children: <Widget>[
                    DiscuzText(
                      user.attributes.username,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),

                    /// 显示回复给谁
                    replyUser == null
                        ? const SizedBox()
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(width: 5),
                              DiscuzText(
                                '回复',
                                overflow: TextOverflow.ellipsis,
                                color: DiscuzApp.themeOf(context).greyTextColor,
                              ),
                              UserLink(user: replyUser)
                            ],
                          ),
                  ]),
                  DiscuzText(
                    ///
                    /// 格式化时间
                    DateUtil.formatDate(
                        DateTime.parse(widget.post.attributes.createdAt)
                            .toLocal(),
                        format: "yyyy-MM-dd HH:mm"),
                    color: DiscuzApp.themeOf(context).greyTextColor,
                    fontSize: DiscuzApp.themeOf(context).smallTextSize,
                  )
                ],
              ),

              /// pop menu
            ),
          ),
        ],
      ));
}
