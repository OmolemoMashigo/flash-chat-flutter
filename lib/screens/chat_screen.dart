import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "chat";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgTxtController =
      TextEditingController(); //controller to clear text field after sending message

  final _auth = FirebaseAuth.instance;

  String messageText = "";

  @override
  void initState() {
    // TODO: implement initState
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        loggedInUser = currentUser;
        print(loggedInUser?.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessages() async {
    final messages = await _firestore.collection("messages").get();

    for (var message in messages.docs) {
      print(message.data());
    }
  }

  void getInstantMsg() async {
    await for (var snapshot in _firestore.collection("messages").snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                // _auth.signOut();
                // Navigator.pop(context);
                getInstantMsg();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: msgTxtController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //Implement send functionality.
                      msgTxtController.clear(); //clears text in text field
                      _firestore.collection("messages").add(
                          {"text": messageText, "sender": loggedInUser?.email});
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("messages").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        final messages = snapshot.data?.docs
            .reversed; //show the list of messages in a reversed order
        List<MessageBubble> messageWidgets = [];

        for (var message in messages!) {
          final msgText = message.get("text");
          final msgSender = message.get("sender");

          final currentUser = loggedInUser
              ?.email; //to compare if the message was sent from the logged in user or another user

          // if (currentUser == msgSender) {
          //   //then message is sent from logged in user
          // }

          final msgWidget = MessageBubble(
            text: msgText,
            sender: msgSender,
            isMe: currentUser == msgSender,
          );
          messageWidgets.add(msgWidget);
        }

        return Expanded(
          child: ListView(
            reverse: true, //makes ListView stick to the bottom of the view
            children: messageWidgets,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  String text;
  String sender;
  bool isMe;

  MessageBubble({required this.text, required this.sender, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Material(
            borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(30) : Radius.circular(0),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
                topRight: isMe ? Radius.circular(0) : Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                "$text",
                style: TextStyle(
                    fontSize: 20, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
