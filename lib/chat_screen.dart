
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

import 'chat_controller.dart';
import 'chat_widgets/chat_widget.dart';
import 'chat_widgets/text_widget.dart';
import 'model/chat_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatController = Get.put(ChatController());

  bool _isTyping = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: chatController.getChatList.isEmpty
                  ? Center(
                  child:ClipRRect(
                    borderRadius: BorderRadius.circular(200), // Adjust the value as needed
                    child: Image.asset('assets/jago.gif'),
                  )

              )
                  : ListView.builder(
                  controller: _listScrollController,
                  itemCount: chatController.getChatList.length, //chatList.length,
                  itemBuilder: (context, index) {
                    return ChatWidget(
                      msg: chatController
                          .getChatList[index].msg, // chatList[index].msg,
                      chatIndex: chatController.getChatList[index]
                          .chatIndex, //chatList[index].chatIndex,
                      shouldAnimate:
                      chatController.getChatList.length - 1 == index,
                    );
                  }),
            ),
            if (_isTyping) ...[
              const SpinKitThreeBounce(
                color: Colors.black,
                size: 18,
              ),
            ],
            const SizedBox(
              height: 15,
            ),
            Material(
              color: Theme.of(context).indicatorColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.black,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.black),
                        controller: textEditingController,
                        onSubmitted: (value) async {
                          await sendMessageFCT(
                            modelsProvider: chatController,);
                        },
                        decoration: const InputDecoration.collapsed(
                            hintText: "How can I help you",
                            hintStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    IconButton(
                        onPressed: () async {
                          await sendMessageFCT(
                            modelsProvider: chatController,
                          );
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.black,
                        ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ChatController modelsProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
          content: ChatTextWidget(
            label: "You cant send multiple messages at a time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: ChatTextWidget(
      //       label: "Please type a message",
      //     ),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatController.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatController.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: ChatTextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTyping = false;
      });
    }
  }
}
