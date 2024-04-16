import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'index.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseReference = FirebaseDatabase.instance.ref();

  String firstName = '';
  String lastName = '';
  String username = '';
  String bio = '';
  String university = '';
  int profilePic = 0;
  String course = '';
  List<Map<String, String>> friendsDetails = [];
  bool isEditingBio = false;
  bool isEditingName = false; // Flag to control editing of the name
  // TextEditingController nameController = TextEditingController();



  @override
  void initState() {
    super.initState();
    print("InitState Called");
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final userSnapshot = await databaseReference.child('Users/${user.uid}').get();
        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          setState(() {
            firstName = userData['firstName'] ?? '';
            lastName = userData['lastName'] ?? '';
            username = userData['username'] ?? '';
            bio = userData['bio'] ?? '';
            university = userData['university'] ?? '';
            course = userData['course'] ?? '';
            profilePic = userData['profilePic'] != null ? userData['profilePic'] : 0;

            if (userData.containsKey('friends')) {
              fetchFriendsDetails(userData['friends'] as Map<dynamic, dynamic>);
            }
          });
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }


  Future<void> fetchFriendsDetails(Map<dynamic, dynamic> friendsIds) async {
    List<Map<String, String>> fetchedFriendsDetails = [];
    for (String friendId in friendsIds.keys) {
      final friendSnapshot = await databaseReference.child('Users/$friendId')
          .get();
      if (friendSnapshot.exists) {
        final friendData = friendSnapshot.value as Map<dynamic, dynamic>;
        fetchedFriendsDetails.add({
          'id': friendId,
          'username': friendData['username'] ?? 'Unknown',
        });
      }
    }
    setState(() {
      friendsDetails = fetchedFriendsDetails;
    });
  }

  void updateNameInDatabase() {
    final user = _auth.currentUser;
    if (user != null) {
      databaseReference.child('Users/${user.uid}').update({
        'firstName': firstName,
        'lastName': lastName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xffad32fe),
        title: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => HomeScreen())),
          child: Row(
            children: [
              Image.asset('assets/logo.png', width: 28),
              SizedBox(width: 28),
              Text("Study Hive", style: TextStyle(fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 16,
                  color: Color(0xffffffff))),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => Setting())),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.settings),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Forums"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_box), label: "Profile"),
        ],
        onTap: (int index) {
          if (index == 0) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Forums()));
          } else if (index == 1) {
            // Handle Messages navigation
          } else if (index == 2) {
            // Handle Profile navigation
          }
        },
        backgroundColor: Color(0xffae32ff),
        selectedItemColor: Color(0xffffffff),
        unselectedItemColor: Color(0xffffffff),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(radius: 60,
                backgroundImage: AssetImage(getProfilePicturePath(profilePic))),
            SizedBox(height: 10),
            !isEditingName
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$firstName $lastName", style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: () => setState(() => isEditingName = true),
                ),
              ],
            ) :
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                        text: "$firstName $lastName"),
                    onChanged: (value) {
                      List<String> names = value.split(' ');
                      if (names.isNotEmpty) {
                        firstName = names.first;
                        lastName = names.length > 1
                            ? names.sublist(1).join(' ')
                            : '';
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Enter your full name",
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, size: 20),
                  onPressed: () {
                    setState(() => isEditingName = false);
                    updateNameInDatabase();
                  },
                ),
              ],
            ),
            Text(username, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileInfoBox(title: course, subtitle: "Subject"),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FriendsPopup(friendsDetails: friendsDetails),
                      ),
                    );
                  },
                  child: ProfileInfoBox(
                      title: "${friendsDetails.length} Friends", subtitle: ""),
                ),
                ProfileInfoBox(title: university, subtitle: "University"),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: isEditingBio
                            ? TextField(
                          controller: TextEditingController(text: bio),
                          onChanged: (value) => bio = value,
                          decoration: InputDecoration(
                            hintText: "Edit your bio",
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                        )
                            : Text(bio),
                      ),
                      IconButton(
                        icon: Icon(isEditingBio ? Icons.check : Icons.edit),
                        onPressed: () {
                          if (isEditingBio) {
                            final user = _auth.currentUser;
                            if (user != null) {
                              databaseReference.child('Users/${user.uid}/bio')
                                  .set(bio);
                            }
                          }
                          setState(() => isEditingBio = !isEditingBio);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getProfilePicturePath(int profilePic) {

    if (profilePic == 1) {
      return "assets/purple.png";
    } else if (profilePic == 2) {
      return "assets/blue.png";
    } else if (profilePic == 3) {
      return "assets/blue-purple.png";
    } else if (profilePic == 4) {
      return "assets/orange.png";
    } else if (profilePic == 5) {
      return "assets/pink.png";
    } else if (profilePic == 6) {
      return "assets/turquoise.png";
    }

    return "assets/blue.png";
  }
}
class ProfileInfoBox extends StatelessWidget {
  final String title;
  final String subtitle;
  ProfileInfoBox({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

  }

}
