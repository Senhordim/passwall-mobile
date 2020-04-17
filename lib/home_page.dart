import 'package:Passwall/antenna.dart';
import 'package:Passwall/detail_page.dart';
import 'package:Passwall/login_page.dart';
import 'package:Passwall/objects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Credential>> future;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    future = Antenna().getCredentials();
  }

  Future<void> refresh() async {
    await Future.delayed(Duration(milliseconds: 400));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (searchQuery == "") {
      future = Antenna().getCredentials();
    } else {
      future = Antenna().search(searchQuery);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("PassWall"),
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 0,
                child: Text("Log Out"),
              )
            ],
            onSelected: (value) async {
              switch (value) {
                case 0:
                  {
                    print("Loging out");
                    SharedPreferences preferences = await SharedPreferences.getInstance();
                    preferences.remove("token");
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => new LoginPage()));
                  }
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Column(
          children: <Widget>[
            TextField(
              autocorrect: false,
              decoration: InputDecoration(prefixIcon: Icon(Icons.search)),
              onChanged: (text) {
                setState(() {
                  searchQuery = text;
                });
              },
            ),
            FutureBuilder(
              future: future,
              builder: (BuildContext context, AsyncSnapshot<List<Credential>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        if (snapshot.data.length == 0) {
                          //TODO: Test no data situation. Bus Stop
                          return Center(child: Text("No Data"));
                        } else {
                          return Dismissible(
                            key: UniqueKey(),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 28, 0),
                                child: Icon(
                                  Icons.delete_sweep,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            onDismissed: (direction) async {
                              await Antenna().deleteCredential(snapshot.data[index].id);
                            },
                            //TODO: Confirm dismiss or Toast bar Undo
                            child: Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(snapshot.data[index])));
                                },
                                title: Text(snapshot.data[index].url),
                                subtitle: Text(snapshot.data[index].username),
                                trailing: PopupMenuButton(
                                  icon: Icon(Icons.more_vert),
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Text("Copy Username"),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Text("Copy Password"),
                                    )
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 0:
                                        {
                                          Clipboard.setData(ClipboardData(text: snapshot.data[index].username));
                                          print("Username copied to Clipboard: " + snapshot.data[index].username);
                                          break;
                                        }
                                      case 1:
                                        {
                                          Clipboard.setData(ClipboardData(text: snapshot.data[index].password));
                                          print("Password copied to Clipboard: " + snapshot.data[index].password);
                                          break;
                                        }
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: creator,
      ),
    );
  }

  void creator() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = "";
        String username = "";
        String password = "";
        return AlertDialog(
          title: Text("Create new credential"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                autocorrect: false,
                decoration: InputDecoration(labelText: "Title", hintText: "http://passwall.io"),
                onChanged: (text) {
                  title = text;
                },
              ),
              TextField(
                autocorrect: false,
                decoration: InputDecoration(labelText: "Username"),
                onChanged: (text) {
                  username = text;
                },
              ),
              TextField(
                autocorrect: false,
                decoration: InputDecoration(labelText: "Password", helperText: "Leave blank for a random password"),
                onChanged: (text) {
                  password = text;
                },
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("CANCEL"),
              textColor: Colors.red,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("SAVE"),
              onPressed: () async {
                await Antenna().create(title: title, username: username, password: password);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
