import 'package:flutter/material.dart';
import 'dart:developer';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

// TextWidget
class _TutorialScreenState extends State<TutorialScreen> {
  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
        body: Text(
            "Styled Text is large so it will possibly take a line or two!",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 20,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
                letterSpacing: 2,
                wordSpacing: 4)),
      ),
    );
  }
}

// Container Widget
class TutorialScreen2 extends StatefulWidget {
  const TutorialScreen2({super.key});

  @override
  State<TutorialScreen2> createState() => _TutorialScreen2State();
}

class _TutorialScreen2State extends State<TutorialScreen2> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: GestureDetector(
      onTap: () {
        log("Button Clicked!");
      },
      child: Container(
          height: 50,
          width: 200,
          padding: const EdgeInsets.only(top: 15, left: 50, right: 10),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.grey, blurRadius: 5, offset: Offset(2, 2))
            ],
          ),
          child: const Text("Login Button")),
    )));
  }
}

// Row and Column Widget | Expanded Widget | Flex Layout
class TutorialScreen3 extends StatefulWidget {
  const TutorialScreen3({super.key});

  @override
  State<TutorialScreen3> createState() => _TutorialScreen3State();
}

class _TutorialScreen3State extends State<TutorialScreen3> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: () {},
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 200,
                      // transform: Matrix4.rotationY(.2),
                      // margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 1),
                        boxShadow: const [BoxShadow(color: Colors.black26)],
                      ),
                      child: const Center(child: Text("Login Button")),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 200,
                      // transform: Matrix4.rotationY(.2),
                      // margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 1),
                        boxShadow: const [BoxShadow(color: Colors.black26)],
                      ),
                      child: const Center(child: Text("Login Button")),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 200,
                      // transform: Matrix4.rotationY(.2),
                      // margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 1),
                        boxShadow: const [BoxShadow(color: Colors.black26)],
                      ),
                      child: const Center(child: Text("Login Button")),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CircleAvatar Widget | SizedBox and Divider Widget
class TutorialScreen4 extends StatefulWidget {
  const TutorialScreen4({super.key});

  @override
  State<TutorialScreen4> createState() => _TutorialScreen4State();
}

class _TutorialScreen4State extends State<TutorialScreen4> {
  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                minRadius: 50,
                maxRadius: 100,
                backgroundColor: Colors.amber,
                backgroundImage: NetworkImage(
                    "https://thumbs.dreamstime.com/b/cartoon-small-red-hair-blond-boy-vector-illustration-young-teenager-outlined-boy-head-icon-96500463.jpg"),
              ),
            ),
            SizedBox(
              height: 100,
            ),
            Divider(
              color: Colors.black,
              thickness: 2,
              height: 2,
            ),
            SizedBox(
              height: 100,
            ),
            Center(
              child: CircleAvatar(
                minRadius: 50,
                maxRadius: 100,
                backgroundColor: Colors.amber,
                backgroundImage: NetworkImage(
                    "https://thumbs.dreamstime.com/b/cartoon-small-red-hair-blond-boy-vector-illustration-young-teenager-outlined-boy-head-icon-96500463.jpg"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TextField and TextFormField Widget
class TutorialScreen5 extends StatefulWidget {
  const TutorialScreen5({super.key});

  @override
  State<TutorialScreen5> createState() => _TutorialScreen5State();
}

class _TutorialScreen5State extends State<TutorialScreen5> {
  TextEditingController userController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: userController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Enter your email",
                  hintText: "Enter your email",
                  border: OutlineInputBorder(),
                  prefix: Icon(Icons.person),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stack Widget | Alignment Widget
class TutorialScreen6 extends StatefulWidget {
  const TutorialScreen6({super.key});

  @override
  State<TutorialScreen6> createState() => _TutorialScreen6State();
}

class _TutorialScreen6State extends State<TutorialScreen6> {
  TextEditingController userController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  color: Colors.amber,
                ),
                Container(
                  height: 50,
                  width: 50,
                  color: Colors.blue,
                ),
                const Text("Hello"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ListTile Widget
class TutorialScreen7 extends StatefulWidget {
  const TutorialScreen7({super.key});

  @override
  State<TutorialScreen7> createState() => _TutorialScreen7State();
}

class _TutorialScreen7State extends State<TutorialScreen7> {
  TextEditingController userController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              title: const Text("User Profile"),
              subtitle: const Text("View or Edit User Profile"),
              leading: const CircleAvatar(
                backgroundImage: NetworkImage(
                    "https://thumbs.dreamstime.com/b/cartoon-small-red-hair-blond-boy-vector-illustration-young-teenager-outlined-boy-head-icon-96500463.jpg"),
              ),
              trailing: const Icon(Icons.fork_right),
              onTap: () {},
            )
          ],
        ),
      ),
    );
  }
}

// ListView Widget | ListView.builder Widget
class TutorialScreen8 extends StatefulWidget {
  const TutorialScreen8({super.key});

  @override
  State<TutorialScreen8> createState() => _TutorialScreen8State();
}

class _TutorialScreen8State extends State<TutorialScreen8> {
  List<String> list = ["John", "James", "Justine", "Bola", "Kemi", "Mawuli"];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    // title: const Text("User Profile"),
                    title: Text(list[index]),
                    subtitle: const Text("View or Edit User Profile"),
                    leading: const CircleAvatar(
                      backgroundImage: NetworkImage(
                          "https://thumbs.dreamstime.com/b/cartoon-small-red-hair-blond-boy-vector-illustration-young-teenager-outlined-boy-head-icon-96500463.jpg"),
                    ),
                    trailing: const Icon(Icons.fork_right),
                    onTap: () {},
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Image Widget | Image.asset Widget | Image.network Widget
class TutorialScreen9 extends StatefulWidget {
  const TutorialScreen9({super.key});

  @override
  State<TutorialScreen9> createState() => _TutorialScreen9State();
}

class _TutorialScreen9State extends State<TutorialScreen9> {
  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/images/girl_icon.png");
  }
}
